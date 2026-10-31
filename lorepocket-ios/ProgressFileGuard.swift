import Foundation

/// 進捗ファイルの読み込み結果。壊れているときは元ファイルを上書きしない。
struct ProgressSession: Equatable {
    var root: ProgressRoot
    var writesEnabled: Bool
    var loadWarning: String?
    var quarantineURL: URL?

    static func open(url: URL, now: Date = Date(), fileManager: FileManager = .default) -> ProgressSession {
        guard fileManager.fileExists(atPath: url.path) else {
            return ProgressSession(root: ProgressRoot(), writesEnabled: true, loadWarning: nil, quarantineURL: nil)
        }
        do {
            let root = try ProgressCoding.load(from: url)
            return ProgressSession(root: root, writesEnabled: true, loadWarning: nil, quarantineURL: nil)
        } catch {
            let copy = quarantineCopy(of: url, now: now, fileManager: fileManager)
            return ProgressSession(
                root: ProgressRoot(),
                writesEnabled: false,
                loadWarning: "進捗ファイルを読めませんでした。元のファイルは残してあります。",
                quarantineURL: copy
            )
        }
    }

    mutating func record(packId: String, ownedCard: OwnedCard) {
        ProgressBook.recordDraw(root: &root, packId: packId, ownedCard: ownedCard)
    }

    mutating func resetAll() {
        ProgressBook.resetAll(root: &root)
        writesEnabled = true
        loadWarning = nil
    }

    func persist(to url: URL) throws {
        guard writesEnabled else { return }
        try ProgressCoding.save(root, to: url)
    }

    static func quarantineCopy(of url: URL, now: Date, fileManager: FileManager) -> URL? {
        let destination = url.deletingLastPathComponent()
            .appendingPathComponent("progress.corrupt-\(Int(now.timeIntervalSince1970)).json")
        guard destination.path != url.path else { return nil }
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}
