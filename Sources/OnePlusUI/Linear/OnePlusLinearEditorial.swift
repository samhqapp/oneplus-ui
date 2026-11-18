import SwiftUI

/// The "Editorial list" look for main-window pages: no list fill or ring, a `line` hairline on top of each
/// group, a `lineSoft` hairline under each row, and semibold ink captions. Set by `OnePlusLinearEditorialBody`;
/// applet sections, groups, rows, and Linear sections read it, so settings views restyle without local changes.
public extension EnvironmentValues {
    @Entry var onePlusLinearEditorial = false
}

public enum OnePlusLinearEditorialMetrics {
    public static let bodyTop: CGFloat = 20
    public static let gutter: CGFloat = 32
    public static let bottom: CGFloat = 24
    public static let blockGap: CGFloat = 20
    public static let captionPadding: CGFloat = 8
    public static let row: CGFloat = 40
    public static let toolRow: CGFloat = 48
    public static let toolRowInset: CGFloat = 4
    public static let toolIcon: CGFloat = 24
    public static let headerIcon: CGFloat = 56
    public static let headerGap: CGFloat = 16
    public static let title: CGFloat = 24
    public static let titleTracking: CGFloat = -0.6
    public static let titleGap: CGFloat = 4
    public static let disabledIconOpacity: Double = 0.45
}

/// The scrolling editorial body: 20 pt top, 32 pt gutters, blocks 20 pt apart, 24 pt bottom inside the scroll.
/// A `footer` (How to use) ends the page: on a short page the free space sits above it, on a long page it
/// follows the content.
public struct OnePlusLinearEditorialBody<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer
    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content(); self.footer = footer()
    }
    public var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.blockGap) { content }
                    if Footer.self != EmptyView.self {
                        Spacer(minLength: OnePlusLinearEditorialMetrics.blockGap)
                        footer
                    }
                }
                .padding(.top, OnePlusLinearEditorialMetrics.bodyTop)
                .padding(.horizontal, OnePlusLinearEditorialMetrics.gutter)
                .padding(.bottom, OnePlusLinearEditorialMetrics.bottom)
                .frame(maxWidth: .infinity, minHeight: viewport.size.height, alignment: .topLeading)
            }
            .onePlusScrollIndicators()
        }
        .environment(\.onePlusLinearEditorial, true)
    }
}

public extension OnePlusLinearEditorialBody where Footer == EmptyView {
    init(@ViewBuilder content: () -> Content) { self.init(content: content) { EmptyView() } }
}

/// The large page title: 24 pt semibold ink, then an optional subtitle in `secondary`, 4 pt apart.
public struct OnePlusLinearPageTitle: View {
    private let title: String
    private let subtitle: String?
    public init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    public var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.titleGap) {
            Text(title).font(.system(size: OnePlusLinearEditorialMetrics.title, weight: .semibold))
                .tracking(OnePlusLinearEditorialMetrics.titleTracking).foregroundStyle(OnePlusLinearColor.ink)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).linearText(color: OnePlusLinearColor.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The editorial tool page header: the 56 pt icon, the large title and description, then trailing actions.
public struct OnePlusLinearToolHeader<Icon: View, Actions: View>: View {
    private let title: String
    private let detail: String
    private let icon: Icon
    private let actions: Actions
    public init(_ title: String, detail: String, @ViewBuilder icon: () -> Icon, @ViewBuilder actions: () -> Actions) {
        self.title = title; self.detail = detail; self.icon = icon(); self.actions = actions()
    }
    public var body: some View {
        HStack(alignment: .center, spacing: OnePlusLinearEditorialMetrics.headerGap) {
            icon.frame(width: OnePlusLinearEditorialMetrics.headerIcon, height: OnePlusLinearEditorialMetrics.headerIcon)
                .accessibilityHidden(true)
            OnePlusLinearPageTitle(title, subtitle: detail).frame(maxWidth: .infinity, alignment: .leading)
            actions
        }
    }
}

/// The editorial caption above a group: 13 pt semibold ink with 8 pt above and below.
struct OnePlusLinearEditorialCaption: View {
    let title: String
    var body: some View {
        Text(title).linearText(weight: .semibold)
            .padding(.vertical, OnePlusLinearEditorialMetrics.captionPadding)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The editorial group: no fill or ring, a `line` hairline on top, a `lineSoft` hairline under each row. `flush` cancels the applet row padding, so setting rows start on the page's one leading edge
/// (the header and caption edge); hover rows (tool rows) keep their own inset.
struct OnePlusLinearEditorialGroup<Content: View>: View {
    let content: Content
    var flush = false
    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row.padding(.horizontal, flush ? -OnePlusLinearMetrics.appletRowPadding : 0)
                        .overlay(alignment: .bottom) {
                            OnePlusLinearColor.lineSoft.frame(height: 1).allowsHitTesting(false)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) { OnePlusLinearColor.line.frame(height: 1).allowsHitTesting(false) }
    }
}

/// The 48 pt editorial tool row: 24 pt icon, the name over a one-line summary, then a quiet "Off" word for a
/// tool that is off, the favorite star slot, and a chevron. The star slot sits at one x on every row. The whole
/// row opens the tool. The star paints on hover, keyboard focus, or when set.
public struct OnePlusLinearEditorialToolRow: View {
    private let name: String
    private let summary: String
    private let icon: Image
    private let isOn: Bool
    private let isFavorite: Binding<Bool>?
    private let open: () -> Void
    @State private var hover = false
    @FocusState private var starFocused: Bool
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var interactive
    public init(_ name: String, summary: String, icon: Image, isOn: Bool, isFavorite: Binding<Bool>? = nil,
                open: @escaping () -> Void) {
        self.name = name; self.summary = summary; self.icon = icon; self.isOn = isOn
        self.isFavorite = isFavorite; self.open = open
    }
    private var hovering: Bool { interactive && (hover || sample == .hover) }
    public var body: some View {
        ZStack {
            Button(action: open) { Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity) }
                .buttonStyle(.plain).focusEffectDisabled(!OnePlusFocusPolicy.shared.showsFocus)
                .accessibilityLabel("Open \(name)")
            HStack(spacing: OnePlusLinearMetrics.toolRowGap) {
                icon.resizable().scaledToFit()
                    .frame(width: OnePlusLinearEditorialMetrics.toolIcon, height: OnePlusLinearEditorialMetrics.toolIcon)
                    .opacity(isOn ? 1 : OnePlusLinearEditorialMetrics.disabledIconOpacity)
                    .allowsHitTesting(false).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).linearText(weight: .medium, color: isOn ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                    Text(summary).linearText(OnePlusLinearMetrics.caption, color: isOn ? OnePlusLinearColor.secondary : OnePlusLinearColor.muted)
                }
                .lineLimit(1).truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading).allowsHitTesting(false)
                if !isOn {
                    Text("Off").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted).allowsHitTesting(false)
                }
                star
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OnePlusLinearColor.tertiary).allowsHitTesting(false).accessibilityHidden(true)
            }
            .padding(.horizontal, OnePlusLinearEditorialMetrics.toolRowInset)
        }
        .frame(height: OnePlusLinearEditorialMetrics.toolRow)
        .background(hovering ? OnePlusLinearColor.hover : .clear)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isOn ? "\(name), \(summary)" : "\(name), off, \(summary)")
    }

    @ViewBuilder private var star: some View {
        if let isFavorite {
            let set = isFavorite.wrappedValue
            // Hide only the glyph paint: an opacity-0 button leaves the accessibility tree and keyboard focus loop.
            let visible = set || hovering || starFocused
            Button { isFavorite.wrappedValue.toggle() } label: {
                Image(systemName: set ? "star.fill" : "star").font(.system(size: 11))
                    .foregroundStyle(!visible ? Color.clear : set ? OnePlusLinearColor.accent : OnePlusLinearColor.muted)
                    .frame(width: OnePlusLinearMetrics.starSlot, height: OnePlusLinearMetrics.starSlot)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain).focused($starFocused)
            .focusEffectDisabled(!OnePlusFocusPolicy.shared.showsFocus)
            .help(set ? "Remove from Favorites" : "Add to Favorites")
            .accessibilityLabel("Favorite").accessibilityValue(set ? "On" : "Off").accessibilityAddTraits(.isToggle)
        } else {
            Color.clear.frame(width: OnePlusLinearMetrics.starSlot, height: OnePlusLinearMetrics.starSlot)
        }
    }
}
