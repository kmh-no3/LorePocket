import Foundation
import UIKit

@MainActor
enum PackCoverProvider {
    private static var cache: [String: UIImage] = [:]
    
    static func coverImage(packId: String) -> UIImage? {
        if let cached = cache[packId] { return cached }
        guard let url = try? PackStorage.packDirectory(packId: packId)
            .appendingPathComponent("assets", isDirectory: true) else { return nil }
        
        let candidates = [
            url.appendingPathComponent("cover.png"),
            url.appendingPathComponent("cover.jpg"),
            url.appendingPathComponent("cover.jpeg"),
        ]
        for c in candidates {
            if let img = UIImage(contentsOfFile: c.path) {
                cache[packId] = img
                return img
            }
        }
        return nil
    }
}


