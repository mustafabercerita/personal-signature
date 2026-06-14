import SwiftUI
import AppKit

struct DrawingLine: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
}

struct DrawingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var manager: SignatureManager
    
    @State private var lines: [DrawingLine] = []
    @State private var currentLine = DrawingLine()
    
    let canvasSize = CGSize(width: 400, height: 200)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Draw Signature")
                    .font(.headline)
                Spacer()
                Button(action: {
                    lines.removeAll()
                    currentLine = DrawingLine()
                }) {
                    Text("Clear")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .padding()
            
            Divider()
            
            // Canvas
            ZStack {
                Color.white // Ensure white background for contrast while drawing, we'll strip it later.
                
                Canvas { context, size in
                    for line in lines {
                        var path = Path()
                        path.addLines(line.points)
                        context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    var path = Path()
                    path.addLines(currentLine.points)
                    context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            let newPoint = value.location
                            currentLine.points.append(newPoint)
                        }
                        .onEnded { value in
                            lines.append(currentLine)
                            currentLine = DrawingLine()
                        }
                )
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .border(Color.gray.opacity(0.2), width: 1)
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button("Save Signature") {
                    saveSignature()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(lines.isEmpty && currentLine.points.isEmpty)
            }
            .padding()
        }
        .frame(width: canvasSize.width)
    }
    
    @MainActor
    private func saveSignature() {
        let exportView = ZStack {
            Color.clear // Transparent background
            Canvas { context, size in
                for line in lines {
                    var path = Path()
                    path.addLines(line.points)
                    context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 2.0 // Retina quality
        
        if let nsImage = renderer.nsImage {
            do {
                try manager.saveSignature(image: nsImage, removeBackground: false) // Background is already clear!
                presentationMode.wrappedValue.dismiss()
            } catch {
                manager.showToast("Failed to save drawing: \(error.localizedDescription)")
            }
        }
    }
}
