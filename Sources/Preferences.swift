import AppKit
import Combine
import SwiftUI

enum Accent: String, CaseIterable, Identifiable {
    case amber, coral, mint, blue, violet, black, white
    var id: String { rawValue }
    var title: String {
        switch self {
        case .amber: return L10n.text(.yellow)
        case .coral: return L10n.text(.orange)
        case .mint: return L10n.text(.green)
        case .blue: return L10n.text(.blue)
        case .violet: return L10n.text(.purple)
        case .black: return L10n.text(.black)
        case .white: return L10n.text(.white)
        }
    }
    var nsColor: NSColor {
        switch self {
        case .amber: return NSColor(srgbRed: 1, green: 0.76, blue: 0.12, alpha: 1)
        case .coral: return NSColor(srgbRed: 1, green: 0.36, blue: 0.23, alpha: 1)
        case .mint: return NSColor(srgbRed: 0.12, green: 0.78, blue: 0.53, alpha: 1)
        case .blue: return NSColor(srgbRed: 0.16, green: 0.57, blue: 1, alpha: 1)
        case .violet: return NSColor(srgbRed: 0.66, green: 0.40, blue: 1, alpha: 1)
        case .black: return NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        case .white: return NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    var color: Color { Color(nsColor: nsColor) }
}

enum SpotlightShortcut: String, CaseIterable, Identifiable {
    case control, optionShift, controlOption, controlShift
    var id: String { rawValue }
    var title: String {
        switch self {
        case .control: return "⌃ Control"
        case .optionShift: return "⌥ Option + ⇧ Shift"
        case .controlOption: return "⌃ Control + ⌥ Option"
        case .controlShift: return "⌃ Control + ⇧ Shift"
        }
    }
    var flags: NSEvent.ModifierFlags {
        switch self {
        case .control: return [.control]
        case .optionShift: return [.option, .shift]
        case .controlOption: return [.control, .option]
        case .controlShift: return [.control, .shift]
        }
    }
    func matches(_ current: NSEvent.ModifierFlags) -> Bool {
        current.intersection([.command, .option, .control, .shift]) == flags
    }
}

enum KeyDisplayFilter: String, CaseIterable, Identifiable {
    case shortcutsOnly, allKeys
    var id: String { rawValue }
    var title: String { L10n.text(self == .shortcutsOnly ? .shortcutsOnly : .allKeys) }
}

enum KeyDisplayMode: String, CaseIterable, Identifiable {
    case continuous, separate
    var id: String { rawValue }
    var title: String { self == .continuous ? L10n.text(.continuous) : L10n.text(.separate) }
}

enum KeyDisplayPosition: String, CaseIterable, Identifiable {
    case top, center, bottom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .top: return L10n.text(.top)
        case .center: return L10n.text(.center)
        case .bottom: return L10n.text(.bottom)
        }
    }

    /// Screen-local coordinates. Horizontal centering is always relative to the full screen.
    func frame(for size: CGSize, screen: CGRect, visible: CGRect) -> CGRect {
        let lower = max(0, visible.minY - screen.minY) + 28
        let upper = min(screen.height, visible.maxY - screen.minY) - 28 - size.height
        let desired: CGFloat
        switch self {
        case .top: desired = upper
        case .center: desired = (screen.height - size.height) / 2
        case .bottom: desired = lower
        }
        // Very small displays can lack room for both margins; keep the box on screen.
        let minimum = min(lower, max(0, screen.height - size.height))
        let maximum = max(minimum, upper)
        return CGRect(x: (screen.width - size.width) / 2, y: min(maximum, max(minimum, desired)),
                      width: size.width, height: size.height)
    }
}

enum KeyDisplayFont {
    static let system = "__system__"
    static let monospaced = "__monospaced__"
    static let families = NSFontManager.shared.availableFontFamilies
        .filter { !$0.hasPrefix(".") }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    static func resolve(_ family: String, size: Double) -> NSFont {
        let size = CGFloat(Preferences.clamp(size, to: 18...128, fallback: 28))
        if family == monospaced { return .monospacedSystemFont(ofSize: size, weight: .medium) }
        if family != system,
           let font = NSFontManager.shared.font(withFamily: family, traits: [], weight: 5, size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: .medium)
    }
}

final class Preferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var enabled: Bool { didSet { save() } }
    @Published var haloEnabled: Bool { didSet { save() } }
    @Published var clicksEnabled: Bool { didSet { save() } }
    @Published var spotlightEnabled: Bool { didSet { save() } }
    @Published var zoomEnabled: Bool { didSet { save() } }
    @Published var haloDiameter: Double { didSet { save() } }
    @Published var haloLineWidth: Double { didSet { save() } }
    @Published var haloOpacity: Double { didSet { save() } }
    @Published var spotlightDiameter: Double { didSet { save() } }
    @Published var dimOpacity: Double { didSet { save() } }
    @Published var zoomDiameter: Double { didSet { save() } }
    @Published var zoomScale: Double { didSet { save() } }
    @Published var hideWhenIdle: Bool { didSet { save() } }
    @Published var accent: Accent { didSet { save() } }
    @Published var shortcuts: ShortcutBindings { didSet { save() } }
    @Published var keyFontFamily: String { didSet { save() } }
    @Published var keyFontSize: Double { didSet { save() } }
    @Published var keyDisplayMode: KeyDisplayMode { didSet { save() } }
    @Published var keyDisplayPosition: KeyDisplayPosition { didSet { save() } }
    @Published var keyDisplayFilter: KeyDisplayFilter { didSet { save() } }
    @Published var keyIncludeSpecialKeys: Bool { didSet { save() } }

    var keyFont: NSFont { KeyDisplayFont.resolve(keyFontFamily, size: keyFontSize) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Older builds persist this marker on first launch. Keep their all-key behavior;
        // new installations start with shortcuts only. Persist the choice before the
        // marker is created so a second launch cannot look like a legacy upgrade.
        let initialFilter: KeyDisplayFilter = defaults.bool(forKey: "controlShortcutMigration") ? .allKeys : .shortcutsOnly
        let savedFilter = defaults.string(forKey: "keyDisplayFilter")
        let resolvedFilter = savedFilter.flatMap(KeyDisplayFilter.init(rawValue:))
            ?? (savedFilter == nil ? initialFilter : .shortcutsOnly)
        defaults.set(resolvedFilter.rawValue, forKey: "keyDisplayFilter")
        defaults.register(defaults: [
            "enabled": true, "haloEnabled": true, "clicksEnabled": true,
            "spotlightEnabled": true, "zoomEnabled": true, "haloDiameter": 56.0,
            "haloLineWidth": 2.5, "haloOpacity": 0.18, "zoomDiameter": 300.0, "zoomScale": 2.0,
            "spotlightDiameter": 320.0, "dimOpacity": 0.65, "hideWhenIdle": false,
            "accent": Accent.amber.rawValue, "shortcut": SpotlightShortcut.control.rawValue,
            "keyFontFamily": KeyDisplayFont.monospaced, "keyFontSize": 28.0,
            "keyDisplayMode": KeyDisplayMode.continuous.rawValue,
            "keyDisplayPosition": KeyDisplayPosition.bottom.rawValue,
            "keyIncludeSpecialKeys": true
        ])
        // Apply the user's requested shortcut once when upgrading the first prototype.
        if !defaults.bool(forKey: "controlShortcutMigration") {
            defaults.set(SpotlightShortcut.control.rawValue, forKey: "shortcut")
            defaults.set(true, forKey: "controlShortcutMigration")
        }
        enabled = defaults.bool(forKey: "enabled")
        haloEnabled = defaults.bool(forKey: "haloEnabled")
        clicksEnabled = defaults.bool(forKey: "clicksEnabled")
        spotlightEnabled = defaults.bool(forKey: "spotlightEnabled")
        zoomEnabled = defaults.bool(forKey: "zoomEnabled")
        haloDiameter = Self.clamp(defaults.double(forKey: "haloDiameter"), to: 28...160, fallback: 56)
        haloLineWidth = Self.clamp(defaults.double(forKey: "haloLineWidth"), to: 1...12, fallback: 2.5)
        haloOpacity = Self.clamp(defaults.double(forKey: "haloOpacity"), to: 0...0.6, fallback: 0.18)
        spotlightDiameter = Self.clamp(defaults.double(forKey: "spotlightDiameter"), to: 120...720, fallback: 320)
        dimOpacity = Self.clamp(defaults.double(forKey: "dimOpacity"), to: 0.15...0.9, fallback: 0.65)
        zoomDiameter = Self.clamp(defaults.double(forKey: "zoomDiameter"), to: 160...520, fallback: 300)
        zoomScale = Self.clamp(defaults.double(forKey: "zoomScale"), to: 1.5...4, fallback: 2)
        hideWhenIdle = defaults.bool(forKey: "hideWhenIdle")
        accent = Accent(rawValue: defaults.string(forKey: "accent") ?? "") ?? .amber
        let legacy = SpotlightShortcut(rawValue: defaults.string(forKey: "shortcut") ?? "") ?? .control
        var migrated = ShortcutBindings()
        migrated.spotlight = ShortcutBinding(flags: legacy.flags)
        if let data = defaults.data(forKey: "activationShortcuts"),
           let saved = try? JSONDecoder().decode(ShortcutBindings.self, from: data), saved.isValid {
            shortcuts = saved
        } else { shortcuts = migrated }
        let family = defaults.string(forKey: "keyFontFamily") ?? KeyDisplayFont.monospaced
        keyFontFamily = [KeyDisplayFont.system, KeyDisplayFont.monospaced].contains(family)
            || KeyDisplayFont.families.contains(family) ? family : KeyDisplayFont.monospaced
        keyFontSize = Self.clamp(defaults.double(forKey: "keyFontSize"), to: 18...128, fallback: 28)
        keyDisplayMode = KeyDisplayMode(rawValue: defaults.string(forKey: "keyDisplayMode") ?? "") ?? .continuous
        keyDisplayPosition = KeyDisplayPosition(rawValue: defaults.string(forKey: "keyDisplayPosition") ?? "") ?? .bottom
        keyDisplayFilter = resolvedFilter
        keyIncludeSpecialKeys = defaults.bool(forKey: "keyIncludeSpecialKeys")
        if let data = try? JSONEncoder().encode(shortcuts) { defaults.set(data, forKey: "activationShortcuts") }
    }

    static func clamp(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
    }

    private func save() {
        defaults.set(enabled, forKey: "enabled")
        defaults.set(haloEnabled, forKey: "haloEnabled")
        defaults.set(clicksEnabled, forKey: "clicksEnabled")
        defaults.set(spotlightEnabled, forKey: "spotlightEnabled")
        defaults.set(zoomEnabled, forKey: "zoomEnabled")
        defaults.set(haloDiameter, forKey: "haloDiameter")
        defaults.set(haloLineWidth, forKey: "haloLineWidth")
        defaults.set(haloOpacity, forKey: "haloOpacity")
        defaults.set(spotlightDiameter, forKey: "spotlightDiameter")
        defaults.set(dimOpacity, forKey: "dimOpacity")
        defaults.set(zoomDiameter, forKey: "zoomDiameter")
        defaults.set(zoomScale, forKey: "zoomScale")
        defaults.set(hideWhenIdle, forKey: "hideWhenIdle")
        defaults.set(accent.rawValue, forKey: "accent")
        if let data = try? JSONEncoder().encode(shortcuts) { defaults.set(data, forKey: "activationShortcuts") }
        defaults.set(keyFontFamily, forKey: "keyFontFamily")
        defaults.set(keyFontSize, forKey: "keyFontSize")
        defaults.set(keyDisplayMode.rawValue, forKey: "keyDisplayMode")
        defaults.set(keyDisplayPosition.rawValue, forKey: "keyDisplayPosition")
        defaults.set(keyDisplayFilter.rawValue, forKey: "keyDisplayFilter")
        defaults.set(keyIncludeSpecialKeys, forKey: "keyIncludeSpecialKeys")
    }
}
