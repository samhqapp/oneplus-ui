import AppKit
import SwiftUI

public struct OnePlusSwitchStyle: ToggleStyle {
    @Environment(\.onePlusDensity) private var density
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        let capHeight = NSFont.systemFont(ofSize: OnePlusTextRole.row.size(for: density)).capHeight
        return LabeledContent {
            Button { configuration.isOn.toggle() } label: {
                Capsule().fill(configuration.isOn ? OnePlusColor.primaryFill : OnePlusColor.selection)
                    .overlay { Capsule().strokeBorder(OnePlusColor.line, lineWidth: 1) }
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(configuration.isOn ? OnePlusColor.primaryInk : OnePlusColor.secondary)
                            .frame(width: 11, height: 11).padding(.horizontal, 3)
                    }
                    .frame(width: 29, height: 17)
                    .frame(height: 24)
            }
            .buttonStyle(OnePlusInteractionStyle(radius: 10)).focusEffectDisabled()
            .accessibilityRepresentation {
                Toggle(isOn: configuration.$isOn) { configuration.label }
            }
        } label: {
            OnePlusControlContentLayout(pointSize: OnePlusTextRole.row.size(for: density), iconIndex: nil) {
                configuration.label.onePlusText(.row)
            }
        }
        .alignmentGuide(.firstTextBaseline) { dimensions in
            dimensions.height / 2 + capHeight / 2
        }
    }
}

public struct OnePlusSegmented<Value: Hashable>: View {
    private let choices: [(Value, String)]
    private let symbols: [Value: String]
    private let identifierPrefix: String?
    @Binding private var selection: Value
    private let label: String
    private let width: CGFloat?
    private let isChoiceEnabled: (Value) -> Bool
    @Environment(\.onePlusDensity) private var density
    @Environment(\.onePlusControlHeight) private var controlHeight
    @Environment(\.isEnabled) private var enabled
    @State private var hovered: Value?
    @State private var picks = 0

    public init(choices: [(Value, String)], selection: Binding<Value>, accessibilityLabel: String = "Selection",
                accessibilityIdentifierPrefix: String? = nil, width: CGFloat? = nil,
                isChoiceEnabled: @escaping (Value) -> Bool = { _ in true }) {
        self.choices = choices
        symbols = [:]
        identifierPrefix = accessibilityIdentifierPrefix
        _selection = selection
        label = accessibilityLabel
        self.width = width.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        self.isChoiceEnabled = isChoiceEnabled
    }

    public init(iconChoices: [(Value, String, String)], selection: Binding<Value>, accessibilityLabel: String,
                isChoiceEnabled: @escaping (Value) -> Bool = { _ in true }) {
        choices = iconChoices.map { ($0.0, $0.1) }
        symbols = Dictionary(uniqueKeysWithValues: iconChoices.map { ($0.0, $0.2) })
        identifierPrefix = nil
        _selection = selection
        label = accessibilityLabel
        width = nil
        self.isChoiceEnabled = isChoiceEnabled
    }

    public static func nextSelection(in values: [Value], current: Value, direction: Int,
                                     isChoiceEnabled: (Value) -> Bool = { _ in true }) -> Value? {
        let values = values.filter(isChoiceEnabled)
        guard !values.isEmpty else { return nil }
        guard values.contains(current) else { return direction < 0 ? values.last : values.first }
        let index = values.firstIndex(of: current) ?? 0
        return values[min(max(index + direction, 0), values.count - 1)]
    }

    private var labelPadding: CGFloat {
        guard !choices.isEmpty, symbols.isEmpty else { return 8 }
        let font = NSFont.systemFont(ofSize: OnePlusTextRole.control.size(for: density))
        let labelsWidth = choices.reduce(CGFloat.zero) { $0 + ceil(($1.1 as NSString).size(withAttributes: [.font: font]).width) }
        let remaining = (width ?? OnePlusMetrics.wideControlColumn) - labelsWidth - 4
        return min(8, max(4, floor(remaining / CGFloat(choices.count)) / 2))
    }

    public var body: some View {
        let padding = labelPadding
        let values = choices.map(\.0)
        let selectedIndex = values.firstIndex(of: selection)
        let hoveredIndex = hovered.flatMap { values.firstIndex(of: $0) }
        let innerHeight = (controlHeight ?? density.controlHeight) - 4
        HStack(spacing: 0) {
            ForEach(choices.indices, id: \.self) { index in
                let choice = choices[index]
                Button { pick(choice.0) } label: {
                    OnePlusSegmentLabel(title: choice.1, symbol: symbols[choice.0], selected: selection == choice.0,
                                        padding: padding, expands: width != nil)
                }
                .segmentKeyAnchor(selection == choice.0)
                // The label draws its own hover fill; a style fill would sit on top of the key.
                .buttonStyle(.plain)
                .linearSegmentDivider(OnePlusSegmentKey.showsDivider(before: index, selected: selectedIndex, hovered: hoveredIndex),
                                      height: OnePlusSegmentKey.dividerHeight(inner: innerHeight))
                .onHover { inside in
                    OnePlusMotion.withHover(inside) { if inside { hovered = choice.0 } else if hovered == choice.0 { hovered = nil } }
                }
                .disabled(!isChoiceEnabled(choice.0))
                .opacity(enabled && !isChoiceEnabled(choice.0) ? OnePlusMetrics.disabledOpacity : 1)
                .accessibilityAddTraits(selection == choice.0 ? .isSelected : [])
                .accessibilityIdentifier(identifierPrefix.map { "\($0).\(choice.0)" } ?? "")
                .help(choice.1)
            }
        }
        .segmentKey(OnePlusSegmentKey(radius: OnePlusMetrics.segmentRadius, fill: OnePlusColor.selectedControl))
        .padding(2).frame(width: width).fixedSize(horizontal: width == nil, vertical: false).frame(height: controlHeight ?? density.controlHeight)
        .background(OnePlusColor.track, in: RoundedRectangle(cornerRadius: 6))
        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(OnePlusColor.line, lineWidth: 1) }
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        .linearMotion(OnePlusMotion.segment, value: picks)
        .onMoveCommand { direction in
            guard enabled else { return }
            let delta = direction == .left || direction == .up ? -1 : 1
            if let value = Self.nextSelection(in: choices.map(\.0), current: selection, direction: delta,
                                              isChoiceEnabled: isChoiceEnabled) { pick(value) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    /// Only a click or arrow key slides the key; a value set from code lands at once.
    private func pick(_ value: Value) {
        guard value != selection else { return }
        picks &+= 1
        selection = value
    }
}

private struct OnePlusSegmentLabel: View {
    let title: String
    let symbol: String?
    let selected: Bool
    let padding: CGFloat
    let expands: Bool
    @Environment(\.onePlusDensity) private var density
    @Environment(\.onePlusControlHeight) private var controlHeight
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    @State private var hover = false
    private var hovering: Bool { enabled && (hover || sample == .hover) }
    var body: some View {
        OnePlusControlContentLayout(pointSize: OnePlusTextRole.control.size(for: density), iconIndex: symbol == nil ? nil : 0) {
            if let symbol { Image(systemName: symbol).accessibilityLabel(title) }
            else { Text(title) }
        }.onePlusText(.control, color: selected || hovering ? OnePlusColor.ink : OnePlusColor.secondary)
            .lineLimit(1).fixedSize(horizontal: true, vertical: false).padding(.horizontal, padding)
            .frame(maxWidth: expands ? .infinity : nil).frame(height: (controlHeight ?? density.controlHeight) - 4)
            .background(!selected && hovering ? OnePlusColor.raised : .clear,
                        in: RoundedRectangle(cornerRadius: OnePlusMetrics.segmentRadius))
            .contentShape(Rectangle()).onePlusHover($hover)
    }
}

public struct OnePlusSegments<Value: Hashable>: View {
    private let choices: [(Value, String)]
    @Binding private var selection: Value
    public init(choices: [(Value, String)], selection: Binding<Value>) {
        self.choices = choices
        _selection = selection
    }
    public var body: some View { OnePlusSegmented(choices: choices, selection: $selection).fixedSize() }
}

public struct OnePlusMenuLabel: View {
    let title: String
    let width: CGFloat?
    let expanded: Bool
    @Environment(\.onePlusDensity) private var density
    @Environment(\.onePlusControlHeight) private var controlHeight
    @Environment(\.isFocused) private var focused
    @Environment(\.isEnabled) private var enabled
    @State private var hover = false
    public init(title: String, width: CGFloat?, expanded: Bool = false) {
        self.title = title
        self.width = width
        self.expanded = expanded
    }
    public var body: some View {
        OnePlusControlContentLayout(pointSize: OnePlusTextRole.control.size(for: density), spacing: 8, iconIndex: 1) {
            Text(title).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.down").accessibilityHidden(true)
        }
        .onePlusText(.control).padding(.horizontal, 10).frame(width: width, height: controlHeight ?? density.controlHeight)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(enabled && ((focused && OnePlusFocusPolicy.shared.showsFocus) || hover || expanded) ? OnePlusColor.raisedHover : OnePlusColor.raised,
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(OnePlusColor.line, lineWidth: 1) }
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity).onePlusHover($hover)
        .contentShape(Rectangle())
    }
}

public struct OnePlusSelect<Value: Hashable>: View {
    private let choices: [(Value, String)]
    @Binding private var selection: Value
    private let width: CGFloat?
    private let label: String
    @Environment(\.onePlusDensity) private var density
    @FocusState private var focused: Bool
    @State private var expanded = false
    @State private var anchor = OnePlusPopupAnchorReference()
    public init(choices: [(Value, String)], selection: Binding<Value>, width: CGFloat? = 160, accessibilityLabel: String) {
        self.choices = choices
        _selection = selection
        self.width = width
        label = accessibilityLabel
    }
    public var body: some View {
        Button {
            toggle()
        } label: {
            OnePlusMenuLabel(title: choices.first { $0.0 == selection }?.1 ?? "Select",
                             width: width, expanded: expanded)
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: width != nil, vertical: true)
        .focused($focused)
        .focusEffectDisabled()
        .background { OnePlusPopupAnchor(reference: anchor) }
        .onMoveCommand { direction in
            if direction == .down, !expanded { toggle() }
        }
        .accessibilityLabel(label)
        .accessibilityValue(choices.first { $0.0 == selection }?.1 ?? "No selection")
        .accessibilityHint(expanded ? "Menu open" : "Opens menu")
        .help(choices.first { $0.0 == selection }?.1 ?? "No selection")
    }

    private func toggle() {
        let entries = popupEntries
        OnePlusPopupPresenter.shared.toggle(anchor: anchor.view, entries: entries, density: density,
                                            initialID: entries.first { $0.item?.isSelected == true }?.id) { reason in
            expanded = false
            if reason == .escape { focused = true }
        }
        expanded = OnePlusPopupPresenter.shared.isOpen(for: anchor.view)
    }

    private var popupEntries: [OnePlusPopupMenuEntry] {
        guard !choices.isEmpty else {
            return [.item(OnePlusPopupMenuItem("No options", isEnabled: false) {})]
        }
        return choices.map { choice in
            .item(OnePlusPopupMenuItem(choice.1, isSelected: choice.0 == selection) {
                selection = choice.0
            })
        }
    }
}

public struct OnePlusCheckboxStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 6) {
                OnePlusCheckboxBox(isOn: configuration.isOn)
                configuration.label.onePlusText(.row)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(OnePlusCheckboxButtonStyle())
        .focusEffectDisabled()
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

/// A 14 pt rounded square: the track well with a hairline when off, the accent with a white check when on.
/// Hover shades it one `pressed` step, press two steps, like the stepper key. Disabled and on, it is the neutral
/// well with a gray check (a fixed "already done" state), never the accent faded toward a warning tint.
private struct OnePlusCheckboxBox: View {
    static let size: CGFloat = 14
    static let radius: CGFloat = 4
    static let check: CGFloat = 8
    let isOn: Bool
    @Environment(\.onePlusCheckboxState) private var live
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    private var state: OnePlusCheckboxState {
        live == .pressed || sample == .pressed ? .pressed : live == .hover || sample == .hover ? .hover : .rest
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius)
        let accent = isOn && enabled
        shape.fill(accent ? OnePlusLinearColor.accent : OnePlusLinearColor.fillTrack)
            .overlay { if enabled, state != .rest { shape.fill(OnePlusLinearColor.pressed) } }
            .overlay { if enabled, state == .pressed { shape.fill(OnePlusLinearColor.pressed) } }
            .overlay { shape.strokeBorder(OnePlusLinearColor.line, lineWidth: 1) }
            .overlay {
                if isOn {
                    Image(systemName: "checkmark").font(.system(size: Self.check, weight: .bold))
                        .foregroundStyle(accent ? Color.white : OnePlusLinearColor.appletSecondary)
                }
            }
            .frame(width: Self.size, height: Self.size)
            .opacity(enabled || isOn ? 1 : OnePlusMetrics.disabledOpacity)
    }
}

private enum OnePlusCheckboxState { case rest, hover, pressed }

private struct OnePlusCheckboxStateKey: EnvironmentKey { static let defaultValue = OnePlusCheckboxState.rest }

private extension EnvironmentValues {
    var onePlusCheckboxState: OnePlusCheckboxState {
        get { self[OnePlusCheckboxStateKey.self] }
        set { self[OnePlusCheckboxStateKey.self] = newValue }
    }
}

private struct OnePlusCheckboxButtonStyle: ButtonStyle {
    @State private var hover = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.onePlusCheckboxState, configuration.isPressed ? .pressed : hover ? .hover : .rest)
            .onHover { hover = $0 }
    }
}

public struct OnePlusRadio<Value: Hashable>: View {
    let choices: [(Value, String)]
    @Binding var selection: Value
    let label: String
    public init(_ label: String, choices: [(Value, String)], selection: Binding<Value>) {
        self.label = label; self.choices = choices; _selection = selection
    }
    public var body: some View {
        Picker(label, selection: $selection) {
            ForEach(choices.indices, id: \.self) { index in Text(choices[index].1).tag(choices[index].0) }
        }.pickerStyle(.radioGroup).onePlusText(.row).tint(OnePlusColor.primaryFill)
    }
}
