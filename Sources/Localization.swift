import Foundation

enum AppLanguage: String, CaseIterable {
    case korean = "ko"
    case english = "en"

    /// Follow the macOS region, independently of the preferred UI language.
    /// A missing region also uses English.
    static func resolve(for locale: Locale) -> AppLanguage {
        locale.region?.identifier == "KR" ? .korean : .english
    }

    var locale: Locale { Locale(identifier: self == .korean ? "ko_KR" : "en_US") }
}

enum L10n {
    // Keep one language throughout a session; region changes apply on relaunch.
    static let language = AppLanguage.resolve(for: .current)

    enum Key: String, CaseIterable {
        case shortcutSettings
        case shortcutNone
        case shortcutHold
        case shortcutDoubleTap
        case shortcutToggle
        case shortcutEditHint
        case shortcutReset
        case shortcutRecordTitle
        case shortcutRecordHoldHelp
        case shortcutRecordToggleHelp
        case shortcutPressKeys
        case shortcutInvalid
        case shortcutDuplicate
        case shortcutUnavailable
        case shortcutCancel
        case shortcutApply
        case enableZoom
        case appIcon
        case enabled
        case haloPreview
        case accentColor
        case showHalo
        case ringSize
        case borderWidth
        case fill
        case hideWhenIdle
        case cursorHighlight
        case clickSparkles
        case clickEffects
        case showKeys
        case keysShortcutHint
        case keyFilter
        case shortcutsOnly
        case allKeys
        case includeSpecialKeys
        case specialKeysHelp
        case font
        case systemFont
        case monospacedFont
        case fontSize
        case keyFontSize
        case displayMode
        case displayPosition
        case inputPermissionRequired
        case permissionSettings
        case keysSection
        case enableSpotlight
        case holdKey
        case brightArea
        case dimLevel
        case holdKeyHint
        case preview
        case spotlight
        case holdFnToZoom
        case lensSize
        case zoomScale
        case zoomUnit
        case zoomPermissionRequired
        case zoom
        case on
        case paused
        case autoSaved
        case versionFormat
        case keyPreview
        case yellow
        case orange
        case green
        case blue
        case purple
        case black
        case white
        case continuous
        case separate
        case top
        case center
        case bottom
        case quit
        case edit
        case copy
        case paste
        case selectAll
        case pause
        case resume
        case keysMenu
        case spotlightShortcut
        case settings
        case settingsTitle
        case screenPermissionRestart
        case screenPermissionHelp
        case screenPermissionNeeded
        case screenNotFound
        case zoomStartFailed
        case captureStopped
        case keyPermissionNeeded
        case keyPermissionRestart
        case keysOn
    }

    private static let bundles: [AppLanguage: Bundle] = {
        var result: [AppLanguage: Bundle] = [:]
        for language in AppLanguage.allCases {
            if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                result[language] = bundle
            }
        }
        return result
    }()

    static func text(_ key: Key, language: AppLanguage = language) -> String {
        let fallback = bundles[.english]?.localizedString(forKey: key.rawValue, value: nil, table: nil)
            ?? key.rawValue
        return bundles[language]?.localizedString(forKey: key.rawValue, value: fallback, table: nil)
            ?? fallback
    }

    static func format(_ key: Key, _ value: String) -> String {
        String(format: text(key), locale: language.locale, value)
    }

    static func spotlightShortcut(_ shortcut: String) -> String {
        String(format: text(.spotlightShortcut), locale: language.locale, shortcut)
    }
}
