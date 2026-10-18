import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let preferences = Preferences()
    let zoom = ZoomCapture()
    let keys = KeystrokeMonitor()
    var overlay: OverlayController!
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makeMainMenu()
        overlay = OverlayController(preferences: preferences, zoom: zoom, keys: keys)
        zoom.onPermissionNeeded = { [weak self] in self?.showSettings() }
        keys.onPermissionNeeded = { [weak self] in self?.showSettings() }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let appIcon = NSImage(named: "AppIcon") ?? NSApplication.shared.applicationIconImage
        // Preserve the app icon silhouette and transparency, but draw it in white.
        if let appIcon {
            let menuBarIcon = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                appIcon.draw(in: rect)
                NSColor.white.setFill()
                rect.fill(using: .sourceAtop)
                return true
            }
            menuBarIcon.isTemplate = false
            menuBarIcon.accessibilityDescription = "BigMouse"
            statusItem.button?.imageScaling = .scaleProportionallyDown
            statusItem.button?.image = menuBarIcon
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refreshMenu()
        preferences.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.refreshMenu() }
            .store(in: &subscriptions)
        keys.$isEnabled.receive(on: RunLoop.main).sink { [weak self] _ in self?.refreshMenu() }
            .store(in: &subscriptions)
        if !UserDefaults.standard.bool(forKey: "hasLaunched") || !UserDefaults.standard.bool(forKey: "hasSeenVersion2") {
            showSettings()
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            UserDefaults.standard.set(true, forKey: "hasSeenVersion2")
        }
    }

    func makeMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L10n.text(.quit), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: L10n.text(.edit))
        for (title, action, key) in [(L10n.text(.copy), "copy:", "c"), (L10n.text(.paste), "paste:", "v"), (L10n.text(.selectAll), "selectAll:", "a")] {
            editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        editItem.submenu = editMenu
        main.addItem(editItem)
        NSApp.mainMenu = main
    }

    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }

    func refreshMenu() {
        guard let menu = statusItem?.menu else { return }
        menu.removeAllItems()
        let title = NSMenuItem(title: "BigMouse", action: nil, keyEquivalent: "")
        menu.addItem(title)
        menu.addItem(.separator())
        addItem(menu, title: preferences.enabled ? L10n.text(.pause) : L10n.text(.resume), action: #selector(toggleEnabled))
        addItem(menu, title: L10n.text(.cursorHighlight), action: #selector(toggleHalo), checked: preferences.haloEnabled)
        addItem(menu, title: L10n.text(.clickEffects), action: #selector(toggleClicks), checked: preferences.clicksEnabled)
        addItem(menu, title: L10n.text(.keysMenu), action: #selector(toggleKeys), checked: keys.isEnabled)
        addItem(menu, title: L10n.text(.spotlight), action: #selector(toggleSpotlight), checked: preferences.spotlightEnabled)
        addItem(menu, title: L10n.text(.zoom), action: #selector(toggleZoom), checked: preferences.zoomEnabled)
        let shortcut = NSMenuItem(title: L10n.spotlightShortcut(preferences.shortcut.title), action: nil, keyEquivalent: "")
        menu.addItem(shortcut)
        menu.addItem(.separator())
        addItem(menu, title: L10n.text(.settings), action: #selector(showSettings), key: ",")
        addItem(menu, title: L10n.text(.quit), action: #selector(quit), key: "q")
        statusItem.button?.appearsDisabled = !preferences.enabled
        statusItem.button?.toolTip = "BigMouse · " + (preferences.enabled ? L10n.text(.on) : L10n.text(.paused))
    }

    private func addItem(_ menu: NSMenu, title: String, action: Selector, checked: Bool? = nil, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        if let checked { item.state = checked ? .on : .off }
        menu.addItem(item)
    }

    @objc func toggleEnabled() { preferences.enabled.toggle() }
    @objc func toggleHalo() { preferences.haloEnabled.toggle() }
    @objc func toggleClicks() { preferences.clicksEnabled.toggle() }
    @objc func toggleKeys() { if preferences.enabled { keys.toggle() } }
    @objc func toggleSpotlight() { preferences.spotlightEnabled.toggle() }
    @objc func toggleZoom() { preferences.zoomEnabled.toggle() }
    @objc func quit() { NSApp.terminate(nil) }

    @objc func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView(preferences: preferences, zoom: zoom, keys: keys,
                                    previewSpotlight: { [weak self] in self?.overlay.previewSpotlight() },
                                    previewZoom: { [weak self] in self?.overlay.previewZoom() })
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: SettingsView.windowWidth, height: 790),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = L10n.text(.settingsTitle)
            window.contentView = NSHostingView(rootView: view)
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { overlay?.stop() }

    func applicationDidBecomeActive(_ notification: Notification) {
        zoom.refreshPermission()
        keys.refreshPermission()
        if preferences.enabled && preferences.zoomEnabled { zoom.prepare() }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
