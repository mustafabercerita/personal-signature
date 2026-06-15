import SwiftUI

struct ImageEditorView: View {
    @EnvironmentObject private var manager: SignatureManager
    
    let sourceImage: NSImage
    
    @State private var contrast: Double = 1.0
    @State private var brightness: Double = 0.0
    @State private var thicken: Double = 0.0
    @State private var rotation: Double = 0
    @State private var autoTrim: Bool = true
    @State private var removeBackground: Bool = true
    @State private var previewWhiteBackground: Bool = true
    @State private var zoomLevel: Double = 1.0
    
    @State private var previewImage: NSImage?
    @State private var isProcessingPreview: Bool = false
    @State private var previewUpdateTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Signature")
                    .font(.headline)
                Spacer()
                Button(action: {
                    manager.pendingImageToEdit = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            // Preview Area
            ZStack {
                Color(previewWhiteBackground ? NSColor.white : NSColor.controlBackgroundColor)
                
                if let img = previewImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .scaleEffect(zoomLevel)
                }
                
                if isProcessingPreview {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                }
            }
            .frame(height: 200)
            .clipped()
            
            Divider()
            
            // Controls
            VStack(spacing: 16) {
                // Rotation Slider
                HStack {
                    Text("Rotate")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: $rotation, in: -180.0...180.0)
                    Text(String(format: "%.0f°", rotation))
                        .frame(width: 40, alignment: .trailing)
                    
                    // Reset Button
                    Button(action: { rotation = 0 }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Reset Rotation")
                }
                
                // Contrast Slider
                HStack {
                    Text("Contrast")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: $contrast, in: 0.5...3.0)
                    Text(String(format: "%.1f", contrast))
                        .frame(width: 30, alignment: .trailing)
                }
                
                // Brightness Slider
                HStack {
                    Text("Brightness")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: $brightness, in: -0.5...0.5)
                    Text(String(format: "%.1f", brightness))
                        .frame(width: 30, alignment: .trailing)
                }
                
                // Thicken Slider
                HStack {
                    Text("Thicken")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: $thicken, in: 0.0...30.0)
                    Text(String(format: "%.0f", thicken))
                        .frame(width: 30, alignment: .trailing)
                }
                
                // Zoom Slider
                HStack {
                    Text("Zoom")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: $zoomLevel, in: 0.5...5.0)
                    Text(String(format: "%.1f x", zoomLevel))
                        .frame(width: 30, alignment: .trailing)
                }
                
                HStack(spacing: 16) {
                    Toggle("Auto-Trim", isOn: $autoTrim)
                    Toggle("Remove Bg", isOn: $removeBackground)
                    Toggle("White Canvas", isOn: $previewWhiteBackground)
                }
                .padding(.top, 4)
            }
            .padding(16)
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    manager.pendingImageToEdit = nil
                    manager.pendingEditSignatureID = nil
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Save Signature") {
                    saveEditedImage()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(isProcessingPreview || previewImage == nil)
            }
            .padding(16)
        }
        .frame(width: 400)
        .onAppear {
            updatePreview()
        }
        .onChange(of: contrast) { _ in updatePreview() }
        .onChange(of: brightness) { _ in updatePreview() }
        .onChange(of: thicken) { _ in updatePreview() }
        .onChange(of: rotation) { _ in updatePreview() }
        .onChange(of: autoTrim) { _ in updatePreview() }
        .onChange(of: removeBackground) { _ in updatePreview() }
        .onDisappear {
            previewUpdateTask?.cancel()
        }
    }
    
    private func updatePreview() {
        previewUpdateTask?.cancel()
        
        let currentContrast = contrast
        let currentBrightness = brightness
        let currentThicken = thicken
        let currentRotation = rotation
        let currentAutoTrim = autoTrim
        let currentRemoveBg = removeBackground
        
        previewUpdateTask = Task {
            // Debounce 0.1 seconds
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run { isProcessingPreview = true }
            
            let finalImg = await Task.detached(priority: .userInitiated) { () -> NSImage? in
                var img = sourceImage
                
                // 0. Thicken Lines
                if currentThicken > 0 {
                    if let thickened = ImageProcessor.thickenLines(image: img, radius: currentThicken) {
                        img = thickened
                    }
                }
                guard !Task.isCancelled else { return nil }

                // 1. Color Adjustments
                if let colorAdjusted = ImageProcessor.adjustColor(image: img, contrast: currentContrast, brightness: currentBrightness) {
                    img = colorAdjusted
                }
                guard !Task.isCancelled else { return nil }

                // 2. Rotation
                if currentRotation != 0 {
                    if let rotated = ImageProcessor.rotate(image: img, degrees: CGFloat(currentRotation)) {
                        img = rotated
                    }
                }
                guard !Task.isCancelled else { return nil }

                // 3. Remove Background
                if currentRemoveBg {
                    if let removed = img.removingWhiteBackground() {
                        img = removed
                    }
                }
                guard !Task.isCancelled else { return nil }

                // 4. Auto-Trim
                if currentAutoTrim {
                    let dynamicPadding = max(10, Int(ceil(currentThicken)) + 12)
                    if let trimmed = ImageProcessor.autoTrimWhitespace(image: img, padding: dynamicPadding) {
                        img = trimmed
                    }
                }
                
                return img
            }.value
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                if let finalImg = finalImg {
                    self.previewImage = finalImg
                }
                self.isProcessingPreview = false
            }
        }
    }
    
    private func saveEditedImage() {
        guard let finalImage = previewImage else { return }
        
        let targetID = manager.pendingEditSignatureID
        manager.pendingImageToEdit = nil
        manager.pendingEditSignatureID = nil
        manager.isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try manager.saveSignature(image: finalImage, removeBackground: false, vectorize: false, overwriteID: targetID)
                DispatchQueue.main.async {
                    manager.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    manager.errorMessage = error.localizedDescription
                    manager.isProcessing = false
                }
            }
        }
    }
}
