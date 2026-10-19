import AppKit
import Carbon
import Combine

/// Recognizes two short press/release pairs of the selected modifier combination.
/// Event counts cancel shortcuts without reading or retaining their characters.
struct ModifierDoubleTap {
    var modifiers: NSEvent.ModifierFlags = .option
    private var wasDown = false
    private var pressedAt: TimeInterval?
    private var releasedAt: TimeInterval?
    private var inputCount: UInt32?

    @discardableResult
    mutating func update(flags: NSEvent.ModifierFlags, at time: TimeInterval,
                         inputCount currentCount: UInt32, mouseDown: Bool = false) -> Bool {
        let down = !modifiers.isEmpty && flags.isSuperset(of: modifiers)
        let otherModifier = !flags.intersection(ShortcutBinding.modifierMask).subtracting(modifiers).isEmpty
        let interveningInput = inputCount.map { $0 != currentCount } ?? false
        inputCount = currentCount
        if otherModifier || interveningInput || mouseDown {
            pressedAt = nil
            releasedAt = nil
            wasDown = down
            return false
        }
        defer { wasDown = down }
        if down && !wasDown { pressedAt = time }
        guard !down && wasDown, let start = pressedAt else { return false }
        pressedAt = nil
        guard time - start <= 0.3 else { releasedAt = nil; return false }
        if let previous = releasedAt, start - previous <= 0.4 {
            releasedAt = nil
            return true
        }
        releasedAt = time
        return false
    }
}

struct KeyReadout: Equatable {
    var labels: [String] = []
    var opacity: Float = 0
    var text: String { labels.joined(separator: "  ") }
}

/// A short, memory-only row of key labels. Never contains a transcript or files.
struct KeyReadoutBuffer {
    private var labels: [String] = []
    private var lastInput: TimeInterval = 0

    mutating func append(_ label: String, at time: TimeInterval) {
        if time - lastInput >= 1.8 { labels.removeAll() }
        labels.append(String(label.prefix(12)))
        while labels.count > 24 || labels.joined(separator: "  ").count > 144 { labels.removeFirst() }
        lastInput = time
    }

    mutating func clear() { labels.removeAll(); lastInput = 0 }

    mutating func readout(at time: TimeInterval) -> KeyReadout {
        let age = time - lastInput
        guard !labels.isEmpty, age < 1.8 else { clear(); return KeyReadout() }
        return KeyReadout(labels: labels, opacity: Float(min(1, (1.8 - age) / 0.2)))
    }
}

final class KeystrokeMonitor: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var permissionGranted = CGPreflightListenEventAccess()
    @Published private(set) var message: String?
    var onPermissionNeeded: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    let shortcuts: ShortcutController
    private var buffer = KeyReadoutBuffer()
    private var filter: KeyDisplayFilter
    private var includeSpecialKeys: Bool
    private var filterSubscription: AnyCancellable?

    init(preferences: Preferences) {
        shortcuts = ShortcutController(preferences: preferences)
        filter = preferences.keyDisplayFilter
        includeSpecialKeys = preferences.keyIncludeSpecialKeys
        shortcuts.onToggleKeys = { [weak self] in self?.toggle() }
        filterSubscription = Publishers.CombineLatest(preferences.$keyDisplayFilter, preferences.$keyIncludeSpecialKeys)
            .sink { [weak self] filter, includeSpecialKeys in
                guard let self, self.filter != filter || self.includeSpecialKeys != includeSpecialKeys else { return }
                self.filter = filter
                self.includeSpecialKeys = includeSpecialKeys
                self.buffer.clear()
            }
    }

    func refreshPermission() {
        let granted = CGPreflightListenEventAccess()
        if permissionGranted != granted { permissionGranted = granted }
        if !granted && isEnabled { setEnabled(false) }
        if granted { message = nil }
    }

    func requestPermission() {
        _ = CGRequestListenEventAccess()
        refreshPermission()
        if !permissionGranted,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    func toggle() { setEnabled(!isEnabled) }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        buffer.clear()
        if !enabled {
            stopListening()
            isEnabled = false
            return
        }
        refreshPermission()
        guard permissionGranted else {
            message = L10n.text(.keyPermissionNeeded)
            onPermissionNeeded?()
            return
        }
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let newTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap,
                                             options: .listenOnly, eventsOfInterest: mask,
                                             callback: { _, type, event, context in
            if let context {
                let monitor = Unmanaged<KeystrokeMonitor>.fromOpaque(context).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if monitor.isEnabled, let tap = monitor.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                } else if type == .keyDown {
                    monitor.receive(event)
                }
            }
            return Unmanaged.passUnretained(event)
        }, userInfo: context) else {
            message = L10n.text(.keyPermissionRestart)
            onPermissionNeeded?()
            return
        }
        tap = newTap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        isEnabled = true
        message = nil
        buffer.append(L10n.text(.keysOn), at: ProcessInfo.processInfo.systemUptime)
    }

    func poll(flags: NSEvent.ModifierFlags, at time: TimeInterval) -> KeyReadout {
        shortcuts.poll(flags: flags, at: time)
        guard isEnabled, !shortcuts.isRecording, !IsSecureEventInputEnabled() else { buffer.clear(); return KeyReadout() }
        return buffer.readout(at: time)
    }

    private func receive(_ event: CGEvent) {
        guard isEnabled, !shortcuts.isRecording, !IsSecureEventInputEnabled(), let key = NSEvent(cgEvent: event) else {
            buffer.clear()
            return
        }
        guard let label = label(for: key) else { return }
        buffer.append(label, at: ProcessInfo.processInfo.systemUptime)
    }

    func label(for key: NSEvent) -> String? {
        Self.label(keyCode: key.keyCode, characters: key.charactersIgnoringModifiers,
                   flags: key.modifierFlags, filter: filter, includeSpecialKeys: includeSpecialKeys)
    }

    static func label(keyCode: UInt16, characters: String?, flags: NSEvent.ModifierFlags,
                      filter: KeyDisplayFilter = .allKeys, includeSpecialKeys: Bool = true) -> String? {
        let names: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "Esc", 76: "⌤", 117: "⌦",
            123: "←", 124: "→", 125: "↓", 126: "↑", 115: "Home", 119: "End", 116: "Pg↑", 121: "Pg↓",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
            106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20"
        ]
        let isShortcut = !flags.intersection([.command, .control, .option]).isEmpty
        // Shift/Caps Lock/Fn alone do not make typing a shortcut. In particular,
        // arrow/function keys can carry the Fn flag without Fn being held.
        let isSpecialKey = keyCode != 49 && names[keyCode] != nil
        guard filter == .allKeys || isShortcut || (includeSpecialKeys && isSpecialKey) else { return nil }
        let printable = characters?.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0) && !CharacterSet.illegalCharacters.contains($0)
        }.map(String.init).joined()
        // Control shortcuts can contain a control scalar instead of a visible letter.
        let fallback: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
            39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 50: "`"
        ]
        let visible = printable.flatMap { $0.isEmpty ? nil : $0 }
        // Normalize only Hangul shortcut labels by physical key, never the input
        // source or the original event. Keep other keyboard layouts unchanged.
        let hasHangul = visible?.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x1100...0x11FF, 0x3130...0x318F, 0xA960...0xA97F, 0xAC00...0xD7AF, 0xD7B0...0xD7FF:
                return true
            default: return false
            }
        } ?? false
        let shortcutKey = isShortcut && hasHangul ? fallback[keyCode] : nil
        guard let base = names[keyCode] ?? shortcutKey ?? visible ?? fallback[keyCode], !base.isEmpty else { return nil }
        var prefix = ""
        if flags.contains(.control) { prefix += "⌃" }
        if flags.contains(.option) { prefix += "⌥" }
        if flags.contains(.shift) { prefix += "⇧" }
        if flags.contains(.command) { prefix += "⌘" }
        return prefix + String(base.uppercased().prefix(8))
    }

    func suspend() {
        setEnabled(false)
        buffer.clear()
        shortcuts.resetState()
    }

    private func stopListening() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
    }

    deinit { stopListening() }
}
