import XCTest
@testable import Ponten

final class ImageProcessorTests: XCTestCase {

    func testThickenLines() {
        let size = CGSize(width: 50, height: 50)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.black.setFill()
        NSRect(x: 20, y: 20, width: 10, height: 10).fill()
        image.unlockFocus()

        guard let result = ImageProcessor.thickenLines(image: image, radius: 5.0) else {
            XCTFail("Failed to thicken lines")
            return
        }
        XCTAssertNotNil(result)
        // ImageProcessor.thickenLines adds padding to prevent clipping
        XCTAssertTrue(result.size.width > size.width, "Padding should be added")
    }

    func testHasPredominantlyWhiteEdgesFailsClosedOnInvalidImage() {
        let image = NSImage(size: .zero)
        XCTAssertFalse(image.hasPredominantlyWhiteOrTransparentEdges())
    }

    func testAutoTrimWhitespace() {
        let size = CGSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.black.setFill()
        NSRect(x: 40, y: 40, width: 20, height: 20).fill()
        image.unlockFocus()
        
        guard let result = ImageProcessor.autoTrimWhitespace(image: image, padding: 0) else {
            XCTFail("Failed to trim whitespace")
            return
        }
        XCTAssertNotNil(result)
        XCTAssertTrue(result.size.width <= 21, "Cropping should have reduced the size significantly")
    }
}
