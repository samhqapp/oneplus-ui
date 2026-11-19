import AppKit
import SwiftUI

/// A horizontal slider at the applet look: a sunken track, the accent fill, and a solid knob. The knob follows the
/// pointer at once while dragged; a change from code (reset) slides it with the Quiet motion. Arrow keys step by `step`.
public struct OnePlusLinearSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let label: String
    @State private var dragging = false
    @FocusState private var focused: Bool
    @Environment(\.onePlusLinearControlLook) private var environmentLook
    @Environment(\.isEnabled) private var enabled

    public init(_ label: String, value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01) {
        self.label = label; _value = value; self.range = range; self.step = step
    }

    public var body: some View {
        let look = environmentLook ?? .quietRaised
        let fraction = Self.fraction(of: value, in: range)
        let travel = look.sliderWidth - look.knob
        ZStack(alignment: .leading) {
            OnePlusQuietWell(shape: Capsule(), focused: focused)
                .overlay(alignment: .leading) {
                    Capsule().fill(OnePlusLinearColor.accent).frame(width: look.knob / 2 + travel * fraction)
                }
                .frame(height: look.sliderTrack)
            OnePlusQuietCap(shape: Circle(), pressed: dragging)
                .frame(width: look.knob, height: look.knob)
                .padding(.leading, travel * fraction)
        }
        .linearMotion(OnePlusMotion.slider, value: value, enabled: !dragging)
        .frame(width: look.sliderWidth, height: look.height)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { drag in
                dragging = true
                value = Self.value(at: (drag.location.x - look.knob / 2) / travel, in: range, step: step)
            }
            .onEnded { _ in dragging = false })
        .focusable(enabled).focused($focused).focusEffectDisabled()
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            value = min(range.upperBound, max(range.lowerBound, value + (press.key == .leftArrow ? -step : step)))
            return .handled
        }
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        .accessibilityRepresentation { Slider(value: $value, in: range) { Text(label) } }
    }

    static func fraction(of value: Double, in range: ClosedRange<Double>) -> Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return min(1, max(0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    static func value(at fraction: Double, in range: ClosedRange<Double>, step: Double) -> Double {
        let raw = range.lowerBound + min(1, max(0, fraction)) * (range.upperBound - range.lowerBound)
        guard step > 0 else { return raw }
        return min(range.upperBound, max(range.lowerBound, (raw / step).rounded() * step))
    }
}

/// A color well at the applet look: the color in a 40 x 22 field. A click opens the shared color panel.
public struct OnePlusLinearColorWell: View {
    @Binding private var color: NSColor
    private let label: String
    private let showsAlpha: Bool
    @State private var target = OnePlusColorPanelTarget()
    @Environment(\.displayScale) private var scale
    @Environment(\.onePlusLinearControlLook) private var environmentLook
    @Environment(\.isEnabled) private var enabled

    public init(_ label: String, color: Binding<NSColor>, showsAlpha: Bool = false) {
        self.label = label; _color = color; self.showsAlpha = showsAlpha
    }

    public var body: some View {
        let look = environmentLook ?? .quietRaised
        let swatch = RoundedRectangle(cornerRadius: look.radius - look.wellInset)
        Button {
            target.open(color: color, showsAlpha: showsAlpha) { color = $0 }
        } label: {
            swatch.fill(Color(nsColor: color))
                .overlay { swatch.strokeBorder(OnePlusLinearColor.quietSwatchLine, lineWidth: 1 / max(scale, 1)) }
                .padding(look.wellInset)
                .frame(width: look.well.width, height: look.well.height)
                .background { OnePlusQuietWell.field(RoundedRectangle(cornerRadius: look.radius)) }
        }
        .buttonStyle(.plain).focusEffectDisabled(!OnePlusFocusPolicy.shared.showsFocus)
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        .help(label).accessibilityLabel(label)
    }
}

@MainActor
private final class OnePlusColorPanelTarget: NSObject {
    private var changed: ((NSColor) -> Void)?
    func open(color: NSColor, showsAlpha: Bool, changed: @escaping (NSColor) -> Void) {
        self.changed = changed
        let panel = NSColorPanel.shared
        panel.showsAlpha = showsAlpha
        panel.setTarget(nil)
        panel.color = color
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.orderFront(nil)
    }
    @objc private func colorChanged(_ sender: NSColorPanel) { changed?(sender.color) }
}

/// A select at the applet look. `.field` is a 26 pt bezel with an up-down chevron (the Color Picker format);
/// `.text` is a plain label with a down chevron for a tab row (the project filter). Both open `OnePlusPopupMenu`.
public struct OnePlusLinearSelect<Value: Hashable>: View {
    public enum Style: Sendable { case field, text }
    private let choices: [(Value, String)]
    @Binding private var selection: Value
    private let label: String
    private let style: Style
    private let width: CGFloat?
    @State private var expanded = false
    @State private var hover = false
    @State private var anchor = OnePlusPopupAnchorReference()
    @FocusState private var focused: Bool
    @Environment(\.onePlusLinearControlLook) private var environmentLook
    @Environment(\.isEnabled) private var enabled

    public init(choices: [(Value, String)], selection: Binding<Value>, accessibilityLabel: String,
                style: Style = .field, width: CGFloat? = nil) {
        self.choices = choices; _selection = selection; label = accessibilityLabel; self.style = style; self.width = width
    }

    private var title: String { choices.first { $0.0 == selection }?.1 ?? "Select" }

    public var body: some View {
        Button(action: toggle) { trigger }
            .buttonStyle(.plain)
            .focused($focused).focusEffectDisabled()
            .background { OnePlusPopupAnchor(reference: anchor) }
            .onMoveCommand { if $0 == .down, !expanded { toggle() } }
            .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
            .accessibilityLabel(label).accessibilityValue(title)
            .accessibilityHint(expanded ? "Menu open" : "Opens menu")
    }

    @ViewBuilder private var trigger: some View {
        let look = environmentLook ?? .quietRaised
        let lit = enabled && (hover || expanded)
        switch style {
        case .field:
            HStack(spacing: 8) {
                Text(title).linearText().lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(OnePlusLinearColor.appletSecondary)
            }
            .padding(.horizontal, 11)
            .frame(width: width, height: look.keys ? look.height : OnePlusLinearMetrics.appletField)
            .linearFieldBezel(look, focused: focused)
            .overlay { if lit { RoundedRectangle(cornerRadius: look.radius).fill(OnePlusLinearColor.hover) } }
            .contentShape(Rectangle()).onePlusHover($hover)
        case .text:
            HStack(spacing: 5) {
                Text(title).linearText(color: lit ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(lit ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary)
            }
            .frame(width: width, alignment: .trailing)
            .contentShape(Rectangle()).onePlusHover($hover)
        }
    }

    private func toggle() {
        let entries: [OnePlusPopupMenuEntry] = choices.isEmpty
            ? [.item(OnePlusPopupMenuItem("No options", isEnabled: false) {})]
            : choices.map { choice in .item(OnePlusPopupMenuItem(choice.1, isSelected: choice.0 == selection) { selection = choice.0 }) }
        OnePlusPopupPresenter.shared.toggle(anchor: anchor.view, entries: entries, density: .regular,
                                            initialID: entries.first { $0.item?.isSelected == true }?.id) { reason in
            expanded = false
            if reason == .escape { focused = true }
        }
        expanded = OnePlusPopupPresenter.shared.isOpen(for: anchor.view)
    }
}

/// A text field at the applet look: a 22 pt field with the control radius, 13 pt text, and the title as
/// its placeholder. The focus line shows only under the shared keyboard focus policy. An error adds the danger
/// line and a tooltip; the host shows any visible error text.
public struct OnePlusLinearTextField: View {
    private let title: String
    @Binding private var text: String
    private let error: String?
    private let onSubmit: () -> Void
    @FocusState private var focused: Bool
    @Environment(\.onePlusLinearControlLook) private var environmentLook
    @Environment(\.isEnabled) private var enabled

    public init(_ title: String, text: Binding<String>, error: String? = nil, onSubmit: @escaping () -> Void = {}) {
        self.title = title; _text = text; self.error = error; self.onSubmit = onSubmit
    }

    public var body: some View {
        let look = environmentLook ?? .quietRaised
        let shape = RoundedRectangle(cornerRadius: look.radius)
        TextField(text: $text, prompt: Text(title).foregroundStyle(OnePlusLinearColor.appletMuted)) { Text(title) }
            .textFieldStyle(.plain).linearText().focusEffectDisabled()
            .focused($focused).onSubmit(onSubmit)
            .padding(.horizontal, 8).frame(height: look.height)
            .background { OnePlusQuietWell.field(shape, focused: focused) }
            .overlay { if error != nil { shape.strokeBorder(OnePlusColor.dangerLine, lineWidth: 1) } }
            .help(error ?? "")
            .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
            .accessibilityLabel(title).accessibilityHint(error ?? "")
    }
}

/// An applet empty state: a 22 pt glyph, a 13 pt medium title, an optional 12 pt line, and an optional action
/// (usually a `.soft` or `.ghost` button), centered with 28 pt above and below.
public struct OnePlusLinearEmptyState<Action: View>: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let action: Action
    public init(_ title: String, systemImage: String, message: String? = nil, @ViewBuilder action: () -> Action) {
        self.title = title; self.systemImage = systemImage; self.message = message; self.action = action()
    }
    public var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 22)).foregroundStyle(OnePlusLinearColor.appletMuted)
                .padding(.bottom, 4).accessibilityHidden(true)
            Text(title).linearText(weight: .medium)
            if let message {
                Text(message).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.appletSecondary)
                    .multilineTextAlignment(.center)
            }
            if Action.self != EmptyView.self { action.padding(.top, 6) }
        }
        .padding(.vertical, 28).padding(.horizontal, OnePlusLinearMetrics.appletGutter)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

public extension OnePlusLinearEmptyState where Action == EmptyView {
    init(_ title: String, systemImage: String, message: String? = nil) {
        self.init(title, systemImage: systemImage, message: message) { EmptyView() }
    }
}

/// An applet banner: a filled 10 pt group with a leading glyph, a 13 pt medium title, an optional 12 pt line,
/// and an optional trailing action. `.info` uses the group fill; `.warning` an amber tint and a triangle glyph;
/// `.error` a red tint and an octagon glyph, so the state never relies on color alone.
public struct OnePlusLinearBanner<Action: View>: View {
    public enum Kind: Sendable { case info, warning, error }
    private let kind: Kind
    private let title: String
    private let message: String?
    private let action: Action
    public init(_ kind: Kind, title: String, message: String? = nil, @ViewBuilder action: () -> Action) {
        self.kind = kind; self.title = title; self.message = message; self.action = action()
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.appletRowGap) {
            Image(systemName: glyph).font(.system(size: 13))
                .foregroundStyle(tint)
                .accessibilityLabel(kind == .info ? "Information" : kind == .warning ? "Warning" : "Error")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).linearText(weight: .medium).textSelection(.enabled)
                if let message {
                    Text(message).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.appletSecondary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            action
        }
        .padding(.horizontal, OnePlusLinearMetrics.appletRowPadding).padding(.vertical, 9)
        .background(fill, in: RoundedRectangle(cornerRadius: OnePlusLinearMetrics.appletGroupRadius))
        .accessibilityElement(children: .contain)
    }
    private var glyph: String {
        switch kind {
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "exclamationmark.octagon.fill"
        }
    }
    private var tint: Color {
        switch kind {
        case .info: OnePlusLinearColor.appletSecondary
        case .warning: OnePlusLinearColor.warning
        case .error: OnePlusLinearColor.destructiveText
        }
    }
    private var fill: Color {
        switch kind {
        case .info: OnePlusLinearColor.appletGroup
        case .warning: OnePlusLinearColor.warningFill
        case .error: OnePlusLinearColor.destructiveFill
        }
    }
}

public extension OnePlusLinearBanner where Action == EmptyView {
    init(_ kind: Kind, title: String, message: String? = nil) { self.init(kind, title: title, message: message) { EmptyView() } }
}
