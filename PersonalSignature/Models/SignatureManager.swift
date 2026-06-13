import AppKit
import Foundation

/// Persists and vends the active signature image.
/// Storage: the PNG is copied into ~/Library/Application Support/PersonalSignature/signature.png
final class SignatureManager: ObservableObject {

    static let shared = SignatureManager()

    // MARK: - Published State

    @Published private(set) var signatureImage: NSImage?
    @Published var toastMessage: String?

    private var toastTimer: Timer?

    // MARK: - Paths

    private let storageDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PersonalSignature", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var signaturePath: URL {
        storageDirectory.appendingPathComponent("signature.png")
    }

    // MARK: - Init

    private init() {
        loadSignature()
    }

    // MARK: - Load

    private func loadSignature() {
        guard FileManager.default.fileExists(atPath: signaturePath.path),
              let img = NSImage(contentsOf: signaturePath) else { return }
        signatureImage = img
    }

    // MARK: - Save

    /// Copies the user-chosen PNG file into the app's storage directory.
    func saveSignature(from sourceURL: URL) throws {
        let dest = signaturePath

        // Validate it's actually a PNG
        guard let img = NSImage(contentsOf: sourceURL) else {
            throw SignatureError.invalidImage
        }

        // Re-encode as PNG to guarantee format
        guard let tiff = img.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw SignatureError.encodingFailed
        }

        try pngData.write(to: dest, options: .atomic)

        DispatchQueue.main.async {
            self.signatureImage = img
        }
    }

    // MARK: - Copy to Clipboard

    func copySignatureToClipboard() {
        guard let image = signatureImage else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])

        showToast("Signature copied to clipboard ✓")
    }

    // MARK: - Delete

    func deleteSignature() {
        try? FileManager.default.removeItem(at: signaturePath)
        DispatchQueue.main.async {
            self.signatureImage = nil
        }
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toastTimer?.invalidate()
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.toastMessage = nil
                }
            }
        }
    }
}

// MARK: - Errors

enum SignatureError: LocalizedError {
    case invalidImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:    return "The selected file is not a valid image."
        case .encodingFailed:  return "Failed to process the image file."
        }
    }
}
