import SwiftUI

// Controls whose thumb or knob slides on a state change (Native snap, `OnePlusMotion`).

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
                .buttonStyle(OnePlusQuietSwitchStyle(isOn: isOn, look: look))
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
                    .linearMotion(OnePlusMotion.knob, value: isOn)
                    .frame(width: OnePlusLinearMetrics.switchSize.width, height: OnePlusLinearMetrics.switchSize.height)
            }
            .buttonStyle(OnePlusLinearButtonStyle(radius: OnePlusLinearMetrics.switchSize.height / 2))
        }
    }
}

/// Quiet Raised switch: a sunken track (the accent when on) and a solid knob that darkens while pressed.
private struct OnePlusQuietSwitchStyle: ButtonStyle {
    let isOn: Bool
    let look: OnePlusLinearControlLook
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            if isOn {
                Capsule().fill(OnePlusLinearColor.accent).overlay { OnePlusQuietFocusRing(shape: Capsule()) }
            } else {
                OnePlusQuietWell(shape: Capsule())
            }
            OnePlusQuietCap(shape: Circle(), fill: isOn ? OnePlusLinearColor.quietKnobOn : OnePlusLinearColor.quietKnob,
                            pressed: configuration.isPressed)
                .frame(width: look.switchKnob, height: look.switchKnob)
                .padding((look.switchSize.height - look.switchKnob) / 2)
        }
        .linearMotion(OnePlusMotion.knob, value: isOn)
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
        // Panel: 22 pt track, 40 x 18 segments, 11 pt labels. Applet look: a sunken 22 pt track, 36 x 18 segments,
        // 13 pt labels, a solid thumb, and faded dividers between unselected segments.
        let radius = look?.segmentRadius ?? 4
        HStack(spacing: look == nil ? 2 : 0) {
            ForEach(choices, id: \.0) { value, title in
                let on = value == selection
                let previous = choices.firstIndex { $0.0 == value }.flatMap { $0 > 0 ? choices[$0 - 1].0 : nil }
                let divided = look != nil && !on && previous != nil && previous != selection
                Button { if isChoiceEnabled(value) { selection = value } } label: {
                    Text(title).linearText(look == nil ? OnePlusLinearMetrics.caption : OnePlusLinearMetrics.body,
                                           weight: on ? .medium : .regular,
                                           color: on ? OnePlusLinearColor.ink : look == nil ? OnePlusLinearColor.secondary : OnePlusLinearColor.appletSecondary)
                        .offset(y: look == nil ? 0 : Self.opticalOffset(title))
                        .fixedSize(horizontal: sizing == .fitted, vertical: false)
                        .padding(.horizontal, sizing == .fitted ? 10 : 0)
                        .frame(width: sizing == .fitted ? nil : look?.segmentWidth ?? OnePlusLinearMetrics.segment.width,
                               height: look?.segmentHeight ?? OnePlusLinearMetrics.segment.height)
                        .background {
                            // One thumb moves between segments, so Quiet motion slides it.
                            if on { thumbShape(radius: radius).matchedGeometryEffect(id: "thumb", in: thumb) }
                        }
                        .overlay(alignment: .leading) { if divided { OnePlusQuietDivider() } }
                }
                .modifier(OnePlusLinearSegmentButton(quiet: look != nil, radius: radius))
                .disabled(!isChoiceEnabled(value))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .linearMotion(OnePlusMotion.segment, value: selection)
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

    /// A label with no capitals or digits has no cap height, so its x-height sits 1.25 pt below the line box
    /// center at 13 pt; this lifts it onto the true center. Labels with capitals or digits are already centered.
    public static func opticalOffset(_ title: String) -> CGFloat {
        title.contains { $0.isUppercase || $0.isNumber } ? 0 : -1.25
    }

    @ViewBuilder private func thumbShape(radius: CGFloat) -> some View {
        if look != nil {
            OnePlusQuietCap.thumb(RoundedRectangle(cornerRadius: radius))
        } else {
            RoundedRectangle(cornerRadius: radius).fill(OnePlusLinearColor.segmentSelected)
                .shadow(color: OnePlusLinearColor.segmentShadow, radius: 1, y: 1)
                .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(OnePlusLinearColor.segmentRing, lineWidth: 0.5) }
        }
    }
}

/// Panel segments use the shared button feedback; Quiet Raised segments only darken while pressed.
private struct OnePlusLinearSegmentButton: ViewModifier {
    let quiet: Bool
    let radius: CGFloat
    func body(content: Content) -> some View {
        if quiet { content.buttonStyle(OnePlusQuietPressStyle(radius: radius)) } else { content.buttonStyle(OnePlusLinearButtonStyle(radius: radius)) }
    }
}

private struct OnePlusQuietPressStyle: ButtonStyle {
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
                .background { OnePlusQuietWell(shape: RoundedRectangle(cornerRadius: look.radius)) }
        } else {
            content.linearTrack(radius: OnePlusLinearMetrics.radius)
        }
    }
}
