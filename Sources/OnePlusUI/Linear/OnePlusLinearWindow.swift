import AppKit
import SwiftUI

/// The v15 main-window sidebar: 215 pt, sidebar fill, trailing line, search below the traffic lights,
/// a scrolling navigation list, and a bottom group (Settings, Exit).
public struct OnePlusLinearSidebar<Search: View, Navigation: View, Bottom: View>: View {
    private let search: Search
    private let navigation: Navigation
    private let bottom: Bottom
    public init(@ViewBuilder search: () -> Search, @ViewBuilder navigation: () -> Navigation, @ViewBuilder bottom: () -> Bottom) {
        self.search = search(); self.navigation = navigation(); self.bottom = bottom()
    }
    public var body: some View {
        VStack(spacing: 0) {
            OnePlusWindowDragArea().frame(height: OnePlusLinearMetrics.sidebarTop)
            search.padding(.horizontal, OnePlusLinearMetrics.sidebarInset).padding(.bottom, OnePlusLinearMetrics.searchBelow)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) { navigation }
                    .padding(.horizontal, OnePlusLinearMetrics.sidebarInset).frame(maxWidth: .infinity, alignment: .leading)
            }.onePlusScrollIndicators()
            VStack(alignment: .leading, spacing: 0) { bottom }
                .padding(.horizontal, OnePlusLinearMetrics.sidebarInset).padding(.top, OnePlusLinearMetrics.navCaption)
                .padding(.bottom, 20)
        }
        .frame(width: OnePlusLinearMetrics.sidebarWidth)
        .background(OnePlusLinearColor.sidebar)
        .overlay(alignment: .trailing) { OnePlusLinearColor.line.frame(width: 1) }
        .accessibilityElement(children: .contain)
    }
}

/// A 28 pt sidebar row: 16 pt tool icon or 14 pt glyph, 13 pt label, optional trailing count or shortcut hint.
/// `dimmed` shows a disabled destination's name in `muted`; the row stays clickable.
public struct OnePlusLinearNavRow: View {
    private let title: String
    private let image: Image?
    private let systemImage: String?
    private let selected: Bool
    private let shortcut: String?
    private let count: Int?
    private let dimmed: Bool
    private let action: () -> Void
    private enum GlyphMode { case artwork, template, symbol }
    private var glyphMode = GlyphMode.artwork
    private var glyphColor: Color {
        selected ? OnePlusLinearColor.ink : dimmed ? OnePlusLinearColor.muted : OnePlusLinearColor.secondary
    }
    /// A tool row with its own icon artwork. `dimmed` marks a disabled tool.
    public init(_ title: String, image: Image, selected: Bool = false, dimmed: Bool = false, count: Int? = nil,
                action: @escaping () -> Void) {
        self.title = title; self.image = image; systemImage = nil; self.selected = selected
        shortcut = nil; self.count = count; self.dimmed = dimmed; self.action = action
    }
    /// A monochrome glyph row: a template glyph in `secondary`, `ink` when selected, never clipped.
    /// Pass `Image(systemName:)` for an SF Symbol; it draws at 13 pt medium in the 16 pt slot.
    public init(_ title: String, glyph: Image, symbol: Bool = false, selected: Bool = false, dimmed: Bool = false,
                shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title; image = glyph; systemImage = nil; self.selected = selected
        self.shortcut = shortcut; count = nil; self.dimmed = dimmed; self.action = action
        glyphMode = symbol ? .symbol : .template
    }
    /// A glyph row such as Settings (`⌘,`) or Exit (`⌘Q`), or a page with a trailing count.
    public init(_ title: String, systemImage: String, selected: Bool = false, dimmed: Bool = false, count: Int? = nil,
                shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title; image = nil; self.systemImage = systemImage; self.selected = selected
        self.shortcut = shortcut; self.count = count; self.dimmed = dimmed; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: OnePlusLinearMetrics.navIconGap) {
                Group {
                    if let image, glyphMode == .template {
                        image.renderingMode(.template).resizable().scaledToFit().foregroundStyle(glyphColor)
                    } else if let image, glyphMode == .symbol {
                        image.font(.system(size: 13, weight: .medium)).foregroundStyle(glyphColor)
                    } else if let image {
                        image.resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.navIcon * 0.22))
                    } else if let systemImage {
                        Image(systemName: systemImage).font(.system(size: 13))
                            .foregroundStyle(selected ? OnePlusLinearColor.accent : OnePlusLinearColor.muted)
                    }
                }
                .frame(width: OnePlusLinearMetrics.navIcon, height: OnePlusLinearMetrics.navIcon)
                Text(title).linearText(weight: selected ? .medium : .regular,
                                       color: selected ? OnePlusLinearColor.ink : dimmed ? OnePlusLinearColor.muted : OnePlusLinearColor.secondary)
                    .lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 0)
                if let count {
                    Text("\(count)").linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.muted).fixedSize()
                }
                if let shortcut {
                    Text(shortcut).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.muted).accessibilityHidden(true)
                }
            }
            .padding(.horizontal, OnePlusLinearMetrics.navPadding)
            .frame(height: OnePlusLinearMetrics.navRow)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(OnePlusLinearButtonStyle(selected: selected)).focusEffectDisabled()
        .help(title)
        .accessibilityLabel(title)
        .accessibilityValue(count.map(String.init) ?? "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// A sidebar group caption: 28 pt slot with 6 pt above the text, 11.5 pt medium.
public struct OnePlusLinearNavCaption: View {
    private let title: String
    private let count: Int?
    public init(_ title: String, count: Int? = nil) { self.title = title; self.count = count }
    public var body: some View {
        HStack(spacing: 6) {
            Text(title).linearText(OnePlusLinearMetrics.sectionCaption, weight: .medium, color: OnePlusLinearColor.muted)
            Spacer(minLength: 0)
            if let count { Text("\(count)").linearText(OnePlusLinearMetrics.sectionCaption, color: OnePlusLinearColor.muted) }
        }
        .padding(.horizontal, OnePlusLinearMetrics.navPadding)
        .padding(.top, OnePlusLinearMetrics.navCaptionTop)
        .frame(height: OnePlusLinearMetrics.navCaption)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The 44 pt pane toolbar: back and forward, the page title, and trailing content (usually text tabs).
/// Without navigation the title starts on the 24 pt content gutter.
public struct OnePlusLinearPaneToolbar<Trailing: View>: View {
    private let title: String
    private let canGoBack: Bool
    private let canGoForward: Bool
    private let back: (() -> Void)?
    private let forward: (() -> Void)?
    private let trailing: Trailing
    public init(title: String, canGoBack: Bool, canGoForward: Bool, back: @escaping () -> Void, forward: @escaping () -> Void,
                @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.canGoBack = canGoBack; self.canGoForward = canGoForward
        self.back = back; self.forward = forward; self.trailing = trailing()
    }
    /// A toolbar with no back and forward buttons.
    public init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; canGoBack = false; canGoForward = false; back = nil; forward = nil; self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 8) {
            if let back, let forward {
                HStack(spacing: 4) {
                    OnePlusLinearIconButton(systemImage: "chevron.left", help: "Back", size: OnePlusLinearMetrics.toolbarButton, action: back)
                        .disabled(!canGoBack).keyboardShortcut("[")
                    OnePlusLinearIconButton(systemImage: "chevron.right", help: "Forward", size: OnePlusLinearMetrics.toolbarButton, action: forward)
                        .disabled(!canGoForward).keyboardShortcut("]")
                }
            }
            Text(title).linearText(weight: .semibold).lineLimit(1).accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            // The tool page Enabled switch is the same Quiet Raised switch as the page's settings.
            trailing.frame(maxHeight: .infinity)
                .transformEnvironment(\.onePlusLinearControlLook) { if $0 == nil { $0 = .quietRaised } }
        }
        .padding(.leading, back == nil ? OnePlusLinearMetrics.gutter : OnePlusLinearMetrics.toolbarLeading)
        .padding(.trailing, OnePlusLinearMetrics.toolbarTrailing)
        .frame(height: OnePlusLinearMetrics.toolbar - 1)
        .background(OnePlusWindowDragArea())
        .padding(.bottom, 1)
        .background(alignment: .bottom) { OnePlusLinearColor.line.frame(height: 1) }
    }
}

public extension OnePlusLinearPaneToolbar where Trailing == EmptyView {
    init(title: String, canGoBack: Bool, canGoForward: Bool, back: @escaping () -> Void, forward: @escaping () -> Void) {
        self.init(title: title, canGoBack: canGoBack, canGoForward: canGoForward, back: back, forward: forward) { EmptyView() }
    }
    init(title: String) { self.init(title: title) { EmptyView() } }
}

/// Text tabs with counts for the pane toolbar. The selected tab draws the 2 pt accent underline on the
/// toolbar's bottom line, across the whole padded tab. Selection changes only color and the underline.
/// The last tab's padded box ends on the trailing content inset.
public struct OnePlusLinearTextTabs<Value: Hashable>: View {
    private let tabs: [OnePlusTab<Value>]
    @Binding private var selection: Value
    public init(tabs: [OnePlusTab<Value>], selection: Binding<Value>) { self.tabs = tabs; _selection = selection }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.tabGap - 2 * OnePlusLinearMetrics.tabPadding) {
            ForEach(tabs) { tab in
                OnePlusLinearTextTab(tab: tab, selected: tab.id == selection) { selection = tab.id }
                    .anchorPreference(key: OnePlusLinearTabBounds.self, value: .bounds) { [AnyHashable(tab.id): $0] }
            }
        }
        .overlayPreferenceValue(OnePlusLinearTabBounds.self) { tabs in
            // One underline slides to the selected tab.
            GeometryReader { proxy in
                if let anchor = tabs[AnyHashable(selection)] {
                    let tab = proxy[anchor]
                    RoundedRectangle(cornerRadius: 1).fill(OnePlusLinearColor.accent)
                        .frame(width: tab.width, height: OnePlusLinearMetrics.tabUnderline)
                        .offset(x: tab.minX, y: tab.maxY + 1 - OnePlusLinearMetrics.tabUnderline)
                }
            }
            .linearMotion(OnePlusMotion.tabSlide, value: selection)
            .allowsHitTesting(false).accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            if let next = OnePlusSegmented<Value>.nextSelection(in: tabs.map(\.id), current: selection,
                                                              direction: press.key == .leftArrow ? -1 : 1) { selection = next }
            return .handled
        }
    }
}

private struct OnePlusLinearTabBounds: PreferenceKey {
    static var defaultValue: [AnyHashable: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [AnyHashable: Anchor<CGRect>], nextValue: () -> [AnyHashable: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct OnePlusLinearTextTab<Value: Hashable>: View {
    let tab: OnePlusTab<Value>
    let selected: Bool
    let action: () -> Void
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    var body: some View {
        Button(action: action) {
            HStack(spacing: OnePlusLinearMetrics.tabCountGap) {
                Text(tab.title).linearText(color: selected || hover || sample == .hover ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                if let count = tab.count {
                    Text("\(count)").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted)
                }
            }
            .padding(.horizontal, OnePlusLinearMetrics.tabPadding)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onePlusHover($hover)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .accessibilityLabel(tab.count.map { "\(tab.title), \($0)" } ?? tab.title)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// A body section caption with a count, 20 pt high, 11.5 pt medium.
public struct OnePlusLinearSectionCaption: View {
    private let title: String
    private let count: Int?
    public init(_ title: String, count: Int? = nil) { self.title = title; self.count = count }
    public var body: some View {
        HStack(spacing: 6) {
            Text(title).linearText(OnePlusLinearMetrics.sectionCaption, weight: .medium, color: OnePlusLinearColor.muted)
            if let count { Text("\(count)").linearText(OnePlusLinearMetrics.sectionCaption, color: OnePlusLinearColor.muted) }
            Spacer(minLength: 0)
        }
        .frame(height: OnePlusLinearMetrics.sectionCaptionHeight)
        .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
    }
}

/// A captioned section: caption, 6 pt gap, then a window-style list of rows.
public struct OnePlusLinearSection<Content: View>: View {
    private let title: String
    private let count: Int?
    private let content: Content
    public init(_ title: String, count: Int? = nil, @ViewBuilder content: () -> Content) {
        self.title = title; self.count = count; self.content = content()
    }
    @Environment(\.onePlusLinearEditorial) private var editorial
    public var body: some View {
        if editorial {
            VStack(alignment: .leading, spacing: 0) {
                OnePlusLinearEditorialCaption(title: title)
                OnePlusLinearEditorialGroup(content: content)
            }
        } else {
            VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionCaptionBelow) {
                OnePlusLinearSectionCaption(title, count: count)
                OnePlusLinearList(style: .window) { content }
            }
        }
    }
}

/// The scrolling pane body: 14 pt top, 24 pt gutters, 16 pt between sections, 16 pt bottom inside the scroll.
public struct OnePlusLinearPaneBody<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionGap) { content }
                .padding(.top, OnePlusLinearMetrics.bodyTop)
                .padding(.horizontal, OnePlusLinearMetrics.gutter)
                .padding(.bottom, OnePlusLinearMetrics.sectionGap)
        }.onePlusScrollIndicators()
    }
}

/// A 36 pt tool row: 20 pt icon, name, one-line summary, favorite star, enable switch, chevron.
/// The whole row opens the tool. The star paints on hover, keyboard focus, or when set; at rest it stays
/// an unpainted "Favorite" toggle for VoiceOver and Full Keyboard Access.
public struct OnePlusLinearToolRow: View {
    private let name: String
    private let summary: String
    private let icon: Image
    @Binding private var isEnabled: Bool
    private let isFavorite: Binding<Bool>?
    private let open: () -> Void
    @State private var hover = false
    @FocusState private var starFocused: Bool
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var interactive

    public init(_ name: String, summary: String, icon: Image, isEnabled: Binding<Bool>, isFavorite: Binding<Bool>? = nil,
                open: @escaping () -> Void) {
        self.name = name; self.summary = summary; self.icon = icon
        _isEnabled = isEnabled; self.isFavorite = isFavorite; self.open = open
    }

    private var hovering: Bool { interactive && (hover || sample == .hover) }

    public var body: some View {
        ZStack {
            Button(action: open) { Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity) }
                .buttonStyle(.plain).focusEffectDisabled()
                .accessibilityLabel("Open \(name)")
            HStack(spacing: OnePlusLinearMetrics.toolRowGap) {
                icon.resizable().scaledToFit()
                    .frame(width: OnePlusLinearMetrics.toolIcon, height: OnePlusLinearMetrics.toolIcon)
                    .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.toolIcon * 0.21875))
                    .opacity(isEnabled ? 1 : 0.6)
                    .allowsHitTesting(false).accessibilityHidden(true)
                Text(name).linearText(weight: .medium, color: isEnabled ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                    .lineLimit(1).frame(width: OnePlusLinearMetrics.toolNameWidth, alignment: .leading)
                    .allowsHitTesting(false)
                Text(summary).linearText(color: OnePlusLinearColor.secondary).lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading).allowsHitTesting(false)
                star
                Toggle("Enable \(name)", isOn: $isEnabled).toggleStyle(OnePlusLinearSwitchStyle())
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OnePlusLinearColor.tertiary).allowsHitTesting(false).accessibilityHidden(true)
            }
            .padding(.horizontal, OnePlusLinearMetrics.toolRowPadding)
        }
        .frame(height: OnePlusLinearMetrics.toolRow)
        .background(hovering ? OnePlusLinearColor.hover : .clear)
        .contentShape(Rectangle())
        .onePlusHover($hover)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(name), \(summary)")
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
            .focusEffectDisabled()            .help(set ? "Remove from Favorites" : "Add to Favorites")
            .accessibilityLabel("Favorite")
            .accessibilityValue(set ? "On" : "Off")
            .accessibilityAddTraits(.isToggle)
        } else {
            Color.clear.frame(width: OnePlusLinearMetrics.starSlot, height: OnePlusLinearMetrics.starSlot)
        }
    }
}
