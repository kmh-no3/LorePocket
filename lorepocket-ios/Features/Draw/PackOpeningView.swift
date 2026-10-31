import SwiftUI
import UIKit

extension View {
    /// 開封を全面で出し、閉じたあとに結果を渡す。カバーを出しながらシートを出さない。
    func drawOpening(
        pack: Binding<Pack?>,
        store: ProgressStore,
        onResult: @escaping (Pack, DrawEngine.DrawResult) -> Void
    ) -> some View {
        modifier(DrawOpeningModifier(pack: pack, store: store, onResult: onResult))
    }
}

private struct DrawOpeningModifier: ViewModifier {
    @Binding var pack: Pack?
    var store: ProgressStore
    var onResult: (Pack, DrawEngine.DrawResult) -> Void
    @State private var pending: PendingDraw?

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $pack) { item in
                PackOpeningView(pack: item, store: store) { result in
                    pending = PendingDraw(pack: item, result: result)
                    pack = nil
                } onCancel: {
                    pack = nil
                }
            }
            .onChange(of: pack?.id) {
                guard pack == nil, let pending else { return }
                onResult(pending.pack, pending.result)
                self.pending = nil
            }
    }
}

private struct PendingDraw {
    var pack: Pack
    var result: DrawEngine.DrawResult
}

struct PackOpeningView: View {
    let pack: Pack
    @Bindable var store: ProgressStore
    var onComplete: (DrawEngine.DrawResult) -> Void
    var onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = DrawSession()
    @State private var appeared = false
    @State private var didFinish = false
    @State private var advanceTask: Task<Void, Never>?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 0)
                stage
                caption
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                if session.phase == .sealed {
                    Button("閉じる", action: cancel)
                        .accessibilityLabel("開封をやめる")
                }
                Spacer()
                Button("スキップ") {
                    begin(.skip)
                }
                .font(.headline)
                .accessibilityLabel("演出をスキップ")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onAppear {
            appeared = true
        }
        .onDisappear {
            advanceTask?.cancel()
            finishIfNeeded()
        }
        .alert("ドローできませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var stage: some View {
        switch session.phase {
        case .sealed:
            PackCoverView(pack: pack)
                .frame(maxWidth: 300)
                .aspectRatio(0.8, contentMode: .fit)
                .scaleEffect(reduceMotion || appeared ? 1 : 0.94)
                .animation(reduceMotion ? nil : .spring(duration: 0.35), value: appeared)
                .onTapGesture { begin(.start) }
                .gesture(openSwipe)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("タップまたは上にスワイプして開封します")
        case .opening, .revealed, .settled:
            if let result = session.result {
                revealedCard(result)
            }
        }
    }

    private func revealedCard(_ result: DrawEngine.DrawResult) -> some View {
        let glow = glowColor(for: result.variant, active: session.phase != .opening)
        return CardView(card: result.card, variant: result.variant)
            .shadow(color: glow, radius: glowRadius(for: result.variant))
            .scaleEffect(session.phase == .opening && !reduceMotion ? 0.9 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.45), value: session.phase)
            .accessibilityElement(children: .combine)
    }

    private var caption: some View {
        Text(session.phase == .sealed ? "タップまたは上にスワイプ" : " ")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(minHeight: 22)
    }

    private var openSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                if value.translation.height < -48, abs(value.translation.width) < 120 {
                    begin(.start)
                }
            }
    }

    private func begin(_ action: DrawSession.Action) {
        if action != .advance {
            advanceTask?.cancel()
        }
        var rng = SystemRandomNumberGenerator()
        let outcome = session.handle(action, canDraw: store.canDrawToday(packId: pack.id), reduceMotion: reduceMotion) {
            try DrawEngine.draw(
                pack: pack,
                progress: store.progress(for: pack.id),
                now: Date(),
                rng: &rng
            )
        }
        if outcome.shouldPersist, let result = outcome.result {
            store.recordDraw(packId: pack.id, ownedCard: result.ownedCard)
            haptic(for: result.variant)
        }
        if let failure = outcome.failure {
            errorMessage = failure == .emptyCards
                ? "カードが空です。"
                : "バリアントが空です。"
            return
        }
        if outcome.blocked {
            errorMessage = "今日はすでに引いています。"
            return
        }
        switch session.phase {
        case .opening:
            scheduleAdvance(after: .milliseconds(480))
        case .revealed:
            scheduleAdvance(after: .milliseconds(620))
        case .settled:
            finishIfNeeded()
        case .sealed:
            break
        }
    }

    private func scheduleAdvance(after delay: Duration) {
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, !didFinish else { return }
            begin(.advance)
        }
    }

    private func finishIfNeeded() {
        guard !didFinish, let result = session.result else { return }
        didFinish = true
        advanceTask?.cancel()
        onComplete(result)
    }

    private func cancel() {
        guard session.result == nil else {
            finishIfNeeded()
            return
        }
        guard !didFinish else { return }
        didFinish = true
        advanceTask?.cancel()
        onCancel()
    }

    private func glowColor(for variant: Variant, active: Bool) -> Color {
        guard active else { return .clear }
        switch Rarity(variantRarity: variant.rarity) {
        case .rare: return .blue.opacity(0.45)
        case .epic: return .purple.opacity(0.55)
        case .legendary: return .orange.opacity(0.7)
        default: return .clear
        }
    }

    private func glowRadius(for variant: Variant) -> CGFloat {
        guard session.phase != .opening else { return 0 }
        switch Rarity(variantRarity: variant.rarity) {
        case .rare: return 12
        case .epic: return 20
        case .legendary: return 32
        default: return 0
        }
    }

    private func haptic(for variant: Variant) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch Rarity(variantRarity: variant.rarity) {
        case .legendary: style = .heavy
        case .epic, .rare: style = .medium
        default: style = .light
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
