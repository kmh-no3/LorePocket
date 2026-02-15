import Foundation
import Observation

@Observable
final class ShowcaseViewModel {
    var card: CardModel
    var caseStyle: CaseStyle = .clear
    var rotationY: Float = 0

    init(card: CardModel = .sample) {
        self.card = card
    }
}

enum CaseStyle: String, CaseIterable, Identifiable {
    case clear, smoky, gold
    var id: String { rawValue }
}
