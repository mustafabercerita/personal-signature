import XCTest
@testable import Ponten

@MainActor
final class SignatureManagerTests: XCTestCase {

    var manager: SignatureManager!
    var testStore: SignatureStore!
    var testDirectory: URL!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PontenTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)

        testStore = SignatureStore(storageDirectory: testDirectory)
        manager = SignatureManager(store: testStore)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testDirectory)
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Creates a minimal valid PNG with white edges in the test directory.
    private func makePNGFile(named name: String = "test_signature.png") throws -> URL {
        let url = testDirectory.appendingPathComponent(name)
        let image = NSImage(size: NSSize(width: 200, height: 80))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 200, height: 80)).fill()
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(x: 10, y: 30, width: 180, height: 20)).fill()
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw XCTSkip("Could not create test PNG — skipping")
        }
        try png.write(to: url)
        return url
    }

    // MARK: - Tests

    func testInitialStateHasNoSignature() {
        XCTAssertNil(manager.signatureImage, "Should start with no signature")
    }

    func testSaveValidPNGLoadsImage() throws {
        let url = try makePNGFile()
        XCTAssertNoThrow(try manager.saveSignature(from: url))
        XCTAssertNotNil(manager.signatureImage)
    }

    func testSaveInvalidPathThrowsError() {
        let badURL = URL(fileURLWithPath: "/nonexistent/path/signature.png")
        XCTAssertThrowsError(try manager.saveSignature(from: badURL)) { error in
            XCTAssertTrue(error is SignatureError)
        }
    }

    func testDeleteSignatureClearsImage() throws {
        let url = try makePNGFile()
        try manager.saveSignature(from: url)
        XCTAssertNotNil(manager.signatureImage)

        manager.deleteSignature()
        XCTAssertNil(manager.signatureImage)
    }

    func testCopyToClipboardReturnsFalseWithNoSignature() {
        let result = manager.copySignatureToClipboard()
        XCTAssertFalse(result, "Should return false when no signature is set")
    }

    func testCopyToClipboardReturnsTrueWithSignature() throws {
        let url = try makePNGFile()
        try manager.saveSignature(from: url)
        XCTAssertNotNil(manager.signatureImage)

        let result = manager.copySignatureToClipboard()
        XCTAssertTrue(result)
        let hasImage = NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: nil)
        XCTAssertTrue(hasImage, "Pasteboard should contain an image")
    }

    func testToastMessageClearsAfterDelay() {
        manager.showToast("Test toast")

        let predicateSet = NSPredicate { _, _ in
            self.manager.toastMessage != nil
        }
        let expSet = XCTNSPredicateExpectation(predicate: predicateSet, object: nil)
        wait(for: [expSet], timeout: 2.0)

        let predicateClear = NSPredicate { _, _ in
            self.manager.toastMessage == nil
        }
        let expClear = XCTNSPredicateExpectation(predicate: predicateClear, object: nil)
        wait(for: [expClear], timeout: 5.0)
    }

    func testReplacingSignatureUpdatesImage() throws {
        let url1 = try makePNGFile(named: "sig1.png")
        let url2 = try makePNGFile(named: "sig2.png")

        try manager.saveSignature(from: url1)
        XCTAssertNotNil(manager.signatureImage)
        let firstID = try XCTUnwrap(manager.activeSignatureID)

        try manager.saveSignature(from: url2)
        XCTAssertNotNil(manager.signatureImage)
        XCTAssertNotEqual(manager.activeSignatureID, firstID)
    }

    func testDeletingInactiveSignatureKeepsActiveSignature() throws {
        let url1 = try makePNGFile(named: "sig1.png")
        let url2 = try makePNGFile(named: "sig2.png")

        try manager.saveSignature(from: url1)
        let firstID = try XCTUnwrap(manager.activeSignatureID)

        try manager.saveSignature(from: url2)
        let activeID = try XCTUnwrap(manager.activeSignatureID)
        XCTAssertNotEqual(firstID, activeID)

        manager.deleteSignature(id: firstID)

        XCTAssertEqual(manager.activeSignatureID, activeID)
        XCTAssertNotNil(manager.signatureImage)
    }
}