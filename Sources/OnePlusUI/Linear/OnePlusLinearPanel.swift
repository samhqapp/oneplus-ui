import AppKit
import SwiftUI

/// The v15 menu panel shell: 356 pt, 8 pt radius, body blocks 12 pt apart, and a fixed footer. No top bar.
public struct OnePlusLinearPanel<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer
    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content(); self.footer = footer()
    }
    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: OnePlusLinearMetrics.panelBlockGap) { content }
                .padding(.top, OnePlusLinearMetrics.panelBodyTop)
                .padding(.horizontal, OnePlusLinearMetrics.panelBodyInset)
                .padding(.bottom, OnePlusLinearMetrics.panelBodyBottom)
            footer
        }
        .frame(width: OnePlusLinearMetrics.panelWidth)
        .background(OnePlusLinearColor.panelShell)
        .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: OnePlusLinearMetrics.panelRadius)
                .strokeBorder(Self.edge, lineWidth: 1).allowsHitTesting(false)
        }
    }

    /// Light: a crisp hairline. Dark: a quiet ring below the tile rings, so the system shadow draws the edge
    /// (a 12% white ring was the brightest line in the panel and read as a white border).
    private static var edge: Color {
        Color(nsColor: OnePlusLinearColor.dynamic("panelEdge", light: 0x000000, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.06))
    }
}

/// The 44 pt panel footer: leading content (icon tabs), then trailing actions (gear, `Open App`).
public struct OnePlusLinearPanelFooter<Leading: View, Trailing: View>: View {
    private let leading: Leading
    private let trailing: Trailing
    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading(); self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 8) {
            leading
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, OnePlusLinearMetrics.footerInset)
        .frame(height: OnePlusLinearMetrics.footer)
        .frame(maxWidth: .infinity)
        .background(OnePlusLinearColor.panelFooter)
        .overlay(alignment: .top) { OnePlusLinearColor.line.frame(height: 1) }
    }
}

/// Panel tabs as 26 pt icons in one quiet track. The selected tab is raised.
public struct OnePlusLinearIconTabs<Value: Hashable>: View {
    private let tabs: [OnePlusMenuTab<Value>]
    @Binding private var selection: Value
    private let onMove: ((Int, Int) -> Void)?
    public init(tabs: [OnePlusMenuTab<Value>], selection: Binding<Value>, onMove: ((Int, Int) -> Void)? = nil) {
        self.tabs = tabs; _selection = selection; self.onMove = onMove
    }
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(tabs) { tab in
                let on = tab.id == selection
                Button { selection = tab.id } label: {
                    Group {
                        if let image = tab.image { image.onePlusAssetGlyph(size: 14) }
                        else { Image(systemName: tab.systemImage).font(.system(size: 13)) }
                    }
                    .foregroundStyle(on ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                    .frame(width: OnePlusLinearMetrics.iconTab, height: OnePlusLinearMetrics.iconTab)
                    .linearSegmentSelected(on, radius: 5)
                }
                .buttonStyle(OnePlusLinearButtonStyle(radius: 5))
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
        .linearTrack(radius: 7)
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard press.modifiers.isEmpty else { return .ignored }
            if let next = OnePlusSegmented<Value>.nextSelection(in: tabs.map(\.id), current: selection,
                                                              direction: press.key == .leftArrow ? -1 : 1) { selection = next }
            return .handled
        }
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
    /// The process list header: `CPU` 40 pt and `Memory` 52 pt.
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

/// Two columns of metric tiles, 8 pt apart. Use the fixed tile heights so both columns end on one line
/// (left: tall + short + short, right: three regular tiles = 274 pt each).
public struct OnePlusLinearBento<Leading: View, Trailing: View>: View {
    private let leading: Leading
    private let trailing: Trailing
    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading(); self.trailing = trailing()
    }
    public var body: some View {
        HStack(alignment: .top, spacing: OnePlusLinearMetrics.bentoGap) {
            VStack(spacing: OnePlusLinearMetrics.bentoGap) { leading }.frame(maxWidth: .infinity)
            VStack(spacing: OnePlusLinearMetrics.bentoGap) { trailing }.frame(maxWidth: .infinity)
        }
    }
}

public struct OnePlusLinearSeries: Sendable {
    public let values: [Double]
    public let color: Color
    public let filled: Bool
    public init(_ values: [Double], color: Color, filled: Bool = true) { self.values = values; self.color = color; self.filled = filled }
}

/// A history chart at a tile's bottom edge, full width. Cached paths; static while values do not change.
public struct OnePlusLinearChart: Sendable {
    public let series: [OnePlusLinearSeries]
    public let range: ClosedRange<Double>
    public let height: CGFloat
    public let midline: Bool
    public init(_ series: [OnePlusLinearSeries], range: ClosedRange<Double> = 0...100,
                height: CGFloat = OnePlusLinearMetrics.chart, midline: Bool = false) {
        self.series = series; self.range = range; self.height = height; self.midline = midline
    }
}

/// A usage bar pinned 12 pt above a tile's bottom, with an optional trailing caption.
public struct OnePlusLinearUsage: Sendable {
    public let fraction: Double
    public let color: Color
    public let caption: String?
    public init(_ fraction: Double, color: Color, caption: String? = nil) { self.fraction = fraction; self.color = color; self.caption = caption }
}

/// A bento metric tile: panel-tile fill, 6 pt radius, outer 1 pt ring, 10 pt padding.
/// Heights: `OnePlusLinearMetrics.tile` (86), `.tallTile` (146), `.shortTile` (56).
public struct OnePlusLinearTile<Content: View>: View {
    private let height: CGFloat
    private let chart: OnePlusLinearChart?
    private let usage: OnePlusLinearUsage?
    private let content: Content
    public init(height: CGFloat = OnePlusLinearMetrics.tile, chart: OnePlusLinearChart? = nil, usage: OnePlusLinearUsage? = nil,
                @ViewBuilder content: () -> Content) {
        self.height = height; self.chart = chart; self.usage = usage; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding([.top, .horizontal], OnePlusLinearMetrics.tilePadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .bottom) {
                if let chart { OnePlusLinearChartView(chart: chart).frame(height: chart.height) }
            }
            .overlay(alignment: .bottom) {
                if let usage { OnePlusLinearUsageRow(usage: usage) }
            }
            .frame(height: height)
            .background(OnePlusLinearColor.panelTile)
            .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.tileRadius))
            .linearOuterRing(OnePlusLinearColor.line, radius: OnePlusLinearMetrics.tileRadius)
            .accessibilityElement(children: .combine)
    }
}

/// The tile's 16 pt label row: 14 pt glyph in the data color, 13 pt label, trailing content.
public struct OnePlusLinearTileLabel<Trailing: View>: View {
    private let title: String
    private let systemImage: String
    private let color: Color
    private let trailing: Trailing
    public init(_ title: String, systemImage: String, color: Color, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.systemImage = systemImage; self.color = color; self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 12)).foregroundStyle(color)
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
    public init(_ value: String, unit: String) { self.value = value; self.unit = unit }
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value).linearText(weight: .semibold)
            Text(unit).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
        }
    }
}

/// The tile's main value: 22 pt semibold, 11 pt unit, optional leading glyph and trailing note.
public struct OnePlusLinearTileValue: View {
    private let value: String
    private let unit: String
    private let glyph: (systemImage: String, color: Color)?
    private let note: String?
    public init(_ value: String, unit: String, glyph: (systemImage: String, color: Color)? = nil, note: String? = nil) {
        self.value = value; self.unit = unit; self.glyph = glyph; self.note = note
    }
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if let glyph {
                Image(systemName: glyph.systemImage).font(.system(size: 11, weight: .medium)).foregroundStyle(glyph.color)
                    .frame(width: 12, height: 12).alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                    .accessibilityHidden(true)
            }
            Text(value).font(.system(size: OnePlusLinearMetrics.tileValue, weight: .semibold)).tracking(-0.5)
                .foregroundStyle(OnePlusLinearColor.ink).monospacedDigit()
            Text(unit).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
            if let note {
                Text(note).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.secondary)
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
    public init(_ items: [(label: String, value: String, unit: String)]) { self.items = items }
    public var body: some View {
        HStack(spacing: 12) {
            ForEach(items, id: \.label) { item in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(item.label) ").linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted)
                    Text(item.value).linearText(OnePlusLinearMetrics.caption, weight: .medium, color: OnePlusLinearColor.secondary)
                    Text(item.unit).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).padding(.leading, 3)
                }
            }
        }
        .lineLimit(1)
        .padding(.top, 4)
    }
}

private struct OnePlusLinearUsageRow: View {
    let usage: OnePlusLinearUsage
    var body: some View {
        HStack(spacing: 8) {
            let fraction = usage.fraction.isFinite ? min(max(usage.fraction, 0), 1) : 0
            RoundedRectangle(cornerRadius: 3).fill(OnePlusLinearColor.barTrack)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 3).fill(usage.color).frame(width: proxy.size.width * fraction)
                    }
                }
                .frame(height: OnePlusLinearMetrics.usageBar)
                .accessibilityLabel("Usage").accessibilityValue("\(Int((fraction * 100).rounded())) percent")
            if let caption = usage.caption {
                Text(caption).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).fixedSize()
            }
        }
        .frame(height: 14)
        .padding(.horizontal, OnePlusLinearMetrics.tilePadding)
        .padding(.bottom, OnePlusLinearMetrics.usageRowBottom)
    }
}

private struct OnePlusLinearChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let chart: OnePlusLinearChart
    var body: some View {
        let paths = chart.series.map { OnePlusChartPaths.cached(values: $0.values, range: chart.range) }
        let fill = colorScheme == .dark ? OnePlusLinearColor.chartFillOpacity.dark : OnePlusLinearColor.chartFillOpacity.light
        Canvas { context, size in
            let width = size.width.isFinite ? max(0, size.width) : 0
            let height = size.height.isFinite ? max(0, size.height) : 0
            if chart.midline {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: height / 2)); line.addLine(to: CGPoint(x: width, y: height / 2))
                context.stroke(line, with: .color(OnePlusLinearColor.lineSoft), lineWidth: 1)
            }
            let transform = CGAffineTransform(scaleX: width, y: height)
            for (series, path) in zip(chart.series, paths) {
                if series.filled { context.fill(path.area.applying(transform), with: .color(series.color.opacity(fill))) }
                context.stroke(path.line.applying(transform), with: .color(series.color),
                               style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chart.series.first?.values.last.flatMap { $0.isFinite ? "Latest value \($0.formatted())" : nil } ?? "No history")
    }
}

/// A 32 pt control row for a panel card: 14 pt glyph, 48 pt name, quiet status, trailing control
/// (`OnePlusLinearSegmented` for Fan, a `Toggle` with `OnePlusLinearSwitchStyle` for Kwake).
public struct OnePlusLinearControlRow<Control: View>: View {
    private let title: String
    private let systemImage: String
    private let status: String?
    private let control: Control
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    public init(_ title: String, systemImage: String, status: String? = nil, @ViewBuilder control: () -> Control) {
        self.title = title; self.systemImage = systemImage; self.status = status; self.control = control()
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.rowGap) {
            Image(systemName: systemImage).font(.system(size: 12)).foregroundStyle(OnePlusLinearColor.panelMuted)
                .frame(width: 14, height: 14).accessibilityHidden(true)
            Text(title).linearText().lineLimit(1).frame(width: 48, alignment: .leading)
            if let status { Text(status).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.panelMuted).lineLimit(1) }
            Spacer(minLength: 0)
            control
        }
        .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
        .frame(height: OnePlusLinearMetrics.controlRow)
        .linearRowHover($hover, sample: sample, enabled: enabled)
        .accessibilityElement(children: .contain)
    }
}

/// A 30 pt process row: 16 pt app icon (terminal glyph when nil), name, CPU percent in the data color
/// (number and percent sign), memory. Pass preformatted strings.
public struct OnePlusLinearProcessRow: View {
    private let name: String
    private let icon: Image?
    private let cpu: String
    private let memory: String
    private let color: Color
    @State private var hover = false
    @Environment(\.onePlusControlState) private var sample
    @Environment(\.isEnabled) private var enabled
    public init(_ name: String, icon: Image?, cpu: String, memory: String, color: Color = OnePlusLinearColor.cpuText) {
        self.name = name; self.icon = icon; self.cpu = cpu; self.memory = memory; self.color = color
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
            Text(name).linearText().lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(cpu).linearText(weight: .medium, color: color)
                Text("%").linearText(OnePlusLinearMetrics.caption, color: color)
            }
            .frame(width: OnePlusLinearMetrics.cpuColumn, alignment: .trailing)
            Text(memory).linearText(color: OnePlusLinearColor.secondary).lineLimit(1)
                .frame(width: OnePlusLinearMetrics.memoryColumn, alignment: .trailing)
        }
        .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
        .frame(height: OnePlusLinearMetrics.processRow)
        .linearRowHover($hover, sample: sample, enabled: enabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), CPU \(cpu) percent, memory \(memory)")
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

/// One joined 28 pt action bar: equal segments, hairline dividers, glyph and label on one line,
/// full-segment hover.
public struct OnePlusLinearActionBar: View {
    private let actions: [OnePlusLinearAction]
    public init(_ actions: [OnePlusLinearAction]) { self.actions = actions }
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(actions) { item in
                Button(action: item.action) {
                    HStack(spacing: 6) {
                        Image(systemName: item.systemImage).font(.system(size: 12)).foregroundStyle(OnePlusLinearColor.secondary)
                            .frame(height: 14).accessibilityHidden(true)
                        Text(item.title).font(.system(size: OnePlusLinearMetrics.control, weight: .medium)).tracking(-0.04)
                            .foregroundStyle(OnePlusLinearColor.ink).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(OnePlusLinearButtonStyle(radius: 0))
                .overlay(alignment: .leading) {
                    if item.id != actions.first?.id { OnePlusLinearColor.lineSoft.frame(width: 1).allowsHitTesting(false) }
                }
                .accessibilityIdentifier(item.id)
            }
        }
        .frame(height: OnePlusLinearMetrics.actionBar)
        .clipShape(RoundedRectangle(cornerRadius: OnePlusLinearMetrics.radius))
        .linearRaised(radius: OnePlusLinearMetrics.radius)
    }
}
