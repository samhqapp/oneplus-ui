import SwiftUI

/// The one style point for the v15 applet controls (switch, slider, segmented control, stepper field, color well,
/// search, select, and text field). `.quietRaised` is the owner's pick (2026-11-16): quiet sunken tracks, one solid
/// knob with one soft shadow, and coral only for an "on" state. Reference: the showcase `ControlStyleOptions.swift`.
/// The applet sets it. When no look is set (main window, menu panel), the switch and segmented control keep their
/// panel look.
public struct OnePlusLinearControlLook: Sendable, Equatable {
    /// Fields (stepper, well, search, select, text field): fill and a 1 physical pixel line.
    public var field: Color
    public var fieldLine: Color
    public var height: CGFloat
    public var radius: CGFloat
    public var segmentWidth: CGFloat
    public var segmentInset: CGFloat
    /// Concentric with the track: `radius` - `segmentInset`.
    public var segmentRadius: CGFloat
    public var knob: CGFloat
    public var sliderTrack: CGFloat
    public var sliderWidth: CGFloat
    public var sliderValueWidth: CGFloat
    public var switchSize: CGSize
    public var switchKnob: CGFloat
    /// The switch hit area; the track sits on its trailing edge.
    public var switchFrame: CGSize
    /// The minus and plus columns of the stepper field.
    public var stepperButton: CGFloat
    public var stepperValueWidth: CGFloat
    public var well: CGSize
    public var wellInset: CGFloat

    public static let quietRaised = OnePlusLinearControlLook(
        field: OnePlusLinearColor.quietField, fieldLine: OnePlusLinearColor.quietFieldLine,
        height: 22, radius: 6, segmentWidth: 36, segmentInset: 2, segmentRadius: 4,
        knob: 14, sliderTrack: 4, sliderWidth: 140, sliderValueWidth: 36,
        switchSize: CGSize(width: 32, height: 18), switchKnob: 14, switchFrame: CGSize(width: 40, height: 24),
        stepperButton: 22, stepperValueWidth: 59, well: CGSize(width: 40, height: 22), wellInset: 3)

    /// The segment height inside the track.
    public var segmentHeight: CGFloat { height - 2 * segmentInset }
}

public extension EnvironmentValues {
    @Entry var onePlusLinearControlLook: OnePlusLinearControlLook? = nil
}

extension View {
    /// The bezel shared by applet search and select fields: fill, 1 pt line, control radius.
    func linearFieldBezel(_ look: OnePlusLinearControlLook, radius: CGFloat? = nil, focused: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius ?? look.radius)
        return background(look.field, in: shape)
            .overlay { shape.strokeBorder(focused && OnePlusFocusPolicy.shared.showsFocus ? OnePlusColor.focus : look.fieldLine, lineWidth: 1) }
    }
}

/// A sunken track or field: the fill with a soft 1 pt inner top shade and a 1 physical pixel inner line. The focus
/// line shows only under the shared keyboard focus policy (or a sampled `.focus` state).
struct OnePlusQuietWell<S: InsettableShape>: View {
    let shape: S
    var fill: Color = OnePlusLinearColor.quietTrack
    var line: Color = OnePlusLinearColor.quietTrackLine
    var focused = false
    @Environment(\.displayScale) private var scale
    var body: some View {
        shape.fill(fill.shadow(.inner(color: OnePlusLinearColor.quietTrackShade, radius: 1, y: 0.5)))
            .overlay { shape.strokeBorder(line, lineWidth: 1 / max(scale, 1)) }
            .overlay { OnePlusQuietFocusRing(shape: shape, focused: focused) }
    }
}

/// The 1 pt focus line 2 pt outside a control, under the shared keyboard focus policy or a sampled `.focus` state.
struct OnePlusQuietFocusRing<S: InsettableShape>: View {
    let shape: S
    var focused = false
    @Environment(\.onePlusControlState) private var sample
    var body: some View {
        if sample == .focus || (focused && OnePlusFocusPolicy.shared.showsFocus) {
            shape.inset(by: -2).strokeBorder(OnePlusColor.focus, lineWidth: 1)
        }
    }
}

extension OnePlusQuietWell {
    /// A field (stepper, well, text field) rather than a track.
    static func field(_ shape: S, focused: Bool = false) -> OnePlusQuietWell {
        OnePlusQuietWell(shape: shape, fill: OnePlusLinearColor.quietField, line: OnePlusLinearColor.quietFieldLine, focused: focused)
    }
}

/// A knob or segment thumb: one solid part with a 1 physical pixel line and one soft contact shadow. Press darkens
/// the fill one step; hover changes nothing. Both follow a sampled `onePlusControlState`.
struct OnePlusQuietCap<S: InsettableShape>: View {
    let shape: S
    var fill: Color = OnePlusLinearColor.quietKnob
    var line: Color = OnePlusLinearColor.quietKnobLine
    var pressedFill: Color = OnePlusLinearColor.quietKnobPressed
    var pressed = false
    @Environment(\.displayScale) private var scale
    @Environment(\.onePlusControlState) private var sample
    var body: some View {
        shape.fill(pressed || sample == .pressed ? pressedFill : fill)
            .overlay { shape.strokeBorder(line, lineWidth: 1 / max(scale, 1)) }
            .shadow(color: OnePlusLinearColor.quietKnobShadow, radius: 1, y: 0.5)
    }
}

/// The segment thumb: the cap in the thumb fill.
extension OnePlusQuietCap {
    static func thumb(_ shape: S) -> OnePlusQuietCap {
        OnePlusQuietCap(shape: shape, fill: OnePlusLinearColor.quietThumb, line: OnePlusLinearColor.quietThumbLine,
                        pressedFill: OnePlusLinearColor.quietThumbPressed)
    }
}

/// A short divider that fades out at both ends, as between unselected classic macOS segments.
struct OnePlusQuietDivider: View {
    @Environment(\.displayScale) private var scale
    var body: some View {
        LinearGradient(colors: [.clear, OnePlusLinearColor.quietDivider, .clear], startPoint: .top, endPoint: .bottom)
            .frame(width: 1 / max(scale, 1), height: 12)
    }
}

/// A stepper field's minus or plus column: a 9 pt semibold glyph in `appletSecondary`; press fills the column.
struct OnePlusQuietStepButtonStyle: ButtonStyle {
    let width: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9, weight: .semibold)).foregroundStyle(OnePlusLinearColor.appletSecondary)
            .frame(width: width).frame(maxHeight: .infinity)
            .background(configuration.isPressed ? OnePlusLinearColor.pressed : .clear)
            .contentShape(Rectangle())
    }
}
