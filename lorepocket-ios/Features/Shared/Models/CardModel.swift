import Foundation

struct CardModel: Identifiable {
    let id: String
    let title: String

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    init(card: Card) {
        self.id = card.id
        self.title = card.person
    }

    static let sample = CardModel(id: "sample-001", title: "Sample Card")
}
