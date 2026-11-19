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
    /// Instrument chart ticker: a new sample slides the line left one step over the 1 s sample interval, linear.
    public static let chartTick: TimeInterval = 1

    public static func animation(_ duration: TimeInterval) -> Animation { .timingCurve(easeOut, duration: duration) }

    /// The animation for one change, or nil when the surface is instant or Reduce Motion is on.
    public static func resolved(_ duration: TimeInterval, style: OnePlusLinearMotionStyle, reduceMotion: Bool) -> Animation? {
        style == .quiet && !reduceMotion ? animation(duration) : nil
    }

    /// Runs a hover state change: the fill fades in (`entering`) or out with the hover timing.
    public static func withHover(_ entering: Bool, _ change: () -> Void) {
        let animation = reducesMotion ? nil : animation(entering ? hoverIn : hoverOut)
        withTransaction(Transaction(animation: animation), change)
    }

    public static var reducesMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    public static var easeOutTiming: CAMediaTimingFunction { CAMediaTimingFunction(controlPoints: 0.25, 1, 0.5, 1) }
    public static var easeInTiming: CAMediaTimingFunction { CAMediaTimingFunction(controlPoints: 0.4, 0, 1, 1) }
}

public extension View {
    /// Tracks pointer hover into `hover`; the fill that depends on it fades with the Native snap hover timing.
    func onePlusHover(_ hover: Binding<Bool>) -> some View {
        onHover { inside in OnePlusMotion.withHover(inside) { hover.wrappedValue = inside } }
    }
}
