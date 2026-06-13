import AppKit
import SwiftUI

/// AppDelegate — manages the NSStatusItem (menu bar icon) and its popover.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var signatureManager = SignatureManager.shared
    private var eventMonitor: EventMonitor?
    private var globalHotkeyMonitor: Any?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only: hide from Dock and ⌘Tab switcher
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupGlobalHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        teardownGlobalHotkey()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "signature",
                accessibilityDescription: "Personal Signature — click to open"
            )
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Personal Signature"
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.animates = true

        let contentView = MenuBarView()
            .environmentObject(signatureManager)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 300, height: 340)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 300, height: 340)
    }

    // MARK: - Event Monitor (close on outside click)

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.closePopover()
        }
    }

    // MARK: - Global Hotkey (⌥⌘S)

    private func setupGlobalHotkey() {
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌥⌘S — Option + Command + S
            let optionCommand: NSEvent.ModifierFlags = [.option, .command]
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == optionCommand,
                  event.charactersIgnoringModifiers?.lowercased() == "s" else { return }

            let copied = self?.signatureManager.copySignatureToClipboard() ?? false
            if !copied && self?.signatureManager.signatureImage == nil {
                // No signature yet — open popover to let user add one
                DispatchQueue.main.async { self?.openPopover() }
            }
        }
    }

    private func teardownGlobalHotkey() {
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalHotkeyMonitor = nil
        }
    }

    // MARK: - Popover Control

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    func openPopover() {
        guard let button = statusItem.button else { return }

        // Resize based on current state
        let hasSignature = signatureManager.signatureImage != nil
        let height: CGFloat = hasSignature ? 360 : 260
        popover.contentSize = NSSize(width: 300, height: height)

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        eventMonitor?.start()
    }

    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
}
