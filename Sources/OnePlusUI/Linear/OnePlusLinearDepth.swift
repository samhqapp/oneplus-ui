import SwiftUI

/// The one style point for the v15 applet controls (switch, segmented control, slider, stepper field, color well,
/// search, and select). `.depth` is the owner's pick (2026-11-16): recessed tracks, gently raised caps, and a fine
/// top-edge highlight, from `docs/design/v15/controls-depth.html`. The applet sets it; another family replaces
/// this value. When no look is set (main window, menu panel), the switch and segmented control keep their panel look.
public struct OnePlusLinearControlLook: Sendable, Equatable {
    /// Search and select fields stay flat: fill and 1 pt line.
    public var field: Color
    public var fieldLine: Color
    public var height: CGFloat
    public var radius: CGFloat
    public var segmentWidth: CGFloat
    public var segmentHeight: CGFloat
    public var segmentInset: CGFloat
    public var segmentRadius: CGFloat
    public var segmentTrackRadius: CGFloat
    public var knob: CGFloat
    public var sliderTrack: CGFloat
    public var sliderWidth: CGFloat
    public var sliderValueWidth: CGFloat
    public var switchSize: CGSize
    public var switchKnob: CGFloat
    /// The switch hit area; the track sits on its trailing edge.
    public var switchFrame: CGSize
    public var stepperCap: CGFloat
    /// Concentric with the field: `radius` = `stepperCapRadius` + the 2 pt inset.
    public var stepperCapRadius: CGFloat
    public var stepperValueWidth: CGFloat
    public var well: CGSize
    public var wellInset: CGFloat

    public static let depth = OnePlusLinearControlLook(
        field: OnePlusLinearColor.appletField, fieldLine: OnePlusLinearColor.appletFieldLine,
        height: 24, radius: 6, segmentWidth: 36, segmentHeight: 20, segmentInset: 2, segmentRadius: 5, segmentTrackRadius: 7,
        knob: 16, sliderTrack: 6, sliderWidth: 140, sliderValueWidth: 36,
        switchSize: CGSize(width: 30, height: 18), switchKnob: 14, switchFrame: CGSize(width: 40, height: 24),
        stepperCap: 20, stepperCapRadius: 4, stepperValueWidth: 38, well: CGSize(width: 44, height: 24), wellInset: 3)
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

/// A recessed surface: the fill with a soft inner top shade, a one-pixel inner ring, and a one-pixel lip of light
/// below. The focus line shows only under the shared keyboard focus policy (or a sampled `.focus` state).
struct OnePlusDepthRecess<S: InsettableShape, Fill: ShapeStyle>: View {
    let shape: S
    let fill: Fill
    var focused = false
    @Environment(\.displayScale) private var scale
    @Environment(\.onePlusControlState) private var sample
    var body: some View {
        let pixel = 1 / max(scale, 1)
        shape.fill(fill.shadow(.inner(color: OnePlusLinearColor.depthRecessShade, radius: 1, y: 1)))
            .overlay { shape.strokeBorder(OnePlusLinearColor.depthRecessRing, lineWidth: pixel) }
            .background { shape.fill(OnePlusLinearColor.depthRecessLip).padding(.top, pixel).padding(.bottom, -pixel) }
            .overlay {
                if sample == .focus || (focused && OnePlusFocusPolicy.shared.showsFocus) {
                    shape.inset(by: -2).strokeBorder(OnePlusColor.focus, lineWidth: 1)
                }
            }
    }
}

extension OnePlusDepthRecess where Fill == Color {
    init(_ shape: S, focused: Bool = false) { self.init(shape: shape, fill: OnePlusLinearColor.depthRecess, focused: focused) }
}

/// The rod gradient: the switch's on track (under the recess shade) and a slider's fill.
var onePlusDepthRodGradient: LinearGradient {
    LinearGradient(colors: [OnePlusLinearColor.depthRodTop, OnePlusLinearColor.depthRodBottom], startPoint: .top, endPoint: .bottom)
}

/// The slider fill: the rod with its own one-pixel top highlight.
struct OnePlusDepthRodFill: View {
    @Environment(\.displayScale) private var scale
    var body: some View {
        Rectangle().fill(onePlusDepthRodGradient.shadow(.inner(color: OnePlusLinearColor.depthRodHighlight, radius: 0, y: 1 / max(scale, 1))))
    }
}

/// A raised cap: gradient, a crisp one-pixel top highlight, a one-pixel outer ring, a crisp one-pixel contact
/// shadow, and a soft low glow. Hover deepens the ring and shadows; press darkens the gradient. Both also follow a
/// sampled `onePlusControlState`.
struct OnePlusDepthCap<S: InsettableShape>: View {
    let shape: S
    var pressed = false
    var hover = false
    @Environment(\.displayScale) private var scale
    @Environment(\.onePlusControlState) private var sample
    var body: some View {
        let pixel = 1 / max(scale, 1)
        let isPressed = pressed || sample == .pressed
        let isHover = hover || sample == .hover
        let top = isPressed ? OnePlusLinearColor.depthCapPressedTop : OnePlusLinearColor.depthCapTop
        let bottom = isPressed ? OnePlusLinearColor.depthCapPressedBottom : OnePlusLinearColor.depthCapBottom
        shape.fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            .shadow(.inner(color: isHover ? OnePlusLinearColor.depthCapHoverHighlight : OnePlusLinearColor.depthCapHighlight,
                           radius: 0, y: pixel)))
            .background {
                ZStack {
                    shape.fill(bottom).shadow(color: isHover ? OnePlusLinearColor.depthCapHoverGlow : OnePlusLinearColor.depthCapGlow,
                                              radius: isHover ? 2 : 1.5, y: 1)
                    shape.fill(bottom).shadow(color: isHover ? OnePlusLinearColor.depthCapHoverShadow : OnePlusLinearColor.depthCapShadow,
                                              radius: 0, y: pixel)
                    shape.inset(by: -pixel).fill(isHover ? OnePlusLinearColor.depthCapHoverRing : OnePlusLinearColor.depthCapRing)
                }
            }
    }
}

/// The minus or plus glyph of a stepper cap: 8 x 1.5 pt bars in ink.
struct OnePlusDepthStepGlyph: View {
    let plus: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1).frame(width: 8, height: 1.5)
            if plus { RoundedRectangle(cornerRadius: 1).frame(width: 1.5, height: 8) }
        }
        .foregroundStyle(OnePlusLinearColor.ink)
    }
}

/// A stepper cap button: a raised cap; hover deepens its shadow, press darkens its gradient.
struct OnePlusDepthCapButtonStyle: ButtonStyle {
    let size: CGFloat
    let radius: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        OnePlusDepthCapButton(label: configuration.label, pressed: configuration.isPressed, size: size, radius: radius)
    }
}

private struct OnePlusDepthCapButton<Label: View>: View {
    let label: Label
    let pressed: Bool
    let size: CGFloat
    let radius: CGFloat
    @State private var hover = false
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        label.frame(width: size, height: size)
            .background { OnePlusDepthCap(shape: RoundedRectangle(cornerRadius: radius), pressed: pressed, hover: hover && enabled) }
            .contentShape(Rectangle())
            .onHover { hover = $0 }
    }
}
