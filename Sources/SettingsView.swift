import SwiftUI

struct SettingsView: View {
    static var windowWidth: CGFloat { L10n.language == .korean ? 500 : 560 }
    @ObservedObject var preferences: Preferences
    @ObservedObject var zoom: ZoomCapture
    @ObservedObject var keys: KeystrokeMonitor
    let previewSpotlight: () -> Void
    let previewZoom: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSApplication.shared.applicationIconImage)
                    .resizable().interpolation(.high).scaledToFit()
                    .frame(width: 40, height: 40)
                    .accessibilityLabel(L10n.text(.appIcon))
                Text("BigMouse").font(.system(size: 23, weight: .bold, design: .rounded))
                Spacer()
                Toggle(L10n.text(.enabled), isOn: $preferences.enabled).toggleStyle(.switch)
                    .accessibilityIdentifier("masterToggle")
            }
            .padding(22)
            Divider()
            if preferences.enabled && preferences.zoomEnabled, let message = zoom.message {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message).font(.callout).fontWeight(.medium)
                    if !zoom.permissionGranted {
                        Text(L10n.text(.screenPermissionHelp))
                            .font(.caption).foregroundStyle(.secondary)
                        Button(L10n.text(.permissionSettings)) { zoom.requestPermission() }
                            .accessibilityIdentifier("zoomPermissionNoticeButton")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .accessibilityIdentifier("zoomNotice")
                Divider()
            }
            Form {
                ShortcutSettingsView(preferences: preferences, controller: keys.shortcuts)
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(preferences.accent.color.opacity(preferences.haloOpacity))
                                .overlay(Circle().stroke(preferences.accent.color, lineWidth: preferences.haloLineWidth))
                                .frame(width: preferences.haloDiameter, height: preferences.haloDiameter)
                                .opacity(preferences.haloEnabled ? 1 : 0)
                            Image(systemName: "cursorarrow")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.primary)
                                .offset(x: 7, y: 13)
                        }
                        .frame(height: 164)
                        .accessibilityLabel(L10n.text(.haloPreview))
                        Spacer()
                    }
                    Picker(L10n.text(.accentColor), selection: $preferences.accent) {
                        ForEach(Accent.allCases) { accent in Text(accent.title).tag(accent) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle(L10n.text(.showHalo), isOn: $preferences.haloEnabled)
                    slider(L10n.text(.ringSize), value: $preferences.haloDiameter, range: 28...160, unit: "pt")
                        .disabled(!preferences.haloEnabled)
                    slider(L10n.text(.borderWidth), value: $preferences.haloLineWidth, range: 1...12, unit: "pt", decimal: true)
                        .disabled(!preferences.haloEnabled)
                    slider(L10n.text(.fill), value: $preferences.haloOpacity, range: 0...0.6, percent: true)
                        .disabled(!preferences.haloEnabled)
                    Toggle(L10n.text(.hideWhenIdle), isOn: $preferences.hideWhenIdle)
                        .disabled(!preferences.haloEnabled)
                } header: { featureTitle(L10n.text(.cursorHighlight), icon: "circle-dot") }
                Section {
                    Toggle(L10n.text(.clickSparkles), isOn: $preferences.clicksEnabled)
                } header: { featureTitle(L10n.text(.clickEffects), icon: "sparkles") }
                Section {
                    Toggle(L10n.text(.showKeys), isOn: Binding(get: { keys.isEnabled }, set: keys.setEnabled))
                        .accessibilityIdentifier("keystrokeToggle")
                    Text(preferences.shortcuts.keys.instruction(for: .keys))
                        .font(.caption).foregroundStyle(.secondary)
                    Picker(L10n.text(.keyFilter), selection: $preferences.keyDisplayFilter) {
                        ForEach(KeyDisplayFilter.allCases) { filter in Text(filter.title).tag(filter) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("keyDisplayFilter")
                    Toggle(L10n.text(.includeSpecialKeys), isOn: $preferences.keyIncludeSpecialKeys)
                        .disabled(preferences.keyDisplayFilter == .allKeys)
                        .help(L10n.text(.specialKeysHelp))
                        .accessibilityIdentifier("keyIncludeSpecialKeys")
                    Picker(L10n.text(.font), selection: $preferences.keyFontFamily) {
                        Text(L10n.text(.systemFont)).tag(KeyDisplayFont.system)
                        Text(L10n.text(.monospacedFont)).tag(KeyDisplayFont.monospaced)
                        ForEach(KeyDisplayFont.families, id: \.self) { family in Text(family).tag(family) }
                    }
                    .accessibilityIdentifier("keyFontPicker")
                    HStack(spacing: 12) {
                        Text(L10n.text(.fontSize)).frame(width: 78, alignment: .leading)
                        Slider(value: $preferences.keyFontSize, in: 18...128, step: 1)
                            .accessibilityLabel(L10n.text(.keyFontSize))
                        Text("\(Int(preferences.keyFontSize)) pt")
                            .monospacedDigit().foregroundStyle(.secondary).frame(width: 60, alignment: .trailing)
                    }
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.text(.displayMode))
                            Picker(L10n.text(.displayMode), selection: $preferences.keyDisplayMode) {
                                ForEach(KeyDisplayMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("keyDisplayMode")
                        }
                        .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.text(.displayPosition))
                            PositionPicker(selection: $preferences.keyDisplayPosition)
                                .frame(height: 24)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                    KeyDisplayPreview(font: preferences.keyFont, mode: preferences.keyDisplayMode,
                                      filter: preferences.keyDisplayFilter)
                        .frame(height: max(76, preferences.keyFontSize * 2.3))
                    if !keys.permissionGranted {
                        HStack {
                            Text(L10n.text(.inputPermissionRequired))
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button(L10n.text(.permissionSettings)) { keys.requestPermission() }
                                .accessibilityIdentifier("keystrokePermission")
                        }
                    }
                    if let message = keys.message {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                } header: { featureTitle(L10n.text(.keysSection), icon: "keyboard") }
                Section {
                    Toggle(L10n.text(.enableSpotlight), isOn: $preferences.spotlightEnabled)
                    Text(preferences.shortcuts.spotlight.instruction(for: .spotlight))
                        .font(.caption).foregroundStyle(.secondary)
                    slider(L10n.text(.brightArea), value: $preferences.spotlightDiameter, range: 120...720, unit: "pt")
                        .disabled(!preferences.spotlightEnabled)
                    slider(L10n.text(.dimLevel), value: $preferences.dimOpacity, range: 0.15...0.9, percent: true)
                        .disabled(!preferences.spotlightEnabled)
                    HStack {
                        Text(L10n.text(.holdKeyHint))
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button(L10n.text(.preview), action: previewSpotlight)
                            .disabled(!preferences.spotlightEnabled)
                    }
                } header: { featureTitle(L10n.text(.spotlight), icon: "flashlight") }
                Section {
                    Toggle(L10n.text(.enableZoom), isOn: $preferences.zoomEnabled)
                    Text(preferences.shortcuts.zoom.instruction(for: .zoom))
                        .font(.caption).foregroundStyle(.secondary)
                    slider(L10n.text(.lensSize), value: $preferences.zoomDiameter, range: 160...520, unit: "pt")
                        .disabled(!preferences.zoomEnabled)
                    slider(L10n.text(.zoomScale), value: $preferences.zoomScale, range: 1.5...4, unit: L10n.text(.zoomUnit), decimal: true)
                        .disabled(!preferences.zoomEnabled)
                    HStack {
                        Spacer()
                        Button(L10n.text(.preview), action: previewZoom)
                            .accessibilityIdentifier("zoomPreview")
                            .disabled(!preferences.zoomEnabled)
                    }
                    if !zoom.permissionGranted {
                        HStack {
                            Text(L10n.text(.zoomPermissionRequired))
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button(L10n.text(.permissionSettings)) { zoom.requestPermission() }
                                .accessibilityIdentifier("zoomPermission")
                        }
                    }
                } header: { featureTitle(L10n.text(.zoom), icon: "zoom-in") }
            }
            .formStyle(.grouped)
            .disabled(!preferences.enabled)
            Divider()
            VStack(spacing: 6) {
                HStack {
                    Circle().fill(preferences.enabled ? Color.green : Color.secondary).frame(width: 6, height: 6)
                    Text(preferences.enabled ? L10n.text(.on) : L10n.text(.paused))
                    Spacer()
                    Text(L10n.text(.autoSaved))
                }
                if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    Text(String(format: L10n.text(.versionFormat), locale: L10n.language.locale, version))
                        .monospacedDigit()
                        .accessibilityIdentifier("appVersion")
                }
            }
            .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 22).padding(.vertical, 12)
        }
        .frame(width: Self.windowWidth, height: 790)
        .environment(\.locale, L10n.language.locale)
    }

    private func featureTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            if let url = Bundle.main.url(forResource: icon, withExtension: "png", subdirectory: "Lucide"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().renderingMode(.template)
                    .frame(width: 18, height: 18).accessibilityHidden(true)
            }
            Text(title)
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String = "", percent: Bool = false, decimal: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(title).frame(width: 78, alignment: .leading)
            Slider(value: value, in: range)
                .accessibilityLabel(title)
            Text(percent ? "\(Int((value.wrappedValue * 100).rounded()))%" : decimal ? String(format: "%.1f %@", value.wrappedValue, unit) : "\(Int(value.wrappedValue.rounded())) \(unit)")
                .monospacedDigit().foregroundStyle(.secondary).frame(width: 60, alignment: .trailing)
        }
    }
}

private struct PositionPicker: NSViewRepresentable {
    @Binding var selection: KeyDisplayPosition

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(labels: KeyDisplayPosition.allCases.map(\.title),
                                         trackingMode: .selectOne,
                                         target: context.coordinator,
                                         action: #selector(Coordinator.selectPosition(_:)))
        control.segmentStyle = .rounded
        control.setAccessibilityLabel(L10n.text(.displayPosition))
        control.setAccessibilityIdentifier("keyDisplayPosition")
        for (index, position) in KeyDisplayPosition.allCases.enumerated() {
            control.setImage(positionImage(position), forSegment: index)
            control.setImageScaling(.scaleProportionallyDown, forSegment: index)
        }
        return control
    }

    private func positionImage(_ position: KeyDisplayPosition) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 14), flipped: false) { _ in
            NSColor.black.set()
            let outline = NSBezierPath(roundedRect: NSRect(x: 0.75, y: 0.75, width: 16.5, height: 12.5),
                                       xRadius: 1.5, yRadius: 1.5)
            outline.lineWidth = 1.5
            outline.stroke()
            let y: CGFloat = position == .top ? 9.5 : position == .bottom ? 2.5 : 6
            NSBezierPath(roundedRect: NSRect(x: 3, y: y, width: 12, height: 2),
                         xRadius: 0.5, yRadius: 0.5).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.parent = self
        control.selectedSegment = KeyDisplayPosition.allCases.firstIndex(of: selection) ?? 2
        control.isEnabled = context.environment.isEnabled
    }

    final class Coordinator: NSObject {
        var parent: PositionPicker
        init(_ parent: PositionPicker) { self.parent = parent }
        @objc func selectPosition(_ sender: NSSegmentedControl) {
            guard KeyDisplayPosition.allCases.indices.contains(sender.selectedSegment) else { return }
            parent.selection = KeyDisplayPosition.allCases[sender.selectedSegment]
        }
    }
}
