import XCTest
@testable import LorePocketCore

final class CarouselMetricsTests: XCTestCase {
    func testNarrowPhoneKeepsRoomForAPeek() {
        let width = CarouselMetrics.cardWidth(containerWidth: 320)
        XCTAssertEqual(width, 264)
        XCTAssertEqual(CarouselMetrics.sideMargin(containerWidth: 320, cardWidth: width), 28)
        XCTAssertLessThan(width, 320)
    }

    func testWideScreenCapsTheCard() {
        let width = CarouselMetrics.cardWidth(containerWidth: 800)
        XCTAssertEqual(width, 340)
        XCTAssertGreaterThan(CarouselMetrics.sideMargin(containerWidth: 800, cardWidth: width), 28)
    }
}
