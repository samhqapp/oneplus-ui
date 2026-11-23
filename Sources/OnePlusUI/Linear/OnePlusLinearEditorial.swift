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
    /// The tool row hover fill: radius 8, 4 pt past the row sides (8 pt past the content), 2 pt inside the
    /// row top and bottom, so two rows' fills never touch and the separator sits in the gap.
    public static let toolRowHoverOutset: CGFloat = 4
    public static let toolRowHoverInset: CGFloat = 2
    public static let toolRowHoverRadius: CGFloat = 8
    /// The key chip (`OnePlusLinearKeyChip`), drawn like the sidebar search `⌘K` chip.
    public static let keyChipHeight: CGFloat = 18
    public static let keyChipPadding: CGFloat = 5
    public static let keyChipRadius: CGFloat = 4
    /// Editorial hairlines fade to clear over this share of their width at each end.
    public static let hairlineFade: CGFloat = 0.12
    public static let toolIcon: CGFloat = 24
    public static let headerIcon: CGFloat = 56
    public static let headerGap: CGFloat = 16
    public static let title: CGFloat = 24
    public static let titleTracking: CGFloat = -0.6
    public static let titleGap: CGFloat = 4
    public static let disabledIconOpacity: Double = 0.45
    /// The tool page header ("Icon beside the title"): a 48 pt icon 16 pt left of the title
    /// and a description of at most 2 lines, top-aligned with the Open tile 20 pt to the right.
    public static let headerTileIcon: CGFloat = 48
    public static let headerDetailLines = 2
    public static let headerTileGap: CGFloat = 20
    public static let launchTile = CGSize(width: 176, height: 108)
    public static let launchTileRadius: CGFloat = 12
    public static let launchTilePadding: CGFloat = 14
    /// The shortcut key caps draw 1.2 times their 20 pt size, 6 pt above the action name.
    public static let launchTileKeyScale: CGFloat = 1.2
    public static let launchTileKeyGap: CGFloat = 6
    public static let launchTileName: CGFloat = 20
    /// The reset block (`OnePlusLinearButtonStyle(.resetBlock)`): one full-width inset row, 40 pt, radius 10.
    public static let resetBlock: CGFloat = 40
    public static let resetBlockRadius: CGFloat = OnePlusLinearMetrics.appletGroupRadius
    /// "Inset, gray glyphs": a 13 pt glyph in a 20 pt slot; the separator starts after the slot and the row padding.
    public static let rowGlyph: CGFloat = 20
    public static let rowGlyphSize: CGFloat = 13
    static var rowGlyphSlot: CGFloat { rowGlyph + OnePlusLinearMetrics.appletRowPadding }
    /// The panel row mark: radius 6, 4 pt inside the group sides, a 2 pt dotted line at 40%, a fill at 5%.
    public static let rowMarkRadius: CGFloat = 6
    public static let rowMarkInset: CGFloat = 4
    public static let rowMarkLine = 0.4
    public static let rowMarkFill = 0.05
    public static let rowMarkDash: [CGFloat] = [2, 2]
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
        .transformEnvironment(\.onePlusLinearControlLook) { if $0 == nil { $0 = .raisedKeys } }
    }
}

public extension OnePlusLinearEditorialBody where Footer == EmptyView {
    init(@ViewBuilder content: () -> Content) { self.init(content: content) { EmptyView() } }
}

/// The large page title: 24 pt semibold ink, then an optional subtitle in `secondary`, 4 pt apart.
public struct OnePlusLinearPageTitle: View {
    private let title: String
    private let subtitle: String?
    private let subtitleLines: Int?
    public init(_ title: String, subtitle: String? = nil, subtitleLines: Int? = nil) {
        self.title = title; self.subtitle = subtitle; self.subtitleLines = subtitleLines
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.titleGap) {
            Text(title).font(.system(size: OnePlusLinearEditorialMetrics.title, weight: .semibold))
                .tracking(OnePlusLinearEditorialMetrics.titleTracking).foregroundStyle(OnePlusLinearColor.ink)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).linearText(color: OnePlusLinearColor.secondary).lineLimit(subtitleLines).truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The editorial tool page header, "Icon beside the title": the 48 pt icon, then the large title over a description
/// of at most 2 lines, all top-aligned with the trailing actions (an `OnePlusLinearLaunchTile`, or nothing).
public struct OnePlusLinearToolHeader<Icon: View, Actions: View>: View {
    private let title: String
    private let detail: String
    private let icon: Icon
    private let actions: Actions
    public init(_ title: String, detail: String, @ViewBuilder icon: () -> Icon, @ViewBuilder actions: () -> Actions) {
        self.title = title; self.detail = detail; self.icon = icon(); self.actions = actions()
    }
    public var body: some View {
        HStack(alignment: .top, spacing: OnePlusLinearEditorialMetrics.headerTileGap) {
            HStack(alignment: .top, spacing: OnePlusLinearEditorialMetrics.headerGap) {
                icon.frame(width: OnePlusLinearEditorialMetrics.headerTileIcon, height: OnePlusLinearEditorialMetrics.headerTileIcon)
                    .accessibilityHidden(true)
                OnePlusLinearPageTitle(title, subtitle: detail, subtitleLines: OnePlusLinearEditorialMetrics.headerDetailLines)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            actions
        }
    }
}

/// The "Key tile" of the tool page header: a large raised key with "Open" and an arrow on
/// top, then the tool's global shortcut as key caps over its action name. With no shortcut, the tool name sits at
/// the bottom in 20 pt semibold.
public struct OnePlusLinearLaunchTile: View {
    private let shortcut: String?
    private let caption: String
    private let name: String?
    private let action: () -> Void
    public init(shortcut: String?, caption: String, name: String? = nil, action: @escaping () -> Void) {
        self.shortcut = shortcut; self.caption = caption; self.name = name; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Open").linearText(weight: .semibold, color: OnePlusLinearColor.softKeyInk)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(OnePlusLinearColor.softKeyInk).accessibilityHidden(true)
                }
                Spacer(minLength: 0)
                if let shortcut {
                    OnePlusLinearKeyCombo(shortcut)
                        .scaleEffect(OnePlusLinearEditorialMetrics.launchTileKeyScale, anchor: .bottomLeading)
                        .padding(.bottom, OnePlusLinearEditorialMetrics.launchTileKeyGap)
                    Text(caption).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.secondary).lineLimit(1)
                } else {
                    Text(name ?? caption).font(.system(size: OnePlusLinearEditorialMetrics.launchTileName, weight: .semibold))
                        .foregroundStyle(OnePlusLinearColor.softKeyInk).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }
        .buttonStyle(OnePlusLinearLaunchTileStyle())
        .accessibilityLabel(caption)
        .accessibilityHint(shortcut.map { "Shortcut \($0)" } ?? "")
    }
}

private struct OnePlusLinearLaunchTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OnePlusLinearLaunchTileBody(label: configuration.label, pressed: configuration.isPressed)
    }
}

/// The raised key with paint-only hover and press, in every motion style: nothing moves or scales.
private struct OnePlusLinearLaunchTileBody<Label: View>: View {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.onePlusLinearMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hover = false
    let label: Label
    let pressed: Bool
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusLinearEditorialMetrics.launchTileRadius)
        let hovering = enabled && (hover || sample == .hover)
        let isPressed = enabled && (pressed || sample == .pressed)
        label.padding(OnePlusLinearEditorialMetrics.launchTilePadding)
            .frame(width: OnePlusLinearEditorialMetrics.launchTile.width, height: OnePlusLinearEditorialMetrics.launchTile.height)
            .background {
                OnePlusRaisedKey(shape: shape)
                    .overlay { shape.fill(isPressed ? OnePlusLinearColor.pressed : hovering ? OnePlusLinearColor.hover : .clear) }
            }
            .overlay { OnePlusQuietFocusFill(shape: shape, focused: enabled && focused) }
            .animation(OnePlusMotion.resolved(hovering ? OnePlusMotion.hoverIn : OnePlusMotion.hoverOut, style: motion, reduceMotion: reduceMotion),
                       value: hovering)
            .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
            .contentShape(shape)
            .onHover { hover = $0 }
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

/// The editorial group: no fill or ring, a `line` hairline on top, a `lineSoft` hairline between rows and none
/// under the last. Both hairlines fade out at their ends. Used by the All tools list; settings use the inset group.
struct OnePlusLinearEditorialGroup<Content: View>: View {
    let content: Content
    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row.overlay(alignment: .bottom) {
                        if row.id != rows.last?.id { OnePlusLinearFadedHairline(OnePlusLinearColor.lineSoft) }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) { OnePlusLinearFadedHairline(OnePlusLinearColor.line) }
    }
}

extension ContainerValues {
    /// True for a tool page row that leads with a glyph, so the inset group starts its separator at the text.
    @Entry var onePlusLinearRowGlyph = false
}

/// "Inset, gray glyphs": a tool page settings group. `fillGroup` fill, 1 pt `line` ring, 10 pt radius,
/// 40 pt rows, and `lineSoft` separators that start at the row text and run to the right edge.
struct OnePlusLinearInsetGroup<Content: View>: View {
    let content: Content
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusLinearMetrics.appletGroupRadius, style: .continuous)
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    let glyph = row.containerValues.onePlusLinearRowGlyph ? OnePlusLinearEditorialMetrics.rowGlyphSlot : 0
                    row.frame(minHeight: OnePlusLinearEditorialMetrics.row)
                        .overlay(alignment: .top) {
                            if row.id != rows.first?.id {
                                OnePlusLinearColor.lineSoft.frame(height: 1)
                                    .padding(.leading, OnePlusLinearMetrics.appletRowPadding + glyph)
                                    .allowsHitTesting(false).accessibilityHidden(true)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(shape.fill(OnePlusLinearColor.fillGroup))
        .overlay(shape.strokeBorder(OnePlusLinearColor.line, lineWidth: 1))
    }
}

/// The plain monochrome row glyph of an inset group: 13 pt regular `secondary` in a 20 pt slot. Never a tile.
struct OnePlusLinearRowGlyph: View {
    let symbol: String
    init(_ symbol: String) { self.symbol = symbol }
    var body: some View {
        Image(systemName: symbol).font(.system(size: OnePlusLinearEditorialMetrics.rowGlyphSize, weight: .regular))
            .foregroundStyle(OnePlusLinearColor.secondary)
            .frame(width: OnePlusLinearEditorialMetrics.rowGlyph, height: OnePlusLinearEditorialMetrics.rowGlyph)
            .accessibilityHidden(true)
    }
}

/// "Dotted border and faint fill": marks a panel row for a moment when another surface sends the reader to it.
/// Set `pending` to true; the mark fades in 0.3 s later over 0.2 s, holds 1.2 s, fades out over 0.5 s, and
/// resets `pending`. Reduce Motion shows and hides it at once.
public struct OnePlusLinearRowMark: ViewModifier {
    @Binding var pending: Bool
    @State private var amount = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public init(pending: Binding<Bool>) { _pending = pending }
    public func body(content: Content) -> some View {
        content
            .background { OnePlusLinearRowMarkShape(amount: amount) }
            .onChange(of: pending, initial: true) { _, value in
                guard value else { return }
                pending = false
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(OnePlusMotion.rowMarkDelay))
                    withAnimation(reduceMotion ? nil : .easeOut(duration: OnePlusMotion.rowMarkIn)) { amount = 1 }
                    try? await Task.sleep(for: .seconds(OnePlusMotion.rowMarkIn + OnePlusMotion.rowMarkHold))
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: OnePlusMotion.rowMarkOut)) { amount = 0 }
                }
            }
    }
}

public extension View {
    func onePlusLinearRowMark(pending: Binding<Bool>) -> some View { modifier(OnePlusLinearRowMark(pending: pending)) }
}

/// The row mark at `amount` (0 hidden, 1 full): a 2 pt dotted accent line at 40% and an accent fill at 5%.
public struct OnePlusLinearRowMarkShape: View {
    let amount: Double
    public init(amount: Double) { self.amount = amount }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusLinearEditorialMetrics.rowMarkRadius, style: .continuous)
        ZStack {
            shape.fill(OnePlusLinearColor.accent.opacity(OnePlusLinearEditorialMetrics.rowMarkFill * amount))
            shape.strokeBorder(OnePlusLinearColor.accent.opacity(OnePlusLinearEditorialMetrics.rowMarkLine * amount),
                               style: StrokeStyle(lineWidth: 1, dash: OnePlusLinearEditorialMetrics.rowMarkDash))
        }
        .padding(.horizontal, OnePlusLinearEditorialMetrics.rowMarkInset).padding(.vertical, 1)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A 1 pt hairline in `color` at its center that fades to clear over the last 12% at each end.
public struct OnePlusLinearFadedHairline: View {
    private let color: Color
    public init(_ color: Color) { self.color = color }
    public var body: some View {
        let fade = OnePlusLinearEditorialMetrics.hairlineFade
        LinearGradient(stops: [.init(color: color.opacity(0), location: 0), .init(color: color, location: fade),
                               .init(color: color, location: 1 - fade), .init(color: color.opacity(0), location: 1)],
                       startPoint: .leading, endPoint: .trailing)
            .frame(height: 1).allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// All keys of a shortcut in one small chip, like the sidebar search `⌘K` chip: 18 pt, `kbd` fill, 1 pt `line`,
/// 11 pt `muted` text.
public struct OnePlusLinearKeyChip: View {
    private let keys: String
    public init(_ keys: String) { self.keys = keys }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusLinearEditorialMetrics.keyChipRadius)
        Text(keys).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.muted).fixedSize()
            .padding(.horizontal, OnePlusLinearEditorialMetrics.keyChipPadding)
            .frame(height: OnePlusLinearEditorialMetrics.keyChipHeight)
            .background(shape.fill(OnePlusLinearColor.kbd))
            .overlay(shape.strokeBorder(OnePlusLinearColor.line, lineWidth: 1))
            .accessibilityLabel("Shortcut \(keys)")
    }
}

/// The 48 pt editorial tool row: 24 pt icon, the name over a one-line summary, then a quiet "Off" word for a
/// tool that is off or the shortcut key chip for a tool that is on, the favorite star slot, and a chevron. The
/// star slot sits at one x on every row, and the chip or "Off" right-aligns against it. The whole row opens the
/// tool. The star paints on hover, keyboard focus, or when set. Hover paints a radius 8 fill wider than the row.
public struct OnePlusLinearEditorialToolRow: View {
    private let name: String
    private let summary: String
    private let icon: Image
    private let isOn: Bool
    private let shortcut: String?
    private let isFavorite: Binding<Bool>?
    private let open: () -> Void
    @State private var hover = false
    @FocusState private var starFocused: Bool
    @Environment(\.onePlusLinearMotion) private var motion
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var interactive
    public init(_ name: String, summary: String, icon: Image, isOn: Bool, shortcut: String? = nil,
                isFavorite: Binding<Bool>? = nil, open: @escaping () -> Void) {
        self.name = name; self.summary = summary; self.icon = icon; self.isOn = isOn; self.shortcut = shortcut
        self.isFavorite = isFavorite; self.open = open
    }
    private var hovering: Bool { interactive && (hover || sample == .hover) }
    public var body: some View {
        ZStack {
            Button(action: open) { Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity) }
                .buttonStyle(.plain).focusEffectDisabled()
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
                } else if let shortcut {
                    OnePlusLinearKeyChip(shortcut).allowsHitTesting(false).accessibilityHidden(true)
                }
                star
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OnePlusLinearColor.tertiary).allowsHitTesting(false).accessibilityHidden(true)
            }
            .padding(.horizontal, OnePlusLinearEditorialMetrics.toolRowInset)
        }
        .frame(height: OnePlusLinearEditorialMetrics.toolRow)
        .background {
            RoundedRectangle(cornerRadius: OnePlusLinearEditorialMetrics.toolRowHoverRadius)
                .fill(hovering ? OnePlusLinearColor.hover : .clear)
                .padding(.horizontal, -OnePlusLinearEditorialMetrics.toolRowHoverOutset)
                .padding(.vertical, OnePlusLinearEditorialMetrics.toolRowHoverInset)
        }
        .contentShape(Rectangle())
        .onHover { inside in
            if motion == .spring { OnePlusMotion.withHover(inside, in: OnePlusMotion.springRowHover) { hover = inside } } else { hover = inside }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel([name, isOn ? nil : "off", summary, isOn ? shortcut.map { "shortcut \($0)" } : nil]
                                .compactMap { $0 }.joined(separator: ", "))
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
            .focusEffectDisabled()
            .help(set ? "Remove from Favorites" : "Add to Favorites")
            .accessibilityLabel("Favorite").accessibilityValue(set ? "On" : "Off").accessibilityAddTraits(.isToggle)
        } else {
            Color.clear.frame(width: OnePlusLinearMetrics.starSlot, height: OnePlusLinearMetrics.starSlot)
        }
    }
}
