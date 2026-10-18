import AppKit
import Foundation

setbuf(stdout, nil)
var assertions = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    guard condition() else { fatalError("FAIL: \(label)") }
    assertions += 1
    print("PASS: \(label)")
}

let regionCases: [(String, AppLanguage)] = [
    ("ko_KR", .korean), ("en_KR", .korean), ("ja_KR", .korean),
    ("ko_US", .english), ("en_US", .english), ("ja_JP", .english),
    ("fr_FR", .english), ("zh_CN", .english), ("und", .english),
    ("en_US@rg=krzzzz", .korean), ("ko_KR@rg=uszzzz", .english)
]
for (identifier, expected) in regionCases {
    check(AppLanguage.resolve(for: Locale(identifier: identifier)) == expected,
          "Region selects \(expected.rawValue) for \(identifier)")
}
check(Locale.Region.isoRegions.allSatisfy { region in
    let language = AppLanguage.resolve(for: Locale(identifier: "en_\(region.identifier)"))
    return language == (region.identifier == "KR" ? .korean : .english)
}, "Every non-Korean region falls back to English")
let translationKeys = Set(L10n.Key.allCases.map(\.rawValue))
for language in AppLanguage.allCases {
    let url = Bundle.main.url(forResource: "Localizable", withExtension: "strings",
                              subdirectory: "\(language.rawValue).lproj")!
    let table = try! PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: String]
    check(Set(table.keys) == translationKeys && table.values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
          "\(language.rawValue) includes every interface string")
    check(L10n.Key.allCases.allSatisfy { L10n.text($0, language: language) == table[$0.rawValue] },
          "\(language.rawValue) loads its bundled translations")
    check(L10n.text(.keysOn, language: language).count <= 12,
          "\(language.rawValue) activation label fits the keystroke buffer")
    if language == .english {
        check(table.values.allSatisfy { $0.range(of: "[가-힣]", options: .regularExpression) == nil },
              "English interface contains no untranslated Korean")
    }
}
check(L10n.text(.settingsTitle, language: .korean) == "BigMouse 설정"
      && L10n.text(.settingsTitle, language: .english) == "BigMouse Settings",
      "Both languages load independently of the system UI language")
check(L10n.spotlightShortcut("⌃ Control").contains("⌃ Control")
      && !L10n.spotlightShortcut("⌃ Control").contains("%@"),
      "Spotlight menu inserts the selected shortcut")
if let expected = ProcessInfo.processInfo.environment["BIGMOUSE_EXPECTED_LANGUAGE"] {
    check(L10n.language.rawValue == expected, "Launch region selects \(expected) regardless of preferred language")
}
if CommandLine.arguments.contains("--localization-only") {
    print("All \(assertions) localization checks passed.")
    exit(0)
}

let suite = "com.jvisualschool.BigMouse.tests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
let preferences = Preferences(defaults: defaults)
check(preferences.enabled && preferences.haloEnabled && preferences.clicksEnabled, "First launch enables core effects")
check(preferences.shortcut == .control, "Spotlight uses Control by default")
check(SpotlightShortcut.control.matches(.control), "Control alone activates spotlight")
check(!SpotlightShortcut.control.matches([.control, .command]), "Control with Command does not trigger spotlight")
check(ZoomCapture.isShortcutHeld(.function), "Fn activates zoom")
check(!ZoomCapture.isShortcutHeld(.control), "Control does not activate zoom")
preferences.accent = .violet
preferences.haloDiameter = 100
preferences.haloLineWidth = 7.5
preferences.enabled = false
let restored = Preferences(defaults: defaults)
check(restored.accent == .violet && restored.haloDiameter == 100 && !restored.enabled, "Preferences survive recreation")
check(restored.haloLineWidth == 7.5, "Ring width is saved")
check(preferences.keyDisplayMode == .continuous && preferences.keyFontSize == 28 && preferences.keyDisplayPosition == .bottom,
      "Existing users retain a continuous row at 28 points at the bottom")
preferences.keyFontFamily = "Helvetica"
preferences.keyFontSize = 42
preferences.keyDisplayMode = .separate
preferences.keyDisplayPosition = .top
let restoredKeys = Preferences(defaults: defaults)
check(restoredKeys.keyFontFamily == "Helvetica" && restoredKeys.keyFontSize == 42 && restoredKeys.keyDisplayMode == .separate && restoredKeys.keyDisplayPosition == .top,
      "Key font, size, display mode and position survive reopening")
check(restoredKeys.keyFont.familyName == "Helvetica" && restoredKeys.keyFont.pointSize == 42,
      "The selected family and size resolve to the actual display font")
defaults.set("missing-font-family", forKey: "keyFontFamily")
defaults.set(500, forKey: "keyFontSize")
defaults.set("invalid-mode", forKey: "keyDisplayMode")
defaults.set("invalid-position", forKey: "keyDisplayPosition")
let repairedKeys = Preferences(defaults: defaults)
check(repairedKeys.keyFontFamily == KeyDisplayFont.monospaced && repairedKeys.keyFontSize == 128 && repairedKeys.keyDisplayMode == .continuous && repairedKeys.keyDisplayPosition == .bottom,
      "Unavailable fonts and invalid saved options recover safely")
preferences.keyFontFamily = KeyDisplayFont.monospaced
preferences.keyFontSize = 28
preferences.keyDisplayMode = .continuous
preferences.keyDisplayPosition = .bottom
let crop = ZoomCapture.cropRect(point: CGPoint(x: -500, y: 400),
    screen: CGRect(x: -1000, y: -100, width: 1000, height: 1000),
    pixels: CGSize(width: 2000, height: 2000), diameter: 300, magnification: 2)
check(crop == CGRect(x: 850, y: 850, width: 300, height: 300), "Retina zoom crop handles negative monitor coordinates")
let edgeCrop = ZoomCapture.cropRect(point: .zero, screen: CGRect(x: 0, y: 0, width: 1000, height: 1000),
    pixels: CGSize(width: 2000, height: 2000), diameter: 300, magnification: 2)
check(edgeCrop.midX == 0 && edgeCrop.midY == 0, "Zoom remains centered at a screen corner")
defaults.set(-10, forKey: "haloDiameter")
defaults.set(9000, forKey: "spotlightDiameter")
defaults.set("unknown", forKey: "accent")
let repaired = Preferences(defaults: defaults)
check(repaired.haloDiameter == 28 && repaired.spotlightDiameter == 720 && repaired.accent == .amber, "Invalid stored values are bounded")
check(Preferences.clamp(.nan, to: 0...1, fallback: 0.5) == 0.5, "Nonfinite preference falls back safely")
check(SpotlightShortcut.optionShift.matches([.option, .shift]), "Both shortcut keys activate spotlight")
check(!SpotlightShortcut.optionShift.matches(.option), "One key alone does not activate spotlight")
check(!SpotlightShortcut.optionShift.matches([.option, .shift, .command]), "Unrelated shortcut does not activate spotlight")
check(SpotlightShortcut.optionShift.matches([.option, .shift, .capsLock]), "Caps Lock does not interfere")
check(!SpotlightShortcut.optionShift.matches([]), "Releasing keys deactivates spotlight")

var doubleOption = OptionDoubleTap()
check(!doubleOption.update(flags: .option, at: 1, inputCount: 0), "Option down alone cannot toggle key display")
check(!doubleOption.update(flags: [], at: 1.08, inputCount: 0), "One Option tap cannot toggle key display")
doubleOption.update(flags: .option, at: 1.2, inputCount: 0)
check(doubleOption.update(flags: [], at: 1.28, inputCount: 0), "Two quick Option taps toggle key display")
doubleOption.update(flags: .option, at: 1.4, inputCount: 0)
check(!doubleOption.update(flags: [], at: 1.48, inputCount: 0), "A third tap does not retrigger the same pair")
doubleOption.update(flags: .option, at: 2.4, inputCount: 0)
check(!doubleOption.update(flags: [], at: 2.48, inputCount: 0), "Separated Option taps do not toggle")
doubleOption.update(flags: .option, at: 2.6, inputCount: 0)
check(!doubleOption.update(flags: [], at: 3.2, inputCount: 0), "Holding Option cancels a double tap")
doubleOption = OptionDoubleTap()
doubleOption.update(flags: .option, at: 4, inputCount: 0)
doubleOption.update(flags: [], at: 4.05, inputCount: 0)
doubleOption.update(flags: [.option, .command], at: 4.2, inputCount: 0)
check(!doubleOption.update(flags: [], at: 4.25, inputCount: 0), "Option with another modifier does not toggle")
doubleOption = OptionDoubleTap()
doubleOption.update(flags: .option, at: 5, inputCount: 0)
doubleOption.update(flags: [], at: 5.05, inputCount: 0)
doubleOption.update(flags: .option, at: 5.2, inputCount: 1)
check(!doubleOption.update(flags: [], at: 5.25, inputCount: 1), "Intervening typing or clicking cancels the gesture")
check(KeystrokeMonitor.label(keyCode: 8, characters: "c", flags: .command) == "⌘C", "Command shortcuts show their modifier and key")
check(KeystrokeMonitor.label(keyCode: 8, characters: "\u{3}", flags: .control) == "⌃C", "Control characters have readable key labels")
check(KeystrokeMonitor.label(keyCode: 126, characters: nil, flags: .shift) == "⇧↑", "Shift and navigation keys are readable")
check(KeystrokeMonitor.label(keyCode: 0, characters: "ㅁ", flags: []) == "ㅁ", "Unicode key labels retain Korean input characters")
var keyBuffer = KeyReadoutBuffer()
keyBuffer.append("⌘C", at: 1)
check(keyBuffer.readout(at: 2).text == "⌘C", "Pressed keys remain visible briefly")
check(abs(keyBuffer.readout(at: 2.7).opacity - 0.5) < 0.001, "Key labels fade out smoothly")
check(keyBuffer.readout(at: 2.9).text.isEmpty, "Expired input is removed from the display buffer")
for number in 0..<30 { keyBuffer.append(String(number), at: 3) }
check(keyBuffer.readout(at: 3).labels == (6..<30).map(String.init), "Continuous typing stays bounded to the latest 24 labels")
keyBuffer.clear()
check(keyBuffer.readout(at: 3).text.isEmpty, "Turning off or secure input clears all key labels")

var transition = EffectTransition()
check(transition.update(visible: true, at: 10) == 0, "Zoom starts at native size on the first captured frame")
let midpoint = transition.update(visible: true, at: 10.12)
check(abs(midpoint - 0.5) < 0.000001, "Zoom interpolates magnification instead of appearing at full size")
let released = transition.update(visible: false, at: 10.12)
check(abs(released - midpoint) < 0.000001 && transition.isActive, "Early release keeps the current scale and capture for zoom-out")
let returning = transition.update(visible: false, at: 10.17)
check(returning > 0 && returning < released, "Zoom-out progresses smoothly toward native size")
let reversed = transition.update(visible: true, at: 10.17)
check(abs(reversed - returning) < 0.000001, "Pressing Fn again during zoom-out does not jump")
check(transition.update(visible: true, at: 10.20) > reversed, "Reversed zoom resumes enlargement")
check(transition.update(visible: true, at: 11) == 1, "Zoom settles exactly at the selected magnification")
check(transition.update(visible: false, at: 11) == 1, "Release begins from the displayed magnification")
check(abs(transition.update(visible: false, at: 11.10) - 0.5) < 0.000001, "Full zoom-out passes through its intermediate scale")
check(transition.update(visible: false, at: 11.3) == 0 && !transition.isActive, "Finished zoom-out releases the capture requirement")
transition.update(visible: true, at: 12)
transition.update(visible: true, at: 12.1)
transition.reset()
check(transition.progress == 0 && !transition.isActive, "Suspend or capture loss clears the animation")
var spotlightFade = EffectTransition(appearDuration: 0.22, disappearDuration: 0.22)
spotlightFade.update(visible: true, at: 20)
check(abs(spotlightFade.update(visible: true, at: 20.11) - 0.5) < 0.000001,
      "Spotlight fades in through an intermediate brightness")
spotlightFade.update(visible: true, at: 20.3)
spotlightFade.update(visible: false, at: 20.3)
check(abs(spotlightFade.update(visible: false, at: 20.41) - 0.5) < 0.000001,
      "Spotlight fades out through an intermediate brightness")
check(spotlightFade.update(visible: false, at: 20.6) == 0 && !spotlightFade.isActive,
      "Spotlight fade-out removes the dimming completely")

var responsiveZoom = EffectTransition.zoom()
check(responsiveZoom.update(visible: true, at: 30) == 0,
      "Responsive zoom still begins from native size")
let firstVisibleFrame = responsiveZoom.update(visible: true, at: 30 + 1.0 / 60)
check(firstVisibleFrame > 0.2 && firstVisibleFrame < 0.3,
      "First animation frame provides visible feedback instead of an imperceptible slow start")
check(responsiveZoom.update(visible: true, at: 30.18) > 0.999999,
      "Responsive zoom reaches its selected magnification in 180ms without overshoot")
let beforeRelease = responsiveZoom.progress
check(responsiveZoom.update(visible: false, at: 30.18) == beforeRelease,
      "Responsive zoom release preserves the currently displayed scale")
check(abs(responsiveZoom.update(visible: false, at: 30.28) - 0.5) < 0.000001,
      "Responsive zoom keeps the existing smooth 200ms zoom-out")
responsiveZoom.reset()
responsiveZoom.update(visible: true, at: 31)
check(abs(responsiveZoom.update(visible: true, at: 31 + 1.0 / 60) - firstVisibleFrame) < 0.000001,
      "Reset after sleep retains the responsive zoom curve")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
guard let screen = NSScreen.screens.first else { fatalError("A display is required for overlay checks") }
let surface = OverlaySurface(screen: screen)
preferences.enabled = true
preferences.haloDiameter = 56
preferences.spotlightDiameter = 320
let center = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
surface.render(point: center, preferences: preferences, spotlight: true, showHalo: true)
check(surface.panel.ignoresMouseEvents && !surface.panel.canBecomeKey, "Overlay cannot capture clicks or keyboard focus")
surface.render(point: center, preferences: preferences, spotlight: false, showHalo: true,
               keyReadout: KeyReadout(labels: ["⌘C", "⇧↑"], opacity: 1))
check(!surface.keyHUD.isHidden && surface.keyHUD.frame.minY >= 28 && surface.keyHUD.frame.midX == surface.root.bounds.midX,
      "Key labels appear at the bottom center without intercepting input")
var positionedFrames: [KeyDisplayPosition: CGRect] = [:]
for position in KeyDisplayPosition.allCases {
    preferences.keyDisplayPosition = position
    surface.render(point: center, preferences: preferences, spotlight: false, showHalo: false,
                   keyReadout: KeyReadout(labels: ["A", "⌘C"], opacity: 1))
    positionedFrames[position] = surface.keyHUD.frame
}
check(positionedFrames.values.allSatisfy { $0.midX == surface.root.bounds.midX }
      && positionedFrames[.top]!.minY > positionedFrames[.center]!.maxY
      && positionedFrames[.center]!.minY > positionedFrames[.bottom]!.maxY,
      "Top, center and bottom move the overlay vertically while keeping horizontal center")
check(positionedFrames[.center]!.midY == surface.root.bounds.midY,
      "Middle placement is centered on the full screen")
let secondaryScreen = CGRect(x: -1800, y: -300, width: 1600, height: 900)
let secondaryVisible = CGRect(x: -1720, y: -240, width: 1520, height: 810)
let largeKeySize = CGSize(width: 700, height: 290)
let topKeyFrame = KeyDisplayPosition.top.frame(for: largeKeySize, screen: secondaryScreen, visible: secondaryVisible)
let bottomKeyFrame = KeyDisplayPosition.bottom.frame(for: largeKeySize, screen: secondaryScreen, visible: secondaryVisible)
check(topKeyFrame.midX == 800 && bottomKeyFrame.midX == 800 && topKeyFrame.maxY == 842 && bottomKeyFrame.minY == 88,
      "Large keys avoid menu and Dock while remaining centered on a negative-origin display")
preferences.keyDisplayPosition = .bottom
surface.render(point: center, preferences: preferences, spotlight: true, showHalo: true)
check(surface.keyHUD.isHidden && surface.keyDisplay.texts.isEmpty, "Disabling key labels clears their rendered contents")
let keyRenderer = KeyDisplayRenderer()
let sampleKeys = KeyReadout(labels: ["A", "B", "⌘C"], opacity: 1)
let smallFont = KeyDisplayFont.resolve(KeyDisplayFont.monospaced, size: 28)
let firstKeySize = keyRenderer.render(KeyReadout(labels: ["A"], opacity: 1), font: smallFont,
                                      mode: .continuous, maxWidth: 900, scale: 2)
let continuousSize = keyRenderer.render(sampleKeys, font: smallFont, mode: .continuous, maxWidth: 900, scale: 2)
check(keyRenderer.boxes.count == 1 && continuousSize.width > firstKeySize.width,
      "Continuous input expands one box as more keys arrive")
keyRenderer.render(sampleKeys, font: smallFont, mode: .separate, maxWidth: 900, scale: 2)
check(keyRenderer.boxes.count == 3 && (keyRenderer.texts.last?.string as? NSAttributedString)?.string == "⌘C",
      "Separate mode gives each key its own box while keeping a shortcut together")
check(zip(keyRenderer.boxes, keyRenderer.boxes.dropFirst()).allSatisfy { $0.frame.maxX < $1.frame.minX },
      "Separate key boxes have visible gaps and never overlap")
let largeFont = KeyDisplayFont.resolve("Helvetica", size: 128)
let largeSize = keyRenderer.render(sampleKeys, font: largeFont, mode: .continuous, maxWidth: 900, scale: 2)
let renderedFont = (keyRenderer.texts[0].string as? NSAttributedString)?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
check(largeSize.height > continuousSize.height && renderedFont?.pointSize == 128 && renderedFont?.familyName == "Helvetica",
      "Font changes resize both text and box without clipping the line height")
for mode in KeyDisplayMode.allCases {
    let fittedSize = keyRenderer.render(KeyReadout(labels: Array(repeating: "⌃⌥⇧⌘W", count: 24) + ["끝"], opacity: 1),
                                         font: largeFont, mode: mode, maxWidth: 260, scale: 2)
    check(fittedSize.width <= 260 && (keyRenderer.texts.last?.string as? NSAttributedString)?.string.hasSuffix("끝") == true,
          "\(mode.title) keeps the newest input within narrow screen bounds")
}
let retainedKeyText = keyRenderer.texts[0]
keyRenderer.render(KeyReadout(), font: smallFont, mode: .separate, maxWidth: 900, scale: 2)
check(keyRenderer.boxes.isEmpty && retainedKeyText.string == nil && keyRenderer.layer.isHidden,
      "Turning off clears every separate box and its text")
check(!surface.dim.isHidden && !surface.halo.isHidden, "Halo and spotlight can coexist")
check(surface.halo.lineWidth == 7.5, "Ring width is reflected in the overlay")
let path = surface.dim.path!
check(!path.contains(surface.local(center), using: .evenOdd), "Spotlight center is transparent")
check(path.contains(CGPoint(x: 8, y: 8), using: .evenOdd), "Area outside spotlight is dimmed")
surface.render(point: center, preferences: preferences, spotlight: true, showHalo: true, spotlightProgress: 0.5)
check(surface.dim.opacity == 0.5 && !surface.dim.isHidden,
      "Spotlight opacity tracks the fade without hiding early")
check(!surface.dim.path!.contains(surface.local(center), using: .evenOdd),
      "Spotlight center remains clear during the fade")
let edge = CGPoint(x: screen.frame.minX - 10, y: screen.frame.midY)
surface.render(point: edge, preferences: preferences, spotlight: true, showHalo: true)
check(surface.halo.path!.boundingBoxOfPath.maxX > 0, "Halo crossing from adjacent display remains visible")
// Sample inside the display; containment on the rectangle's exact boundary is undefined.
check(!surface.dim.path!.contains(CGPoint(x: 1, y: screen.frame.height / 2), using: .evenOdd), "Spotlight cutout crosses a display boundary")
let haloBoundsBeforeClick = surface.halo.path!.boundingBoxOfPath
surface.click(at: center, preferences: preferences)
let firstSparkle = surface.clickEffects.sublayers!.last!
check(firstSparkle.position == surface.local(center) && firstSparkle.bounds.width <= 64,
      "Click sparkle stays close to the pointer")
preferences.haloDiameter = 160
surface.click(at: center, preferences: preferences)
let secondSparkle = surface.clickEffects.sublayers!.last!
check(firstSparkle.bounds == secondSparkle.bounds && CATransform3DEqualToTransform(firstSparkle.transform, secondSparkle.transform),
      "Click sparkle size does not grow with the outer highlight circle")
check(surface.halo.path!.boundingBoxOfPath == haloBoundsBeforeClick,
      "Click leaves the outer circle geometry unchanged")
RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.45))
check(surface.clickEffects.sublayers?.isEmpty != false,
      "Sparkles are removed after their brief animation")
surface.click(at: center, preferences: preferences)
let context = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.setFillColor(NSColor.white.cgColor)
context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
let sampleImage = context.makeImage()!
surface.render(point: center, preferences: preferences, spotlight: false, showHalo: true,
               zoomImage: sampleImage, zoomProgress: 0.5)
check(surface.lens.opacity == 0.5 && surface.halo.opacity == 0.5,
      "Lens border and cursor halo crossfade during zoom")
check(surface.lens.bounds.width == preferences.zoomDiameter,
      "Lens keeps its size while captured content zooms")
surface.render(point: center, preferences: preferences, spotlight: false, showHalo: true,
               zoomImage: sampleImage, zoomProgress: 0)
check(surface.lens.isHidden && surface.halo.opacity == 1 && !surface.halo.isHidden,
      "Zoom-out ends without a sudden lens or halo switch")
surface.render(point: center, preferences: preferences, spotlight: false, showHalo: false)
check(surface.dim.isHidden && surface.halo.isHidden, "Disabled effects leave no static overlay")
surface.render(point: center, preferences: preferences, spotlight: false, showHalo: false,
               zoomImage: sampleImage, zoomProgress: 1,
               keyReadout: KeyReadout(labels: ["A", "⌘C"], opacity: 1))
let suspendedText = surface.keyDisplay.texts[0]
surface.hide()
check(surface.clickEffects.sublayers?.isEmpty != false, "Hiding removes remaining click effects")
check(surface.lens.contents == nil && surface.lens.isHidden,
      "Hiding releases the last captured image without waiting for another frame")
check(surface.keyDisplay.texts.isEmpty && surface.keyDisplay.boxes.isEmpty
      && suspendedText.string == nil && suspendedText.contents == nil && surface.keyHUD.isHidden,
      "Hiding immediately clears rendered keystrokes, including retained text layers")
surface.panel.orderFrontRegardless()
check(surface.lens.isHidden && surface.keyHUD.isHidden,
      "Reopening an overlay cannot briefly redisplay content from before suspension")
surface.panel.close()
print("All \(assertions) checks passed.")
