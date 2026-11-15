import AppKit
import SwiftUI

/// A horizontal slider at the applet look: a recessed track, the rod fill, and a raised knob. The knob follows the
/// pointer at once while dragged; a change from code (reset) slides it with the Quiet motion. Arrow keys step by `step`.
public struct OnePlusLinearSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let label: String
    @State private var dragging = false
    @State private var hover = false
    @FocusState private var focused: Bool
    @Environment(\.onePlusLinearControlLook) private var environmentLook
    @Environment(\.isEnabled) private var enabled

    public init(_ label: String, value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01) {
        self.label = label; _value = value; self.range = range; self.step = step
    }

    public var body: some View {
        let look = environmentLook ?? .depth
        let fraction = Self.fraction(of: value, in: range)
        let travel = look.sliderWidth - look.knob
        ZStack(alignment: .leading) {
            // The rod covers the track's inner shade and is clipped to the track; the lip below stays outside.
            OnePlusDepthRecess(Capsule(), focused: focused)
                .overlay(alignment: .leading) {
                    OnePlusDepthRodFill().frame(width: look.knob / 2 + travel * fraction)
                        .frame(maxWidth: .infinity, alignment: .leading).clipShape(Capsule())
                }
                .frame(height: look.sliderTrack)
            OnePlusDepthCap(shape: Circle(), pressed: dragging, hover: hover && enabled)
                .frame(width: look.knob, height: look.knob)
                .padding(.leading, travel * fraction)
        }
        .linearMotion(OnePlusLinearMotion.slider, value: value, enabled: !dragging)
        .frame(width: look.sliderWidth, height: look.height)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
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

/// A color well at the applet look: the color in a 44 x 24 field. A click opens the shared color panel.
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
        let look = environmentLook ?? .depth
        let swatch = RoundedRectangle(cornerRadius: look.radius - look.wellInset)
        Button {
            target.open(color: color, showsAlpha: showsAlpha) { color = $0 }
        } label: {
            swatch.fill(Color(nsColor: color))
                .overlay(alignment: .top) { Color.white.opacity(0.5).frame(height: 1 / max(scale, 1)) }
                .clipShape(swatch)
                .overlay { swatch.strokeBorder(OnePlusLinearColor.depthSwatchRing, lineWidth: 1 / max(scale, 1)) }
                .padding(look.wellInset)
                .frame(width: look.well.width, height: look.well.height)
                .background { OnePlusDepthRecess(RoundedRectangle(cornerRadius: look.radius)) }
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
        let look = environmentLook ?? .depth
        let lit = enabled && (hover || expanded)
        switch style {
        case .field:
            HStack(spacing: 8) {
                Text(title).linearText().lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(OnePlusLinearColor.appletSecondary)
            }
            .padding(.horizontal, 11)
            .frame(width: width, height: OnePlusLinearMetrics.appletField)
            .linearFieldBezel(look, focused: focused)
            .overlay { if lit { RoundedRectangle(cornerRadius: look.radius).fill(OnePlusLinearColor.hover) } }
            .contentShape(Rectangle()).onHover { hover = $0 }
        case .text:
            HStack(spacing: 5) {
                Text(title).linearText(color: lit ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(lit ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary)
            }
            .frame(width: width, alignment: .trailing)
            .contentShape(Rectangle()).onHover { hover = $0 }
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
