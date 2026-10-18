import AppKit
import Combine
import CoreImage
import OSLog
import ScreenCaptureKit

/// Keeps frames in memory while Fn is held and during the brief zoom-out transition.
/// No files, audio, or network output.
final class ZoomCapture: NSObject, ObservableObject, SCStreamOutput, SCStreamDelegate {
    @Published private(set) var permissionGranted = CGPreflightScreenCaptureAccess()
    @Published private(set) var message: String?
    var onFrame: (() -> Void)?
    var onPermissionNeeded: (() -> Void)?
    private var capture: SCStream?
    private var frame: CVPixelBuffer?
    private var displayID: CGDirectDisplayID?
    private var displayFrame = CGRect.zero
    private var generation = 0
    private var active = false
    private var failedForCurrentHold = false
    private var permissionNoticeShown = false
    private let context = CIContext(options: [.cacheIntermediates: false])
    private var preparedContent: Task<SCShareableContent, Error>?
    private var requestedAt: TimeInterval = 0
    private let logger = Logger(subsystem: "com.jvisualschool.BigMouse", category: "Zoom")

    var hasFrame: Bool { active && frame != nil }

    static func isShortcutHeld(_ flags: NSEvent.ModifierFlags) -> Bool {
        flags.contains(.function)
    }

    func requestPermission() {
        permissionGranted = CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
        if !permissionGranted {
            message = L10n.text(.screenPermissionRestart)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        } else {
            message = nil
        }
        permissionNoticeShown = false
        failedForCurrentHold = false
        if permissionGranted { prepare() }
    }

    func refreshPermission() {
        let granted = CGPreflightScreenCaptureAccess()
        if permissionGranted != granted { permissionGranted = granted }
        if granted { message = nil }
        else { invalidatePreparation() }
    }

    /// Enumerate displays/windows ahead of the key press, without starting a capture.
    /// These objects remain valid until our overlays or the display layout change.
    func prepare() {
        guard permissionGranted, preparedContent == nil else { return }
        preparedContent = Task { @MainActor in
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            try Task.checkCancellation()
            return content
        }
    }

    private func invalidatePreparation() {
        preparedContent?.cancel()
        preparedContent = nil
    }

    func update(active requested: Bool, screen: NSScreen?, excluding windowIDs: Set<CGWindowID>) {
        guard requested, let screen,
              let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            if active { stopCapture() }
            failedForCurrentHold = false
            return
        }
        guard !failedForCurrentHold else { return }
        let targetID = id.uint32Value
        if active && displayID == targetID { return }
        stopCapture()
        refreshPermission()
        guard permissionGranted else {
            failedForCurrentHold = true
            message = L10n.text(.screenPermissionNeeded)
            if !permissionNoticeShown {
                permissionNoticeShown = true
                onPermissionNeeded?()
            }
            return
        }
        active = true
        requestedAt = ProcessInfo.processInfo.systemUptime
        displayID = targetID
        displayFrame = screen.frame
        let token = generation
        let scale = screen.backingScaleFactor
        prepare()
        guard let preparation = preparedContent else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let content = try await preparation.value
                guard self.generation == token && self.active else { return }
                guard let display = content.displays.first(where: { $0.displayID == targetID }) else {
                    throw NSError(domain: "BigMouse", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.text(.screenNotFound)])
                }
                // Exclude our overlays, while allowing the settings window itself to be magnified.
                let excluded = content.windows.filter { windowIDs.contains($0.windowID) }
                let filter = SCContentFilter(display: display, excludingWindows: excluded)
                let config = SCStreamConfiguration()
                config.width = Int(screen.frame.width * scale)
                config.height = Int(screen.frame.height * scale)
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.showsCursor = false
                config.capturesAudio = false
                config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
                config.queueDepth = 3
                let stream = SCStream(filter: filter, configuration: config, delegate: self)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                self.capture = stream
                try await stream.startCapture()
                guard self.generation == token && self.active else {
                    try? await stream.stopCapture()
                    return
                }
                self.message = nil
            } catch {
                guard self.generation == token else { return }
                self.stop()
                self.failedForCurrentHold = true
                self.message = L10n.text(.zoomStartFailed)
                self.onPermissionNeeded?()
            }
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard stream === capture, active, outputType == .screen, sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let raw = attachments.first?[.status] as? Int,
              SCFrameStatus(rawValue: raw) == .complete,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }
        if frame == nil {
            let milliseconds = (ProcessInfo.processInfo.systemUptime - requestedAt) * 1000
            logger.notice("Zoom first frame: \(milliseconds, format: .fixed(precision: 1)) ms")
        }
        frame = pixelBuffer
        onFrame?()
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self, stream === self.capture else { return }
            self.stop()
            self.failedForCurrentHold = true
            self.message = L10n.text(.captureStopped)
            self.onFrame?()
        }
    }

    /// Core Image and AppKit both use bottom-left origins here.
    static func cropRect(point: CGPoint, screen: CGRect, pixels: CGSize, diameter: Double, magnification: Double) -> CGRect {
        let sx = pixels.width / screen.width
        let sy = pixels.height / screen.height
        let width = diameter / magnification * sx
        let height = diameter / magnification * sy
        return CGRect(x: (point.x - screen.minX) * sx - width / 2,
                      y: (point.y - screen.minY) * sy - height / 2,
                      width: width, height: height)
    }

    func image(at point: CGPoint, diameter: Double, magnification: Double) -> CGImage? {
        guard active, let frame else { return nil }
        let image = CIImage(cvPixelBuffer: frame)
        let crop = Self.cropRect(point: point, screen: displayFrame, pixels: image.extent.size,
                                 diameter: diameter, magnification: magnification)
        // Extend edge pixels, preserving cursor alignment even at display corners.
        return context.createCGImage(image.clampedToExtent(), from: crop)
    }

    func stop() {
        invalidatePreparation()
        stopCapture()
    }

    private func stopCapture() {
        generation += 1
        active = false
        displayID = nil
        frame = nil
        let previous = capture
        capture = nil
        if let previous { previous.stopCapture { _ in } }
    }
}
