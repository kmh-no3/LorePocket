import Foundation

/// 開封の進行。抽選そのものは `DrawEngine` に任せ、この型は「いつ1回だけ引くか」だけを持つ。
struct DrawSession: Equatable {
    enum Phase: Equatable {
        case sealed
        case opening
        case revealed
        case settled
    }

    enum Action: Equatable {
        /// タップ、または開封方向へのスワイプ。
        case start
        /// 演出を飛ばして結果へ進む。封のままなら、ここで1回だけ引く。
        case skip
        /// すでに引き終わったあとの段階を一つ進める。封のままでは引かない。
        case advance
    }

    struct Outcome: Equatable {
        var shouldPersist: Bool
        var result: DrawEngine.DrawResult?
        var blocked: Bool
        var failure: DrawEngine.DrawError?
    }

    private(set) var phase: Phase
    private(set) var result: DrawEngine.DrawResult?

    init() {
        phase = .sealed
        result = nil
    }

    mutating func handle(
        _ action: Action,
        canDraw: Bool,
        reduceMotion: Bool = false,
        draw: () throws -> DrawEngine.DrawResult
    ) -> Outcome {
        if result != nil {
            moveCommitted(action)
            return Outcome(shouldPersist: false, result: result, blocked: false, failure: nil)
        }

        switch action {
        case .advance:
            return Outcome(shouldPersist: false, result: nil, blocked: false, failure: nil)
        case .start, .skip:
            guard canDraw else {
                return Outcome(shouldPersist: false, result: nil, blocked: true, failure: nil)
            }
            let drawn: DrawEngine.DrawResult
            do {
                drawn = try draw()
            } catch let error as DrawEngine.DrawError {
                return Outcome(shouldPersist: false, result: nil, blocked: false, failure: error)
            } catch {
                return Outcome(shouldPersist: false, result: nil, blocked: false, failure: .emptyCards)
            }
            result = drawn
            if action == .skip || reduceMotion {
                phase = .settled
            } else {
                phase = .opening
            }
            return Outcome(shouldPersist: true, result: drawn, blocked: false, failure: nil)
        }
    }

    private mutating func moveCommitted(_ action: Action) {
        switch action {
        case .skip:
            phase = .settled
        case .start, .advance:
            switch phase {
            case .sealed, .opening:
                phase = .revealed
            case .revealed, .settled:
                phase = .settled
            }
        }
    }
}
