import AppKit
import SwiftUI

/// AppDelegate — manages the NSStatusItem (menu bar icon) and its popover.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var signatureManager = SignatureManager.shared
    private var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make this a background-only (menu bar) app
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "signature",
                accessibilityDescription: "Personal Signature"
            )
            button.image?.isTemplate = true   // Adapts to light/dark menu bar
            button.action = #selector(togglePopover)
            button.target = self
            button.toolTip = "Personal Signature"
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 340)
        popover.behavior = .transient
        popover.animates = true

        let contentView = MenuBarView()
            .environmentObject(signatureManager)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    // MARK: - Event Monitor (close popover on outside click)

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }

        // Dynamically resize popover based on state
        let hasSignature = signatureManager.signatureImage != nil
        popover.contentSize = NSSize(width: 300, height: hasSignature ? 340 : 240)

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        eventMonitor?.start()
    }

    private func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
}
