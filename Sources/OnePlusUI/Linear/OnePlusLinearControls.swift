import AppKit
import SwiftUI

/// Paint-only feedback for v15 buttons: hover and press change the fill, never the geometry.
/// The focus line shows only under the shared keyboard focus policy.
public struct OnePlusLinearButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        /// Transparent until hover (nav rows, toolbar and footer icon buttons, tabs).
        case plain
        /// The raised text button (`Open App`): 28 pt, button fill, ring, 13 pt medium.
        case raised
    }
    let kind: Kind
    let radius: CGFloat
    let selected: Bool
    public init(_ kind: Kind = .plain, radius: CGFloat = OnePlusLinearMetrics.radius, selected: Bool = false) {
        self.kind = kind; self.radius = radius; self.selected = selected
    }
    public func makeBody(configuration: Configuration) -> some View {
        OnePlusLinearButtonBody(label: configuration.label, pressed: configuration.isPressed,
                                kind: kind, radius: radius, selected: selected)
    }
}

private struct OnePlusLinearButtonBody<Label: View>: View {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.onePlusControlState) private var sample
    @State private var hover = false
    let label: Label
    let pressed: Bool
    let kind: OnePlusLinearButtonStyle.Kind
    let radius: CGFloat
    let selected: Bool

    private var fill: Color {
        guard enabled else { return .clear }
        if pressed || sample == .pressed { return OnePlusLinearColor.pressed }
        if selected { return OnePlusLinearColor.selection }
        return hover || sample == .hover ? OnePlusLinearColor.hover : .clear
    }

    var body: some View {
        Group {
            if kind == .raised {
                label.linearText(weight: .medium)
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.button)
                    .linearRaised(radius: radius)
            } else {
                label
            }
        }
        .background(fill, in: RoundedRectangle(cornerRadius: radius))
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(enabled && (focused || sample == .focus) && OnePlusFocusPolicy.shared.showsFocus ? OnePlusColor.focus : .clear, lineWidth: 1)
        }
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        .contentShape(RoundedRectangle(cornerRadius: radius))
        .onHover { hover = $0 }
    }
}

/// An icon-only button: 24 pt in the pane toolbar, 28 pt in the panel footer.
public struct OnePlusLinearIconButton: View {
    private let systemImage: String
    private let help: String
    private let size: CGFloat
    private let action: () -> Void
    public init(systemImage: String, help: String, size: CGFloat = OnePlusLinearMetrics.iconButton, action: @escaping () -> Void) {
        self.systemImage = systemImage; self.help = help; self.size = size; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size >= OnePlusLinearMetrics.iconButton ? 15 : 12, weight: .regular))
                .foregroundStyle(OnePlusLinearColor.secondary)
                .frame(width: size, height: size)
        }
        .buttonStyle(OnePlusLinearButtonStyle())
        .help(help).accessibilityLabel(help)
    }
}

/// The v15 switch: 26 x 16 track, 12 pt knob. The label is used for accessibility only.
public struct OnePlusLinearSwitchStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule().fill(configuration.isOn ? OnePlusLinearColor.switchOn : OnePlusLinearColor.switchOff)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle().fill(configuration.isOn ? OnePlusLinearColor.knobOn : OnePlusLinearColor.knobOff)
                        .shadow(color: .black.opacity(0.2), radius: 0.5, y: 1)
                        .frame(width: OnePlusLinearMetrics.knob, height: OnePlusLinearMetrics.knob)
                        .padding(.horizontal, 2)
                }
                .frame(width: OnePlusLinearMetrics.switchSize.width, height: OnePlusLinearMetrics.switchSize.height)
        }
        .buttonStyle(OnePlusLinearButtonStyle(radius: OnePlusLinearMetrics.switchSize.height / 2))
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

/// A compact segmented control: 22 pt track, 40 x 18 segments, 11 pt labels.
public struct OnePlusLinearSegmented<Value: Hashable>: View {
    private let choices: [(Value, String)]
    @Binding private var selection: Value
    private let label: String
    public init(choices: [(Value, String)], selection: Binding<Value>, accessibilityLabel: String) {
        self.choices = choices; _selection = selection; label = accessibilityLabel
    }
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(choices, id: \.0) { value, title in
                let on = value == selection
                Button { selection = value } label: {
                    Text(title).linearText(OnePlusLinearMetrics.caption, weight: on ? .medium : .regular,
                                           color: on ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                        .frame(width: OnePlusLinearMetrics.segment.width, height: OnePlusLinearMetrics.segment.height)
                        .linearSegmentSelected(on, radius: 4)
                }
                .buttonStyle(OnePlusLinearButtonStyle(radius: 4))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .linearTrack(radius: OnePlusLinearMetrics.radius)
        .accessibilityElement(children: .contain).accessibilityLabel(label)
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            if let next = OnePlusSegmented<Value>.nextSelection(in: choices.map(\.0), current: selection,
                                                              direction: press.key == .leftArrow ? -1 : 1) { selection = next }
            return .handled
        }
    }
}

/// A rounded group with hairline separators between its rows.
/// `.window` is the main window tool list; `.panel` is a menu-panel card.
public struct OnePlusLinearList<Content: View>: View {
    public enum Style: Sendable { case window, panel }
    private let style: Style
    private let content: Content
    public init(style: Style = .window, @ViewBuilder content: () -> Content) { self.style = style; self.content = content() }
    public var body: some View {
        let radius = style == .window ? OnePlusLinearMetrics.listRadius : OnePlusLinearMetrics.tileRadius
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row.overlay(alignment: .top) {
                        if row.id != rows.first?.id { OnePlusLinearColor.lineSoft.frame(height: 1).allowsHitTesting(false) }
                    }
                }
            }
        }
        .background(style == .window ? Color.clear : OnePlusLinearColor.panelTile)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .linearOuterRing(OnePlusLinearColor.line, radius: radius)
    }
}

extension View {
    func linearRowHover(_ hover: Binding<Bool>, sample: OnePlusControlState, enabled: Bool) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(enabled && (hover.wrappedValue || sample == .hover) ? OnePlusLinearColor.hover : .clear)
            .contentShape(Rectangle())
            .onHover { hover.wrappedValue = $0 }
    }
}
