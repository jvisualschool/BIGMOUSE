import AppKit
import Combine
import QuartzCore

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OverlaySurface {
    let panel: OverlayPanel
    let screenFrame: CGRect
    let root = CALayer()
    let dim = CAShapeLayer()
    let halo = CAShapeLayer()
    let lens = CALayer()
    let clickEffects = CALayer()
    let keyDisplay = KeyDisplayRenderer()
    var keyHUD: CALayer { keyDisplay.layer }
    private let screen: NSScreen

    init(screen: NSScreen) {
        self.screen = screen
        screenFrame = screen.frame
        panel = OverlayPanel(contentRect: screen.frame,
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.setFrame(screen.frame, display: false)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        if #available(macOS 13.0, *) { panel.collectionBehavior.insert(.canJoinAllApplications) }
        panel.animationBehavior = .none
        let view = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        root.frame = view.bounds
        root.masksToBounds = true
        root.contentsScale = screen.backingScaleFactor
        view.layer = root
        panel.contentView = view
        for layer in [dim, halo] {
            layer.contentsScale = screen.backingScaleFactor
            root.addSublayer(layer)
        }
        root.addSublayer(clickEffects)
        root.insertSublayer(lens, below: halo)
        lens.masksToBounds = true
        lens.contentsGravity = .resize
        lens.contentsScale = screen.backingScaleFactor
        lens.isHidden = true
        dim.fillRule = .evenOdd
        dim.isHidden = true
        halo.isHidden = true
        root.addSublayer(keyHUD)
        keyHUD.isHidden = true
    }

    func local(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - screenFrame.minX, y: point.y - screenFrame.minY)
    }

    func render(point: CGPoint, preferences: Preferences, spotlight: Bool, showHalo: Bool,
                zoomImage: CGImage? = nil, zoomProgress: Double = 1, spotlightProgress: Double = 1,
                keyReadout: KeyReadout = KeyReadout()) {
        let position = local(point)
        let visibleZoom = zoomImage == nil ? 0 : min(1, max(0, zoomProgress))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let keySize = keyDisplay.render(keyReadout, font: preferences.keyFont, mode: preferences.keyDisplayMode,
                                        maxWidth: root.bounds.width - 64, scale: root.contentsScale)
        keyHUD.frame = preferences.keyDisplayPosition.frame(for: keySize, screen: screenFrame, visible: screen.visibleFrame)
        lens.isHidden = visibleZoom == 0
        lens.opacity = Float(visibleZoom)
        lens.contents = zoomImage
        if zoomImage != nil {
            let diameter = preferences.zoomDiameter
            lens.frame = CGRect(x: position.x - diameter / 2, y: position.y - diameter / 2,
                                width: diameter, height: diameter)
            lens.cornerRadius = diameter / 2
            lens.borderColor = preferences.accent.nsColor.cgColor
            lens.borderWidth = preferences.haloLineWidth
        }
        // Draw on every display, clipped at its edges, so circles remain whole across a seam.
        halo.isHidden = !showHalo || visibleZoom == 1
        halo.opacity = Float(1 - visibleZoom)
        halo.lineWidth = preferences.haloLineWidth
        if showHalo {
            let radius = preferences.haloDiameter / 2
            halo.path = CGPath(ellipseIn: CGRect(x: position.x - radius, y: position.y - radius,
                                               width: radius * 2, height: radius * 2), transform: nil)
            halo.strokeColor = preferences.accent.nsColor.cgColor
            halo.fillColor = preferences.accent.nsColor.withAlphaComponent(preferences.haloOpacity).cgColor
        }
        dim.isHidden = !spotlight || spotlightProgress <= 0
        dim.opacity = Float(min(1, max(0, spotlightProgress)))
        if spotlight {
            let radius = preferences.spotlightDiameter / 2
            let path = CGMutablePath()
            path.addRect(root.bounds)
            path.addEllipse(in: CGRect(x: position.x - radius, y: position.y - radius,
                                      width: radius * 2, height: radius * 2))
            dim.path = path
            dim.fillColor = NSColor.black.withAlphaComponent(preferences.dimOpacity).cgColor
        }
        CATransaction.commit()
    }

    func click(at point: CGPoint, preferences: Preferences) {
        let position = local(point)
        // Keep the sparkle close to the pointer, independent of the highlight circle size.
        guard root.bounds.insetBy(dx: -32, dy: -32).contains(position) else { return }
        let burst = CALayer()
        burst.bounds = CGRect(x: 0, y: 0, width: 64, height: 64)
        burst.position = position
        clickEffects.addSublayer(burst)
        let startedAt = burst.convertTime(CACurrentMediaTime(), from: nil)
        let angles: [CGFloat] = [22, 78, 140, 198, 250, 312]
        let distances: [CGFloat] = [18, 22, 18, 21, 16, 23]
        for index in angles.indices {
            let angle = angles[index] * .pi / 180
            let radius: CGFloat = index.isMultiple(of: 2) ? 5 : 3.5
            let sparkle = CAShapeLayer()
            sparkle.position = CGPoint(x: 32 + cos(angle) * distances[index],
                                       y: 32 + sin(angle) * distances[index])
            sparkle.path = Self.sparklePath(radius: radius)
            sparkle.fillColor = preferences.accent.nsColor.cgColor
            sparkle.contentsScale = root.contentsScale
            sparkle.shadowColor = preferences.accent.nsColor.cgColor
            sparkle.shadowOpacity = 0.75
            sparkle.shadowRadius = 2
            sparkle.shadowOffset = .zero
            sparkle.opacity = 0

            let glint = CAShapeLayer()
            glint.path = Self.sparklePath(radius: radius * 0.38)
            glint.fillColor = NSColor.white.cgColor
            glint.contentsScale = root.contentsScale
            sparkle.addSublayer(glint)
            burst.addSublayer(sparkle)

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 1, 0.65, 0]
            fade.keyTimes = [0, 0.18, 0.48, 1]
            let twinkle = CAKeyframeAnimation(keyPath: "transform.scale")
            twinkle.values = [0.6, 1, 0.82]
            twinkle.keyTimes = [0, 0.2, 1]
            let animation = CAAnimationGroup()
            animation.animations = [fade, twinkle]
            animation.beginTime = startedAt + Double(index) * 0.012
            animation.duration = 0.30
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            sparkle.add(animation, forKey: "twinkle")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak burst] in burst?.removeFromSuperlayer() }
    }

    private static func sparklePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<8 {
            let angle = CGFloat(index) * .pi / 4
            let distance = index.isMultiple(of: 2) ? radius : radius * 0.24
            let point = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    func hide() {
        panel.orderOut(nil)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        lens.contents = nil
        lens.isHidden = true
        keyDisplay.clear()
        CATransaction.commit()
        clickEffects.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}

final class OverlayController {
    let preferences: Preferences
    let zoom: ZoomCapture
    let keys: KeystrokeMonitor
    private(set) var surfaces: [OverlaySurface] = []
    private var timer: Timer?
    private var globalClicks: Any?
    private var localClicks: Any?
    private var observers: [NSObjectProtocol] = []
    private var subscriptions = Set<AnyCancellable>()
    private var lastPoint: CGPoint?
    private var lastMovement = ProcessInfo.processInfo.systemUptime
    private var lastSpotlight = false
    private var lastShowHalo = false
    private var lastZoom = false
    private var lastKeyReadout = KeyReadout()
    private var zoomTransition = EffectTransition.zoom()
    private var spotlightTransition = EffectTransition(appearDuration: 0.22, disappearDuration: 0.22)
    private var previewUntil: TimeInterval = 0
    private var zoomPreviewUntil: TimeInterval = 0
    private var suspended = false

    init(preferences: Preferences, zoom: ZoomCapture, keys: KeystrokeMonitor) {
        self.preferences = preferences
        self.zoom = zoom
        self.keys = keys
        zoom.onFrame = { [weak self] in self?.tick(force: true) }
        preferences.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in
            self?.applyPreferences()
        }.store(in: &subscriptions)
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.rebuild() })
        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.suspended = true
                self?.applyPreferences()
            })
        }
        for name in [NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.suspended = false
                self?.rebuild()
            })
        }
        rebuild()
    }

    func rebuild() {
        keys.suspend()
        lastKeyReadout = KeyReadout()
        zoom.stop()
        zoomTransition.reset()
        zoomPreviewUntil = 0
        spotlightTransition.reset()
        surfaces.forEach { $0.hide(); $0.panel.close() }
        surfaces = NSScreen.screens.map(OverlaySurface.init)
        lastPoint = nil
        applyPreferences()
    }

    func applyPreferences() {
        stopTracking()
        // Keep polling the double-Option gesture even when other visual effects are off.
        let active = preferences.enabled && !suspended
        guard active else {
            keys.suspend()
            lastKeyReadout = KeyReadout()
            zoom.stop()
            zoomTransition.reset()
            spotlightTransition.reset()
            previewUntil = 0
            zoomPreviewUntil = 0
            surfaces.forEach { $0.hide() }
            return
        }
        lastPoint = nil
        lastMovement = ProcessInfo.processInfo.systemUptime
        surfaces.forEach { $0.panel.orderFrontRegardless() }
        if preferences.zoomEnabled {
            zoom.prepare()
        } else {
            zoomPreviewUntil = 0
            zoom.stop()
        }
        tick(force: true)
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.tick() }
        timer.tolerance = 0.003
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        if preferences.clicksEnabled {
            let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            globalClicks = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in self?.clicked() }
            localClicks = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
                self?.clicked()
                return event
            }
        }
    }

    func previewSpotlight() {
        guard preferences.enabled && preferences.spotlightEnabled else { return }
        previewUntil = ProcessInfo.processInfo.systemUptime + 3
        tick(force: true)
    }

    func previewZoom() {
        guard preferences.enabled && preferences.zoomEnabled && !suspended else { return }
        zoomPreviewUntil = ProcessInfo.processInfo.systemUptime + 3
        tick(force: true)
    }

    private func clicked() {
        guard preferences.enabled && preferences.clicksEnabled && !suspended else { return }
        let point = NSEvent.mouseLocation
        lastMovement = ProcessInfo.processInfo.systemUptime
        surfaces.forEach { $0.click(at: point, preferences: preferences) }
        tick(force: true)
    }

    func tick(force: Bool = false) {
        guard preferences.enabled && !suspended else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let point = NSEvent.mouseLocation
        let keyReadout = keys.poll(flags: NSEvent.modifierFlags, at: now)
        let moved = point != lastPoint
        if moved { lastMovement = now }
        let spotlight = preferences.spotlightEnabled &&
            (preferences.shortcut.matches(NSEvent.modifierFlags) || now < previewUntil)
        let previousSpotlightProgress = spotlightTransition.progress
        let spotlightProgress = spotlightTransition.update(visible: spotlight, at: now)
        let zoomHeld = preferences.zoomEnabled &&
            (ZoomCapture.isShortcutHeld(NSEvent.modifierFlags) || now < zoomPreviewUntil)
        let screen = NSScreen.screens.first { $0.frame.contains(point) }
        let excludedWindows = Set(surfaces.map { CGWindowID($0.panel.windowNumber) })
        zoom.update(active: zoomHeld || zoomTransition.isActive, screen: screen, excluding: excludedWindows)
        let previousProgress = zoomTransition.progress
        // Wait for the first real frame so capture startup cannot skip the zoom-in animation.
        if !zoom.hasFrame { zoomTransition.reset() }
        let progress = zoomTransition.update(visible: zoomHeld && zoom.hasFrame, at: now)
        if !zoomHeld && !zoomTransition.isActive {
            zoom.update(active: false, screen: screen, excluding: excludedWindows)
        }
        let showHalo = preferences.haloEnabled &&
            (!preferences.hideWhenIdle || now - lastMovement < 2 || spotlightTransition.isActive)
        guard force || moved || spotlight != lastSpotlight || showHalo != lastShowHalo ||
                zoomHeld != lastZoom || progress != previousProgress ||
                spotlightProgress != previousSpotlightProgress || keyReadout != lastKeyReadout else { return }
        let magnification = 1 + (preferences.zoomScale - 1) * progress
        let zoomImage = progress > 0 ? zoom.image(at: point, diameter: preferences.zoomDiameter, magnification: magnification) : nil
        surfaces.forEach {
            $0.render(point: point, preferences: preferences, spotlight: spotlightTransition.isActive, showHalo: showHalo,
                      zoomImage: zoomImage, zoomProgress: progress, spotlightProgress: spotlightProgress,
                      keyReadout: $0.screenFrame.contains(point) ? keyReadout : KeyReadout())
        }
        lastPoint = point
        lastSpotlight = spotlight
        lastShowHalo = showHalo
        lastZoom = zoomHeld
        lastKeyReadout = keyReadout
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        if let globalClicks { NSEvent.removeMonitor(globalClicks) }
        if let localClicks { NSEvent.removeMonitor(localClicks) }
        globalClicks = nil
        localClicks = nil
    }

    func stop() {
        keys.suspend()
        lastKeyReadout = KeyReadout()
        zoom.stop()
        zoomTransition.reset()
        spotlightTransition.reset()
        stopTracking()
        surfaces.forEach { $0.hide(); $0.panel.close() }
        surfaces.removeAll()
        observers.forEach {
            NotificationCenter.default.removeObserver($0)
            NSWorkspace.shared.notificationCenter.removeObserver($0)
        }
        observers.removeAll()
    }
}
