import AppKit

/// AppKit menu panel used for in-process E2E tests where SwiftUI AX is unreliable on CI.
final class E2EMenuPanelView: NSView {
    let manager: SignatureManager

    private let stack = NSStackView()
    private let emptyLabel = NSTextField(labelWithString: "No signatures yet.")
    private let signatureList = NSStackView()
    private let signButton = NSButton()
    private let autoPasteCheckbox = NSButton(checkboxWithTitle: "Auto-paste after copying", target: nil, action: nil)
    private let quitButton = NSButton()

    init(manager: SignatureManager, frame: NSRect) {
        self.manager = manager
        super.init(frame: frame)
        configureViews()
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        wantsLayer = true

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14),
        ])

        emptyLabel.setAccessibilityIdentifier("empty-state")
        emptyLabel.setAccessibilityLabel("No signatures yet.")

        signatureList.orientation = .vertical
        signatureList.alignment = .leading
        signatureList.spacing = 6

        signButton.title = "Sign"
        signButton.bezelStyle = .rounded
        signButton.target = self
        signButton.action = #selector(signPressed)
        signButton.setAccessibilityIdentifier("sign-button")
        signButton.setAccessibilityLabel("Copy signature to clipboard")

        autoPasteCheckbox.target = self
        autoPasteCheckbox.action = #selector(autoPasteChanged)
        autoPasteCheckbox.setAccessibilityIdentifier("auto-paste-toggle")
        autoPasteCheckbox.setAccessibilityLabel("Auto-paste after copying")

        quitButton.title = "Quit"
        quitButton.bezelStyle = .inline
        quitButton.target = self
        quitButton.action = #selector(quitPressed)
        quitButton.setAccessibilityIdentifier("quit-button")
        quitButton.setAccessibilityLabel("Quit")

        stack.addArrangedSubview(emptyLabel)
        stack.addArrangedSubview(signatureList)
        stack.addArrangedSubview(signButton)
        stack.addArrangedSubview(autoPasteCheckbox)
        stack.addArrangedSubview(quitButton)
    }

    func reload() {
        let hasSignatures = !manager.signatures.isEmpty
        emptyLabel.isHidden = hasSignatures
        signatureList.isHidden = !hasSignatures
        signButton.isHidden = !hasSignatures

        signatureList.subviews.forEach { $0.removeFromSuperview() }
        for sig in manager.signatures {
            let button = NSButton(title: sig.item.name ?? "Signature", target: self, action: #selector(signatureSelected(_:)))
            button.bezelStyle = .inline
            button.setAccessibilityLabel(sig.item.name ?? "Signature")
            button.identifier = NSUserInterfaceItemIdentifier(sig.item.id.uuidString)
            signatureList.addArrangedSubview(button)
        }

        autoPasteCheckbox.state = manager.autoPaste ? .on : .off
        layoutSubtreeIfNeeded()
    }

    @objc private func signatureSelected(_ sender: NSButton) {
        guard let idString = sender.identifier?.rawValue,
              let id = UUID(uuidString: idString) else { return }
        manager.activeSignatureID = id
        reload()
    }

    @objc private func signPressed() {
        manager.copySignatureToClipboard()
    }

    @objc private func autoPasteChanged() {
        manager.autoPaste = autoPasteCheckbox.state == .on
    }

    @objc private func quitPressed() {
        if E2EMode.isEnabled && E2EMode.isInProcess {
            window?.close()
        } else {
            NSApp.terminate(nil)
        }
    }
}