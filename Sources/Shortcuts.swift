import AppKit
import Carbon
import Combine

enum ShortcutAction: String, CaseIterable, Codable, Identifiable {
    case zoom, spotlight, keys
    var id: String { rawValue }
    var title: String { L10n.text(self == .zoom ? .zoom : self == .spotlight ? .spotlight : .keysSection) }
}

/// Physical key codes keep activation independent of the Korean/English input source.
struct ShortcutBinding: Codable, Equatable {
    var modifiers: UInt
    var keyCode: UInt16?
    static let modifierMask: NSEvent.ModifierFlags = [.command, .control, .option, .shift, .function]
    static let standardMask: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
    static let disabled = ShortcutBinding(flags: [])

    init(flags: NSEvent.ModifierFlags, keyCode: UInt16? = nil) {
        modifiers = flags.intersection(Self.modifierMask).rawValue
        self.keyCode = keyCode
    }
    var flags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }
    var isDisabled: Bool { modifiers == 0 && keyCode == nil }
    var isValid: Bool {
        guard flags.subtracting(Self.modifierMask).isEmpty else { return false }
        guard let code = keyCode else { return true }
        return !flags.contains(.function) && !flags.intersection([.command, .control, .option]).isEmpty
            && Self.keyNames[code] != nil
    }
    func matches(_ current: NSEvent.ModifierFlags) -> Bool {
        !isDisabled && current.intersection(Self.modifierMask) == flags
    }
    func conflicts(with other: Self) -> Bool {
        !isDisabled && !other.isDisabled && modifiers == other.modifiers
            && (keyCode == other.keyCode || keyCode == nil || other.keyCode == nil)
    }
    var title: String {
        guard !isDisabled else { return L10n.text(.shortcutNone) }
        let parts: [(NSEvent.ModifierFlags, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘"), (.function, "Fn")]
        let prefix = parts.filter { flags.contains($0.0) }.map(\.1).joined()
        return prefix + (keyCode.flatMap { Self.keyNames[$0] } ?? "")
    }
    func instruction(for action: ShortcutAction) -> String {
        guard !isDisabled else { return L10n.text(.shortcutNone) }
        let key: L10n.Key = action == .keys ? (keyCode == nil ? .shortcutDoubleTap : .shortcutToggle) : .shortcutHold
        return L10n.format(key, title)
    }
    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        for (flag, value) in [(NSEvent.ModifierFlags.command, cmdKey), (.option, optionKey), (.control, controlKey), (.shift, shiftKey)] {
            if flags.contains(flag) { result |= UInt32(value) }
        }
        return result
    }
    static let keyNames: [UInt16: String] = [
        0:"A", 1:"S", 2:"D", 3:"F", 4:"H", 5:"G", 6:"Z", 7:"X", 8:"C", 9:"V", 11:"B",
        12:"Q", 13:"W", 14:"E", 15:"R", 16:"Y", 17:"T", 18:"1", 19:"2", 20:"3", 21:"4",
        22:"6", 23:"5", 24:"=", 25:"9", 26:"7", 27:"−", 28:"8", 29:"0", 30:"]", 31:"O",
        32:"U", 33:"[", 34:"I", 35:"P", 36:"↩", 37:"L", 38:"J", 39:"'", 40:"K", 41:";",
        42:"\\", 43:",", 44:"/", 45:"N", 46:"M", 47:".", 48:"⇥", 49:"Space", 50:"`", 51:"⌫", 53:"Esc",
        65:"Num .", 67:"Num *", 69:"Num +", 75:"Num /", 76:"Num ↩", 78:"Num −", 81:"Num =",
        82:"Num 0", 83:"Num 1", 84:"Num 2", 85:"Num 3", 86:"Num 4", 87:"Num 5", 88:"Num 6", 89:"Num 7", 91:"Num 8", 92:"Num 9",
        122:"F1", 120:"F2", 99:"F3", 118:"F4", 96:"F5", 97:"F6", 98:"F7", 100:"F8", 101:"F9", 109:"F10",
        103:"F11", 111:"F12", 105:"F13", 107:"F14", 113:"F15", 106:"F16", 64:"F17", 79:"F18", 80:"F19", 90:"F20",
        115:"↖", 119:"↘", 116:"⇞", 121:"⇟", 117:"⌦", 123:"←", 124:"→", 125:"↓", 126:"↑"
    ]
}

struct ShortcutBindings: Codable, Equatable {
    var zoom = ShortcutBinding(flags: .function)
    var spotlight = ShortcutBinding(flags: .control)
    var keys = ShortcutBinding(flags: .option)
    subscript(_ action: ShortcutAction) -> ShortcutBinding {
        get { switch action { case .zoom: return zoom; case .spotlight: return spotlight; case .keys: return keys } }
        set { switch action { case .zoom: zoom = newValue; case .spotlight: spotlight = newValue; case .keys: keys = newValue } }
    }
    func conflict(for action: ShortcutAction, binding: ShortcutBinding) -> ShortcutAction? {
        ShortcutAction.allCases.first { $0 != action && binding.conflicts(with: self[$0]) }
    }
    var isValid: Bool {
        ShortcutAction.allCases.allSatisfy { self[$0].isValid && conflict(for: $0, binding: self[$0]) == nil }
    }
}

/// Pure activation state, shared by modifier polling and registered hotkey events.
struct ShortcutActivation {
    var bindings: ShortcutBindings
    private var pressed = Set<ShortcutAction>()
    private var gesture: ModifierDoubleTap
    private var waitingForRelease = true
    init(bindings: ShortcutBindings) {
        self.bindings = bindings
        gesture = ModifierDoubleTap(modifiers: bindings.keys.flags)
    }
    mutating func reset() { self = Self(bindings: bindings) }
    @discardableResult
    mutating func update(flags: NSEvent.ModifierFlags, at time: TimeInterval, inputCount: UInt32, mouseDown: Bool) -> Bool {
        if waitingForRelease {
            if flags.intersection(ShortcutBinding.modifierMask).isEmpty { waitingForRelease = false }
            return false
        }
        pressed = pressed.filter { bindings[$0].flags == flags.intersection(ShortcutBinding.standardMask) }
        guard bindings.keys.keyCode == nil, !bindings.keys.isDisabled else { return false }
        return gesture.update(flags: flags, at: time, inputCount: inputCount, mouseDown: mouseDown)
    }
    @discardableResult
    mutating func receive(_ action: ShortcutAction, down: Bool) -> Bool {
        guard !waitingForRelease else { return false }
        if !down { pressed.remove(action); return false }
        return pressed.insert(action).inserted && action == .keys
    }
    func isHeld(_ action: ShortcutAction, flags: NSEvent.ModifierFlags) -> Bool {
        guard !waitingForRelease else { return false }
        let binding = bindings[action]
        return binding.keyCode == nil ? binding.matches(flags) : pressed.contains(action)
    }
}

/// Carbon registers only the explicitly selected key combinations. It does not read typing.
final class ShortcutController: ObservableObject {
    @Published private(set) var errors: [ShortcutAction: String] = [:]
    @Published private(set) var isRecording = false
    var onToggleKeys: (() -> Void)?
    private let preferences: Preferences
    private var bindings: ShortcutBindings
    private var activation: ShortcutActivation
    private var subscription: AnyCancellable?
    private var enabledActions = Set<ShortcutAction>()
    private var active = false
    private var handler: EventHandlerRef?
    private var registrations: [UInt32: (ShortcutAction, EventHotKeyRef)] = [:]
    private var nextID: UInt32 = 1
    private static let signature: OSType = 0x424D5343 // BMSC

    init(preferences: Preferences) {
        self.preferences = preferences
        bindings = preferences.shortcuts
        activation = ShortcutActivation(bindings: preferences.shortcuts)
        subscription = preferences.$shortcuts.sink { [weak self] value in
            guard let self, self.bindings != value else { return }
            self.bindings = value
            self.activation = ShortcutActivation(bindings: value)
            self.refreshRegistrations()
        }
    }
    deinit {
        registrations.values.forEach { UnregisterEventHotKey($0.1) }
        if let handler { RemoveEventHandler(handler) }
    }
    func setActive(_ value: Bool) {
        var actions: Set<ShortcutAction> = [.keys]
        if preferences.zoomEnabled { actions.insert(.zoom) }
        if preferences.spotlightEnabled { actions.insert(.spotlight) }
        guard active != value || actions != enabledActions else { return }
        active = value
        enabledActions = actions
        activation.reset()
        refreshRegistrations()
    }
    func beginRecording() {
        isRecording = true
        activation.reset()
        refreshRegistrations()
    }
    func endRecording() {
        isRecording = false
        activation.reset()
        refreshRegistrations()
    }
    func resetState() { activation.reset() }
    func resetDefaults() { preferences.shortcuts = ShortcutBindings() }

    /// Failure leaves both the persisted assignment and the previous hotkey intact.
    func assign(_ binding: ShortcutBinding, to action: ShortcutAction) -> String? {
        guard binding.isValid else { return L10n.text(.shortcutInvalid) }
        if let other = bindings.conflict(for: action, binding: binding) {
            return L10n.format(.shortcutDuplicate, other.title)
        }
        if binding != bindings[action], binding.keyCode != nil {
            if Self.isSystemShortcut(binding) { return L10n.text(.shortcutUnavailable) }
            var probe: EventHotKeyRef?
            let status = RegisterEventHotKey(UInt32(binding.keyCode!), binding.carbonModifiers,
                EventHotKeyID(signature: Self.signature, id: 0), GetApplicationEventTarget(),
                OptionBits(kEventHotKeyExclusive), &probe)
            if let probe { UnregisterEventHotKey(probe) }
            guard status == noErr else { return L10n.text(.shortcutUnavailable) }
        }
        var updated = bindings
        updated[action] = binding
        preferences.shortcuts = updated
        return nil
    }
    static func isSystemShortcut(_ binding: ShortcutBinding) -> Bool {
        guard let code = binding.keyCode else { return false }
        // These are BigMouse's own menu equivalents, including Quit and Settings.
        if binding.flags == .command && [12, 43, 8, 9, 0].contains(code) { return true }
        var array: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&array) == noErr, let list = array?.takeRetainedValue() as? [[String: Any]] else { return false }
        return list.contains {
            ($0[kHISymbolicHotKeyEnabled as String] as? NSNumber)?.boolValue == true
                && ($0[kHISymbolicHotKeyCode as String] as? NSNumber)?.uint16Value == code
                && ($0[kHISymbolicHotKeyModifiers as String] as? NSNumber)?.uint32Value == binding.carbonModifiers
        }
    }
    func poll(flags: NSEvent.ModifierFlags, at time: TimeInterval) {
        guard active, preferences.enabled, !isRecording, !IsSecureEventInputEnabled() else { activation.reset(); return }
        let activity = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
            &+ CGEventSource.counterForEventType(.combinedSessionState, eventType: .leftMouseDown)
            &+ CGEventSource.counterForEventType(.combinedSessionState, eventType: .rightMouseDown)
            &+ CGEventSource.counterForEventType(.combinedSessionState, eventType: .otherMouseDown)
        if activation.update(flags: flags, at: time, inputCount: activity, mouseDown: NSEvent.pressedMouseButtons != 0) {
            onToggleKeys?()
        }
    }
    func isHeld(_ action: ShortcutAction, flags: NSEvent.ModifierFlags) -> Bool {
        active && preferences.enabled && !isRecording && enabledActions.contains(action)
            && !IsSecureEventInputEnabled() && activation.isHeld(action, flags: flags)
    }
    private func receive(id: UInt32, down: Bool) {
        guard let (action, _) = registrations[id], active, preferences.enabled, !isRecording,
              !IsSecureEventInputEnabled() else { return }
        if activation.receive(action, down: down) { onToggleKeys?() }
    }
    private func refreshRegistrations() {
        registrations.values.forEach { UnregisterEventHotKey($0.1) }
        registrations.removeAll()
        errors = [:]
        guard active, !isRecording else { return }
        if handler == nil {
            var types = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                         EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))]
            let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                var id = EventHotKeyID()
                guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &id) == noErr,
                    id.signature == ShortcutController.signature else { return OSStatus(eventNotHandledErr) }
                Unmanaged<ShortcutController>.fromOpaque(context).takeUnretainedValue()
                    .receive(id: id.id, down: GetEventKind(event) == UInt32(kEventHotKeyPressed))
                return noErr
            }, types.count, &types, Unmanaged.passUnretained(self).toOpaque(), &handler)
            if status != noErr {
                for action in enabledActions where bindings[action].keyCode != nil { errors[action] = L10n.text(.shortcutUnavailable) }
                return
            }
        }
        for action in ShortcutAction.allCases where enabledActions.contains(action) {
            let binding = bindings[action]
            guard let code = binding.keyCode else { continue }
            if Self.isSystemShortcut(binding) { errors[action] = L10n.text(.shortcutUnavailable); continue }
            let id = nextID
            nextID &+= 1
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(UInt32(code), binding.carbonModifiers,
                EventHotKeyID(signature: Self.signature, id: id), GetApplicationEventTarget(),
                OptionBits(kEventHotKeyExclusive), &reference)
            if status == noErr, let reference { registrations[id] = (action, reference) }
            else { errors[action] = L10n.text(.shortcutUnavailable) }
        }
    }
}
