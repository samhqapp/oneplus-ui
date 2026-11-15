import SwiftUI

// Controls whose thumb or knob moves on a state change (Quiet motion). Hover stays paint-only in
// `OnePlusLinearButtonStyle`; keep hover handlers out of this file so the hover-motion guard stays strict.

/// The v15 switch: 26 x 16 track, 12 pt knob. The label is used for accessibility only.
/// Inside an applet it takes the colors of `OnePlusLinearControlLook`; under Quiet motion the knob slides.
public struct OnePlusLinearSwitchStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        OnePlusLinearSwitch(isOn: configuration.$isOn)
            .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

private struct OnePlusLinearSwitch: View {
    @Binding var isOn: Bool
    @Environment(\.onePlusLinearControlLook) private var look
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        if let look {
            Button { isOn.toggle() } label: { EmptyView() }
                .buttonStyle(OnePlusDepthSwitchStyle(isOn: isOn, look: look))
                .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        } else {
            Button { isOn.toggle() } label: {
                Capsule().fill(isOn ? OnePlusLinearColor.switchOn : OnePlusLinearColor.switchOff)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle().fill(isOn ? OnePlusLinearColor.knobOn : OnePlusLinearColor.knobOff)
                            .shadow(color: .black.opacity(0.2), radius: 0.5, y: 1)
                            .frame(width: OnePlusLinearMetrics.knob, height: OnePlusLinearMetrics.knob)
                            .padding(.horizontal, 2)
                    }
                    .linearMotion(OnePlusLinearMotion.knob, value: isOn)
                    .frame(width: OnePlusLinearMetrics.switchSize.width, height: OnePlusLinearMetrics.switchSize.height)
            }
            .buttonStyle(OnePlusLinearButtonStyle(radius: OnePlusLinearMetrics.switchSize.height / 2))
        }
    }
}

/// Depth switch: a recessed track (the rod when on) and a raised knob that darkens while pressed.
private struct OnePlusDepthSwitchStyle: ButtonStyle {
    let isOn: Bool
    let look: OnePlusLinearControlLook
    func makeBody(configuration: Configuration) -> some View {
        OnePlusDepthRecess(shape: Capsule(), fill: isOn ? AnyShapeStyle(onePlusDepthRodGradient) : AnyShapeStyle(OnePlusLinearColor.depthRecess))
        .overlay(alignment: isOn ? .trailing : .leading) {
            OnePlusDepthCap(shape: Circle(), pressed: configuration.isPressed)
                .frame(width: look.switchKnob, height: look.switchKnob)
                .padding(.horizontal, (look.switchSize.height - look.switchKnob) / 2)
        }
        .linearMotion(OnePlusLinearMotion.knob, value: isOn)
        .frame(width: look.switchSize.width, height: look.switchSize.height)
        .frame(width: look.switchFrame.width, height: look.switchFrame.height, alignment: .trailing)
        .contentShape(Rectangle())
    }
}

/// How segments take their width: `.equal` uses the fixed segment width; `.fitted` sizes each segment to its
/// label plus 10 pt on each side ("Fast / Accurate / Custom").
public enum OnePlusLinearSegmentSizing: Sendable { case equal, fitted }

/// A compact segmented control: 22 pt track, 40 x 18 segments, 11 pt labels.
/// A choice for which `isChoiceEnabled` returns false is dimmed and takes no click, hover, or arrow-key selection.
public struct OnePlusLinearSegmented<Value: Hashable>: View {
    private let choices: [(Value, String)]
    @Binding private var selection: Value
    private let label: String
    private let sizing: OnePlusLinearSegmentSizing
    private let isChoiceEnabled: (Value) -> Bool
    @Namespace private var thumb
    @Environment(\.onePlusLinearControlLook) private var look
    @Environment(\.isEnabled) private var enabled
    public init(choices: [(Value, String)], selection: Binding<Value>, accessibilityLabel: String,
                sizing: OnePlusLinearSegmentSizing = .equal, isChoiceEnabled: @escaping (Value) -> Bool = { _ in true }) {
        self.choices = choices; _selection = selection; label = accessibilityLabel; self.sizing = sizing
        self.isChoiceEnabled = isChoiceEnabled
    }
    public var body: some View {
        // Panel: 22 pt track, 40 x 18 segments, 11 pt labels. Applet look: recessed 24 pt track, 36 x 20 segments,
        // 12 pt labels, a raised cap thumb.
        let radius = look?.segmentRadius ?? 4
        HStack(spacing: look == nil ? 2 : 0) {
            ForEach(choices, id: \.0) { value, title in
                let on = value == selection
                Button { if isChoiceEnabled(value) { selection = value } } label: {
                    Text(title).linearText(look == nil ? OnePlusLinearMetrics.caption : OnePlusLinearMetrics.body,
                                           weight: on ? .medium : .regular,
                                           color: on ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                        .fixedSize(horizontal: sizing == .fitted, vertical: false)
                        .padding(.horizontal, sizing == .fitted ? 10 : 0)
                        .frame(width: sizing == .fitted ? nil : look?.segmentWidth ?? OnePlusLinearMetrics.segment.width,
                               height: look?.segmentHeight ?? OnePlusLinearMetrics.segment.height)
                        .background {
                            // One thumb moves between segments, so Quiet motion slides it.
                            if on { thumbShape(radius: radius).matchedGeometryEffect(id: "thumb", in: thumb) }
                        }
                }
                .modifier(OnePlusLinearSegmentButton(depth: look != nil, radius: radius))
                .disabled(!isChoiceEnabled(value))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .linearMotion(OnePlusLinearMotion.knob, value: selection)
        .modifier(OnePlusLinearSegmentTrack(look: look))
        .opacity(look != nil && !enabled ? OnePlusMetrics.disabledOpacity : 1)
        .accessibilityElement(children: .contain).accessibilityLabel(label)
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            if let next = OnePlusSegmented<Value>.nextSelection(in: choices.map(\.0), current: selection,
                                                              direction: press.key == .leftArrow ? -1 : 1,
                                                              isChoiceEnabled: isChoiceEnabled) { selection = next }
            return .handled
        }
    }

    @ViewBuilder private func thumbShape(radius: CGFloat) -> some View {
        if look != nil {
            OnePlusDepthCap(shape: RoundedRectangle(cornerRadius: radius))
        } else {
            RoundedRectangle(cornerRadius: radius).fill(OnePlusLinearColor.segmentSelected)
                .shadow(color: OnePlusLinearColor.segmentShadow, radius: 1, y: 1)
                .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(OnePlusLinearColor.segmentRing, lineWidth: 0.5) }
        }
    }
}

/// Panel segments use the shared button feedback; Depth segments only darken while pressed.
private struct OnePlusLinearSegmentButton: ViewModifier {
    let depth: Bool
    let radius: CGFloat
    func body(content: Content) -> some View {
        if depth { content.buttonStyle(OnePlusDepthPressStyle(radius: radius)) } else { content.buttonStyle(OnePlusLinearButtonStyle(radius: radius)) }
    }
}

private struct OnePlusDepthPressStyle: ButtonStyle {
    let radius: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? OnePlusLinearColor.pressed : .clear, in: RoundedRectangle(cornerRadius: radius))
            .contentShape(Rectangle())
    }
}

private struct OnePlusLinearSegmentTrack: ViewModifier {
    let look: OnePlusLinearControlLook?
    func body(content: Content) -> some View {
        if let look {
            content.padding(look.segmentInset)
                .background { OnePlusDepthRecess(RoundedRectangle(cornerRadius: look.segmentTrackRadius)) }
        } else {
            content.linearTrack(radius: OnePlusLinearMetrics.radius)
        }
    }
}
