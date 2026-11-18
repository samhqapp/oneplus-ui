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
        /// The tool page reset or clear (`Reset to Factory Defaults`, `Clear History`): one full-width 32 pt block,
        /// 1 pt `line` border, no fill until hover, red medium text. Its own block outside every group.
        case resetBlock
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
                                kind: kind, radius: radius, selected: selected)
    }
}

private struct OnePlusLinearButtonBody<Label: View>: View {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.onePlusLinearEditorial) private var editorial
    @State private var hover = false
    let label: Label
    let pressed: Bool
    let kind: OnePlusLinearButtonStyle.Kind
    let radius: CGFloat
    let selected: Bool

    private var isPressed: Bool { pressed || sample == .pressed }
    private var isHovered: Bool { hover || sample == .hover }

    private var fill: Color {
        switch kind {
        case .soft:
            guard enabled else { return OnePlusLinearColor.softButton }
            return isPressed ? OnePlusLinearColor.softButtonPressed : isHovered ? OnePlusLinearColor.softButtonHover : OnePlusLinearColor.softButton
        case .filled:
            guard enabled else { return OnePlusColor.primaryFill }
            return isPressed ? OnePlusColor.primaryPressed : isHovered ? OnePlusColor.primaryHover : OnePlusColor.primaryFill
        case .destructive:
            return .clear
        case .resetBlock:
            guard enabled else { return .clear }
            return isPressed ? OnePlusLinearColor.softButtonPressed : isHovered ? OnePlusLinearColor.softButtonHover : .clear
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
            case .raised:
                label.linearText(weight: .medium)
                    .padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.button)
                    .linearRaised(radius: radius)
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
                    .padding(.leading, editorial ? 0 : OnePlusLinearMetrics.appletRowPadding)
                    .frame(maxWidth: .infinity, minHeight: OnePlusLinearMetrics.appletDestructive, alignment: .leading)
            case .resetBlock:
                label.linearText(weight: .medium, color: OnePlusLinearColor.destructiveText)
                    .frame(maxWidth: .infinity, minHeight: OnePlusLinearEditorialMetrics.resetBlock)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius).strokeBorder(OnePlusLinearColor.line, lineWidth: 1)
                    }
            case .plain:
                label
            }
        }
        .background {
            // A selection change crossfades the old and new fills; hover fades with its own timing.
            RoundedRectangle(cornerRadius: radius).fill(fill).linearMotion(OnePlusMotion.selection, value: selected)
        }
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(enabled && (focused || sample == .focus) && OnePlusFocusPolicy.shared.showsFocus ? OnePlusColor.focus : .clear, lineWidth: 1)
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
    func linearRowHover(_ hover: Binding<Bool>, sample: OnePlusControlState, enabled: Bool,
                        fill: Color = OnePlusLinearColor.hover) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(enabled && (hover.wrappedValue || sample == .hover) ? fill : .clear)
            .contentShape(Rectangle())
            .onePlusHover(hover)
    }
}
