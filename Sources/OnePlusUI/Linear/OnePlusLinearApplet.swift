import AppKit
import SwiftUI

/// The v15 applet shell ("Filled groups"): one body-colored surface, a 48 pt title area with no line under it,
/// the traffic lights and title on y 22, trailing actions (the gear, then the primary action), then the body.
/// With a `canvas` it owns the fixed-window chrome (traffic-light placement, size, drag areas). It sets the
/// `.quietRaised` control look unless the host set another one.
public struct OnePlusLinearApplet<Actions: View, Content: View>: View {
    private let title: String
    private let canvas: OnePlusWindowCanvas?
    private let actions: Actions
    private let content: Content
    public init(_ title: String, canvas: OnePlusWindowCanvas? = nil, @ViewBuilder actions: () -> Actions,
                @ViewBuilder content: () -> Content) {
        self.title = title; self.canvas = canvas; self.actions = actions(); self.content = content()
    }
    public var body: some View {
        let shell = VStack(spacing: 0) {
            OnePlusLinearAppletTitlebar(title) { actions }
            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(OnePlusLinearColor.appletWindow)
        .transformEnvironment(\.onePlusLinearControlLook) { if $0 == nil { $0 = .quietRaised } }
        .ignoresSafeArea()
        if let canvas { shell.onePlusFixedCanvas(canvas) } else { shell }
    }
}

/// The 48 pt applet title area. It drags the window and has the body color, with no separator.
public struct OnePlusLinearAppletTitlebar<Actions: View>: View {
    private let title: String
    private let actions: Actions
    @Environment(\.onePlusZoomTrailingX) private var zoomTrailingX
    public init(_ title: String, @ViewBuilder actions: () -> Actions) { self.title = title; self.actions = actions() }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.appletActionGap) {
            Text(title).linearText(weight: .semibold).lineLimit(1).help(title).accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            actions
        }
        .frame(height: OnePlusLinearMetrics.appletButton)
        .padding(.top, OnePlusLinearMetrics.appletCenterline - OnePlusLinearMetrics.appletButton / 2)
        .padding(.leading, OnePlusMetrics.titleStart(afterZoom: zoomTrailingX))
        .padding(.trailing, OnePlusLinearMetrics.appletTitlebarTrailing)
        .frame(height: OnePlusLinearMetrics.appletTitlebar, alignment: .top)
        .background(OnePlusWindowDragArea())
    }
}

/// The titlebar gear: a 24 pt icon button left of the primary action. It toggles Home and Settings,
/// shows the selected fill while Settings is open, and answers Command-comma.
public struct OnePlusLinearAppletSettingsButton: View {
    private let active: Bool
    private let action: () -> Void
    public init(isActive: Bool, action: @escaping () -> Void) { active = isActive; self.action = action }
    public var body: some View {
        let label = active ? "Back to home" : "Settings"
        Button(action: action) {
            Image(systemName: "gearshape").font(.system(size: 13))
                .foregroundStyle(active ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary)
                .frame(width: OnePlusLinearMetrics.appletButton, height: OnePlusLinearMetrics.appletButton)
        }
        .buttonStyle(OnePlusLinearButtonStyle(selected: active))
        .keyboardShortcut(",")
        .help(label).accessibilityLabel(label)
    }
}

/// A scrolling applet body: sections 16 pt apart on a 16 pt gutter, an optional footer (the destructive
/// button) 20 pt below them, and 16 pt below the last item inside the scroll content.
public struct OnePlusLinearAppletForm<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer
    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content(); self.footer = footer()
    }
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: OnePlusLinearMetrics.appletSectionGap) { content }
                if Footer.self != EmptyView.self { footer.padding(.top, OnePlusLinearMetrics.appletFooterGap) }
            }
            .padding(.horizontal, OnePlusLinearMetrics.appletGutter)
            .padding(.bottom, OnePlusLinearMetrics.appletBottom)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onePlusScrollIndicators()
    }
}

public extension OnePlusLinearAppletForm where Footer == EmptyView {
    init(@ViewBuilder content: () -> Content) { self.init(content: content) { EmptyView() } }
}

/// A captioned group: a 12 pt medium caption on the row text edge, 6 pt, then the filled group.
public struct OnePlusLinearAppletSection<Content: View>: View {
    private let title: String
    private let content: Content
    @Environment(\.onePlusLinearEditorial) private var editorial
    public init(_ title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    public var body: some View {
        if editorial {
            VStack(alignment: .leading, spacing: 0) {
                OnePlusLinearEditorialCaption(title: title)
                OnePlusLinearEditorialGroup(content: content, flush: true)
            }
        } else {
            filled
        }
    }
    private var filled: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearMetrics.appletCaptionBelow) {
            Text(title).linearText(OnePlusLinearMetrics.appletCaption, weight: .medium, color: OnePlusLinearColor.appletMuted)
                .frame(height: OnePlusLinearMetrics.appletCaptionHeight)
                .padding(.leading, OnePlusLinearMetrics.appletRowPadding)
                .accessibilityAddTraits(.isHeader)
            OnePlusLinearAppletGroup { content }
        }
    }
}

/// A filled group: no border, 10 pt radius, hairlines between rows that start at the text edge.
public struct OnePlusLinearAppletGroup<Content: View>: View {
    private let content: Content
    @Environment(\.onePlusLinearEditorial) private var editorial
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        if editorial { OnePlusLinearEditorialGroup(content: content, flush: true) } else { filled }
    }
    private var filled: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row.overlay(alignment: .top) {
                        if row.id != rows.first?.id {
                            OnePlusLinearColor.appletLine.frame(height: 1)
                                .padding(.horizontal, OnePlusLinearMetrics.appletRowPadding).allowsHitTesting(false)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(OnePlusLinearColor.appletGroup)
        .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.appletGroupRadius))
    }
}

/// A 36 pt group row: the label and an optional second line lead; the control or value trails.
public struct OnePlusLinearAppletRow<Trailing: View>: View {
    private let label: String
    private let detail: String?
    private let trailing: Trailing
    public init(_ label: String, detail: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.label = label; self.detail = detail; self.trailing = trailing()
    }
    @Environment(\.onePlusLinearEditorial) private var editorial
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.appletRowGap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).linearText().lineLimit(1)
                if let detail {
                    Text(detail).linearText(OnePlusLinearMetrics.control,
                                            color: editorial ? OnePlusLinearColor.secondary : OnePlusLinearColor.appletSecondary).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, OnePlusLinearMetrics.appletRowPadding)
        .padding(.vertical, detail == nil ? 0 : 8)
        .frame(minHeight: editorial ? OnePlusLinearEditorialMetrics.row : OnePlusLinearMetrics.appletRow)
        .accessibilityElement(children: .contain)
    }
}

public extension OnePlusLinearAppletRow where Trailing == Text {
    /// A label and a read-only value.
    init(_ label: String, value: String) {
        self.init(label) {
            Text(value).font(.system(size: OnePlusLinearMetrics.body)).tracking(OnePlusLinearMetrics.bodyTracking)
                .monospacedDigit().foregroundStyle(OnePlusLinearColor.appletSecondary)
        }
    }
}

/// A slider row: the label, a 150 pt slider, and the live value right-aligned in a 36 pt column.
/// The number changes at once; only the knob moves.
public struct OnePlusLinearAppletSliderRow: View {
    private let label: String
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let format: (Double) -> String
    @Environment(\.onePlusLinearControlLook) private var look
    public init(_ label: String, value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01,
                format: @escaping (Double) -> String = { "\(Int(($0 * 100).rounded()))%" }) {
        self.label = label; _value = value; self.range = range; self.step = step; self.format = format
    }
    public var body: some View {
        OnePlusLinearAppletRow(label) {
            HStack(spacing: 8) {
                OnePlusLinearSlider(label, value: $value, in: range, step: step)
                Text(format(value)).linearText(color: OnePlusLinearColor.appletSecondary).lineLimit(1)
                    .frame(width: (look ?? .quietRaised).sliderValueWidth, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A list row in a filled group: leading swatch or icon, the title, trailing metadata, and trailing icon actions.
/// Hover fills the whole row.
public struct OnePlusLinearAppletListRow<Leading: View>: View {
    private let title: String
    private let monospaced: Bool
    private let metadata: String?
    private let actions: [OnePlusLinearAction]
    private let leading: Leading
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    public init(_ title: String, monospaced: Bool = false, metadata: String? = nil, actions: [OnePlusLinearAction] = [],
                @ViewBuilder leading: () -> Leading) {
        self.title = title; self.monospaced = monospaced; self.metadata = metadata; self.actions = actions; self.leading = leading()
    }
    public var body: some View {
        HStack(spacing: 0) {
            leading.padding(.trailing, OnePlusLinearMetrics.appletRowGap)
            Group {
                if monospaced {
                    Text(title).font(.system(size: OnePlusLinearMetrics.body, design: .monospaced)).foregroundStyle(OnePlusLinearColor.ink)
                } else {
                    Text(title).linearText()
                }
            }
            .lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
            if let metadata {
                Text(metadata).linearText(color: OnePlusLinearColor.appletMuted).lineLimit(1).fixedSize()
                    .padding(.leading, OnePlusLinearMetrics.appletRowGap)
            }
            if !actions.isEmpty {
                HStack(spacing: 2) {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            Image(systemName: action.systemImage).font(.system(size: 11))
                                .foregroundStyle(OnePlusLinearColor.appletMuted)
                                .frame(width: OnePlusLinearMetrics.appletRowAction, height: OnePlusLinearMetrics.appletRowAction)
                        }
                        .buttonStyle(OnePlusLinearButtonStyle())
                        .help(action.title).accessibilityLabel(action.title)
                    }
                }
                .padding(.leading, OnePlusLinearMetrics.appletRowActionsGap)
            }
        }
        .padding(.leading, OnePlusLinearMetrics.appletRowPadding)
        .padding(.trailing, actions.isEmpty ? OnePlusLinearMetrics.appletRowPadding : OnePlusLinearMetrics.appletRowActionsTrailing)
        .frame(height: OnePlusLinearMetrics.appletRow)
        .linearRowHover($hover, sample: sample, enabled: enabled)
        .accessibilityElement(children: .contain)
    }
}

/// A 20 pt color swatch with a hairline ring, for applet list rows.
public struct OnePlusLinearSwatch: View {
    private let color: Color
    public init(_ color: Color) { self.color = color }
    public var body: some View {
        RoundedRectangle(cornerRadius: 5).fill(color)
            .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(OnePlusLinearColor.iconOutline, lineWidth: 1) }
            .frame(width: OnePlusLinearMetrics.appletSwatch, height: OnePlusLinearMetrics.appletSwatch)
            .accessibilityHidden(true)
    }
}

/// The applet tab row: Linear text tabs with counts and the 2 pt accent underline on its bottom line,
/// and a trailing control (a text select). 32 pt including the line, on the 16 pt gutter.
public struct OnePlusLinearAppletTabRow<Value: Hashable, Trailing: View>: View {
    private let tabs: [OnePlusTab<Value>]
    @Binding private var selection: Value
    private let trailing: Trailing
    public init(tabs: [OnePlusTab<Value>], selection: Binding<Value>, @ViewBuilder trailing: () -> Trailing) {
        self.tabs = tabs; _selection = selection; self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 12) {
            OnePlusLinearTextTabs(tabs: tabs, selection: $selection)
            Spacer(minLength: 0)
            trailing
        }
        .frame(height: OnePlusLinearMetrics.appletTabStrip - 1)
        .padding(.bottom, 1)
        .background(alignment: .bottom) { OnePlusLinearColor.appletLine.frame(height: 1) }
        .padding(.horizontal, OnePlusLinearMetrics.appletGutter)
    }
}

public extension OnePlusLinearAppletTabRow where Trailing == EmptyView {
    init(tabs: [OnePlusTab<Value>], selection: Binding<Value>) { self.init(tabs: tabs, selection: selection) { EmptyView() } }
}

/// A fixed applet toolbar row (search and a select) 12 pt below the tabs, on the 16 pt gutter, 8 pt gaps.
public struct OnePlusLinearAppletToolbar<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.appletActionGap) { content }
            .padding(.horizontal, OnePlusLinearMetrics.appletGutter)
            .padding(.vertical, OnePlusLinearMetrics.appletToolbarGap)
    }
}
