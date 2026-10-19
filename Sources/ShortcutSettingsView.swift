import AppKit
import SwiftUI

// Select the property wrapper when the SDK also exports a State macro.
private typealias StoredState<Value> = SwiftUI.State<Value>

struct ShortcutSettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var controller: ShortcutController
    @StoredState private var editing: ShortcutAction?

    var body: some View {
        Section {
            ForEach(ShortcutAction.allCases) { action in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(action.title)
                        Spacer()
                        Button(preferences.shortcuts[action].instruction(for: action)) {
                            controller.beginRecording()
                            editing = action
                        }
                        .accessibilityIdentifier("shortcut-" + action.rawValue)
                        .accessibilityLabel(action.title + ": " + preferences.shortcuts[action].instruction(for: action))
                    }
                    if let error = controller.errors[action] {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            HStack {
                Text(L10n.text(.shortcutEditHint)).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(L10n.text(.shortcutReset)) { controller.resetDefaults() }
                    .disabled(preferences.shortcuts == ShortcutBindings())
                    .accessibilityIdentifier("resetShortcuts")
            }
        } header: { Text(L10n.text(.shortcutSettings)) }
        .sheet(item: $editing, onDismiss: { controller.endRecording() }) { action in
            ShortcutRecorderSheet(action: action, initial: preferences.shortcuts[action],
                                  save: { controller.assign($0, to: action) }, close: { editing = nil })
        }
    }
}

struct ShortcutRecorderSheet: View {
    let action: ShortcutAction
    let initial: ShortcutBinding
    let save: (ShortcutBinding) -> String?
    let close: () -> Void
    @StoredState private var candidate: ShortcutBinding?
    @StoredState private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.format(.shortcutRecordTitle, action.title)).font(.headline)
            Text(L10n.text(action == .keys ? .shortcutRecordToggleHelp : .shortcutRecordHoldHelp))
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05))
                Text(candidate.map { $0.instruction(for: action) } ?? L10n.text(.shortcutPressKeys))
                    .font(.system(size: 22, weight: .medium)).padding(12)
                ShortcutRecorderInput(onCapture: { binding in
                    candidate = binding.isValid ? binding : nil
                    error = binding.isValid ? nil : L10n.text(.shortcutInvalid)
                }, onCancel: close)
            }
            .frame(height: 88)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.text(.shortcutPressKeys))
            if let error { Text(error).font(.callout).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
            HStack {
                Button(L10n.text(.shortcutNone)) { candidate = .disabled; error = nil }
                Spacer()
                Button(L10n.text(.shortcutCancel), action: close)
                Button(L10n.text(.shortcutApply)) {
                    guard let candidate else { return }
                    if let failure = save(candidate) { error = failure }
                    else { close() }
                }
                .disabled(candidate == nil)
                .accessibilityIdentifier("applyShortcut")
            }
        }
        .padding(24).frame(width: L10n.language == .korean ? 420 : 460)
        .onAppear { candidate = initial }
    }
}

/// Local to this key window. No global event tap or permission is needed to record a choice.
struct ShortcutRecorderInput: NSViewRepresentable {
    var onCapture: (ShortcutBinding) -> Void
    var onCancel: () -> Void
    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onCapture = onCapture
        view.onCancel = onCancel
        view.start()
        return view
    }
    func updateNSView(_ view: RecorderView, context: Context) {
        view.onCapture = onCapture
        view.onCancel = onCancel
    }
    static func dismantleNSView(_ view: RecorderView, coordinator: ()) { view.stop() }

    final class RecorderView: NSView {
        var onCapture: ((ShortcutBinding) -> Void)?
        var onCancel: (() -> Void)?
        private var monitor: Any?
        private var modifiers: NSEvent.ModifierFlags = []
        private var hasKey = false
        override var acceptsFirstResponder: Bool { true }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                window.makeFirstResponder(self)
            }
        }
        func start() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self, self.window?.isKeyWindow == true else { return event }
                if event.type == .keyDown {
                    guard !event.isARepeat else { return nil }
                    if event.keyCode == 53 && event.modifierFlags.intersection(ShortcutBinding.modifierMask).isEmpty {
                        self.onCancel?(); return nil
                    }
                    self.hasKey = true
                    var flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
                    // macOS marks navigation/function keys with .function even without physical Fn.
                    if let name = ShortcutBinding.keyNames[event.keyCode], name.hasPrefix("F") && name.count > 1
                        || [115, 119, 116, 121, 117, 123, 124, 125, 126].contains(event.keyCode) {
                        flags.remove(.function)
                    }
                    self.onCapture?(ShortcutBinding(flags: flags, keyCode: event.keyCode))
                } else {
                    let flags = event.modifierFlags.intersection(ShortcutBinding.modifierMask)
                    if flags.isEmpty {
                        if !self.hasKey && !self.modifiers.isEmpty { self.onCapture?(ShortcutBinding(flags: self.modifiers)) }
                        self.modifiers = []
                        self.hasKey = false
                    } else if flags.isSuperset(of: self.modifiers) { self.modifiers = flags }
                }
                return nil
            }
        }
        func stop() { if let monitor { NSEvent.removeMonitor(monitor) }; monitor = nil }
        deinit { stop() }
    }
}
