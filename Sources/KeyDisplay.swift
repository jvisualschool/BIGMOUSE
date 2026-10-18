import AppKit
import QuartzCore
import SwiftUI

/// Shared by the screen overlay and the settings preview.
final class KeyDisplayRenderer {
    let layer = CALayer()
    private(set) var boxes: [CALayer] = []
    private(set) var texts: [CATextLayer] = []

    /// Drop rendered input as soon as the overlay is hidden or suspended.
    func clear() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.isHidden = true
        layer.opacity = 0
        texts.forEach { $0.string = nil; $0.contents = nil }
        boxes.forEach { $0.removeFromSuperlayer() }
        boxes.removeAll()
        texts.removeAll()
        layer.bounds = .zero
        CATransaction.commit()
    }

    @discardableResult
    func render(_ readout: KeyReadout, font: NSFont, mode: KeyDisplayMode,
                maxWidth: CGFloat, scale: CGFloat) -> CGSize {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        layer.isHidden = readout.labels.isEmpty || readout.opacity <= 0
        layer.opacity = readout.opacity
        guard !layer.isHidden else {
            clear()
            return .zero
        }

        let available = max(1, maxWidth)
        let paddingX = max(14, ceil(font.pointSize * 0.6))
        let paddingY = max(9, ceil(font.pointSize * 0.4))
        let gap: CGFloat = mode == .separate ? 8 : 0
        func label(_ text: String) -> NSAttributedString {
            NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor.white])
        }
        func grouped(_ keys: [String]) -> [NSAttributedString] {
            (mode == .continuous ? [keys.joined(separator: "  ")] : keys).map(label)
        }
        func width(_ text: NSAttributedString) -> CGFloat {
            min(available, max(ceil(font.pointSize * 1.2), ceil(text.size().width)) + paddingX * 2)
        }
        var keys = readout.labels
        var labels = grouped(keys)
        func rowWidth() -> CGFloat {
            labels.reduce(0) { $0 + width($1) } + CGFloat(max(0, labels.count - 1)) * gap
        }
        // Keep the newest whole keys when the row reaches the screen edges.
        // Measure the unbounded joined text so continuous mode also discards old keys.
        while keys.count > 1 && (rowWidth() > available ||
            (mode == .continuous && labels[0].size().width + paddingX * 2 > available)) {
            keys.removeFirst()
            labels = grouped(keys)
        }
        let textHeight = ceil(max(font.ascender - font.descender + font.leading,
                                  labels.map { $0.size().height }.max() ?? 0)) + 2
        let height = textHeight + paddingY * 2
        let size = CGSize(width: rowWidth(), height: height)
        while boxes.count > labels.count {
            boxes.removeLast().removeFromSuperlayer()
            texts.removeLast().string = nil
        }
        while boxes.count < labels.count {
            let box = CALayer()
            box.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor
            let text = CATextLayer()
            text.alignmentMode = .center
            text.truncationMode = .start
            box.addSublayer(text)
            layer.addSublayer(box)
            boxes.append(box)
            texts.append(text)
        }
        var x: CGFloat = 0
        for index in labels.indices {
            let boxWidth = width(labels[index])
            boxes[index].frame = CGRect(x: x, y: 0, width: boxWidth, height: height)
            boxes[index].cornerRadius = min(14, height * 0.22)
            let inset = min(paddingX, max(0, (boxWidth - 1) / 2))
            texts[index].contentsScale = scale
            texts[index].frame = CGRect(x: inset, y: paddingY, width: boxWidth - inset * 2, height: textHeight)
            texts[index].string = labels[index]
            x += boxWidth + gap
        }
        layer.bounds = CGRect(origin: .zero, size: size)
        return size
    }
}

struct KeyDisplayPreview: NSViewRepresentable {
    let font: NSFont
    let mode: KeyDisplayMode

    func makeNSView(context: Context) -> KeyPreviewView { KeyPreviewView() }
    func updateNSView(_ view: KeyPreviewView, context: Context) {
        view.font = font
        view.mode = mode
        view.needsLayout = true
    }
}

final class KeyPreviewView: NSView {
    var font = KeyDisplayFont.resolve(KeyDisplayFont.monospaced, size: 28)
    var mode = KeyDisplayMode.continuous
    private let renderer = KeyDisplayRenderer()

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.addSublayer(renderer.layer)
        setAccessibilityElement(true)
        setAccessibilityLabel(L10n.text(.keyPreview))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        let size = renderer.render(KeyReadout(labels: ["A", "B", "C", "⌘C"], opacity: 1),
                                   font: font, mode: mode, maxWidth: bounds.width,
                                   scale: window?.backingScaleFactor ?? 2)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        renderer.layer.frame = CGRect(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2,
                                      width: size.width, height: size.height)
        CATransaction.commit()
    }
}
