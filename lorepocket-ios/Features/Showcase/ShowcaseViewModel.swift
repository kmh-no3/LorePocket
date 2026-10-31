import Foundation
import Observation

@Observable
final class ShowcaseViewModel {
    var card: CardModel
    var caseStyle: CaseStyle = .clear
    var lightPreset: LightPreset = .standard
    var pedestalStyle: PedestalStyle = .graphite
    var rotationY: Float = 0

    init(card: CardModel = .sample) {
        self.card = card
    }

    var presentation: ShowcasePresentation {
        ShowcasePresentation(
            caseStyle: caseStyle,
            light: lightPreset,
            pedestal: pedestalStyle
        )
    }

    /// 回転・ケース・ライト・台座を初期状態へ戻す。
    /// `rotationY` を渡したときはその角度を残し、見た目のプリセットだけ戻す。
    func reset(rotationY: Float = 0) {
        self.rotationY = rotationY
        caseStyle = ShowcasePresentation.initial.caseStyle
        lightPreset = ShowcasePresentation.initial.light
        pedestalStyle = ShowcasePresentation.initial.pedestal
    }
}

struct ShowcasePresentation: Equatable {
    var caseStyle: CaseStyle
    var light: LightPreset
    var pedestal: PedestalStyle

    static let initial = ShowcasePresentation(
        caseStyle: .clear,
        light: .standard,
        pedestal: .graphite
    )
}

enum CaseStyle: String, CaseIterable, Identifiable {
    case clear, smoky, gold
    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear: return "クリア"
        case .smoky: return "スモーク"
        case .gold: return "ゴールド"
        }
    }
}

enum LightPreset: String, CaseIterable, Identifiable {
    case soft, standard, bright
    var id: String { rawValue }

    /// ルーメン。standard は従来の 2000。
    var intensity: Float {
        switch self {
        case .soft: return 600
        case .standard: return 2000
        case .bright: return 6000
        }
    }

    /// メートル。standard は従来の 2。
    var attenuationRadius: Float {
        switch self {
        case .soft: return 3
        case .standard: return 2
        case .bright: return 3.5
        }
    }

    var title: String {
        switch self {
        case .soft: return "ソフト"
        case .standard: return "標準"
        case .bright: return "明るい"
        }
    }
}

enum PedestalStyle: String, CaseIterable, Identifiable {
    case graphite, walnut, stone
    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphite: return "グラファイト"
        case .walnut: return "ウォールナット"
        case .stone: return "ストーン"
        }
    }
}
