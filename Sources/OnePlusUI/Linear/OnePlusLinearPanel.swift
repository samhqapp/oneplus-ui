import AppKit
import SwiftUI

/// How the panel draws its surfaces. `lines`: hairline rings, dividers, and a bar line. `fillSteps` (owner pick
/// 2026-11-19): no lines anywhere; tiles, groups, rows, buttons, the bar, and segments separate only by a step
/// in fill (`OnePlusLinearColor.fill*`) and by spacing. The panel sets it for everything inside.
public enum OnePlusLinearPanelStyle: Sendable {
    case lines, fillSteps

    public var radius: CGFloat { self == .fillSteps ? 12 : OnePlusLinearMetrics.panelRadius }
    public var bar: CGFloat { self == .fillSteps ? 46 : OnePlusLinearMetrics.footer }
    public var barInset: CGFloat { self == .fillSteps ? 10 : OnePlusLinearMetrics.footerInset }
    /// The gap between the bar's trailing items (gear, `Open App`).
    public var barTrailingGap: CGFloat { self == .fillSteps ? 2 : 8 }
    public var bodyTopUnderBar: CGFloat { self == .fillSteps ? 2 : OnePlusLinearMetrics.panelBodyTopUnderToolbar }
    public var bodyInset: CGFloat { self == .fillSteps ? 10 : OnePlusLinearMetrics.panelBodyInset }
    public var blockGap: CGFloat { self == .fillSteps ? 10 : OnePlusLinearMetrics.panelBlockGap }
    /// Fill steps: a 7 pt gap gives each floating tile's shadow room; 84 and 140 pt tiles keep the bento at 266 pt.
    public var bentoGap: CGFloat { self == .fillSteps ? 7 : OnePlusLinearMetrics.bentoGap }
    public var tile: CGFloat { self == .fillSteps ? 84 : OnePlusLinearMetrics.tile }
    public var tallTile: CGFloat { self == .fillSteps ? 140 : OnePlusLinearMetrics.tallTile }
    /// Fill steps: list and control-card radius, tile and action radius, and the list's top and bottom padding.
    static let groupRadius: CGFloat = 10
    static let tileRadius: CGFloat = 8
    static let listPadding: CGFloat = 4
}

extension EnvironmentValues {
    @Entry public var onePlusLinearPanelStyle: OnePlusLinearPanelStyle = .lines
}

/// The v15 menu panel shell: 356 pt, body blocks apart by the style's gap, and one fixed bar, either a toolbar
/// at the top (`init(toolbar:content:)`) or a footer at the bottom (`init(content:footer:)`).
public struct OnePlusLinearPanel<Content: View, Footer: View>: View {
    private let style: OnePlusLinearPanelStyle
    private let content: Content
    private let footer: Footer
    private let barOnTop: Bool
    public init(style: OnePlusLinearPanelStyle = .lines, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.style = style; self.content = content(); self.footer = footer(); barOnTop = false
    }
    /// Pass `OnePlusLinearPanelFooter(edge: .top)` as the toolbar.
    public init(style: OnePlusLinearPanelStyle = .lines, @ViewBuilder toolbar: () -> Footer, @ViewBuilder content: () -> Content) {
        self.style = style; self.content = content(); self.footer = toolbar(); barOnTop = true
    }
    public var body: some View {
        VStack(spacing: 0) {
            if barOnTop { footer }
            VStack(alignment: .leading, spacing: style.blockGap) { content }
                .padding(.top, barOnTop ? style.bodyTopUnderBar : OnePlusLinearMetrics.panelBodyTop)
                .padding(.horizontal, style.bodyInset)
                .padding(.bottom, OnePlusLinearMetrics.panelBodyBottom)
            if !barOnTop { footer }
        }
        .frame(width: OnePlusLinearMetrics.panelWidth)
        .background(style == .fillSteps ? OnePlusLinearColor.fillShell : OnePlusLinearColor.panelShell)
        .clipShape(RoundedRectangle(cornerRadius: style.radius))
        .overlay {
            if style == .lines {
                RoundedRectangle(cornerRadius: style.radius).strokeBorder(Self.edge, lineWidth: 1).allowsHitTesting(false)
            }
        }
        .environment(\.onePlusLinearPanelStyle, style)
    }

    /// Light: a crisp hairline. Dark: a quiet ring below the tile rings, so the system shadow draws the edge
    /// (a 12% white ring was the brightest line in the panel and read as a white border).
    private static var edge: Color {
        Color(nsColor: OnePlusLinearColor.dynamic("panelEdge", light: 0x000000, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.06))
    }
}

/// The 44 pt panel bar: leading content (icon tabs), then trailing actions (gear, `Open App`). `edge` is where it sits;
/// its hairline faces the body.
public struct OnePlusLinearPanelFooter<Leading: View, Trailing: View>: View {
    private let edge: VerticalEdge
    private let leading: Leading
    private let trailing: Trailing
    @Environment(\.onePlusLinearPanelStyle) private var style
    public init(edge: VerticalEdge = .bottom, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.edge = edge; self.leading = leading(); self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 8) {
            leading
            Spacer(minLength: 0)
            HStack(spacing: style.barTrailingGap) { trailing }
        }
        .padding(.horizontal, style.barInset)
        .frame(height: style.bar)
        .frame(maxWidth: .infinity)
        .background(style == .lines ? OnePlusLinearColor.panelFooter : .clear)
        .overlay(alignment: edge == .bottom ? .top : .bottom) {
            if style == .lines { OnePlusLinearColor.line.frame(height: 1) }
        }
    }
}

/// Panel tabs as 26 pt icons in one quiet track. The selected tab is raised. Fill steps draws "Soft keys":
/// a sunken track and a raised key.
public struct OnePlusLinearIconTabs<Value: Hashable>: View {
    private let tabs: [OnePlusMenuTab<Value>]
    @Binding private var selection: Value
    private let onMove: ((Int, Int) -> Void)?
    @Environment(\.onePlusLinearPanelStyle) private var style
    public init(tabs: [OnePlusMenuTab<Value>], selection: Binding<Value>, onMove: ((Int, Int) -> Void)? = nil) {
        self.tabs = tabs; _selection = selection; self.onMove = onMove
    }
    public var body: some View {
        let fill = style == .fillSteps
        let size = OnePlusLinearMetrics.iconTab
        let radius: CGFloat = fill ? 6 : 5
        HStack(spacing: 2) {
            ForEach(tabs) { tab in
                let on = tab.id == selection
                Button { selection = tab.id } label: {
                    Group {
                        if let image = tab.image { image.onePlusAssetGlyph(size: 14) }
                        else { Image(systemName: tab.systemImage).font(.system(size: 13)) }
                    }
                    .foregroundStyle(on ? (fill ? OnePlusLinearColor.softKeyInk : OnePlusLinearColor.ink)
                                     : (fill ? OnePlusLinearColor.softKeyTrackInk : OnePlusLinearColor.secondary))
                    .frame(width: size, height: size)
                    .background {
                        if fill, on { OnePlusLinearSoftKey(radius: radius) }
                    }
                    .overlay(alignment: .leading) {
                        // Between two unselected tabs only, centered in the 2 pt gap.
                        if fill, !on, let index = tabs.firstIndex(where: { $0.id == tab.id }), index > 0, tabs[index - 1].id != selection {
                            LinearGradient(colors: [.clear, OnePlusLinearColor.softKeyDivider, .clear], startPoint: .top, endPoint: .bottom)
                                .frame(width: 1, height: size - 8).offset(x: -1.5).allowsHitTesting(false)
                        }
                    }
                    .linearSegmentSelected(!fill && on, radius: radius)
                }
                .buttonStyle(OnePlusLinearButtonStyle(radius: radius))
                .help(tab.title).accessibilityLabel(tab.title)
                .accessibilityAddTraits(on ? .isSelected : [])
                .modifier(OnePlusLinearOptionalIdentifier(value: tab.accessibilityIdentifier))
                .contextMenu {
                    if let onMove, let index = tabs.firstIndex(where: { $0.id == tab.id }) {
                        Button("Move left") { onMove(index, index - 1) }.disabled(index == 0)
                        Button("Move right") { onMove(index, index + 1) }.disabled(index == tabs.count - 1)
                    }
                }
            }
        }
        // The key, glyph colors, and dividers change at once: an animated tab swap rides the panel resize and rolls the key.
        .transaction(value: selection) { $0.animation = nil }
        .modifier(OnePlusLinearTabTrack(soft: fill))
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            if let next = OnePlusSegmented<Value>.nextSelection(in: tabs.map(\.id), current: selection,
                                                              direction: press.key == .leftArrow ? -1 : 1) { selection = next }
            return .handled
        }
    }
}

private struct OnePlusLinearTabTrack: ViewModifier {
    let soft: Bool
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder func body(content: Content) -> some View {
        if soft {
            let shape = RoundedRectangle(cornerRadius: 8)
            let shade = colorScheme == .dark ? OnePlusLinearColor.softKeyTrackShadeGeometry.dark : OnePlusLinearColor.softKeyTrackShadeGeometry.light
            content.padding(2).background {
                shape.fill(Self.vertical(OnePlusLinearColor.softKeyTrackTop, OnePlusLinearColor.softKeyTrackBottom)
                    .shadow(.inner(color: OnePlusLinearColor.softKeyTrackShade, radius: shade.radius, y: shade.y)))
                    .overlay { shape.strokeBorder(Self.vertical(OnePlusLinearColor.softKeyTrackEdgeTop,
                                                                OnePlusLinearColor.softKeyTrackEdgeBottom), lineWidth: 1) }
            }
        } else {
            content.linearTrack(radius: 7)
        }
    }

    static func vertical(_ top: Color, _ bottom: Color) -> LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}

/// The raised key under the selected soft-key tab: a light-to-dark fill, a lit top edge, and a short drop.
private struct OnePlusLinearSoftKey: View {
    let radius: CGFloat
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        shape.fill(OnePlusLinearTabTrack.vertical(OnePlusLinearColor.softKeyTop, OnePlusLinearColor.softKeyBottom))
            .overlay { shape.strokeBorder(OnePlusLinearTabTrack.vertical(OnePlusLinearColor.softKeyEdgeTop,
                                                                         OnePlusLinearColor.softKeyEdgeBottom), lineWidth: 1) }
            .shadow(color: OnePlusLinearColor.softKeyShadow, radius: 1.5, y: 1)
    }
}

private struct OnePlusLinearOptionalIdentifier: ViewModifier {
    let value: String?
    @ViewBuilder func body(content: Content) -> some View {
        if let value { content.accessibilityIdentifier(value) } else { content }
    }
}

/// A 24 pt panel section header: title on the 10 pt row inset, optional trailing note, and right-aligned
/// column titles that line up with process-row columns.
public struct OnePlusLinearPanelHeader: View {
    private let title: String
    private let note: String?
    private let columns: [(String, CGFloat)]
    public init(_ title: String, note: String? = nil, columns: [(String, CGFloat)] = []) {
        self.title = title; self.note = note; self.columns = columns
    }
    /// The process list header: `CPU` and `Memory` columns that match `OnePlusLinearProcessRow`.
    public static func processes(_ title: String = "Top processes") -> Self {
        Self(title, columns: [("CPU", OnePlusLinearMetrics.cpuColumn), ("Memory", OnePlusLinearMetrics.memoryColumn)])
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.rowGap) {
            Text(title).linearText(OnePlusLinearMetrics.caption, weight: .medium, color: OnePlusLinearColor.panelMuted)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let note { Text(note).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted) }
            ForEach(columns, id: \.0) { title, width in
                Text(title).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
                    .frame(width: width, alignment: .trailing).accessibilityHidden(true)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
        .frame(height: OnePlusLinearMetrics.panelHeader)
    }
}

/// How the bento draws its tiles. `tiles`: separate filled tiles 8 pt apart. `instrument`: one filled card split by
/// hairlines in the 8 pt gaps, neutral glyphs, large light values in the data color, and charts as a thin
/// data-colored line with a soft fade, a dot at the newest point, and a continuous ticker scroll.
public enum OnePlusLinearBentoStyle: Sendable { case tiles, instrument }

extension EnvironmentValues {
    @Entry var onePlusLinearBentoStyle: OnePlusLinearBentoStyle = .tiles
}

/// Two columns of metric tiles, 8 pt apart. Use the fixed tile heights so both columns end on one line
/// (left: tall + short + short, right: three regular tiles = 274 pt each).
public struct OnePlusLinearBento<Leading: View, Trailing: View>: View {
    private let style: OnePlusLinearBentoStyle
    private let leading: Leading
    private let trailing: Trailing
    public init(style: OnePlusLinearBentoStyle = .tiles, @ViewBuilder leading: () -> Leading,
                @ViewBuilder trailing: () -> Trailing) {
        self.style = style; self.leading = leading(); self.trailing = trailing()
    }
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    public var body: some View {
        let columns = HStack(alignment: .top, spacing: panelStyle.bentoGap) {
            column(leading).frame(maxWidth: .infinity)
            column(trailing).frame(maxWidth: .infinity)
        }
        .environment(\.onePlusLinearBentoStyle, style)
        if style == .instrument, panelStyle == .lines {
            columns
                .overlay { OnePlusLinearColor.lineSoft.frame(width: 1) }
                .background(OnePlusLinearColor.panelTile)
                .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.tileRadius))
                .linearOuterRing(OnePlusLinearColor.line, radius: OnePlusLinearMetrics.tileRadius)
        } else if panelStyle == .fillSteps {
            // "Floating tiles": one shadow under all tile shapes, drawn behind every tile, so no tile darkens a neighbor.
            columns.backgroundPreferenceValue(OnePlusLinearTileFrames.self) { anchors in
                GeometryReader { proxy in
                    ForEach(anchors.indices, id: \.self) { index in
                        let frame = proxy[anchors[index]]
                        RoundedRectangle(cornerRadius: OnePlusLinearPanelStyle.tileRadius).fill(OnePlusLinearColor.fillGroup)
                            .frame(width: frame.width, height: frame.height).offset(x: frame.minX, y: frame.minY)
                    }
                }
                .compositingGroup()
                .shadow(color: OnePlusLinearColor.fillTileContact, radius: 0.75, y: 0.5)
                .shadow(color: OnePlusLinearColor.fillTileShadow, radius: 8, y: 3)
                .allowsHitTesting(false)
            }
        } else {
            columns
        }
    }

    private func column(_ content: some View) -> some View {
        VStack(spacing: panelStyle.bentoGap) {
            Group(subviews: content) { tiles in
                ForEach(tiles) { tile in
                    tile.overlay(alignment: .top) {
                        if style == .instrument, panelStyle == .lines, tile.id != tiles.first?.id {
                            // Centered in the gap; runs to the card edge and the column rule.
                            OnePlusLinearColor.lineSoft.frame(height: 1)
                                .padding(.horizontal, -OnePlusLinearMetrics.bentoGap / 2)
                                .offset(y: -(OnePlusLinearMetrics.bentoGap + 1) / 2)
                        }
                    }
                }
            }
        }
    }
}

private struct OnePlusLinearTileFrames: PreferenceKey {
    static var defaultValue: [Anchor<CGRect>] { [] }
    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) { value += nextValue() }
}

public struct OnePlusLinearSeries: Sendable {
    public let values: [Double]
    public let color: Color
    public let filled: Bool
    public init(_ values: [Double], color: Color, filled: Bool = true) { self.values = values; self.color = color; self.filled = filled }
}

/// A history chart at a tile's bottom edge, full width: a monotone cubic line, cached, static while values do not
/// change. `slots` is the full window (such as 60 one-second samples), so a short history fills from the right.
public struct OnePlusLinearChart: Sendable {
    public let series: [OnePlusLinearSeries]
    public let range: ClosedRange<Double>
    public let height: CGFloat
    public let midline: Bool
    public let slots: Int
    /// The chart's place in the first-open draw-in: each later chart starts `chartDrawInStagger` later.
    public let order: Int
    public init(_ series: [OnePlusLinearSeries], range: ClosedRange<Double> = 0...100,
                height: CGFloat = OnePlusLinearMetrics.chart, midline: Bool = false, slots: Int = 0, order: Int = 0) {
        self.series = series; self.range = range; self.height = height; self.midline = midline; self.slots = slots
        self.order = order
    }
}

/// A usage bar pinned 12 pt above a tile's bottom, with an optional trailing caption that changes at `pace`.
public struct OnePlusLinearUsage: Sendable {
    public let fraction: Double
    public let color: Color
    public let caption: String?
    public let pace: OnePlusNumberPace
    public init(_ fraction: Double, color: Color, caption: String? = nil, pace: OnePlusNumberPace = .memory) {
        self.fraction = fraction; self.color = color; self.caption = caption; self.pace = pace
    }
}

/// A bento metric tile: panel-tile fill, 6 pt radius, outer 1 pt ring, 10 pt padding.
/// Heights: the panel style's `tile` (default) and `tallTile`, and `OnePlusLinearMetrics.shortTile` (56).
/// Fill steps: a floating tile with a faint `tint` wash at its top.
public struct OnePlusLinearTile<Content: View>: View {
    private let height: CGFloat?
    private let chart: OnePlusLinearChart?
    private let usage: OnePlusLinearUsage?
    private let tint: Color?
    private let content: Content
    @Environment(\.onePlusLinearBentoStyle) private var style
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hover = false
    public init(height: CGFloat? = nil, chart: OnePlusLinearChart? = nil, usage: OnePlusLinearUsage? = nil,
                tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.height = height; self.chart = chart; self.usage = usage; self.tint = tint; self.content = content()
    }
    public var body: some View {
        let tile = VStack(alignment: .leading, spacing: 0) { content }
            .padding([.top, .horizontal], OnePlusLinearMetrics.tilePadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .bottom) {
                if let chart { OnePlusLinearChartView(chart: chart, instrument: style == .instrument).frame(height: chart.height) }
            }
            .overlay(alignment: .bottom) {
                if let usage { OnePlusLinearUsageRow(usage: usage) }
            }
            .frame(height: height ?? panelStyle.tile)
        Group {
            if panelStyle == .fillSteps {
                let lifted = hover || sample == .hover
                let rest = colorScheme == .dark ? OnePlusLinearColor.fillTileWashOpacity.dark : OnePlusLinearColor.fillTileWashOpacity.light
                let wash = rest * (lifted ? OnePlusMotion.tileWashBoost : 1)
                tile.background {
                    if let tint {
                        LinearGradient(colors: [tint.opacity(wash), tint.opacity(0)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.75))
                    }
                }
                .background(OnePlusLinearColor.fillGroup)
                .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearPanelStyle.tileRadius))
                // The shared shadow layer reads this anchor, so the tile and its unchanged shadow rise together.
                .offset(y: lifted && !reduceMotion ? -OnePlusMotion.tileLift : 0)
                .anchorPreference(key: OnePlusLinearTileFrames.self, value: .bounds) { [$0] }
                .onePlusHover($hover, timing: (OnePlusMotion.tileHoverIn, OnePlusMotion.tileHoverOut))
            } else if style == .instrument {
                tile
            } else {
                tile.background(OnePlusLinearColor.panelTile)
                    .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.tileRadius))
                    .linearOuterRing(OnePlusLinearColor.line, radius: OnePlusLinearMetrics.tileRadius)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The tile's 16 pt label row: 14 pt glyph in the data color, 13 pt label, trailing content.
public struct OnePlusLinearTileLabel<Trailing: View>: View {
    private let title: String
    private let systemImage: String
    private let color: Color
    private let trailing: Trailing
    @Environment(\.onePlusLinearBentoStyle) private var style
    public init(_ title: String, systemImage: String, color: Color, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.systemImage = systemImage; self.color = color; self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 12))
                .foregroundStyle(style == .instrument ? OnePlusLinearColor.secondary : color)
                .frame(width: 14, height: 14).accessibilityHidden(true)
            Text(title).linearText(color: OnePlusLinearColor.secondary).fixedSize()
            trailing.frame(maxWidth: .infinity, alignment: .trailing)
        }
        .lineLimit(1)
        .frame(height: 16)
    }
}

public extension OnePlusLinearTileLabel where Trailing == Text {
    /// A label with a quiet trailing note, such as `14 cores`.
    init(_ title: String, systemImage: String, color: Color, meta: String) {
        self.init(title, systemImage: systemImage, color: color) {
            Text(meta).font(.system(size: OnePlusLinearMetrics.caption)).foregroundStyle(OnePlusLinearColor.panelMuted)
        }
    }
}

/// A small value with unit for a label row, such as `612 GB free`.
public struct OnePlusLinearInlineValue: View {
    private let value: String
    private let unit: String
    private let color: Color?
    private let pace: OnePlusNumberPace
    @Environment(\.onePlusLinearBentoStyle) private var style
    /// `color` is the data color; the `instrument` bento draws the value in it. `pace` sets how often it changes.
    public init(_ value: String, unit: String, color: Color? = nil, pace: OnePlusNumberPace = .memory) {
        self.value = value; self.unit = unit; self.color = color; self.pace = pace
    }
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            OnePlusLinearNumberText(value, pace: pace)
                .linearText(weight: .semibold, color: style == .instrument ? color ?? OnePlusLinearColor.ink : OnePlusLinearColor.ink)
            Text(unit).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
        }
        .lineLimit(1)
    }
}

/// The tile's main value: 22 pt semibold, 11 pt unit, optional leading glyph and trailing note.
public struct OnePlusLinearTileValue: View {
    private let value: String
    private let unit: String
    private let glyph: (systemImage: String, color: Color)?
    private let note: String?
    private let color: Color?
    private let pace: OnePlusNumberPace
    @Environment(\.onePlusLinearBentoStyle) private var style
    /// `color` is the data color; the `instrument` bento draws the value large, light, and in it, with a neutral glyph.
    /// `pace` sets how often the value and note change and how fast they roll.
    public init(_ value: String, unit: String, glyph: (systemImage: String, color: Color)? = nil, note: String? = nil,
                color: Color? = nil, pace: OnePlusNumberPace = .cpu) {
        self.value = value; self.unit = unit; self.glyph = glyph; self.note = note; self.color = color; self.pace = pace
    }
    public var body: some View {
        let instrument = style == .instrument
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if let glyph {
                Image(systemName: glyph.systemImage).font(.system(size: 11, weight: .medium))
                    .foregroundStyle(instrument ? OnePlusLinearColor.secondary : glyph.color)
                    .frame(width: 12, height: 12).alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                    .accessibilityHidden(true)
            }
            OnePlusLinearNumberText(value, pace: pace)
                .font(.system(size: instrument ? OnePlusLinearMetrics.instrumentValue : OnePlusLinearMetrics.tileValue,
                              weight: instrument ? .light : .semibold))
                .tracking(-0.5)
                .foregroundStyle(instrument ? color ?? OnePlusLinearColor.ink : OnePlusLinearColor.ink).monospacedDigit()
            Text(unit).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
            if let note {
                OnePlusLinearNumberText(note, pace: pace).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .lineLimit(1)
        .frame(height: OnePlusLinearMetrics.tileValueLine)
        .padding(.top, 3)
    }
}

/// A row of small labeled values under a tile value, such as `User 14 %  System 9 %`.
public struct OnePlusLinearTileSplit: View {
    private let items: [(label: String, value: String, unit: String)]
    private let pace: OnePlusNumberPace
    public init(_ items: [(label: String, value: String, unit: String)], pace: OnePlusNumberPace = .cpu) {
        self.items = items; self.pace = pace
    }
    public var body: some View {
        HStack(spacing: 12) {
            ForEach(items, id: \.label) { item in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(item.label) ").linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
                    OnePlusLinearNumberText(item.value, pace: pace)
                        .linearText(OnePlusLinearMetrics.caption, weight: .medium, color: OnePlusLinearColor.secondary)
                    Text(item.unit).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).padding(.leading, 3)
                }
            }
        }
        .lineLimit(1)
        .padding(.top, 4)
    }
}

/// The tile usage bar on its own, for a panel row (a transfer's progress): a 5 pt `barTrack` with the data color,
/// radius 3. On the first open it grows with `onePlusLinearReveal`.
public struct OnePlusLinearUsageBar: View {
    private let fraction: Double
    private let color: Color
    @Environment(\.onePlusLinearReveal) private var reveal
    public init(_ fraction: Double, color: Color) { self.fraction = fraction; self.color = color }
    public var body: some View {
        let fraction = fraction.isFinite ? min(max(fraction, 0), 1) : 0
        RoundedRectangle(cornerRadius: 3).fill(OnePlusLinearColor.barTrack)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: proxy.size.width * fraction * min(max(reveal, 0), 1))
                }
            }
            .frame(height: OnePlusLinearMetrics.usageBar)
            .accessibilityLabel("Usage").accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}

private struct OnePlusLinearUsageRow: View {
    let usage: OnePlusLinearUsage
    var body: some View {
        HStack(spacing: 8) {
            OnePlusLinearUsageBar(usage.fraction, color: usage.color)
            if let caption = usage.caption {
                OnePlusLinearNumberText(caption, pace: usage.pace)
                    .linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).fixedSize()
            }
        }
        .frame(height: 14)
        .padding(.horizontal, OnePlusLinearMetrics.tilePadding)
        .padding(.bottom, OnePlusLinearMetrics.usageRowBottom)
    }
}

private struct OnePlusLinearChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.onePlusLinearReveal) private var reveal
    let chart: OnePlusLinearChart
    let instrument: Bool
    var body: some View {
        // The top value eases to a new ceiling; the hosted canvas animates it inside its own hosting view.
        let canvas = OnePlusLinearChartCanvas(chart: chart, instrument: instrument, dark: colorScheme == .dark,
                                              top: chart.range.upperBound)
            .animation(reduceMotion ? nil : OnePlusMotion.animation(OnePlusMotion.chartScale), value: chart.range.upperBound)
        Group {
            if instrument {
                OnePlusChartTicker(content: canvas, trigger: chart.series.first?.values ?? [], slots: chart.slots,
                                   animates: !reduceMotion && chart.slots > 1, reveal: reveal, order: chart.order)
            } else {
                canvas.clipped()
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chart.series.first?.values.last.flatMap { $0.isFinite ? "Latest value \($0.formatted())" : nil } ?? "No history")
    }
}

private struct OnePlusLinearChartCanvas: View, @MainActor Animatable {
    let chart: OnePlusLinearChart
    let instrument: Bool
    let dark: Bool
    var top: Double
    var animatableData: Double {
        get { top }
        set { top = newValue }
    }

    var body: some View {
        Canvas { context, size in draw(in: &context, size: size) }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let dot = OnePlusLinearMetrics.chartDot
        let width = size.width.isFinite ? max(0, size.width - (instrument ? dot * 2 : 0)) : 0
        let height = size.height.isFinite ? max(0, size.height) : 0
        if chart.midline {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: height / 2)); line.addLine(to: CGPoint(x: width, y: height / 2))
            context.stroke(line, with: .color(OnePlusLinearColor.lineSoft), lineWidth: 1)
        }
        let fill = dark ? OnePlusLinearColor.chartFillOpacity.dark : OnePlusLinearColor.chartFillOpacity.light
        let fade = dark ? OnePlusLinearColor.chartFadeOpacity.dark : OnePlusLinearColor.chartFadeOpacity.light
        let transform = CGAffineTransform(scaleX: width, y: height)
        let range = chart.range.lowerBound...max(top, chart.range.lowerBound + .ulpOfOne)
        for series in chart.series {
            let paths = OnePlusChartPaths.cached(values: series.values, range: range, smoothed: true, slots: chart.slots)
            let line = paths.line.applying(transform)
            if series.filled, !paths.area.isEmpty {
                let area = paths.area.applying(transform)
                if instrument {
                    context.fill(area, with: .linearGradient(Gradient(colors: [series.color.opacity(fade), series.color.opacity(0)]),
                                                             startPoint: CGPoint(x: 0, y: area.boundingRect.minY),
                                                             endPoint: CGPoint(x: 0, y: height)))
                } else {
                    context.fill(area, with: .color(series.color.opacity(fill)))
                }
            }
            context.stroke(line, with: .color(series.color),
                           style: StrokeStyle(lineWidth: instrument ? 1 : 1.25, lineCap: .round, lineJoin: .round))
            if instrument, series.filled, let last = line.currentPoint {
                context.fill(Path(ellipseIn: CGRect(x: last.x - dot, y: last.y - dot, width: dot * 2, height: dot * 2)),
                             with: .color(series.color))
            }
        }
    }
}

/// Instrument chart host: clips the chart, fades its left edge, draws the line in on the first-open reveal, and
/// scrolls it. The scroll keeps one constant speed (one step per sample interval): a new sample shifts the drawing
/// one step left and the layer one step right from wherever the scroll is now, so the line never stops or jumps
/// when a sample comes early or late. The render server runs the frames; the app draws once per sample.
private struct OnePlusChartTicker<Content: View>: NSViewRepresentable {
    let content: Content
    let trigger: [Double]
    let slots: Int
    let animates: Bool
    let reveal: Double
    let order: Int

    func makeNSView(context: Context) -> OnePlusChartTickerView<Content> { OnePlusChartTickerView(content) }

    func updateNSView(_ view: OnePlusChartTickerView<Content>, context: Context) {
        view.host.rootView = content
        view.setReveal(reveal, order: order)
        if !animates { view.stop() }
        guard trigger != view.lastTrigger else { return }
        let first = view.lastTrigger == nil
        view.lastTrigger = trigger
        if animates && !first { view.tick(slots: slots) }
    }
}

private final class OnePlusChartTickerView<Content: View>: NSView {
    let host: NSHostingView<Content>
    var lastTrigger: [Double]?
    private let fade = CAGradientLayer()
    private let revealView = NSView()
    private let revealMask = CALayer()
    private var revealed = true

    init(_ content: Content) {
        host = NSHostingView(rootView: content)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        fade.colors = [NSColor.clear.cgColor, NSColor.black.cgColor, NSColor.black.cgColor]
        fade.startPoint = CGPoint(x: 0, y: 0.5)
        fade.endPoint = CGPoint(x: 1, y: 0.5)
        layer?.mask = fade
        revealView.wantsLayer = true
        revealMask.backgroundColor = NSColor.black.cgColor
        revealMask.anchorPoint = CGPoint(x: 0, y: 0.5)
        revealView.layer?.mask = revealMask
        host.wantsLayer = true
        revealView.addSubview(host)
        addSubview(revealView)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        revealView.frame = bounds
        host.frame = bounds
        CATransaction.begin(); CATransaction.setDisableActions(true)
        fade.frame = bounds
        revealMask.bounds = bounds
        revealMask.position = CGPoint(x: 0, y: bounds.midY)
        let edge = bounds.width > 0 ? OnePlusLinearMetrics.chartEdgeFade / bounds.width : 0
        fade.locations = [0, NSNumber(value: Double(min(edge, 1))), 1]
        CATransaction.commit()
    }

    /// Below 1 the line shows that share from the left; the change to 1 draws it in, `order` charts later.
    func setReveal(_ reveal: Double, order: Int) {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        if reveal < 1 {
            revealed = false
            revealMask.removeAnimation(forKey: "reveal")
            revealMask.transform = CATransform3DMakeScale(CGFloat(max(reveal, 0.0001)), 1, 1)
        } else if !revealed {
            revealed = true
            let from = (revealMask.presentation() ?? revealMask).value(forKeyPath: "transform.scale.x") as? CGFloat ?? 0
            revealMask.transform = CATransform3DIdentity
            let draw = CABasicAnimation(keyPath: "transform.scale.x")
            draw.fromValue = from
            draw.toValue = 1
            draw.duration = OnePlusMotion.chartDrawIn
            draw.beginTime = CACurrentMediaTime() + OnePlusMotion.chartDrawInStagger * Double(order)
            draw.fillMode = .backwards
            draw.timingFunction = OnePlusMotion.easeOutTiming
            revealMask.add(draw, forKey: "reveal")
        }
    }

    func tick(slots: Int) {
        guard let layer = host.layer, bounds.width > 0 else { return }
        let step = (bounds.width - OnePlusLinearMetrics.chartDot * 2) / CGFloat(max(slots - 1, 1))
        let speed = step / OnePlusMotion.chartTick
        let now = layer.presentation()?.value(forKeyPath: "transform.translation.x") as? CGFloat ?? 0
        // Bounds keep the newest point near the right edge: a burst of samples cannot push it far out of view,
        // and a stalled sampler leaves the line resting half a step in.
        let start = min(now + step, step * 1.5)
        let rest = -step * 0.5
        let scroll = CABasicAnimation(keyPath: "transform.translation.x")
        scroll.fromValue = start
        scroll.toValue = rest
        scroll.duration = max(Double((start - rest) / speed), 0.01)
        scroll.timingFunction = CAMediaTimingFunction(name: .linear)
        scroll.fillMode = .forwards
        scroll.isRemovedOnCompletion = false
        layer.add(scroll, forKey: "ticker")
    }

    func stop() {
        host.layer?.removeAnimation(forKey: "ticker")
    }
}

/// A 32 pt control row for a panel card: 14 pt glyph, 48 pt name, quiet status, trailing control
/// (`OnePlusLinearSegmented` for Fan, a `Toggle` with `OnePlusLinearSwitchStyle` for Kwake).
/// `titleWidth: nil` sizes the name to its text, for tool-tab settings rows such as `Use custom scrolling`.
public struct OnePlusLinearControlRow<Control: View>: View {
    private let title: String
    private let systemImage: String
    private let status: String?
    private let titleWidth: CGFloat?
    private let control: Control
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    public init(_ title: String, systemImage: String, status: String? = nil, titleWidth: CGFloat? = 48,
                @ViewBuilder control: () -> Control) {
        self.title = title; self.systemImage = systemImage; self.status = status; self.titleWidth = titleWidth
        self.control = control()
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.rowGap) {
            Image(systemName: systemImage).font(.system(size: 12)).foregroundStyle(OnePlusLinearColor.panelMuted)
                .frame(width: 14, height: 14).accessibilityHidden(true)
            Text(title).linearText().lineLimit(1).frame(width: titleWidth, alignment: .leading)
                .layoutPriority(titleWidth == nil ? 1 : 0)
            if let status { Text(status).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).lineLimit(1) }
            Spacer(minLength: 0)
            control
        }
        .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
        .frame(height: OnePlusLinearMetrics.controlRow)
        .linearRowHover($hover, sample: sample, enabled: enabled, panelStyle: panelStyle)
        .accessibilityElement(children: .contain)
    }
}

/// A 32 pt panel section toggle inside a group: 14 pt glyph, the name, a quiet trailing detail, an optional
/// accessory (such as a refresh icon button), and a chevron that turns down when open. Hover is the row fill step.
public struct OnePlusLinearDisclosureRow<Accessory: View>: View {
    private let title: String
    private let systemImage: String
    private let detail: String?
    @Binding private var isExpanded: Bool
    private let accessory: Accessory
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    private static var chevron: CGFloat { 14 }
    public init(_ title: String, systemImage: String, detail: String? = nil, isExpanded: Binding<Bool>,
                @ViewBuilder accessory: () -> Accessory) {
        self.title = title; self.systemImage = systemImage; self.detail = detail; _isExpanded = isExpanded
        self.accessory = accessory()
    }
    public var body: some View {
        Button { isExpanded.toggle() } label: {
            HStack(spacing: OnePlusLinearMetrics.rowGap) {
                Image(systemName: systemImage).font(.system(size: 12)).foregroundStyle(OnePlusLinearColor.panelMuted)
                    .frame(width: 14, height: 14)
                Text(title).linearText(weight: .medium).lineLimit(1).layoutPriority(1)
                Spacer(minLength: 0)
                if let detail {
                    Text(detail).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).lineLimit(1)
                }
                if Accessory.self != EmptyView.self { Color.clear.frame(width: OnePlusLinearMetrics.panelAccessory) }
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(OnePlusLinearColor.panelMuted)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: Self.chevron, height: Self.chevron)
            }
            .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
            .frame(height: OnePlusLinearMetrics.controlRow)
            .linearRowHover($hover, sample: sample, enabled: enabled, panelStyle: panelStyle)
        }
        .buttonStyle(OnePlusLinearPlainRowStyle())
        .overlay(alignment: .trailing) {
            accessory.frame(width: OnePlusLinearMetrics.panelAccessory)
                .padding(.trailing, OnePlusLinearMetrics.panelRowInset + Self.chevron + OnePlusLinearMetrics.rowGap)
        }
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }
}

public extension OnePlusLinearDisclosureRow where Accessory == EmptyView {
    init(_ title: String, systemImage: String, detail: String? = nil, isExpanded: Binding<Bool>) {
        self.init(title, systemImage: systemImage, detail: detail, isExpanded: isExpanded) { EmptyView() }
    }
}

/// A row that draws its own hover and selected fill, so the button adds no press look.
public struct OnePlusLinearPlainRowStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View { configuration.label }
}

/// A 30 pt process row in 12 pt text: 16 pt app icon (terminal glyph when nil), name, CPU percent in the data color
/// (number and percent sign), memory. Pass preformatted strings. A selected row keeps the hover fill step.
public struct OnePlusLinearProcessRow: View {
    private let name: String
    private let icon: Image?
    private let cpu: String
    private let memory: String
    private let color: Color
    private let selected: Bool
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    public init(_ name: String, icon: Image?, cpu: String, memory: String, color: Color = OnePlusLinearColor.cpuText,
                selected: Bool = false) {
        self.name = name; self.icon = icon; self.cpu = cpu; self.memory = memory; self.color = color; self.selected = selected
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.rowGap) {
            Group {
                if let icon { icon.resizable().scaledToFit() }
                else {
                    Image(systemName: "terminal").font(.system(size: 8)).foregroundStyle(OnePlusLinearColor.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(OnePlusLinearColor.iconOutline, lineWidth: 1) }
                }
            }
            .frame(width: OnePlusLinearMetrics.processIcon, height: OnePlusLinearMetrics.processIcon)
            Text(name).linearText(OnePlusLinearMetrics.control).lineLimit(1).truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                OnePlusLinearNumberText(cpu, pace: .process).linearText(OnePlusLinearMetrics.control, weight: .medium, color: color)
                Text("%").linearText(OnePlusLinearMetrics.caption, color: color)
            }
            .lineLimit(1).fixedSize()
            // A value wider than the column grows it to the left; it never wraps.
            .frame(minWidth: OnePlusLinearMetrics.cpuColumn, alignment: .trailing)
            OnePlusLinearNumberText(memory, pace: .process).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                .lineLimit(1).fixedSize()
                .frame(width: OnePlusLinearMetrics.memoryColumn, alignment: .trailing)
        }
        .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
        .frame(height: OnePlusLinearMetrics.processRow)
        .linearRowHover($hover, sample: sample, enabled: enabled, fill: OnePlusLinearColor.selection, panelStyle: panelStyle,
                        selected: selected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), CPU \(cpu) percent, memory \(memory)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

public struct OnePlusLinearAction: Identifiable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let action: () -> Void
    public init(_ title: String, systemImage: String, id: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.systemImage = systemImage; self.id = id ?? title; self.action = action
    }
}

/// A 28 pt toolbar of equal actions on the panel: no fill or ring, short 14 pt hairline dividers, glyph and label
/// on one line, and a rounded selection fill inset 3 pt on hover.
public struct OnePlusLinearActionBar: View {
    private let actions: [OnePlusLinearAction]
    @Environment(\.onePlusLinearPanelStyle) private var panelStyle
    @Environment(\.colorScheme) private var colorScheme
    public init(_ actions: [OnePlusLinearAction]) { self.actions = actions }
    private var labelWeight: Font.Weight {
        guard panelStyle == .fillSteps else { return .medium }
        return colorScheme == .dark ? OnePlusLinearColor.actionKeyLabelWeight.dark : OnePlusLinearColor.actionKeyLabelWeight.light
    }
    public var body: some View {
        if panelStyle == .fillSteps { filled } else { toolbar }
    }

    /// Fill steps: separate 32 pt buttons 4 pt apart, each a group-fill step with radius 8.
    private var filled: some View {
        HStack(spacing: 4) {
            ForEach(actions) { item in
                Button(action: item.action) { label(item) }
                    .buttonStyle(OnePlusLinearFillStepButtonStyle())
                    .accessibilityIdentifier(item.id)
            }
        }
        .frame(height: 32)
    }

    private func label(_ item: OnePlusLinearAction) -> some View {
        HStack(spacing: 6) {
            Image(systemName: item.systemImage).font(.system(size: 12)).foregroundStyle(OnePlusLinearColor.secondary)
                .frame(height: 14).accessibilityHidden(true)
            Text(item.title).font(.system(size: OnePlusLinearMetrics.control, weight: labelWeight)).tracking(-0.04)
                .foregroundStyle(OnePlusLinearColor.ink).lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack(spacing: 0) {
            ForEach(actions) { item in
                Button(action: item.action) { label(item) }
                .buttonStyle(OnePlusLinearToolbarItemStyle())
                .overlay(alignment: .leading) {
                    if item.id != actions.first?.id {
                        OnePlusLinearColor.lineSoft.frame(width: 1, height: OnePlusLinearMetrics.actionDivider).allowsHitTesting(false)
                    }
                }
                .accessibilityIdentifier(item.id)
            }
        }
        .frame(height: OnePlusLinearMetrics.actionBar)
    }
}

/// The Home action key (Fill steps): a raised radius 8 key that rises 1 pt on hover and sits down while pressed.
/// The action bar sizes it; a row key (`Grant`, `Retry`) uses `.compact`: 24 pt tall, 10 pt label padding.
public struct OnePlusLinearKeyButtonStyle: ButtonStyle {
    private let compact: Bool
    public init() { compact = false }
    public static var compact: Self { Self(compact: true) }
    private init(compact: Bool) { self.compact = compact }
    @ViewBuilder public func makeBody(configuration: Configuration) -> some View {
        if compact {
            OnePlusLinearFillStepButtonStyle.ItemBody(label: configuration.label
                .font(.system(size: OnePlusLinearMetrics.control, weight: .medium)).foregroundStyle(OnePlusLinearColor.ink)
                .lineLimit(1).padding(.horizontal, 10).frame(height: OnePlusLinearMetrics.panelKey),
                isPressed: configuration.isPressed, onGroup: true)
        } else {
            OnePlusLinearFillStepButtonStyle.ItemBody(label: configuration.label, isPressed: configuration.isPressed)
        }
    }
}

private struct OnePlusLinearFillStepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { ItemBody(label: configuration.label, isPressed: configuration.isPressed) }

    struct ItemBody<Label: View>: View {
        let label: Label
        let isPressed: Bool
        /// A row key sits on the group fill, so it rests one soft step above it (the action key matches the group).
        var onGroup = false
        @State private var hover = false
        @Environment(\.onePlusControlState) private var sample
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        var body: some View {
            let pressed = enabled && (isPressed || sample == .pressed)
            let hovered = enabled && (hover || sample == .hover)
            let shift = reduceMotion ? 0 : pressed ? OnePlusMotion.keyPress : hovered ? -OnePlusMotion.keyLift : 0
            let shape = RoundedRectangle(cornerRadius: OnePlusLinearPanelStyle.tileRadius)
            let fill = pressed ? LinearGradient(colors: [OnePlusLinearColor.fillButtonPressed], startPoint: .top, endPoint: .bottom)
                : hovered && onGroup ? LinearGradient(colors: [OnePlusLinearColor.softButtonHover], startPoint: .top, endPoint: .bottom)
                : hovered ? OnePlusLinearTabTrack.vertical(OnePlusLinearColor.actionKeyHoverTop, OnePlusLinearColor.actionKeyHoverBottom)
                : onGroup ? OnePlusLinearTabTrack.vertical(OnePlusLinearColor.softKeyTop, OnePlusLinearColor.softKeyBottom)
                : OnePlusLinearTabTrack.vertical(OnePlusLinearColor.actionKeyTop, OnePlusLinearColor.actionKeyBottom)
            label
                .background {
                    shape.fill(fill)
                        .overlay { shape.strokeBorder(OnePlusLinearTabTrack.vertical(OnePlusLinearColor.actionKeyEdgeTop,
                                                                                     OnePlusLinearColor.actionKeyEdgeBottom), lineWidth: 1) }
                        .shadow(color: OnePlusLinearColor.actionKeyShadow, radius: 1.5, y: 1)
                }
                .offset(y: shift)
                .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
                .contentShape(Rectangle())
                .onePlusHover($hover, timing: (OnePlusMotion.keyHover, OnePlusMotion.keyHover))
                .linearMotion(OnePlusMotion.keyHover, value: hover)
        }
    }
}

private struct OnePlusLinearToolbarItemStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { ItemBody(configuration: configuration) }

    private struct ItemBody: View {
        let configuration: Configuration
        @State private var hover = false
        @Environment(\.onePlusControlState) private var sample
        @Environment(\.isEnabled) private var enabled
        var body: some View {
            let pressed = configuration.isPressed || sample == .pressed
            let fill = !enabled ? Color.clear : pressed ? OnePlusLinearColor.pressed
                : hover || sample == .hover ? OnePlusLinearColor.selection : .clear
            configuration.label
                .background { RoundedRectangle(cornerRadius: 5).fill(fill).padding(.horizontal, 3) }
                .opacity(enabled ? 1 : OnePlusMetrics.disabledOpacity)
                .contentShape(Rectangle())
                .onePlusHover($hover)
        }
    }
}
