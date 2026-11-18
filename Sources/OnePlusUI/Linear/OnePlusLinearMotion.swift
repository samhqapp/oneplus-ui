import SwiftUI

/// Whether a surface moves on a real state change. `.quiet` (the default) uses the Native snap motion in
/// `OnePlusMotion`; `.instant` changes in one frame. Reduce Motion is always instant.
public enum OnePlusLinearMotionStyle: Sendable, Equatable {
    case instant, quiet
}

public extension EnvironmentValues {
    @Entry var onePlusLinearMotion: OnePlusLinearMotionStyle = .quiet
}

public extension View {
    /// Turns the Native snap motion on (the default) or off for this surface.
    func onePlusLinearMotion(_ style: OnePlusLinearMotionStyle) -> some View {
        environment(\.onePlusLinearMotion, style)
    }

    /// Animates changes of `value` inside this view with the ease-out curve when the surface allows motion.
    /// An instant surface keeps whatever transaction the host sent.
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
        let animation = enabled ? OnePlusMotion.resolved(duration, style: style, reduceMotion: reduceMotion) : nil
        content.transaction(value: value) { transaction in
            if let animation { transaction.animation = animation }
        }
    }
}

/// Swaps content when `value` changes (an applet's Home and Settings, a panel page). Page content switches are
/// instant under Native snap: the new content shows in its final layout in the next frame.
public struct OnePlusLinearContentSwitch<Value: Hashable, Content: View>: View {
    private let value: Value
    private let content: Content
    public init(_ value: Value, @ViewBuilder content: () -> Content) { self.value = value; self.content = content() }
    public var body: some View {
        content.id(value).transaction { $0.animation = nil }
    }
}
