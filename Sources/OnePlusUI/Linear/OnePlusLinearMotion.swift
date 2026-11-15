import SwiftUI

/// How v15 parts move on a real state change. `.instant` (the default) changes in one frame.
/// `.quiet` slides knobs and thumbs and fades content; turn it on per surface with `.onePlusLinearMotion(.quiet)`.
public enum OnePlusLinearMotionStyle: Sendable, Equatable {
    case instant, quiet
}

/// DESIGN.md v15 motion "Quiet": one ease-out curve, 120 to 160 ms, no spring, no scale, no stagger, no hover motion.
public enum OnePlusLinearMotion {
    /// `cubic-bezier(0.25, 1, 0.5, 1)`.
    public static let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.25, y: 1), endControlPoint: UnitPoint(x: 0.5, y: 1))
    /// Switch knob and segment thumb.
    public static let knob: TimeInterval = 0.14
    /// Slider knob on a programmatic change (reset). A dragged knob follows the pointer with no animation.
    public static let slider: TimeInterval = 0.16
    /// New panel or sheet content fades in and rises by `contentOffset`.
    public static let contentIn: TimeInterval = 0.16
    /// Old panel or sheet content fades out.
    public static let contentOut: TimeInterval = 0.12
    public static let contentOffset: CGFloat = 4

    public static func animation(_ duration: TimeInterval) -> Animation {
        .timingCurve(curve, duration: duration)
    }

    /// The animation for one change, or nil when the surface is instant or Reduce Motion is on.
    public static func resolved(_ duration: TimeInterval, style: OnePlusLinearMotionStyle, reduceMotion: Bool) -> Animation? {
        style == .quiet && !reduceMotion ? animation(duration) : nil
    }
}

public extension EnvironmentValues {
    @Entry var onePlusLinearMotion: OnePlusLinearMotionStyle = .instant
}

public extension View {
    /// Turns the v15 Quiet motion on (or off) for this surface.
    func onePlusLinearMotion(_ style: OnePlusLinearMotionStyle) -> some View {
        environment(\.onePlusLinearMotion, style)
    }

    /// Animates changes of `value` with the Quiet curve when the surface allows motion. An instant surface keeps
    /// whatever transaction the host sent, so nothing changes for it.
    func linearMotion<V: Equatable>(_ duration: TimeInterval, value: V, enabled: Bool = true) -> some View {
        modifier(OnePlusLinearMotionModifier(duration: duration, value: value, enabled: enabled))
    }
}

private struct OnePlusLinearMotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.onePlusLinearMotion) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let duration: TimeInterval
    let value: V
    let enabled: Bool
    func body(content: Content) -> some View {
        let animation = enabled ? OnePlusLinearMotion.resolved(duration, style: style, reduceMotion: reduceMotion) : nil
        content.transaction(value: value) { transaction in
            if let animation { transaction.animation = animation }
        }
    }
}

/// Swaps content when `value` changes (an applet's Home and Settings, a panel page). Under Quiet motion the new
/// content fades in with a 4 pt rise and the old content fades out; otherwise the swap is instant.
public struct OnePlusLinearContentSwitch<Value: Hashable, Content: View>: View {
    @Environment(\.onePlusLinearMotion) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let value: Value
    private let content: Content
    public init(_ value: Value, @ViewBuilder content: () -> Content) { self.value = value; self.content = content() }
    public var body: some View {
        let moves = OnePlusLinearMotion.resolved(OnePlusLinearMotion.contentIn, style: style, reduceMotion: reduceMotion) != nil
        ZStack(alignment: .top) {
            content.id(value).transition(moves ? Self.transition : .identity)
        }
        .linearMotion(OnePlusLinearMotion.contentIn, value: value)
    }

    private static var transition: AnyTransition {
        .asymmetric(insertion: .opacity.combined(with: .offset(y: OnePlusLinearMotion.contentOffset)),
                    removal: .opacity.animation(OnePlusLinearMotion.animation(OnePlusLinearMotion.contentOut)))
    }
}
