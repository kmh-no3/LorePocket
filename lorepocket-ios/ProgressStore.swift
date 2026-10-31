import Foundation
import Observation

@MainActor
@Observable
final class ProgressStore {
    private(set) var root: ProgressRoot

    private let fileURL: URL

    init(filename: String = "progress.json", directory: URL? = nil) {
        let directory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = directory.appendingPathComponent(filename)
        self.root = (try? ProgressCoding.load(from: fileURL)) ?? .init()
    }

    func progress(for packId: String) -> PackProgress {
        ProgressBook.progress(in: root, packId: packId)
    }

    func canDrawToday(packId: String, calendar: Calendar = .current) -> Bool {
        ProgressBook.canDraw(
            lastDrawDate: progress(for: packId).lastDrawDate,
            now: Date(),
            calendar: calendar
        )
    }

    func recordDraw(packId: String, ownedCard: OwnedCard) {
        ProgressBook.recordDraw(root: &root, packId: packId, ownedCard: ownedCard)
        save()
    }

    func resetAll() {
        ProgressBook.resetAll(root: &root)
        save()
    }

    private func save() {
        do {
            try ProgressCoding.save(root, to: fileURL)
        } catch {
            // 保存失敗は画面に出さない。破損ファイルを空で上書きしない処置は LP-24 で足す。
        }
    }
}
