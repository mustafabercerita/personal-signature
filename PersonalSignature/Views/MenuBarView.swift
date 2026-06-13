import SwiftUI

/// Root view rendered inside the NSPopover.
struct MenuBarView: View {
    @EnvironmentObject private var manager: SignatureManager

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HeaderView()
                Divider()

                if manager.signatureImage != nil {
                    SignatureActiveView()
                } else {
                    EmptyStateView()
                }

                Divider()
                FooterView()
            }
            .frame(width: 300)
            .background(Color(NSColor.windowBackgroundColor))

            // Toast overlay
            if let msg = manager.toastMessage {
                ToastView(message: msg)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: manager.toastMessage)
                    .zIndex(10)
            }
        }
    }
}

// MARK: - Header

private struct HeaderView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "signature")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("Personal Signature")
                .font(.system(size: 14, weight: .semibold))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Active State

private struct SignatureActiveView: View {
    @EnvironmentObject private var manager: SignatureManager
    @State private var isHoveringSign = false
    @State private var showFileImporter = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 14) {
            // Preview
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
                    )

                if let img = manager.signatureImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240, maxHeight: 100)
                        .padding(10)
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 16)
            .padding(.top, 14)

            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // Sign button
            Button(action: {
                manager.copySignatureToClipboard()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Sign")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 16)

            // Change signature button
            Button(action: { showFileImporter = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                    Text("Change Signature")
                        .font(.callout)
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.png, .jpeg, .tiff, .image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            do {
                try manager.saveSignature(from: url)
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    @State private var showFileImporter = false
    @State private var errorMessage: String?
    @EnvironmentObject private var manager: SignatureManager

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 72, height: 72)

                Image(systemName: "signature")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.accentColor.opacity(0.6))
            }

            VStack(spacing: 4) {
                Text("No signature saved yet.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text("Choose a PNG file to get started.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button(action: { showFileImporter = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Signature")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(height: 200)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.png, .jpeg, .tiff, .image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            do {
                try manager.saveSignature(from: url)
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Footer

private struct FooterView: View {
    var body: some View {
        HStack {
            Text("Personal Signature")
                .font(.caption2)
                .foregroundColor(Color.secondary.opacity(0.6))

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
