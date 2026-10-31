import Foundation

/// 画面幅からカルーセルのカード幅を決める。隣が少し見えるように左右を空け、広すぎる画面では幅を頭打ちにする。
enum CarouselMetrics {
    static func cardWidth(containerWidth: Double) -> Double {
        let inset = 56.0
        return min(max(0, containerWidth - inset), 340)
    }

    static func sideMargin(containerWidth: Double, cardWidth: Double) -> Double {
        max(0, (containerWidth - cardWidth) / 2)
    }
}
