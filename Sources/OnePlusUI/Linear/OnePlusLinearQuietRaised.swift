import SwiftUI

/// The one style point for the v15 applet controls (switch, slider, segmented control, stepper field, color well,
/// search, select, and text field). `.quietRaised` is the shipped look: quiet sunken tracks, one solid
/// knob with one soft shadow, and coral only for an "on" state. Reference: the showcase `ControlStyleOptions.swift`.
/// The applet, the editorial body, and the pane toolbar set it. When no look is set (menu panel), the switch and
/// segmented control keep their panel look.
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
    /// "Raised keys": fields, tracks, and selects are sunken key wells, segment thumbs and
    /// buttons are raised keys, all 28 pt. Switches and sliders keep the quiet look.
    public var keys = false
    /// The text inset of a field and a select, which the select's chevron mirrors on the right. Nil keeps the
    /// quiet field's 8 pt and the quiet select's 11 pt.
    public var fieldInset: CGFloat?

    public static let quietRaised = OnePlusLinearControlLook(
        field: OnePlusLinearColor.quietField, fieldLine: OnePlusLinearColor.quietFieldLine,
        height: 22, radius: 6, segmentWidth: 36, segmentInset: 2, segmentRadius: 4,
        knob: 14, sliderTrack: 4, sliderWidth: 140, sliderValueWidth: 36,
        switchSize: CGSize(width: 32, height: 18), switchKnob: 14, switchFrame: CGSize(width: 40, height: 24),
        stepperButton: 22, stepperValueWidth: 59, well: CGSize(width: 40, height: 22), wellInset: 3)

    /// An applet row where a field sits beside a soft or ghost button: the field matches the 24 pt button.
    public static let quietRaisedActionRow: OnePlusLinearControlLook = {
        var look = quietRaised
        look.height = OnePlusLinearMetrics.appletButton
        return look
    }()

    /// The main window and tool pages: every control in a row is 28 pt.
    public static let raisedKeys: OnePlusLinearControlLook = {
        var look = quietRaised
        look.height = 28; look.radius = 7; look.segmentWidth = 40; look.segmentRadius = 5
        look.stepperButton = 24; look.well = CGSize(width: 44, height: 28); look.wellInset = 4; look.keys = true; look.fieldInset = 9
        return look
    }()

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
        return background { if look.keys { OnePlusKeyWell(shape: shape) } else { shape.fill(look.field) } }
            .overlay { shape.strokeBorder(look.keys ? .clear : look.fieldLine, lineWidth: 1) }
            .overlay { OnePlusQuietFocusFill(shape: shape, focused: focused) }
    }
}

/// A sunken track or field: the fill with a soft 1 pt inner top shade and a 1 physical pixel inner line. The focus
/// line shows only under the shared keyboard focus policy (or a sampled `.focus` state).
struct OnePlusQuietWell<S: InsettableShape>: View {
    let shape: S
    var fill: Color = OnePlusLinearColor.quietTrack
    var line: Color = OnePlusLinearColor.quietTrackLine
    var focused = false
    /// A field or segment track, which becomes a sunken key well under `.raisedKeys`. Switch and slider tracks stay quiet.
    var keyable = false
    @Environment(\.displayScale) private var scale
    @Environment(\.onePlusLinearControlLook) private var look
    var body: some View {
        Group {
            if keyable, look?.keys == true {
                OnePlusKeyWell(shape: shape)
            } else {
                shape.fill(fill.shadow(.inner(color: OnePlusLinearColor.quietTrackShade, radius: 1, y: 0.5)))
                    .overlay { shape.strokeBorder(line, lineWidth: 1 / max(scale, 1)) }
            }
        }
        .overlay { OnePlusQuietFocusFill(shape: shape, focused: focused) }
    }
}

/// The sunken key well of the panel soft-key tab track: a dark-to-light fill, a shaded top, and a gradient edge.
struct OnePlusKeyWell<S: InsettableShape>: View {
    let shape: S
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        let shade = colorScheme == .dark ? OnePlusLinearColor.softKeyTrackShadeGeometry.dark : OnePlusLinearColor.softKeyTrackShadeGeometry.light
        shape.fill(LinearGradient(colors: [OnePlusLinearColor.softKeyTrackTop, OnePlusLinearColor.softKeyTrackBottom], startPoint: .top, endPoint: .bottom)
            .shadow(.inner(color: OnePlusLinearColor.softKeyTrackShade, radius: shade.radius / 2, y: shade.y / 2)))
            .overlay { shape.strokeBorder(LinearGradient(colors: [OnePlusLinearColor.softKeyTrackEdgeTop, OnePlusLinearColor.softKeyTrackEdgeBottom],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: 1) }
    }
}

/// A badge well: a lighter, shallower key well (`badgeWell*` tokens) with the track's lit bottom lip.
public struct OnePlusBadgeWell<S: InsettableShape>: View {
    let shape: S
    public init(shape: S) { self.shape = shape }
    public var body: some View {
        shape.fill(LinearGradient(colors: [OnePlusLinearColor.badgeWellTop, OnePlusLinearColor.badgeWellBottom], startPoint: .top, endPoint: .bottom)
            .shadow(.inner(color: OnePlusLinearColor.badgeWellShade, radius: 1, y: 0.75)))
            .overlay { shape.strokeBorder(LinearGradient(colors: [OnePlusLinearColor.softKeyTrackEdgeTop, OnePlusLinearColor.softKeyTrackEdgeBottom],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: 1) }
    }
}

/// A badge: short tabular text in a sunken badge well, such as a Portman port number in its port color.
public struct OnePlusLinearBadge: View {
    private let text: String
    private let color: Color
    public init(_ text: String, color: Color) { self.text = text; self.color = color }
    public var body: some View {
        Text(text).linearText(OnePlusLinearMetrics.caption, weight: .semibold, color: color).monospacedDigit().lineLimit(1)
            .padding(.horizontal, OnePlusLinearMetrics.badgePadding).frame(height: OnePlusLinearMetrics.badge)
            .background { OnePlusBadgeWell(shape: RoundedRectangle(cornerRadius: OnePlusLinearMetrics.badgeRadius)) }
    }
}

/// A host icon: a glyph in an outlined 16 pt box with a status dot on its corner (green online, gray otherwise)
/// ringed in the group fill. `online == nil` hides the dot.
public struct OnePlusLinearHostIcon: View {
    private let systemImage: String
    private let online: Bool?
    public init(systemImage: String = "network", online: Bool?) { self.systemImage = systemImage; self.online = online }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusLinearMetrics.hostIconRadius)
        let dot = OnePlusLinearMetrics.hostIconDot, ring = OnePlusLinearMetrics.hostIconDotRing
        Image(systemName: systemImage).font(.system(size: OnePlusLinearMetrics.hostIconGlyph))
            .foregroundStyle(OnePlusLinearColor.secondary)
            .frame(width: OnePlusLinearMetrics.hostIcon, height: OnePlusLinearMetrics.hostIcon)
            .overlay { shape.strokeBorder(OnePlusLinearColor.iconOutline, lineWidth: 1) }
            .overlay(alignment: .bottomTrailing) {
                if let online {
                    Circle().fill(online ? OnePlusLinearColor.success : OnePlusLinearColor.tertiary)
                        .frame(width: dot, height: dot)
                        .padding(ring).background(OnePlusLinearColor.fillGroup, in: Circle())
                        .offset(x: OnePlusLinearMetrics.hostIconDotOutset + ring, y: OnePlusLinearMetrics.hostIconDotOutset + ring)
                }
            }
            .accessibilityHidden(true)
    }
}

/// A raised key: the panel soft-key gradient (or the ink key), a lit top edge, and a short drop. `lift` raises it.
/// `button` draws a text button: in Dark it has no lit edge and no drop, like the menu panel's row keys.
public struct OnePlusRaisedKey<S: InsettableShape>: View {
    let shape: S
    var ink = false
    var lift: CGFloat = 0
    var button = false
    public init(shape: S, ink: Bool = false, lift: CGFloat = 0, button: Bool = false) {
        self.shape = shape; self.ink = ink; self.lift = lift; self.button = button
    }
    private var edgeTop: Color {
        ink ? OnePlusLinearColor.openKeyEdgeTop : button ? OnePlusLinearColor.buttonKeyEdgeTop : OnePlusLinearColor.softKeyEdgeTop
    }
    private var drop: Color {
        ink ? OnePlusLinearColor.openKeyShadow : button ? OnePlusLinearColor.buttonKeyShadow : OnePlusLinearColor.softKeyShadow
    }
    public var body: some View {
        shape.fill(LinearGradient(colors: ink ? [OnePlusLinearColor.openKeyTop, OnePlusLinearColor.openKeyBottom]
                                              : [OnePlusLinearColor.softKeyTop, OnePlusLinearColor.softKeyBottom], startPoint: .top, endPoint: .bottom))
            .overlay { shape.strokeBorder(LinearGradient(colors: [edgeTop, ink ? OnePlusLinearColor.openKeyEdgeBottom : OnePlusLinearColor.softKeyEdgeBottom],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: 1) }
            .shadow(color: drop, radius: 1.5 + lift, y: 1 + lift)
    }
}

/// The subtle keyboard focus fill over a control (never a ring), under the shared focus policy or a sampled `.focus` state.
struct OnePlusQuietFocusFill<S: InsettableShape>: View {
    let shape: S
    var focused = false
    @Environment(\.onePlusControlState) private var sample
    var body: some View {
        if sample == .focus || (focused && OnePlusFocusPolicy.shared.showsFocus) {
            shape.fill(OnePlusLinearColor.hover).allowsHitTesting(false)
        }
    }
}

extension OnePlusQuietWell {
    /// A text field or color well: the stepper's flat `fillTrack` well, so every field on a page has one fill.
    static func field(_ shape: S, focused: Bool = false) -> some View {
        shape.fill(OnePlusLinearColor.fillTrack).overlay { OnePlusQuietFocusFill(shape: shape, focused: focused) }
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
    /// A segment thumb, which becomes a raised key under `.raisedKeys`.
    var keyable = false
    @Environment(\.displayScale) private var scale
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.onePlusLinearControlLook) private var look
    var body: some View {
        if keyable, look?.keys == true {
            OnePlusRaisedKey(shape: shape)
                .overlay { shape.fill(pressed || sample == .pressed ? OnePlusLinearColor.openKeyPressed : .clear) }
        } else {
            shape.fill(pressed || sample == .pressed ? pressedFill : fill)
                .overlay { shape.strokeBorder(line, lineWidth: 1 / max(scale, 1)) }
                .shadow(color: OnePlusLinearColor.quietKnobShadow, radius: 1, y: 0.5)
        }
    }
}

/// The segment thumb: the cap in the thumb fill.
extension OnePlusQuietCap {
    static func thumb(_ shape: S) -> OnePlusQuietCap {
        OnePlusQuietCap(shape: shape, fill: OnePlusLinearColor.quietThumb, line: OnePlusLinearColor.quietThumbLine,
                        pressedFill: OnePlusLinearColor.quietThumbPressed, keyable: true)
    }
}

