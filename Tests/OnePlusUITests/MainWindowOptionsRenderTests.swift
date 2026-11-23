import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI
@testable import OnePlusUIShowcase

/// Round 1 main window options, Light and Dark at 2x, with a manifest for the decision page.
/// Every panel is composed from the real OnePlusLinear parts the app uses; only the option under test changes.
@MainActor
final class MainWindowOptionsRenderTests: XCTestCase {
    private static let output = "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-main-r1"
    private static let window = CGSize(width: 820, height: 660)

    private struct Option { let file: String; let name: String; let text: String; let size: CGSize; let view: AnyView }

    func testRenderMainWindowOptions() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        let tall = CGSize(width: 820, height: 1120)
        let pair = CGSize(width: 1700, height: 700)
        let groups: [(String, [Option])] = [
            ("Toolbar tabs", [
                Option(file: "tabs-full", name: "Full-tab underline (shipped)",
                       text: "The underline now runs 8 pt past the label and count on each side, and the last tab ends on the right inset.",
                       size: Self.window, view: AnyView(MWWindow(selected: nil) { MWAllTools(rows: .keep) })),
            ]),
            ("Home rows", [
                Option(file: "home-quiet-off", name: "Quiet Off",
                       text: "No switch on Home; a tool that is off shows a dim icon, a gray name, and the word Off.",
                       size: Self.window, view: AnyView(MWWindow(selected: nil) { MWAllTools(rows: .off) })),
                Option(file: "home-off-section", name: "Off section",
                       text: "No switch on Home; tools that are off leave their category and wait in one Off section at the end.",
                       size: Self.window, view: AnyView(MWWindow(selected: nil) { MWAllTools(rows: .offSection) })),
                Option(file: "home-dot", name: "Status column",
                       text: "No switch on Home; every row ends with a small dot and the word On or Off in one aligned column.",
                       size: Self.window, view: AnyView(MWWindow(selected: nil) { MWAllTools(rows: .dot) })),
                Option(file: "home-keep", name: "Keep as is",
                       text: "Every row keeps its enable switch.",
                       size: Self.window, view: AnyView(MWWindow(selected: nil) { MWAllTools(rows: .keep) })),
            ]),
            ("Enable control on the tool page", [
                Option(file: "enable-row", name: "Enabled row",
                       text: "The header keeps only Open Ruler; an Enabled row with a switch and one line of help sits right below it, like System Settings.",
                       size: Self.window, view: AnyView(MWWindow(selected: "Ruler") { MWToolPage(tool: .ruler, enable: .row) })),
                Option(file: "enable-toolbar", name: "Toolbar switch",
                       text: "An Enabled switch sits at the right end of the pane toolbar, the same place on every tool page.",
                       size: Self.window, view: AnyView(MWWindow(selected: "Ruler") { MWToolPage(tool: .ruler, enable: .toolbar) })),
                Option(file: "enable-menu", name: "More menu",
                       text: "Turn Off lives in a ••• menu beside Open; shown here while Ruler is off, with the Turn On notice.",
                       size: Self.window, view: AnyView(MWWindow(selected: "Ruler") { MWToolPage(tool: .ruler, enable: .menu, on: false) })),
                Option(file: "enable-keep", name: "Keep as is",
                       text: "The switch stays in the header beside Open Ruler.",
                       size: Self.window, view: AnyView(MWWindow(selected: "Ruler") { MWToolPage(tool: .ruler, enable: .header) })),
            ]),
            ("Ruler page", [
                Option(file: "ruler-inline", name: "Settings inline",
                       text: "The Ruler Defaults settings sit on the page; only the per-ruler Settings window stays native. Shown as one tall page; the window scrolls.",
                       size: tall, view: AnyView(MWWindow(selected: "Ruler") { MWToolPage(tool: .ruler, enable: .row, inline: true) })),
                Option(file: "ruler-keep", name: "Keep as is",
                       text: "Two buttons open the native Settings and Defaults windows.",
                       size: tall, view: AnyView(MWWindow(selected: "Ruler") { MWToolPage(tool: .ruler, enable: .header) })),
            ]),
            ("Color Picker page", [
                Option(file: "color-inline", name: "Settings inline",
                       text: "The shortcut, its switch, and the copy format sit on the page in main window lists; Clear all stays as red text.",
                       size: tall, view: AnyView(MWWindow(selected: "Color Picker") { MWToolPage(tool: .colorPicker, enable: .row, inline: true) })),
                Option(file: "color-keep", name: "Keep as is",
                       text: "The applet's filled settings groups are embedded on the page.",
                       size: tall, view: AnyView(MWWindow(selected: "Color Picker") { MWToolPage(tool: .colorPicker, enable: .header) })),
            ]),
            ("Kwake page", [
                Option(file: "kwake-inline", name: "Settings inline",
                       text: "Only Keep display on moves to the page; timers, end times, quick times, and process attach stay in the Kwake window.",
                       size: tall, view: AnyView(MWWindow(selected: "Kwake") { MWToolPage(tool: .kwake, enable: .row, inline: true) })),
                Option(file: "kwake-keep", name: "Keep as is",
                       text: "The whole Kwake session form, quick times, and process attach are embedded on the page.",
                       size: tall, view: AnyView(MWWindow(selected: "Kwake") { MWToolPage(tool: .kwake, enable: .header) })),
            ]),
            ("Applet gear", [
                Option(file: "gear-opens-page", name: "Gear opens the tool page",
                       text: "The applet gear opens this main window page; the applet keeps no Settings page of its own.",
                       size: tall, view: AnyView(MWWindow(selected: "Color Picker") { MWToolPage(tool: .colorPicker, enable: .row, inline: true) })),
                Option(file: "gear-reduced", name: "Reduced applet Settings",
                       text: "The applet keeps a short Settings page with Clear all and a link to the rest in MacPowerToys.",
                       size: CGSize(width: 420, height: 300), view: AnyView(MWReducedAppletSettings())),
            ]),
            ("Premium direction", [
                Option(file: "premium-grouped", name: "Grouped inset",
                       text: "System Settings calm: filled groups with no borders, 44 pt two-line rows, 28 pt icons, and the applet look carried into the main window.",
                       size: pair, view: AnyView(MWPair(look: .grouped))),
                Option(file: "premium-editorial", name: "Editorial list",
                       text: "A large title in the body, borderless rows on hairlines, 32 pt gutters, and big quiet tool headers.",
                       size: pair, view: AnyView(MWPair(look: .editorial))),
                Option(file: "premium-table", name: "Pro table",
                       text: "Finder-like density: one zebra table with Name, Category, Status, and Shortcut columns, and key-value settings rows.",
                       size: pair, view: AnyView(MWPair(look: .table))),
                Option(file: "premium-keep", name: "Keep as is",
                       text: "The current Linear lists with a 1 pt ring and the enable switches.",
                       size: pair, view: AnyView(MWPair(look: .linear))),
            ]),
        ]
        var manifest: [[String: Any]] = []
        for (group, options) in groups {
            var entries: [[String: Any]] = []
            for (index, option) in options.enumerated() {
                for appearance: NSAppearance.Name in [.aqua, .darkAqua] {
                    let host = NSHostingView(rootView: option.view.frame(width: option.size.width, height: option.size.height))
                    let render = try LinearRender.bitmap(host, size: option.size, scale: 2, appearance: appearance)
                    let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
                    try data.write(to: URL(fileURLWithPath: "\(Self.output)/\(option.file)-\(appearance == .darkAqua ? "dark" : "light").png"))
                }
                entries.append(["name": option.name, "recommended": index == 0 && options.count > 1, "text": option.text,
                                "light": "\(option.file)-light.png", "dark": "\(option.file)-dark.png"])
            }
            manifest.append(["group": group, "options": entries])
        }
        let json = try JSONSerialization.data(withJSONObject: ["groups": manifest], options: [.prettyPrinted, .sortedKeys])
        try json.write(to: URL(fileURLWithPath: "\(Self.output)/manifest.json"))
    }
}

// MARK: - Sample data

struct MWTool: Identifiable {
    let name: String
    let summary: String
    let detail: String
    let asset: String
    let category: String
    var on = true
    var favorite = false
    var shortcut = ""
    var id: String { name }

    static let ruler = MWTool(name: "Ruler", summary: "Measure on-screen distances in px, mm, or in",
                              detail: "Measure the screen with movable, resizable rulers in pixels, millimeters, or inches.",
                              asset: "RulerLogo", category: "Developer", favorite: true, shortcut: "⌥⌘R")
    static let colorPicker = MWTool(name: "Color Picker", summary: "Pick and save colors from anywhere on screen",
                                    detail: "Pick any onscreen color, copy it instantly, and keep a compact searchable history of useful values.",
                                    asset: "ColorPickerLogo", category: "Developer", favorite: true, shortcut: "⌘⇧3")
    static let kwake = MWTool(name: "Kwake", summary: "Keep your Mac awake for a set time",
                              detail: "Keep your Mac awake indefinitely, for a duration, or until a chosen time without changing Energy settings.",
                              asset: "AwakeLogo", category: "System")

    static let groups: [(String, [MWTool])] = [
        ("System", [kwake,
                    MWTool(name: "Mac Tweaks", summary: "Hidden macOS settings with one switch each", detail: "", asset: "MacTweaksLogo", category: "System"),
                    MWTool(name: "Event Viewer", summary: "Read app and system logs in one place", detail: "", asset: "LogsLogo", category: "System", on: false),
                    MWTool(name: "Input Devices", summary: "Separate mouse and trackpad scrolling", detail: "", asset: "InputDevicesLogoA", category: "System", on: false)]),
        ("Developer", [ruler,
                       MWTool(name: "Portman", summary: "See and stop processes that hold ports", detail: "", asset: "PortmanLogo", category: "Developer", shortcut: "⌥⌘P"),
                       colorPicker]),
        ("Text", [MWTool(name: "Text Extractor", summary: "Copy text from any part of the screen", detail: "", asset: "TextExtractorLogo", category: "Text", shortcut: "⌘⇧2")]),
        ("Files", [MWTool(name: "RSync UI", summary: "Sync folders to cloud and remote storage", detail: "", asset: "CloudSyncLogo", category: "Files")]),
    ]
    static var all: [MWTool] { groups.flatMap(\.1) }
}

@MainActor
enum MWIcons {
    private static let folder = "/Volumes/External1TB/dev/organization/samhq/macpowertoys/powertoys/Assets.xcassets"
    private static var cache: [String: Image] = [:]
    static func icon(_ asset: String) -> Image {
        if let cached = cache[asset] { return cached }
        var result = Image(systemName: "app")
        for file in ["icon.png", "icon.svg"] {
            if let image = NSImage(contentsOfFile: "\(folder)/\(asset).imageset/\(file)") { result = Image(nsImage: image); break }
        }
        cache[asset] = result
        return result
    }
}

// MARK: - Window shell

struct MWLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1, green: 0.373, blue: 0.341))
            Circle().fill(Color(red: 0.996, green: 0.737, blue: 0.180))
            Circle().fill(OnePlusLinearColor.switchOff)
        }
        .frame(width: 52, height: 12)
        .padding(.leading, 13).padding(.top, OnePlusLinearMetrics.toolbar / 2 - 6)
        .allowsHitTesting(false)
    }
}

struct MWWindow<Pane: View>: View {
    let selected: String?
    @ViewBuilder let pane: Pane
    var body: some View {
        HStack(spacing: 0) {
            OnePlusLinearSidebar {
                OnePlusLinearSearchField(text: .constant(""))
            } navigation: {
                OnePlusLinearNavRow("All tools", systemImage: "square.grid.2x2", selected: selected == nil) {}
                ForEach(MWTool.groups, id: \.0) { title, tools in
                    OnePlusLinearNavCaption(title)
                    ForEach(tools) { tool in
                        OnePlusLinearNavRow(tool.name, image: MWIcons.icon(tool.asset), selected: selected == tool.name, dimmed: !tool.on) {}
                    }
                }
            } bottom: {
                OnePlusLinearNavRow("Settings", systemImage: "gearshape", shortcut: "⌘,") {}
                OnePlusLinearNavRow("Exit", systemImage: "power", shortcut: "⌘Q") {}
            }
            pane.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(OnePlusLinearColor.window)
        }
        .overlay(alignment: .topLeading) { MWLights() }
    }
}

struct MWTabs: View {
    @State private var selection = "all"
    var body: some View {
        let all = MWTool.all
        OnePlusLinearTextTabs(tabs: [OnePlusTab("all", "All", count: all.count),
                                     OnePlusTab("enabled", "Enabled", count: all.filter(\.on).count),
                                     OnePlusTab("favorites", "Favorites", count: all.filter(\.favorite).count)],
                              selection: $selection)
    }
}

// MARK: - Home rows

enum MWRowTrailing { case keep, off, offSection, dot }

struct MWHomeRow: View {
    let tool: MWTool
    let trailing: MWRowTrailing
    @State private var on: Bool
    init(tool: MWTool, trailing: MWRowTrailing) { self.tool = tool; self.trailing = trailing; _on = State(initialValue: tool.on) }

    var body: some View {
        if trailing == .keep {
            OnePlusLinearToolRow(tool.name, summary: tool.summary, icon: MWIcons.icon(tool.asset), isEnabled: $on,
                                 isFavorite: .constant(tool.favorite)) {}
        } else {
            HStack(spacing: OnePlusLinearMetrics.toolRowGap) {
                MWIcons.icon(tool.asset).resizable().scaledToFit()
                    .frame(width: OnePlusLinearMetrics.toolIcon, height: OnePlusLinearMetrics.toolIcon)
                    .opacity(tool.on ? 1 : 0.45)
                Text(tool.name).linearText(weight: .medium, color: tool.on ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                    .lineLimit(1).frame(width: OnePlusLinearMetrics.toolNameWidth, alignment: .leading)
                Text(tool.summary).linearText(color: tool.on ? OnePlusLinearColor.secondary : OnePlusLinearColor.muted)
                    .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "star.fill").font(.system(size: 11))
                    .foregroundStyle(tool.favorite ? OnePlusLinearColor.accent : .clear)
                    .frame(width: OnePlusLinearMetrics.starSlot)
                status
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium)).foregroundStyle(OnePlusLinearColor.tertiary)
            }
            .padding(.horizontal, OnePlusLinearMetrics.toolRowPadding)
            .frame(height: OnePlusLinearMetrics.toolRow)
        }
    }

    @ViewBuilder private var status: some View {
        switch trailing {
        case .off:
            Text(tool.on ? "" : "Off").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted)
                .frame(width: 24, alignment: .trailing)
        case .dot:
            HStack(spacing: 6) {
                Circle().strokeBorder(tool.on ? Color.clear : OnePlusLinearColor.muted, lineWidth: 1)
                    .background(Circle().fill(tool.on ? OnePlusLinearColor.secondary : .clear))
                    .frame(width: 6, height: 6)
                Text(tool.on ? "On" : "Off").linearText(OnePlusLinearMetrics.control, color: tool.on ? OnePlusLinearColor.secondary : OnePlusLinearColor.muted)
            }
            .frame(width: 36, alignment: .leading)
        default:
            EmptyView()
        }
    }
}

struct MWAllTools: View {
    let rows: MWRowTrailing
    var body: some View {
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: "All tools", canGoBack: false, canGoForward: true, back: {}, forward: {}) { MWTabs() }
            OnePlusLinearPaneBody {
                ForEach(MWTool.groups, id: \.0) { title, tools in
                    let shown = rows == .offSection ? tools.filter(\.on) : tools
                    if !shown.isEmpty {
                        OnePlusLinearSection(title, count: shown.count) {
                            ForEach(shown) { MWHomeRow(tool: $0, trailing: rows) }
                        }
                    }
                }
                if rows == .offSection {
                    let off = MWTool.all.filter { !$0.on }
                    OnePlusLinearSection("Off", count: off.count) {
                        ForEach(off) { MWHomeRow(tool: $0, trailing: rows) }
                    }
                }
            }
        }
    }
}

// MARK: - Tool page

enum MWEnable { case header, row, toolbar, menu }

struct MWRow<Trailing: View>: View {
    let label: String
    var detail: String? = nil
    @ViewBuilder let trailing: Trailing
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).linearText().lineLimit(1)
                if let detail { Text(detail).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary).lineLimit(2) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, OnePlusLinearMetrics.toolRowPadding)
        .padding(.vertical, detail == nil ? 0 : 8)
        .frame(minHeight: 40)
    }
}

struct MWToolHeader<Controls: View>: View {
    let tool: MWTool
    @ViewBuilder let controls: Controls
    var body: some View {
        OnePlusLinearList {
            HStack(spacing: OnePlusLinearMetrics.toolRowGap) {
                MWIcons.icon(tool.asset).resizable().scaledToFit().frame(width: 32, height: 32).opacity(tool.on ? 1 : 0.45)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.name).linearText(weight: .semibold)
                    Text(tool.detail).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                controls
            }
            .padding(.horizontal, OnePlusLinearMetrics.toolRowPadding)
            .padding(.vertical, 10)
        }
    }
}

struct MWToolPage: View {
    let tool: MWTool
    let enable: MWEnable
    var inline = false
    @State private var on: Bool
    init(tool: MWTool, enable: MWEnable, on: Bool = true, inline: Bool = false) {
        var shown = tool; shown.on = on
        self.tool = shown; self.enable = enable; self.inline = inline; _on = State(initialValue: on)
    }

    var body: some View {
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: tool.name, canGoBack: true, canGoForward: false, back: {}, forward: {}) {
                if enable == .toolbar {
                    HStack(spacing: 8) {
                        Text("Enabled").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                        Toggle("Enable \(tool.name)", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                    }
                }
            }
            OnePlusLinearPaneBody {
                MWToolHeader(tool: tool) {
                    if enable == .header { Toggle("Enable", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden() }
                    Button("Open \(tool.name)") {}.buttonStyle(OnePlusLinearButtonStyle(.raised)).disabled(!on)
                    if enable == .menu { OnePlusLinearIconButton(systemImage: "ellipsis", help: "More") {} }
                }
                if enable == .menu && !on {
                    OnePlusLinearBanner(.info, title: "\(tool.name) is off.", message: "Its shortcut, menu bar icon, and Raycast command do nothing.") {
                        Button("Turn On") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
                    }
                }
                if enable == .row {
                    OnePlusLinearList {
                        MWRow(label: "Enabled", detail: "Turn off to hide \(tool.name) from the menu bar, shortcuts, and Raycast.") {
                            Toggle("Enable \(tool.name)", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                        }
                        if tool.name != "Ruler" { placement }
                    }
                } else if tool.name != "Ruler" {
                    OnePlusLinearList { placement }
                }
                settings
                OnePlusLinearSection("How to use") {
                    MWRow(label: "1.  Open \(tool.name) from the menu bar, a shortcut, or Raycast.") { EmptyView() }
                    MWRow(label: "2.  Press ⌘, inside the tool to change its settings.") { EmptyView() }
                }
            }
        }
    }

    private var placement: some View {
        MWRow(label: "Menu bar icon") {
            OnePlusLinearSegmented(choices: [("none", "None"), ("combined", "Combined"), ("separate", "Separate")],
                                   selection: .constant("combined"), accessibilityLabel: "Menu bar icon", sizing: .fitted)
        }
    }

    @ViewBuilder private var settings: some View {
        switch (tool.name, inline) {
        case ("Ruler", true): MWRulerInline()
        case ("Ruler", false):
            OnePlusLinearList {
                MWRow(label: "Settings for the active rulers") { Button("Open Ruler Settings") {}.buttonStyle(OnePlusLinearButtonStyle(.raised)) }
                MWRow(label: "Defaults for new rulers") { Button("Open Defaults") {}.buttonStyle(OnePlusLinearButtonStyle(.raised)) }
            }
        case ("Color Picker", true): MWColorInline()
        case ("Color Picker", false): MWColorKeep()
        case ("Kwake", true): MWKwakeInline()
        default: MWKwakeKeep()
        }
    }
}

// MARK: - Inline settings (main window lists, Quiet Raised controls)

struct MWRulerInline: View {
    @State private var unit = "px"
    @State private var width = 1920
    @State private var height = 1080
    @State private var color = NSColor(srgbRed: 1, green: 0.859, blue: 0, alpha: 1)
    @State private var foreground = 1.0
    @State private var background = 0.5
    @State private var border = 0.25
    @State private var floats = true
    @State private var shadow = false
    @State private var grouped = true

    var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionGap) {
            OnePlusLinearSection("Defaults for new rulers") {
                MWRow(label: "Unit") {
                    OnePlusLinearSegmented(choices: [("px", "px"), ("mm", "mm"), ("in", "in")], selection: $unit, accessibilityLabel: "Unit")
                }
                MWRow(label: "Dimensions") {
                    HStack(spacing: 6) {
                        OnePlusStepperField("Width", value: $width, in: 1...10000)
                        Text("×").linearText(color: OnePlusLinearColor.muted)
                        OnePlusStepperField("Height", value: $height, in: 1...10000)
                    }
                }
                MWRow(label: "Ruler color") { OnePlusLinearColorWell("Ruler color", color: $color) }
                MWSliderRow(label: "Foreground opacity", value: $foreground)
                MWSliderRow(label: "Background opacity", value: $background)
                MWSliderRow(label: "Border opacity", value: $border)
            }
            OnePlusLinearSection("Behavior") {
                MWRow(label: "Float ruler above other applications") { MWSwitch(label: "Float", isOn: $floats) }
                MWRow(label: "Show ruler shadow") { MWSwitch(label: "Shadow", isOn: $shadow) }
                MWRow(label: "Move both wings together") { MWSwitch(label: "Group", isOn: $grouped) }
            }
            OnePlusLinearList {
                MWRow(label: "Settings for the active rulers", detail: "Each ruler keeps its own color, size, and opacity.") {
                    Button("Open Ruler Settings") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
                }
                MWRow(label: "") { Button("Reset to Factory Defaults", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive)) }
            }
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}

struct MWColorInline: View {
    @State private var enabled = true
    @State private var format = "hex"
    var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionGap) {
            OnePlusLinearSection("Shortcut") {
                MWRow(label: "Pick Color shortcut") { MWSwitch(label: "Pick Color shortcut", isOn: $enabled) }
                MWRow(label: "Keyboard shortcut", detail: "Works in every app.") { MWShortcutField(keys: "⌘⇧3") }
            }
            OnePlusLinearSection("Saved colors") {
                MWRow(label: "Copy format") {
                    OnePlusLinearSelect(choices: [("hex", "HEX"), ("rgb", "RGB"), ("hsl", "HSL")], selection: $format,
                                        accessibilityLabel: "Copy format", width: 120)
                }
                MWRow(label: "") { Button("Clear All Saved Colors", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive)) }
            }
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}

struct MWColorKeep: View {
    @State private var enabled = true
    @State private var format = "hex"
    var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionGap) {
            OnePlusLinearAppletSection("Global shortcut") {
                OnePlusLinearAppletRow("Enable shortcut") { MWSwitch(label: "Enable shortcut", isOn: $enabled) }
                OnePlusLinearAppletRow("Keyboard shortcut", detail: "Works in every app.") { MWShortcutField(keys: "⌘⇧3") }
            }
            OnePlusLinearAppletSection("Saved colors") {
                OnePlusLinearAppletRow("Copy format") {
                    OnePlusLinearSelect(choices: [("hex", "HEX"), ("rgb", "RGB")], selection: $format, accessibilityLabel: "Copy format", width: 120)
                }
            }
            Button("Clear All Saved Colors", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive))
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}

struct MWKwakeInline: View {
    @State private var display = false
    var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionGap) {
            OnePlusLinearSection("Settings") {
                MWRow(label: "Keep display on", detail: "When Kwake runs, the screen stays on too.") { MWSwitch(label: "Keep display on", isOn: $display) }
            }
            OnePlusLinearList {
                MWRow(label: "Timers, end times, quick times, and process attach", detail: "These start a session, so they live in the Kwake window.") {
                    Button("Open Kwake") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
                }
            }
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}

struct MWKwakeKeep: View {
    @State private var mode = "off"
    @State private var display = false
    @State private var hours = 1
    @State private var minutes = 30
    var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionGap) {
            OnePlusLinearAppletSection("Session") {
                OnePlusLinearAppletRow("Keep awake") {
                    OnePlusLinearSelect(choices: [("off", "Off"), ("on", "Indefinitely"), ("for", "For a duration"), ("until", "Until a time")],
                                        selection: $mode, accessibilityLabel: "Keep awake", width: 150)
                }
                OnePlusLinearAppletRow("Keep display on") { MWSwitch(label: "Keep display on", isOn: $display) }
                OnePlusLinearAppletRow("Duration") {
                    HStack(spacing: 6) {
                        OnePlusStepperField("Hours", value: $hours, in: 0...24, unit: "h")
                        OnePlusStepperField("Minutes", value: $minutes, in: 0...59, unit: "m")
                        Button("Start") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                    }
                }
            }
            OnePlusLinearAppletSection("Quick times") {
                OnePlusLinearAppletRow("Presets") {
                    HStack(spacing: 6) {
                        ForEach(["15 m", "30 m", "1 h", "2 h"], id: \.self) { Button($0) {}.buttonStyle(OnePlusLinearButtonStyle(.soft)) }
                    }
                }
            }
            OnePlusLinearAppletSection("Attach to a process") {
                OnePlusLinearAppletRow("Process ID", detail: "Kwake stops when this process quits.") {
                    Button("Attach") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                }
            }
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}

struct MWSwitch: View {
    let label: String
    @Binding var isOn: Bool
    var body: some View { Toggle(label, isOn: $isOn).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden() }
}

struct MWSliderRow: View {
    let label: String
    @Binding var value: Double
    var body: some View {
        MWRow(label: label) {
            HStack(spacing: 8) {
                OnePlusLinearSlider(label, value: $value)
                Text("\(Int((value * 100).rounded()))%").linearText(color: OnePlusLinearColor.secondary)
                    .frame(width: OnePlusLinearControlLook.quietRaised.sliderValueWidth, alignment: .trailing)
            }
        }
    }
}

/// The recorder's resting face: the keys in a Quiet Raised field.
struct MWShortcutField: View {
    let keys: String
    var body: some View {
        Text(keys).linearText(color: OnePlusLinearColor.ink)
            .frame(width: 120, height: OnePlusLinearControlLook.quietRaised.height)
            .linearFieldBezel(.quietRaised)
    }
}

struct MWReducedAppletSettings: View {
    var body: some View {
        OnePlusLinearApplet("Color Picker", actions: {
            OnePlusLinearAppletSettingsButton(isActive: true) {}
            Button("Pick Color") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
        }) {
            OnePlusLinearAppletForm {
                OnePlusLinearAppletSection("Saved colors") {
                    OnePlusLinearAppletRow("Saved colors", value: "128 colors in 4 projects")
                    OnePlusLinearAppletRow("Shortcut, copy format, and more") {
                        Button("Open in MacPowerToys") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                    }
                }
            } footer: {
                Button("Clear All Saved Colors", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive))
            }
        }
        .overlay(alignment: .topLeading) { LinearSampleLights() }
        .environment(\.onePlusZoomTrailingX, 66)
    }
}

// MARK: - Premium directions

enum MWLook { case linear, grouped, editorial, table }

struct MWPair: View {
    let look: MWLook
    var body: some View {
        HStack(spacing: 20) {
            MWWindow(selected: nil) { MWLookAllTools(look: look) }
                .frame(width: 820, height: 660).clipShape(RoundedRectangle(cornerRadius: 12))
            MWWindow(selected: "Ruler") { MWLookRuler(look: look) }
                .frame(width: 820, height: 660).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OnePlusLinearColor.sidebar.opacity(0.6))
    }
}

/// A group of rows drawn in one look. Hairlines between rows; the look decides the surface.
struct MWLookGroup<Content: View>: View {
    let look: MWLook
    @ViewBuilder let content: Content
    var body: some View {
        switch look {
        case .linear: OnePlusLinearList { content }
        case .grouped: OnePlusLinearAppletGroup { content }
        case .editorial:
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(rows) { row in row.overlay(alignment: .bottom) { OnePlusLinearColor.lineSoft.frame(height: 1) } }
                }
            }
            .overlay(alignment: .top) { OnePlusLinearColor.line.frame(height: 1) }
        case .table:
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(rows.indices, id: \.self) { index in
                        rows[index].background(index % 2 == 1 ? OnePlusLinearColor.hover : Color.clear)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(OnePlusLinearColor.line, lineWidth: 1) }
        }
    }
}

struct MWLookCaption: View {
    let title: String
    let look: MWLook
    var count: Int? = nil
    var body: some View {
        switch look {
        case .editorial:
            Text(title).linearText(weight: .semibold).padding(.top, 8).padding(.bottom, 8)
        default:
            OnePlusLinearSectionCaption(title, count: count).padding(.leading, look == .grouped ? 12 : 0)
        }
    }
}

struct MWLookBody<Content: View>: View {
    let look: MWLook
    @ViewBuilder let content: Content
    var body: some View {
        if look == .editorial {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) { content }
                    .padding(.top, 20).padding(.horizontal, 32).padding(.bottom, 24)
            }
        } else {
            OnePlusLinearPaneBody { content }
        }
    }
}

struct MWLookAllTools: View {
    let look: MWLook
    var body: some View {
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: look == .editorial ? "" : "All tools", canGoBack: false, canGoForward: true,
                                     back: {}, forward: {}) { MWTabs() }
            MWLookBody(look: look) {
                if look == .editorial {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All tools").font(.system(size: 24, weight: .semibold)).tracking(-0.6).foregroundStyle(OnePlusLinearColor.ink)
                        Text("9 tools, 7 on").linearText(color: OnePlusLinearColor.secondary)
                    }
                }
                if look == .table {
                    MWTable()
                } else {
                    ForEach(MWTool.groups, id: \.0) { title, tools in
                        VStack(alignment: .leading, spacing: look == .editorial ? 0 : OnePlusLinearMetrics.sectionCaptionBelow) {
                            MWLookCaption(title: title, look: look, count: tools.count)
                            MWLookGroup(look: look) {
                                ForEach(tools) { tool in
                                    if look == .linear { MWHomeRow(tool: tool, trailing: .keep) } else { MWLookRow(tool: tool, look: look) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MWLookRow: View {
    let tool: MWTool
    let look: MWLook
    var body: some View {
        let icon: CGFloat = look == .grouped ? 28 : 24
        HStack(spacing: 12) {
            MWIcons.icon(tool.asset).resizable().scaledToFit().frame(width: icon, height: icon).opacity(tool.on ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 1) {
                Text(tool.name).linearText(weight: .medium, color: tool.on ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
                Text(tool.summary).linearText(OnePlusLinearMetrics.caption, color: tool.on ? OnePlusLinearColor.secondary : OnePlusLinearColor.muted)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if tool.favorite {
                Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(OnePlusLinearColor.accent)
            }
            if !tool.on { Text("Off").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted) }
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium)).foregroundStyle(OnePlusLinearColor.tertiary)
        }
        .padding(.horizontal, look == .editorial ? 4 : 12)
        .frame(height: look == .editorial ? 48 : 44)
    }
}

struct MWTable: View {
    var body: some View {
        VStack(spacing: 0) {
            MWTableRow(cells: ["NAME", "CATEGORY", "STATUS", "SHORTCUT"], header: true)
            MWLookGroup(look: .table) {
                ForEach(MWTool.all) { tool in
                    MWTableRow(cells: [tool.name, tool.category, tool.on ? "On" : "Off", tool.shortcut.isEmpty ? "–" : tool.shortcut], tool: tool)
                }
            }
        }
    }
}

struct MWTableRow: View {
    let cells: [String]
    var header = false
    var tool: MWTool? = nil
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                if let tool {
                    MWIcons.icon(tool.asset).resizable().scaledToFit().frame(width: 16, height: 16).opacity(tool.on ? 1 : 0.45)
                }
                cell(cells[0], weight: header ? .medium : .medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            cell(cells[1]).frame(width: 110, alignment: .leading)
            cell(cells[2]).frame(width: 70, alignment: .leading)
            cell(cells[3]).frame(width: 80, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(height: header ? 28 : 30)
    }

    private func cell(_ text: String, weight: Font.Weight = .regular) -> some View {
        Group {
            if header {
                Text(text).font(.system(size: 10, weight: .medium)).tracking(0.4).foregroundStyle(OnePlusLinearColor.muted)
            } else {
                Text(text).linearText(weight: weight == .medium && text == cells[0] ? .medium : .regular,
                                      color: text == cells[0] && tool?.on != false ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary)
            }
        }
        .lineLimit(1)
    }
}

struct MWLookRuler: View {
    let look: MWLook
    @State private var on = true
    @State private var unit = "px"
    @State private var foreground = 1.0
    @State private var floats = true
    @State private var shadow = false
    @State private var color = NSColor(srgbRed: 1, green: 0.859, blue: 0, alpha: 1)

    var body: some View {
        let tool = MWTool.ruler
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: look == .editorial ? "" : "Ruler", canGoBack: true, canGoForward: false, back: {}, forward: {})
            MWLookBody(look: look) {
                header(tool)
                if look != .linear {
                    MWLookGroup(look: look) {
                        MWRow(label: "Enabled", detail: "Turn off to hide Ruler from the menu bar, shortcuts, and Raycast.") { MWSwitch(label: "Enabled", isOn: $on) }
                    }
                }
                VStack(alignment: .leading, spacing: look == .editorial ? 0 : OnePlusLinearMetrics.sectionCaptionBelow) {
                    MWLookCaption(title: "Defaults for new rulers", look: look)
                    MWLookGroup(look: look) {
                        MWRow(label: "Unit") {
                            OnePlusLinearSegmented(choices: [("px", "px"), ("mm", "mm"), ("in", "in")], selection: $unit, accessibilityLabel: "Unit")
                        }
                        MWRow(label: "Ruler color") { OnePlusLinearColorWell("Ruler color", color: $color) }
                        MWSliderRow(label: "Foreground opacity", value: $foreground)
                        MWRow(label: "Float ruler above other applications") { MWSwitch(label: "Float", isOn: $floats) }
                        MWRow(label: "Show ruler shadow") { MWSwitch(label: "Shadow", isOn: $shadow) }
                    }
                }
                .environment(\.onePlusLinearControlLook, look == .linear ? nil : .quietRaised)
            }
        }
    }

    @ViewBuilder private func header(_ tool: MWTool) -> some View {
        switch look {
        case .linear:
            MWToolHeader(tool: tool) {
                Toggle("Enable", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                Button("Open Ruler") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
            }
        case .editorial:
            HStack(alignment: .center, spacing: 16) {
                MWIcons.icon(tool.asset).resizable().scaledToFit().frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name).font(.system(size: 24, weight: .semibold)).tracking(-0.6).foregroundStyle(OnePlusLinearColor.ink)
                    Text(tool.detail).linearText(color: OnePlusLinearColor.secondary).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Open Ruler") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
            }
        default:
            MWLookGroup(look: look) {
                HStack(spacing: 12) {
                    MWIcons.icon(tool.asset).resizable().scaledToFit().frame(width: look == .grouped ? 40 : 32, height: look == .grouped ? 40 : 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tool.name).linearText(look == .grouped ? 15 : OnePlusLinearMetrics.body, weight: .semibold)
                        Text(tool.detail).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Open Ruler") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                }
                .padding(12)
            }
        }
    }
}
