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
        /// The filled text button (panel `Open App`): the `.raised` geometry on the primary fill with primary ink.
        case filled
        /// The applet primary action (`Pick Color`): 24 pt, soft gray fill, no border, 13 pt medium.
        case soft
        /// A secondary text action: the `.soft` geometry and type with no fill until hover; `appletSecondary` text, `ink` on hover.
        case ghost
        /// The applet destructive action (`Reset to Factory Defaults`): plain red text with no fill and no border,
        /// on the group's row text edge. A native confirmation still guards it.
        case destructive
        /// The tool page reset or clear (`Reset to Factory Defaults`, `Clear History`): one full-width 40 pt inset
        /// row like a settings group (`fillGroup`, 1 pt `line` ring, radius 10), red text on the row text edge.
        case resetBlock
        /// A text action inside a caption line (the Fan chart's `Reset Curve`): caption type in `secondary` ink, one
        /// step darker than a `tertiary` hint, `ink` on hover and press; no fill, no padding.
        case inline
        /// A reset inside a caption line (the Fan chart's `Reset Curve`): `.inline` geometry and caption type in
        /// coral `destructiveText`, `destructivePressedText` on press.
        case inlineDestructive
        /// A segment on a `fillTrack` well: no fill at rest, a clear `fillSegmentHover` step on hover (darker in
        /// Light, lighter in Dark, so it never melts into the well), `fillSegmentPressed` while pressed.
        case segment
        /// A native macOS push button (`Open Settings` on a warning banner): 22 pt, radius 5, 13 pt regular,
        /// `pushButton` fill, a 0.5 pt line, and a soft drop shadow.
        case push
        /// The default push button (`Fix`): the `.push` geometry in system blue with white text.
        case pushProminent
    }
    let kind: Kind
    let radius: CGFloat
    let selected: Bool
    public init(_ kind: Kind = .plain, radius: CGFloat? = nil, selected: Bool = false) {
        self.kind = kind; self.selected = selected
        self.radius = radius ?? (kind == .resetBlock ? OnePlusLinearEditorialMetrics.resetBlockRadius : OnePlusLinearMetrics.radius)
    }
    public func makeBody(configuration: Configuration) -> some View {
        OnePlusLinearButtonBody(label: configuration.label, pressed: configuration.isPressed,
                                kind: kind, baseRadius: radius, selected: selected)
    }
}

private struct OnePlusLinearButtonBody<Label: View>: View {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    @Environment(\.onePlusLinearControlLook) private var look
    @Environment(\.colorScheme) private var colorScheme
    @State private var hover = false
    let label: Label
    let pressed: Bool
    let kind: OnePlusLinearButtonStyle.Kind
    let baseRadius: CGFloat
    /// Raised keys: `.raised` and `.soft` text buttons are 28 pt raised keys.
    private var key: OnePlusLinearControlLook? { look?.keys == true && (kind == .raised || kind == .soft) ? look : nil }
    private var radius: CGFloat {
        if let key { return key.radius }
        return kind == .filled && panelStyle == .fillSteps ? OnePlusLinearPanelStyle.tileRadius : baseRadius
    }
    let selected: Bool

    private var isPressed: Bool { pressed || sample == .pressed }
    private var isHovered: Bool { hover || sample == .hover }

    private var keyFill: Color {
        guard enabled else { return .clear }
        return isPressed ? OnePlusLinearColor.pressed : isHovered ? OnePlusLinearColor.hover : .clear
    }

    private var fill: Color {
        if key != nil { return .clear }
        switch kind {
        case .soft:
            guard enabled else { return OnePlusLinearColor.softButton }
            return isPressed ? OnePlusLinearColor.softButtonPressed : isHovered ? OnePlusLinearColor.softButtonHover : OnePlusLinearColor.softButton
        case .filled where panelStyle == .fillSteps:
            return .clear // The open key draws its own fill, hover, and press.
        case .filled:
            guard enabled else { return OnePlusColor.primaryFill }
            return isPressed ? OnePlusColor.primaryPressed : isHovered ? OnePlusColor.primaryHover : OnePlusColor.primaryFill
        case .destructive, .inline, .inlineDestructive, .push, .pushProminent:
            return .clear
        case .resetBlock:
            guard enabled else { return OnePlusLinearColor.fillGroup }
            return isPressed ? OnePlusLinearColor.softButtonPressed : isHovered ? OnePlusLinearColor.softButtonHover : OnePlusLinearColor.fillGroup
        case .segment:
            guard enabled else { return .clear }
            return isPressed ? OnePlusLinearColor.fillSegmentPressed : isHovered ? OnePlusLinearColor.fillSegmentHover : .clear
        case .plain, .raised, .ghost:
            guard enabled else { return .clear }
            if isPressed { return OnePlusLinearColor.pressed }
            if selected { return OnePlusLinearColor.selection }
            return isHovered ? OnePlusLinearColor.hover : .clear
        }
    }

    var body: some View {
        Group {
            switch kind {
            case .raised where key != nil, .soft where key != nil:
                let shape = RoundedRectangle(cornerRadius: radius)
                label.labelStyle(OnePlusLinearLabelStyle()).linearText(weight: .medium).fixedSize()
                    .padding(.horizontal, 12).frame(height: key?.height ?? OnePlusLinearMetrics.button)
                    .background { OnePlusRaisedKey(shape: shape, button: true).overlay { shape.fill(keyFill) } }
            case .raised:
                label.linearText(weight: .medium)
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.button)
                    .linearRaised(radius: radius)
            case .filled where panelStyle == .fillSteps:
                // Fill steps panel open key: a 26 pt ink key, 10 pt padding, 12 pt text.
                // The label centers on its cap height, not its line box, which sits the caps low.
                label.linearText(OnePlusLinearMetrics.control, weight: .medium, color: OnePlusLinearColor.openKeyInk)
                    .alignmentGuide(VerticalAlignment.center) { $0[.firstTextBaseline] - OnePlusLinearMetrics.controlCapHeight / 2 }
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.iconTab)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: radius)
                        shape.fill(LinearGradient(colors: [OnePlusLinearColor.openKeyTop, OnePlusLinearColor.openKeyBottom],
                                                  startPoint: .top, endPoint: .bottom))
                            .overlay { shape.strokeBorder(LinearGradient(colors: [OnePlusLinearColor.openKeyEdgeTop, OnePlusLinearColor.openKeyEdgeBottom],
                                                                         startPoint: .top, endPoint: .bottom), lineWidth: 1) }
                            .shadow(color: OnePlusLinearColor.openKeyShadow, radius: 1.5, y: 1)
                            .overlay { shape.fill(enabled && isPressed ? OnePlusLinearColor.openKeyPressed : enabled && isHovered ? OnePlusLinearColor.openKeyHover : .clear) }
                    }
            case .filled:
                label.linearText(weight: .medium, color: OnePlusColor.primaryInk)
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.button)
            case .soft:
                // A text action never truncates; the neighboring row label gives way instead.
                label.labelStyle(OnePlusLinearLabelStyle()).linearText(weight: .medium).fixedSize()
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.appletButton)
            case .ghost:
                label.labelStyle(OnePlusLinearLabelStyle())
                    .linearText(weight: .medium, color: enabled && (isHovered || isPressed) ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary)
                    .fixedSize()
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.appletButton)
            case .destructive:
                label.linearText(color: enabled && isPressed ? OnePlusLinearColor.destructivePressedText : OnePlusLinearColor.destructiveText)
                    .padding(.leading, OnePlusLinearMetrics.appletRowPadding)
                    .frame(maxWidth: .infinity, minHeight: OnePlusLinearMetrics.appletDestructive, alignment: .leading)
            case .resetBlock:
                label.linearText(color: OnePlusLinearColor.destructiveText)
                    .padding(.horizontal, OnePlusLinearMetrics.appletRowPadding)
                    .frame(maxWidth: .infinity, minHeight: OnePlusLinearEditorialMetrics.resetBlock, alignment: .leading)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(OnePlusLinearColor.line, lineWidth: 1)
                    }
            case .inline:
                label.linearText(OnePlusLinearMetrics.caption,
                                 color: enabled && (isHovered || isPressed) ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                    .fixedSize()
            case .inlineDestructive:
                label.linearText(OnePlusLinearMetrics.caption,
                                 color: enabled && isPressed ? OnePlusLinearColor.destructivePressedText : OnePlusLinearColor.destructiveText)
                    .fixedSize()
            case .push, .pushProminent:
                let prominent = kind == .pushProminent
                let shape = RoundedRectangle(cornerRadius: OnePlusLinearMetrics.pushButtonRadius, style: .continuous)
                label.font(.system(size: OnePlusLinearMetrics.body))
                    .foregroundStyle(prominent ? OnePlusLinearColor.pushProminentInk : OnePlusLinearColor.ink)
                    .fixedSize()
                    .padding(.horizontal, OnePlusLinearMetrics.pushButtonPadding).frame(height: OnePlusLinearMetrics.pushButton)
                    .background {
                        Group {
                            if look?.keys == true, colorScheme == .light {
                                OnePlusFlatFace(shape: shape, fill: prominent ? OnePlusLinearColor.pushProminent : OnePlusLinearColor.pushButton,
                                                line: prominent ? .clear : OnePlusLinearColor.flatLine)
                            } else {
                                shape.fill(prominent ? OnePlusLinearColor.pushProminent : OnePlusLinearColor.pushButton)
                                    .overlay { shape.strokeBorder(prominent ? OnePlusLinearColor.pushProminentLine : OnePlusLinearColor.pushButtonLine,
                                                                  lineWidth: OnePlusLinearMetrics.pushButtonLine) }
                                    .shadow(color: OnePlusLinearColor.pushButtonShadow, radius: 0.5, y: 0.5)
                            }
                        }
                        .overlay { shape.fill(enabled && isPressed ? OnePlusLinearColor.pressed : .clear) }
                    }
            case .plain, .segment:
                label
            }
        }
        .background {
            // A selection change crossfades the old and new fills; hover fades with its own timing.
            RoundedRectangle(cornerRadius: radius).fill(fill).linearMotion(OnePlusMotion.selection, value: selected)
        }
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .fill(enabled && (focused || sample == .focus) && OnePlusFocusPolicy.shared.showsFocus ? OnePlusLinearColor.hover : .clear)
                .allowsHitTesting(false)
        }
        .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
        .contentShape(RoundedRectangle(cornerRadius: radius))
        .onePlusHover($hover)
    }
}

/// A glyph at the label's size and a 6 pt gap, sharing one center line.
private struct OnePlusLinearLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) { configuration.icon.imageScale(.small); configuration.title }
    }
}

/// An icon-only button: 24 pt in the pane toolbar, 28 pt in the panel footer.
public struct OnePlusLinearIconButton: View {
    private let systemImage: String
    private let help: String
    private let size: CGFloat
    private let busy: String?
    private let action: () -> Void
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    /// `busy` names running work (such as "Scanning"): the glyph turns into a small spinner in the same frame,
    /// so progress never moves the controls around it.
    public init(systemImage: String, help: String, size: CGFloat = OnePlusLinearMetrics.iconButton, busy: String? = nil,
                action: @escaping () -> Void) {
        self.systemImage = systemImage; self.help = help; self.size = size; self.busy = busy; self.action = action
    }
    public var body: some View {
        // Fill steps: the bar's glyphs share the 13 pt tab glyph size.
        let glyph: CGFloat = panelStyle == .fillSteps ? 13 : size >= OnePlusLinearMetrics.iconButton ? 15 : 12
        Button(action: action) {
            Group {
                if busy != nil {
                    ProgressView().controlSize(.small).scaleEffect(glyph / 16)
                } else {
                    let optical = Self.optical[systemImage] ?? (shrink: 0, dx: 0, dy: 0)
                    Image(systemName: systemImage)
                        .font(.system(size: glyph - optical.shrink, weight: .regular))
                        .foregroundStyle(OnePlusLinearColor.secondary)
                        .offset(x: optical.dx, y: optical.dy)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(OnePlusLinearButtonStyle()).focusEffectDisabled()
        .help(busy.map { "\($0). \(help)" } ?? help)
        .accessibilityLabel(busy ?? help)
        .accessibilityValue(busy == nil ? "" : help)
    }

    /// Optical corrections, measured on 4x renders: the diagonal arrow spans the gear's width at the same point
    /// size and its head pulls its ink up and right, so it draws smaller and moves back toward the cell center.
    private static let optical: [String: (shrink: CGFloat, dx: CGFloat, dy: CGFloat)] = [
        "arrow.up.right": (shrink: 2, dx: -0.5, dy: 0.5),
    ]
}

/// A rounded group with hairline separators between its rows.
/// `.window` is the main window tool list; `.panel` is a menu-panel card. Under the editorial page a `.window`
/// list is the main window's inset group. With `maxHeight` the rows scroll inside the group, so its edge stays whole.
public struct OnePlusLinearList<Content: View>: View {
    public enum Style: Sendable { case window, panel }
    private let style: Style
    private let maxHeight: CGFloat?
    private let content: Content
    public init(style: Style = .window, maxHeight: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.style = style; self.maxHeight = maxHeight; self.content = content()
    }
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    @Environment(\.onePlusLinearEditorial) private var editorial
    public var body: some View {
        if style == .window, editorial {
            OnePlusLinearInsetGroup(content: content)
        } else if style == .panel, panelStyle == .fillSteps {
            scrolling(VStack(spacing: 0) { content }.padding(.vertical, OnePlusLinearPanelStyle.listPadding))
                .background(OnePlusLinearColor.fillGroup)
                .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearPanelStyle.groupRadius))
        } else {
            lined
        }
    }

    @ViewBuilder private func scrolling(_ rows: some View) -> some View {
        if let maxHeight {
            ScrollView { rows }.onePlusScrollIndicators(axes: .vertical).frame(maxHeight: maxHeight)
        } else {
            rows
        }
    }

    private var lined: some View {
        let radius = style == .window ? OnePlusLinearMetrics.listRadius : OnePlusLinearMetrics.tileRadius
        return scrolling(VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row.overlay(alignment: .top) {
                        if row.id != rows.first?.id { OnePlusLinearColor.lineSoft.frame(height: 1).allowsHitTesting(false) }
                    }
                }
            }
        })
        .background(style == .window ? Color.clear : OnePlusLinearColor.panelTile)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .linearOuterRing(style == .panel ? OnePlusLinearColor.panelLine : OnePlusLinearColor.line, radius: radius)
    }
}

extension View {
    /// The panel row hover. Under Fill steps: a radius 6 fill step inset 4 pt from the group and 1 pt from the row.
    public func linearRowHover(_ hover: Binding<Bool>, sample: OnePlusControlState, enabled: Bool,
                        fill: Color = OnePlusLinearColor.hover, panelStyle: OnePlusLinearPanelStyle = .lines,
                        selected: Bool = false) -> some View {
        let on = enabled && (selected || hover.wrappedValue || sample == .hover)
        // Fill steps: a rounded fill step inset 4 pt from the group edge and 1 pt from the row edge.
        return frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if panelStyle == .fillSteps {
                    RoundedRectangle(cornerRadius: 6).fill(on ? OnePlusLinearColor.fillRowHover : .clear)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                } else {
                    on ? fill : .clear
                }
            }
            .contentShape(Rectangle())
            .onePlusHover(hover, timing: panelStyle == .fillSteps ? (OnePlusMotion.panelRowHoverIn, OnePlusMotion.panelRowHoverOut)
                          : (OnePlusMotion.hoverIn, OnePlusMotion.hoverOut))
    }
}
