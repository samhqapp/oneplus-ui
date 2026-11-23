import AppKit
import SwiftUI

/// DESIGN.md "Native snap": the one motion system. Only real state changes move. Nothing moves while idle,
/// nothing scales or bounces, numbers and page content change at once, and a press is instant.
/// Reduce Motion makes every change instant; the panel open becomes a fade only.
public enum OnePlusMotion {
    /// Ease-out `cubic-bezier(0.25, 1, 0.5, 1)` for every move, fade, and crossfade.
    public static let easeOut = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.25, y: 1), endControlPoint: UnitPoint(x: 0.5, y: 1))
    /// Ease-in `cubic-bezier(0.4, 0, 1, 1)` for the panel close.
    public static let easeIn = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.4, y: 0), endControlPoint: UnitPoint(x: 1, y: 1))

    /// Menu-bar panel: fades in and moves 4 pt down into place; Reduce Motion fades only, in 100 ms.
    public static let panelOpen: TimeInterval = 0.14
    public static let panelOpenReduced: TimeInterval = 0.10
    public static let panelOffset: CGFloat = 4
    /// Menu-bar panel: fades out with no move.
    public static let panelClose: TimeInterval = 0.10
    /// Row and button hover fill: in 60 ms, out 150 ms.
    public static let hoverIn: TimeInterval = 0.06
    public static let hoverOut: TimeInterval = 0.15
    /// Sidebar selection: the old and new fills crossfade, no slide.
    public static let selection: TimeInterval = 0.12
    /// Pane toolbar tab underline slides to the new tab. The menu panel tab key changes at once.
    public static let tabSlide: TimeInterval = 0.18
    /// Segmented control thumb.
    public static let segment: TimeInterval = 0.16
    /// Switch knob slide and track color crossfade.
    public static let knob: TimeInterval = 0.14
    /// Slider knob on a programmatic change (reset). A dragged knob follows the pointer with no animation.
    public static let slider: TimeInterval = 0.16
    /// Instrument chart ticker: the line scrolls left one step per 1 s sample interval at one constant speed.
    public static let chartTick: TimeInterval = 1

    // Combined menu panel ("Live instrument"). Native snap still applies everywhere else.
    /// First Home open after launch: numbers count up from 0 and usage bars grow, ease-out.
    public static let panelReveal: TimeInterval = 0.6
    /// First Home open after launch: each chart line draws in left to right, ease-out, the next chart 30 ms later.
    public static let chartDrawIn: TimeInterval = 0.45
    public static let chartDrawInStagger: TimeInterval = 0.03
    /// A chart's top value (scale) eases to its new ceiling.
    public static let chartScale: TimeInterval = 0.4
    /// Reduce Motion: a changed number crossfades instead of rolling.
    public static let numberCrossfade: TimeInterval = 0.15
    /// Metric tile hover: only the color wash fades to 1.8 times stronger (ease-out); the tile never moves.
    public static let tileHoverIn: TimeInterval = 0.18
    public static let tileHoverOut: TimeInterval = 0.24
    public static let tileWashBoost: Double = 1.8
    /// Panel row hover fill.
    public static let panelRowHoverIn: TimeInterval = 0.09
    public static let panelRowHoverOut: TimeInterval = 0.2
    /// Panel action key: a 120 ms fill, shadow, and rim fade on hover. Nothing moves.
    public static let keyHover: TimeInterval = 0.12

    // Main window "Soft spring". Native snap still applies everywhere else.
    /// Tool row hover fill: in 120 ms, out 220 ms.
    public static let springRowHover: (TimeInterval, TimeInterval) = (0.12, 0.22)
    /// Page switch: the old page fades out moving 6 pt up, the new one fades in from 6 pt below, 200 ms ease-out.
    public static let springPage: TimeInterval = 0.2
    public static let springPageOffset: CGFloat = 6
    /// Switch knob: a soft spring with a small overshoot.
    public static let springSwitch = Animation.spring(response: 0.3, dampingFraction: 0.72)
    /// The panel row mark (`onePlusLinearRowMark`): in 0.3 s after the panel opens, over 0.2 s, held 1.2 s,
    /// out over 0.5 s.
    public static let rowMarkDelay = 0.3
    public static let rowMarkIn = 0.2
    public static let rowMarkHold = 1.2
    public static let rowMarkOut = 0.5

    public static func animation(_ duration: TimeInterval) -> Animation { .timingCurve(easeOut, duration: duration) }

    /// The animation for one change, or nil when the surface is instant or Reduce Motion is on.
    public static func resolved(_ duration: TimeInterval, style: OnePlusLinearMotionStyle, reduceMotion: Bool) -> Animation? {
        style != .instant && !reduceMotion ? animation(duration) : nil
    }

    /// Runs a hover state change: the fill fades in (`entering`) or out with the hover timing.
    public static func withHover(_ entering: Bool, in timing: (TimeInterval, TimeInterval) = (hoverIn, hoverOut),
                                 _ change: () -> Void) {
        let animation = reducesMotion ? nil : animation(entering ? timing.0 : timing.1)
        withTransaction(Transaction(animation: animation), change)
    }

    public static var reducesMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    public static var easeOutTiming: CAMediaTimingFunction { CAMediaTimingFunction(controlPoints: 0.25, 1, 0.5, 1) }
    public static var easeInTiming: CAMediaTimingFunction { CAMediaTimingFunction(controlPoints: 0.4, 0, 1, 1) }
}

public extension View {
    /// Tracks pointer hover into `hover`; the fill that depends on it fades with the Native snap hover timing.
    func onePlusHover(_ hover: Binding<Bool>,
                      timing: (TimeInterval, TimeInterval) = (OnePlusMotion.hoverIn, OnePlusMotion.hoverOut)) -> some View {
        onHover { inside in OnePlusMotion.withHover(inside, in: timing) { hover.wrappedValue = inside } }
    }
}

/// How fast a live number changes on the combined panel. Busy, fast-moving values change often with a quick roll;
/// slow values change rarely with a calm roll, so the whole panel never flickers at once. `interval` is the
/// shortest time between two shown changes; `offset` delays each change after its sample, so tiles that share a
/// sample change in different frames. Sampling and charts are not slowed down; only the shown text is.
public struct OnePlusNumberPace: Sendable, Equatable {
    public let response: Double
    public let damping: Double
    public let interval: TimeInterval
    public let offset: TimeInterval
    public init(response: Double, damping: Double = 0.9, interval: TimeInterval, offset: TimeInterval) {
        self.response = response; self.damping = damping; self.interval = interval; self.offset = offset
    }

    public static let network = OnePlusNumberPace(response: 0.25, interval: 0, offset: 0)
    public static let cpu = OnePlusNumberPace(response: 0.45, interval: 2, offset: 0.15)
    public static let gpu = OnePlusNumberPace(response: 0.45, interval: 2, offset: 0.3)
    public static let memory = OnePlusNumberPace(response: 0.6, interval: 4, offset: 0.45)
    public static let disk = OnePlusNumberPace(response: 0.6, interval: 5, offset: 0.6)
    public static let battery = OnePlusNumberPace(response: 0.6, interval: 5, offset: 0.75)
    /// Process rows already refresh every 2 s; they only roll calmly.
    public static let process = OnePlusNumberPace(response: 0.5, interval: 0, offset: 0)
}
