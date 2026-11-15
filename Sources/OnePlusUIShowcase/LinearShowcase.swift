import AppKit
import OnePlusUI
import SwiftUI

/// Version 15 page: a full main window pane and a full menu panel from the Linear parts, with mockup sample data.
struct LinearShowcase: View {
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 32) {
                LinearMainWindowSample().frame(width: 820, height: 660)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                LinearPanelSample()
            }
            .padding(24)
        }
        .background(OnePlusLinearColor.sidebar)
    }
}

struct LinearToolSample: Identifiable {
    let name: String
    let summary: String
    let asset: String?
    let symbol: String
    var enabled: Bool
    var favorite: Bool
    var id: String { name }

    static let groups: [(String, [LinearToolSample])] = [
        ("Productivity", [
            .init(name: "Color Picker", summary: "Pick and save colors from anywhere on screen", asset: "ColorPicker", symbol: "eyedropper", enabled: true, favorite: true),
            .init(name: "Text Extractor", summary: "Copy text from any part of the screen", asset: "TextExtractor", symbol: "text.viewfinder", enabled: true, favorite: false),
            .init(name: "Ruler", summary: "Measure on-screen distances in px, mm, or in", asset: "Ruler", symbol: "ruler", enabled: true, favorite: false),
            .init(name: "Kwake", summary: "Keep your Mac awake for a set time", asset: "Awake", symbol: "eye", enabled: false, favorite: false),
        ]),
        ("System", [
            .init(name: "Task Manager", summary: "Live CPU, memory, disk, and process stats", asset: nil, symbol: "chart.xyaxis.line", enabled: true, favorite: true),
            .init(name: "System Cleaner", summary: "Find caches and leftovers to move to Trash", asset: "SystemCare", symbol: "shippingbox", enabled: true, favorite: false),
            .init(name: "Partition Manager", summary: "Inspect, resize, and format disk partitions", asset: "DiskExplorer", symbol: "opticaldisc", enabled: false, favorite: false),
            .init(name: "Event Viewer", summary: "Read app and system logs in one place", asset: "Logs", symbol: "list.bullet.rectangle", enabled: false, favorite: false),
            .init(name: "Mac Tweaks", summary: "Hidden macOS settings with one switch each", asset: "MacTweaks", symbol: "wand.and.stars", enabled: true, favorite: false),
            .init(name: "Input Devices", summary: "Separate mouse and trackpad scrolling", asset: nil, symbol: "computermouse", enabled: false, favorite: false),
        ]),
        ("Network and files", [
            .init(name: "NetToys", summary: "Scan networks and keep SSH hosts reachable", asset: "NetToys", symbol: "network", enabled: true, favorite: true),
            .init(name: "Portman", summary: "See and stop processes that hold ports", asset: "Portman", symbol: "cable.connector", enabled: true, favorite: false),
            .init(name: "RSync UI", summary: "Sync folders to cloud and remote storage", asset: "CloudSync", symbol: "cloud", enabled: true, favorite: false),
        ]),
    ]
}

/// Loads a tool icon from `ONEPLUS_SHOWCASE_ICONS` (an asset catalog folder) when set, else an SF Symbol stands in.
@MainActor
enum LinearSampleIcons {
    private static var cache: [String: Image] = [:]
    static func icon(_ tool: LinearToolSample) -> Image {
        if let cached = cache[tool.name] { return cached }
        var result = Image(systemName: tool.symbol)
        if let folder = ProcessInfo.processInfo.environment["ONEPLUS_SHOWCASE_ICONS"], let asset = tool.asset {
            for file in ["icon.png", "icon.svg"] {
                if let image = NSImage(contentsOfFile: "\(folder)/\(asset)Logo.imageset/\(file)") { result = Image(nsImage: image); break }
            }
        }
        cache[tool.name] = result
        return result
    }
    static func app(_ path: String) -> Image? {
        FileManager.default.fileExists(atPath: path) ? Image(nsImage: NSWorkspace.shared.icon(forFile: path)) : nil
    }
}

struct LinearMainWindowSample: View {
    @State private var groups = LinearToolSample.groups
    @State private var filter = "all"
    @State private var query = ""
    private var all: [LinearToolSample] { groups.flatMap(\.1) }

    var body: some View {
        HStack(spacing: 0) {
            OnePlusLinearSidebar {
                OnePlusLinearSearchField(text: $query)
            } navigation: {
                OnePlusLinearNavRow("All tools", systemImage: "square.grid.2x2", selected: true) {}
                ForEach(groups, id: \.0) { title, tools in
                    OnePlusLinearNavCaption(title)
                    ForEach(tools) { tool in
                        OnePlusLinearNavRow(tool.name, image: LinearSampleIcons.icon(tool)) {}
                    }
                }
            } bottom: {
                OnePlusLinearNavRow("Settings", systemImage: "gearshape", shortcut: "⌘,") {}
                OnePlusLinearNavRow("Exit", systemImage: "power", shortcut: "⌘Q") {}
            }
            VStack(spacing: 0) {
                OnePlusLinearPaneToolbar(title: "All tools", canGoBack: true, canGoForward: false, back: {}, forward: {}) {
                    OnePlusLinearTextTabs(tabs: [OnePlusTab("all", "All", count: all.count),
                                                 OnePlusTab("enabled", "Enabled", count: all.filter(\.enabled).count),
                                                 OnePlusTab("favorites", "Favorites", count: all.filter(\.favorite).count)],
                                          selection: $filter)
                }
                OnePlusLinearPaneBody {
                    ForEach(groups.indices, id: \.self) { group in
                        OnePlusLinearSection(groups[group].0, count: groups[group].1.count) {
                            ForEach(groups[group].1.indices, id: \.self) { index in
                                let tool = groups[group].1[index]
                                OnePlusLinearToolRow(tool.name, summary: tool.summary, icon: LinearSampleIcons.icon(tool),
                                                     isEnabled: $groups[group].1[index].enabled,
                                                     isFavorite: $groups[group].1[index].favorite) {}
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnePlusLinearColor.window)
        }
    }
}

struct LinearPanelSample: View {
    static let cpu: [Double] = [9.6, 8.3, 9.5, 10.3, 9.1, 19.4, 10.5, 11.2, 11.2, 25.5, 24.5, 8.4, 10.0, 10.1, 11.0, 12.5, 11.4, 11.1, 11.3, 27.3, 12.5, 13.2, 24.9, 27.7, 12.3, 12.7, 12.3, 10.9, 12.0, 27.6, 10.7, 12.0, 10.7, 11.9, 12.7, 26.4, 22.4, 10.4, 9.1, 9.2, 8.3, 7.7, 22.8, 23.9, 9.6, 8.2, 8.8, 7.3, 6.9, 21.1, 5.0, 6.5, 7.9, 8.2, 7.9, 7.9, 9.4, 10.0, 11.3, 12.9]
    static let gpu: [Double] = [2.3, 2.4, 2.7, 2.9, 2.9, 3.1, 2.8, 3.0, 3.2, 2.9, 2.8, 3.0, 3.2, 3.0, 2.7, 3.0, 3.1, 8.0, 3.0, 2.7, 2.8, 2.9, 3.2, 3.2, 3.2, 3.2, 3.4, 3.1, 3.1, 2.9, 2.7, 3.0, 8.3, 6.2, 7.7, 3.0, 3.0, 3.2, 3.0, 6.9, 8.1, 5.6, 2.3, 2.2, 2.2, 2.0, 1.7, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.7, 1.7, 6.1, 2.3, 2.6, 2.9, 3.3]
    static let down: [Double] = [4.2, 4.4, 5.6, 6.0, 5.3, 4.9, 4.0, 2.9, 4.1, 4.4, 4.6, 4.8, 3.5, 3.7, 4.5, 5.0, 4.2, 4.0, 5.0, 5.6, 6.7, 7.6, 7.9, 6.8, 5.6, 6.4, 5.6, 6.3, 5.1, 5.4, 4.7, 5.9, 5.2, 5.0, 5.4, 5.7, 6.0, 4.7, 16.3, 15.1, 17.4, 6.5, 7.2, 7.4, 6.6, 7.8, 7.5, 6.8, 20.3, 7.8, 7.9, 7.9, 7.7, 7.9, 23.7, 7.4, 7.7, 12.1, 17.2, 21.8]
    static let up: [Double] = [2.2, 2.3, 2.3, 2.5, 2.7, 2.7, 2.6, 2.7, 2.6, 2.3, 2.5, 5.3, 4.9, 4.9, 2.6, 2.5, 2.5, 2.7, 2.7, 2.5, 2.5, 2.5, 2.4, 2.3, 2.3, 2.1, 2.0, 2.1, 2.2, 2.3, 2.2, 4.2, 2.3, 2.2, 2.0, 2.2, 1.9, 2.1, 2.0, 4.0, 4.2, 2.0, 2.0, 2.2, 2.4, 2.5, 2.5, 2.5, 2.5, 2.4, 2.6, 2.7, 2.7, 2.5, 2.4, 4.9, 2.4, 2.9, 3.3, 3.7]
    private static let xcode = LinearSampleIcons.app("/Applications/Xcode.app")
    private static let chrome = LinearSampleIcons.app("/Applications/Google Chrome.app")
    private static let tabs = [OnePlusMenuTab("home", "Home", systemImage: "square.grid.2x2"),
                               OnePlusMenuTab("input-devices", "Input Devices", systemImage: "computermouse"),
                               OnePlusMenuTab("system-care", "System Cleaner", systemImage: "shippingbox"),
                               OnePlusMenuTab("nettoys", "NetToys", systemImage: "network"),
                               OnePlusMenuTab("rclone", "RSync UI", systemImage: "arrow.up.arrow.down")]
    @State private var fan = "Auto"
    @State private var kwake = true
    @State private var tab = "home"

    var body: some View {
        OnePlusLinearPanel {
            VStack(spacing: 0) {
                OnePlusLinearPanelHeader("System", note: "Last 60 s")
                OnePlusLinearBento { leadingTiles } trailing: { trailingTiles }
            }
            OnePlusLinearList(style: .panel) {
                OnePlusLinearControlRow("Fan", systemImage: "fan", status: "3,472 RPM") {
                    OnePlusLinearSegmented(choices: [("Auto", "Auto"), ("Cool", "Cool"), ("Max", "Max")], selection: $fan,
                                           accessibilityLabel: "Fan mode")
                }
                OnePlusLinearControlRow("Kwake", systemImage: "eye", status: "Indefinite") {
                    Toggle("Kwake", isOn: $kwake).toggleStyle(OnePlusLinearSwitchStyle())
                }
            }
            VStack(spacing: 0) {
                OnePlusLinearPanelHeader.processes()
                OnePlusLinearList(style: .panel) {
                    OnePlusLinearProcessRow("WindowServer", icon: nil, cpu: "6.1", memory: "1.2 GB")
                    OnePlusLinearProcessRow("Xcode", icon: Self.xcode, cpu: "4.8", memory: "3.9 GB")
                    OnePlusLinearProcessRow("Google Chrome", icon: Self.chrome, cpu: "3.2", memory: "2.1 GB")
                }
            }
            OnePlusLinearActionBar([
                OnePlusLinearAction("Pick Color", systemImage: "eyedropper") {},
                OnePlusLinearAction("Extract Text", systemImage: "text.viewfinder") {},
                OnePlusLinearAction("Ruler", systemImage: "ruler") {},
            ])
        } footer: {
            OnePlusLinearPanelFooter {
                OnePlusLinearIconTabs(tabs: Self.tabs, selection: $tab)
            } trailing: {
                OnePlusLinearIconButton(systemImage: "gearshape", help: "Settings") {}
                Button("Open App") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
            }
        }
    }

    @ViewBuilder private var leadingTiles: some View {
        OnePlusLinearTile(height: OnePlusLinearMetrics.tallTile,
                          chart: OnePlusLinearChart([OnePlusLinearSeries(Self.cpu, color: OnePlusLinearColor.cpu)], range: 0...56,
                                                    height: OnePlusLinearMetrics.tallChart, midline: true)) {
            OnePlusLinearTileLabel("CPU", systemImage: "cpu", color: OnePlusLinearColor.cpu, meta: "14 cores")
            OnePlusLinearTileValue("23", unit: "%")
            OnePlusLinearTileSplit([("User", "14", "%"), ("System", "9", "%")])
        }
        OnePlusLinearTile(height: OnePlusLinearMetrics.shortTile,
                          usage: OnePlusLinearUsage(0.388, color: OnePlusLinearColor.disk, caption: "388 GB used")) {
            OnePlusLinearTileLabel("Disk", systemImage: "internaldrive", color: OnePlusLinearColor.disk) {
                OnePlusLinearInlineValue("612", unit: "GB free")
            }
        }
        OnePlusLinearTile(height: OnePlusLinearMetrics.shortTile,
                          usage: OnePlusLinearUsage(0.86, color: OnePlusLinearColor.battery, caption: "3:52 left")) {
            OnePlusLinearTileLabel("Battery", systemImage: "battery.75percent", color: OnePlusLinearColor.battery) {
                OnePlusLinearInlineValue("86", unit: "%")
            }
        }
    }

    @ViewBuilder private var trailingTiles: some View {
        OnePlusLinearTile(chart: OnePlusLinearChart([OnePlusLinearSeries(Self.gpu, color: OnePlusLinearColor.gpu)], range: 0...30)) {
            OnePlusLinearTileLabel("GPU", systemImage: "display", color: OnePlusLinearColor.gpu, meta: "Apple GPU")
            OnePlusLinearTileValue("11", unit: "%")
        }
        OnePlusLinearTile(usage: OnePlusLinearUsage(0.383, color: OnePlusLinearColor.memory)) {
            OnePlusLinearTileLabel("Memory", systemImage: "memorychip", color: OnePlusLinearColor.memory, meta: "48 GB")
            OnePlusLinearTileValue("38", unit: "%", note: "18.4 GB used")
        }
        OnePlusLinearTile(chart: OnePlusLinearChart([OnePlusLinearSeries(Self.down, color: OnePlusLinearColor.networkDown),
                                                     OnePlusLinearSeries(Self.up, color: OnePlusLinearColor.networkUp, filled: false)],
                                                    range: 0...30)) {
            OnePlusLinearTileLabel("Network", systemImage: "network", color: OnePlusLinearColor.networkDown) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").font(.system(size: 9, weight: .medium))
                    Text("310 KB/s").font(.system(size: OnePlusLinearMetrics.caption))
                }.foregroundStyle(OnePlusLinearColor.networkUp)
            }
            OnePlusLinearTileValue("2.4", unit: "MB/s", glyph: ("arrow.down", OnePlusLinearColor.networkDown))
        }
    }
}
