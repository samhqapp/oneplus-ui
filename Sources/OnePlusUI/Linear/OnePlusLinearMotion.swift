import SwiftUI

/// Whether a surface moves on a real state change. `.quiet` (the default) uses the Native snap motion in
/// `OnePlusMotion`; `.spring` (the main window) adds the Soft spring row hover, page switch, launch tile, and switch;
/// `.instant` changes in one frame. Reduce Motion is always instant.
public enum OnePlusLinearMotionStyle: Sendable, Equatable {
    case instant, quiet, spring
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
    /// `spring` replaces the ease-out on a `.spring` surface.
    func linearMotion<V: Equatable>(_ duration: TimeInterval, value: V, enabled: Bool = true, spring: Animation? = nil) -> some View {
        modifier(OnePlusLinearMotionModifier(duration: duration, value: value, enabled: enabled, spring: spring))
    }
}

private struct OnePlusLinearMotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.onePlusLinearMotion) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let duration: TimeInterval
    let value: V
    let enabled: Bool
    let spring: Animation?
    func body(content: Content) -> some View {
        let eased = enabled ? OnePlusMotion.resolved(duration, style: style, reduceMotion: reduceMotion) : nil
        let animation = style == .spring && eased != nil ? spring ?? eased : eased
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

/// Swaps the main window page when `value` changes. On a `.spring` surface the old page fades out moving 6 pt up
/// while the new one fades in from 6 pt below; otherwise, and under Reduce Motion, the switch is instant.
public struct OnePlusLinearPageSwitch<Value: Hashable, Content: View>: View {
    private let value: Value
    private let content: Content
    @Environment(\.onePlusLinearMotion) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public init(_ value: Value, @ViewBuilder content: () -> Content) { self.value = value; self.content = content() }
    public var body: some View {
        let moves = style == .spring && !reduceMotion
        let offset = OnePlusMotion.springPageOffset
        ZStack {
            content.id(value)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: offset)),
                                        removal: .opacity.combined(with: .offset(y: -offset))))
        }
        .animation(moves ? OnePlusMotion.animation(OnePlusMotion.springPage) : nil, value: value)
    }
}

public extension EnvironmentValues {
    /// The panel's first-open reveal, 0 to 1. Below 1, live numbers show that share of their value, usage bars that
    /// share of their length, and chart lines are hidden; the change to 1 counts numbers up, grows bars, and draws
    /// charts in. Animate it to 1 with `OnePlusMotion.panelReveal`. 1 (the default) shows everything as is.
    @Entry var onePlusLinearReveal: Double = 1
}

/// A live number on the combined panel: it rolls only the digits that change (up when the value rises), at the pace
/// of its metric, and counts up during the first-open reveal. Reduce Motion crossfades. Font and color come from
/// the caller. While the surface is hidden, a new value shows at once, so a reopen starts with current text.
public struct OnePlusLinearNumberText: View {
    private let text: String
    private let pace: OnePlusNumberPace
    @State private var shown: String?
    @State private var shownAt = Date.distantPast
    @Environment(\.onePlusIsVisible) private var isVisible
    @Environment(\.onePlusLinearReveal) private var reveal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ text: String, pace: OnePlusNumberPace) { self.text = text; self.pace = pace }

    public var body: some View {
        let current = shown ?? text
        let value = Double(current)
        OnePlusLinearCountText(text: current, value: value, progress: reveal)
            .contentTransition(reveal < 1 ? .identity : reduceMotion ? .opacity : .numericText(value: value ?? 0))
            .animation(reduceMotion ? OnePlusMotion.animation(OnePlusMotion.numberCrossfade)
                       : .spring(response: pace.response, dampingFraction: pace.damping), value: shown)
            .task(id: text) { await follow() }
    }

    private func follow() async {
        guard let shown, shown != text, isVisible, reveal >= 1 else {
            var instant = Transaction(); instant.disablesAnimations = true
            withTransaction(instant) { self.shown = text }
            return
        }
        // The deadline is anchored to the last shown change, so samples that keep arriving never starve it.
        let wait = max(pace.offset, pace.interval - Date.now.timeIntervalSince(shownAt))
        try? await Task.sleep(for: .seconds(wait))
        guard !Task.isCancelled else { return }
        self.shown = text
        shownAt = .now
    }
}

/// Shows `progress` of a plain decimal value with the same decimals; text that is not a plain number shows as is.
private struct OnePlusLinearCountText: View, @MainActor Animatable {
    let text: String
    let value: Double?
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Text(verbatim: shownText)
    }

    private var shownText: String {
        guard progress < 1, let value, value.isFinite else { return text }
        let decimals = text.split(separator: ".").dropFirst().first?.count ?? 0
        return String(format: "%.\(decimals)f", value * max(progress, 0))
    }
}
