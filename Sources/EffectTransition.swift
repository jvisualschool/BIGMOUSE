import Foundation

/// Time-based easing keeps the animation independent of capture and timer frame rates.
struct EffectTransition {
    enum Curve { case smoothstep, easeOut }
    private(set) var progress: Double = 0
    private var origin: Double = 0
    private var target: Double = 0
    private var startedAt: TimeInterval = 0
    private var duration: TimeInterval = 0
    private let appearDuration: TimeInterval
    private let disappearDuration: TimeInterval
    private let appearCurve: Curve

    init(appearDuration: TimeInterval = 0.24, disappearDuration: TimeInterval = 0.20,
         appearCurve: Curve = .smoothstep) {
        self.appearDuration = appearDuration
        self.disappearDuration = disappearDuration
        self.appearCurve = appearCurve
    }

    static func zoom() -> EffectTransition {
        EffectTransition(appearDuration: 0.18, disappearDuration: 0.20, appearCurve: .easeOut)
    }

    var isActive: Bool { progress > 0 || target > 0 }

    @discardableResult
    mutating func update(visible: Bool, at time: TimeInterval) -> Double {
        let nextTarget: Double = visible ? 1 : 0
        if nextTarget != target {
            // Sample the interrupted animation before starting the opposite direction.
            progress = value(at: time)
            origin = progress
            target = nextTarget
            startedAt = time
            duration = (visible ? appearDuration : disappearDuration) * abs(target - origin)
        }
        progress = value(at: time)
        return progress
    }

    mutating func reset() {
        self = EffectTransition(appearDuration: appearDuration, disappearDuration: disappearDuration, appearCurve: appearCurve)
    }

    private func value(at time: TimeInterval) -> Double {
        guard duration > 0 else { return target }
        let t = min(1, max(0, (time - startedAt) / duration))
        // Zoom responds on its first frame; releases and spotlight retain the soft fade.
        let eased = target == 1 && appearCurve == .easeOut ? 1 - pow(1 - t, 3) : t * t * (3 - 2 * t)
        return origin + (target - origin) * eased
    }
}
