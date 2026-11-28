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
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        if let look {
            Button { isOn.toggle() } label: { EmptyView() }
                .buttonStyle(OnePlusQuietSwitchStyle(isOn: isOn, look: look))
                .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        } else if panelStyle == .fillSteps {
            // Fill steps: 32 x 18, 14 pt white knob on the accent when on, a fill-step track when off.
            Button { isOn.toggle() } label: {
                Capsule().fill(isOn ? OnePlusLinearColor.accent : OnePlusLinearColor.fillTrack)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle().fill(isOn ? Color.white : OnePlusLinearColor.fillThumb)
                            .frame(width: 14, height: 14).padding(.horizontal, 2)
                    }
                    .linearMotion(OnePlusMotion.knob, value: isOn)
                    .frame(width: 32, height: 18)
            }
            .buttonStyle(OnePlusLinearButtonStyle(radius: 9))
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
                Capsule().fill(OnePlusLinearColor.accent).overlay { OnePlusQuietFocusFill(shape: Capsule()) }
            } else {
                OnePlusQuietWell(shape: Capsule())
            }
            OnePlusQuietCap(shape: Circle(), fill: isOn ? OnePlusLinearColor.quietKnobOn : OnePlusLinearColor.quietKnob,
                            pressed: configuration.isPressed)
                .frame(width: look.switchKnob, height: look.switchKnob)
                .padding((look.switchSize.height - look.switchKnob) / 2)
        }
        .linearMotion(OnePlusMotion.knob, value: isOn, spring: OnePlusMotion.springSwitch)
        .frame(width: look.switchSize.width, height: look.switchSize.height)
        .frame(width: look.switchFrame.width, height: look.switchFrame.height, alignment: .trailing)
        .contentShape(Rectangle())
    }
}

/// How segments take their width: `.equal` uses the fixed segment width; `.fitted` sizes each segment to its
/// label plus 10 pt on each side ("Fast / Accurate / Custom"); `.snug` sizes each segment to its label plus 8 pt
/// on each side, the room "Auto" has in a fixed segment, so a longer label gets the same air (the panel Fan row).
public enum OnePlusLinearSegmentSizing: Sendable { case equal, fitted, snug }

/// The segmented control, drawn like the menu panel's everywhere (see `OnePlusLinearWell`).
/// A choice for which `isChoiceEnabled` returns false is dimmed and takes no click, hover, or arrow-key selection.
public struct OnePlusLinearSegmented<Value: Hashable>: View {
    private let choices: [(Value, String)]
    @Binding private var selection: Value
    private let label: String
    private let sizing: OnePlusLinearSegmentSizing
    private let width: CGFloat?
    private let isChoiceEnabled: (Value) -> Bool
    @State private var hovered: Value?
    /// Counts clicks and arrow keys; only a change of this slides the key.
    @State private var picks = 0
    @FocusState private var focusedSegment: Value?
    @Environment(\.onePlusLinearControlLook) private var look
    /// `width` is a minimum for the whole control: segments share the extra room, so controls in one column line up.
    public init(choices: [(Value, String)], selection: Binding<Value>, accessibilityLabel: String,
                sizing: OnePlusLinearSegmentSizing = .equal, width: CGFloat? = nil,
                isChoiceEnabled: @escaping (Value) -> Bool = { _ in true }) {
        self.choices = choices; _selection = selection; label = accessibilityLabel; self.sizing = sizing
        self.width = width; self.isChoiceEnabled = isChoiceEnabled
    }
    public var body: some View {
        // Every look draws the menu panel's segmented control: segments touching on a `fillTrack` well, one raised
        // `OnePlusSegmentKey`, short dividers between unlit segments. Only the size follows the look: 24 pt with 11.5 pt labels in a panel, the look's
        // height with 13 pt labels on a page.
        let well = OnePlusLinearWell(look)
        let values = choices.map(\.0)
        let selectedIndex = values.firstIndex(of: selection)
        let hoveredIndex = hovered.flatMap { values.firstIndex(of: $0) }
        HStack(spacing: 0) {
            ForEach(choices, id: \.0) { value, title in
                let index = values.firstIndex(of: value) ?? 0
                let on = value == selection
                Button { pick(value) } label: {
                    Text(title).linearSteadyText(look == nil ? OnePlusLinearMetrics.caption + 0.5 : OnePlusLinearMetrics.body,
                                           selected: on,
                                           color: on ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                        .offset(y: look == nil ? 0 : Self.opticalOffset(title))
                        .fixedSize(horizontal: sizing != .equal, vertical: false)
                        .padding(.horizontal, sizing == .fitted ? 10 : sizing == .snug ? Self.snugPadding : 0)
                        .frame(width: sizing == .equal && width == nil ? look?.segmentWidth ?? OnePlusLinearMetrics.segment.width : nil,
                               height: well.innerHeight)
                        .frame(maxWidth: width == nil ? nil : .infinity)
                        .contentShape(Rectangle())
                }
                .segmentKeyAnchor(on)
                .buttonStyle(OnePlusLinearButtonStyle(.segment, radius: well.innerRadius, selected: on))
                .linearSegmentDivider(OnePlusSegmentKey.showsDivider(before: index, selected: selectedIndex, hovered: hoveredIndex),
                                      height: OnePlusSegmentKey.dividerHeight(inner: well.innerHeight))
                .onHover { inside in
                    OnePlusMotion.withHover(inside) { if inside { hovered = value } else if hovered == value { hovered = nil } }
                }
                .focused($focusedSegment, equals: value).focusEffectDisabled()
                .disabled(!isChoiceEnabled(value))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .frame(minWidth: width.map { $0 - 2 * OnePlusLinearWell.inset }, idealWidth: width.map { $0 - 2 * OnePlusLinearWell.inset })
        .fixedSize(horizontal: width != nil, vertical: false)
        .segmentKey(OnePlusSegmentKey(radius: well.innerRadius))
        // Only a click or arrow key slides the key; a value set from code (launch, load, sync) lands at once.
        .linearMotion(OnePlusMotion.segment, value: picks)
        .padding(OnePlusLinearWell.inset)
        .background(OnePlusLinearColor.fillTrack, in: RoundedRectangle(cornerRadius: well.radius))
        .accessibilityElement(children: .contain).accessibilityLabel(label)
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            if let next = OnePlusSegmented<Value>.nextSelection(in: choices.map(\.0), current: selection,
                                                              direction: press.key == .leftArrow ? -1 : 1,
                                                              isChoiceEnabled: isChoiceEnabled) { pick(next) }
            return .handled
        }
    }

    private func pick(_ value: Value) {
        guard isChoiceEnabled(value), value != selection else { return }
        picks &+= 1
        selection = value
    }

    /// `.snug` side padding: about what an 11 pt "Auto" gets in a 40 pt segment, so every label has the same room.
    static var snugPadding: CGFloat { 8 }

    /// A label with no capitals or digits has no cap height, so its x-height sits 1.25 pt below the line box
    /// center at 13 pt; this lifts it onto the true center. Labels with capitals or digits are already centered.
    public static func opticalOffset(_ title: String) -> CGFloat {
        title.contains { $0.isUppercase || $0.isNumber } ? 0 : -1.25
    }
}

/// The menu panel's control well, shared by the segmented control and the stepper: a `fillTrack` well with a
/// 2 pt inset around `fillThumb` parts. 24 pt, radius 7 in a panel; the look's height and radius on a page.
struct OnePlusLinearWell {
    static let inset: CGFloat = 2
    static let panelHeight: CGFloat = 24
    static let panelRadius: CGFloat = 7
    let height: CGFloat
    let radius: CGFloat
    init(_ look: OnePlusLinearControlLook?) {
        height = look?.height ?? Self.panelHeight
        radius = look?.radius ?? Self.panelRadius
    }
    var innerHeight: CGFloat { height - 2 * Self.inset }
    var innerRadius: CGFloat { OnePlusSegmentKey.radius(track: radius, inset: Self.inset) }
}

/// The stepper, drawn like the menu panel's segmented control: the value sits on the `fillTrack` well and a
/// 16 pt `fillThumb` key on the right holds a chevron up over a chevron down. Up and down arrows step while the
/// key has keyboard focus; a text field in `content` handles its own arrows. It hugs `content`; give `content` a
/// flexible frame to fill a column.
public struct OnePlusLinearStepper<Content: View>: View {
    private let title: String
    private let canDecrement: Bool
    private let canIncrement: Bool
    private let decrement: () -> Void
    private let increment: () -> Void
    private let content: Content
    @Environment(\.onePlusLinearControlLook) private var look
    @Environment(\.isEnabled) private var enabled
    static var keyWidth: CGFloat { 16 }

    public init(_ title: String, canDecrement: Bool = true, canIncrement: Bool = true,
                decrement: @escaping () -> Void, increment: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title; self.canDecrement = canDecrement; self.canIncrement = canIncrement
        self.decrement = decrement; self.increment = increment; self.content = content()
    }

    public var body: some View {
        let well = OnePlusLinearWell(look)
        HStack(spacing: 0) {
            content.padding(.horizontal, 8)
            VStack(spacing: 0) {
                arrow("chevron.up", "Increase \(title)", half: .top, enabled: canIncrement, action: increment)
                arrow("chevron.down", "Decrease \(title)", half: .bottom, enabled: canDecrement, action: decrement)
            }
            .frame(width: Self.keyWidth, height: well.innerHeight)
            .background(OnePlusLinearColor.fillThumb, in: RoundedRectangle(cornerRadius: well.innerRadius))
            .clipShape(RoundedRectangle(cornerRadius: well.innerRadius))
            .onKeyPress(keys: [.upArrow, .downArrow]) { press in
                guard press.modifiers.isEmpty else { return .ignored }
                if press.key == .upArrow { if canIncrement { increment() } } else if canDecrement { decrement() }
                return .handled
            }
        }
        .padding(OnePlusLinearWell.inset)
        .frame(height: well.height)
        .background { OnePlusFieldWell(shape: RoundedRectangle(cornerRadius: well.radius)) }
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
    }

    private func arrow(_ symbol: String, _ label: String, half: OnePlusStepperHalf, enabled: Bool,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(OnePlusStepperArrowStyle(half: half))
            .focusEffectDisabled()
            .disabled(!enabled)
            .accessibilityLabel(label)
    }
}

enum OnePlusStepperHalf { case top, bottom }

/// One half of the stepper key: a 7 pt bold chevron in `secondary`; hover shades the half one `pressed` step
/// with `ink` glyph, press two steps. A sampled hover or press shows on the top half only.
private struct OnePlusStepperArrowStyle: ButtonStyle {
    let half: OnePlusStepperHalf
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        let sampled = half == .top ? sample : .rest
        let pressed = enabled && (configuration.isPressed || sampled == .pressed)
        let lit = enabled && (hover || sampled == .hover || pressed)
        configuration.label
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(lit ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
            .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
            .offset(y: half == .top ? 0.5 : -0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    if lit { OnePlusLinearColor.pressed }
                    if pressed { OnePlusLinearColor.pressed }
                }
            }
            .contentShape(Rectangle())
            .onePlusHover($hover)
    }
}
