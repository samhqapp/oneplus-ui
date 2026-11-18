import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI
@testable import OnePlusUIShowcase

/// Round 2 main window options (owner, 2026-11-18), Light and Dark at 2x, with a manifest for the decision page.
/// Each panel is the shipped editorial page (monochrome sidebar, editorial body, inline settings, How to use
/// footer, toolbar Enabled switch); only the option under test changes.
@MainActor
final class MainWindowRound2RenderTests: XCTestCase {
    private static let output = "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-main-r2"
    private static let window = CGSize(width: 820, height: 660)
    private static let tall = CGSize(width: 820, height: 1190)

    private struct Option { let file: String; let name: String; let text: String; let size: CGSize; let view: AnyView }

    func testRenderRound2Options() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        func ruler(_ reset: R2Reset) -> AnyView {
            AnyView(R2Window(selected: "Ruler") { R2ToolPage(tool: .ruler, header: .keep, reset: reset) })
        }
        func page(_ tool: MWTool, _ header: R2Header) -> AnyView {
            AnyView(R2Window(selected: tool.name) { R2ToolPage(tool: tool, header: header, reset: .keep) })
        }
        let groups: [(String, [Option])] = [
            ("Ruler: Reset to Factory Defaults", [
                Option(file: "reset-defaults-row", name: "Last row of the defaults",
                       text: "The red reset text is the last row of Defaults for new rulers, so it sits with the values it resets. A confirmation still guards it.",
                       size: Self.tall, view: ruler(.defaultsRow)),
                Option(file: "reset-caption", name: "Beside the caption",
                       text: "A small red Reset sits at the right end of the Defaults for new rulers caption, like Clear in a Safari list header.",
                       size: Self.tall, view: ruler(.caption)),
                Option(file: "reset-own-group", name: "Own group at the end",
                       text: "The reset gets its own group after Open Ruler Settings, with one line under it that says rulers on screen keep their settings.",
                       size: Self.tall, view: ruler(.ownGroup)),
                Option(file: "reset-keep", name: "Keep as is",
                       text: "The red reset text is the second row of the group with Open Ruler Settings.",
                       size: Self.tall, view: ruler(.keep)),
            ]),
            ("Tool page header: Color Picker", [
                Option(file: "header-toolbar-color", name: "Open in the toolbar",
                       text: "Open Color Picker moves to the toolbar after the Enabled switch, the same place on every page. The header shows only the icon, name, and description.",
                       size: Self.window, view: page(.colorPicker, .toolbar)),
                Option(file: "header-under-color", name: "Open under the title",
                       text: "Open Color Picker sits below the description, left-aligned with the title, like Get in the App Store.",
                       size: Self.window, view: page(.colorPicker, .underTitle)),
                Option(file: "header-row-color", name: "Open as the first row",
                       text: "A full-width Open Color Picker row sits first in the group under the header, before the settings.",
                       size: Self.window, view: page(.colorPicker, .actionRow)),
                Option(file: "header-keep-color", name: "Keep as is",
                       text: "The soft Open Color Picker button sits at the right end of the header.",
                       size: Self.window, view: page(.colorPicker, .keep)),
            ]),
            ("Tool page header: Ruler", [
                Option(file: "header-toolbar-ruler", name: "Open in the toolbar",
                       text: "Open Ruler moves to the toolbar after the Enabled switch. Kwake has no window, so its page shows no Open in any option.",
                       size: Self.window, view: page(.ruler, .toolbar)),
                Option(file: "header-under-ruler", name: "Open under the title",
                       text: "Open Ruler sits below the description, left-aligned with the title.",
                       size: Self.window, view: page(.ruler, .underTitle)),
                Option(file: "header-row-ruler", name: "Open as the first row",
                       text: "A full-width Open Ruler row with its shortcut sits under the header, in the same group as Menu bar icon.",
                       size: Self.window, view: page(.ruler, .actionRow)),
                Option(file: "header-keep-ruler", name: "Keep as is",
                       text: "The soft Open Ruler button sits at the right end of the header.",
                       size: Self.window, view: page(.ruler, .keep)),
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
                entries.append(["name": option.name, "recommended": index == 0, "text": option.text,
                                "light": "\(option.file)-light.png", "dark": "\(option.file)-dark.png"])
            }
            manifest.append(["group": group, "options": entries])
        }
        let json = try JSONSerialization.data(withJSONObject: ["groups": manifest], options: [.prettyPrinted, .sortedKeys])
        try json.write(to: URL(fileURLWithPath: "\(Self.output)/manifest.json"))
    }
}

enum R2Reset { case defaultsRow, caption, ownGroup, keep }
enum R2Header { case toolbar, underTitle, actionRow, keep }

/// The shipped monochrome sidebar: template glyphs from the app's assets, gray at rest and ink when selected.
enum R2Glyphs {
    private static let folder = "/Volumes/External1TB/dev/personal/powertoys/powertoys/Assets.xcassets"
    private static let names = ["Kwake": "Kwake", "Mac Tweaks": "MacTweaks", "Event Viewer": "EventViewer",
                                "Input Devices": "InputDevices", "Ruler": "Ruler", "Portman": "Portman",
                                "Color Picker": "ColorPicker", "Text Extractor": "TextExtractor", "RSync UI": "RSync",
                                "All tools": "AllTools"]
    static func glyph(_ name: String) -> Image {
        let image = NSImage(contentsOfFile: "\(folder)/SidebarGlyph\(names[name] ?? "").imageset/glyph.svg") ?? NSImage()
        image.isTemplate = true
        return Image(nsImage: image)
    }
}

struct R2Window<Pane: View>: View {
    let selected: String?
    @ViewBuilder let pane: Pane
    var body: some View {
        HStack(spacing: 0) {
            OnePlusLinearSidebar {
                OnePlusLinearSearchField(text: .constant(""))
            } navigation: {
                OnePlusLinearNavRow("All tools", glyph: R2Glyphs.glyph("All tools"), selected: selected == nil) {}
                ForEach(MWTool.groups, id: \.0) { title, tools in
                    OnePlusLinearNavCaption(title)
                    ForEach(tools) { tool in
                        OnePlusLinearNavRow(tool.name, glyph: R2Glyphs.glyph(tool.name), selected: selected == tool.name,
                                            dimmed: !tool.on) {}
                    }
                }
            } bottom: {
                OnePlusLinearNavRow("Settings", glyph: Image(systemName: "gearshape"), symbol: true, shortcut: "⌘,") {}
                OnePlusLinearNavRow("Exit", glyph: Image(systemName: "power"), symbol: true, shortcut: "⌘Q") {}
            }
            pane.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(OnePlusLinearColor.window)
        }
        .overlay(alignment: .topLeading) { MWLights() }
    }
}

/// The shipped tool page: toolbar with the Enabled switch, editorial header, menu bar row, inline settings,
/// and How to use as the footer.
struct R2ToolPage: View {
    let tool: MWTool
    let header: R2Header
    let reset: R2Reset
    @State private var on = true
    @State private var placement = "combined"

    var body: some View {
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: "", canGoBack: true, canGoForward: false, back: {}, forward: {}) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Enabled").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                        Toggle("Enabled", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                    }
                    if header == .toolbar { openButton }
                }
            }
            OnePlusLinearEditorialBody {
                OnePlusLinearToolHeader(tool.name, detail: tool.detail) {
                    MWIcons.icon(tool.asset).resizable().scaledToFit()
                } actions: {
                    if header == .keep { openButton }
                }
                if header == .underTitle {
                    openButton.padding(.leading, OnePlusLinearEditorialMetrics.headerIcon + OnePlusLinearEditorialMetrics.headerGap)
                        .padding(.top, -8)
                }
                OnePlusLinearAppletGroup {
                    if header == .actionRow {
                        Button {} label: {
                            HStack(spacing: 8) {
                                Image(systemName: "macwindow").font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(OnePlusLinearColor.secondary).frame(width: 16)
                                Text("Open \(tool.name)").linearText(weight: .medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(tool.name == "Ruler" ? tool.shortcut : "").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted)
                                Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(OnePlusLinearColor.tertiary)
                            }
                            .padding(.horizontal, OnePlusLinearMetrics.appletRowPadding)
                            .frame(height: OnePlusLinearEditorialMetrics.row).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    OnePlusLinearAppletRow("Menu bar icon") {
                        OnePlusLinearSegmented(choices: [("none", "None"), ("combined", "Combined"), ("separate", "Separate")],
                                               selection: $placement, accessibilityLabel: "Menu bar placement", sizing: .fitted)
                    }
                }
                if tool.name == "Ruler" { R2RulerSettings(reset: reset) } else { R2ColorSettings() }
            } footer: {
                VStack(alignment: .leading, spacing: OnePlusLinearMetrics.sectionCaptionBelow) {
                    OnePlusLinearSectionCaption("How to use")
                    VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.blockGap) {
                        ForEach(R2Manual.sections(for: tool.name), id: \.0) { title, points in
                            OnePlusLinearSection(title) {
                                ForEach(points.indices, id: \.self) { index in
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text("\(index + 1).").linearText(color: OnePlusLinearColor.muted).monospacedDigit()
                                        Text(points[index]).linearText().fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, OnePlusLinearMetrics.toolRowPadding).padding(.vertical, 11)
                                    .frame(minHeight: OnePlusLinearEditorialMetrics.row)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var openButton: some View {
        Button("Open \(tool.name)") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
    }
}

enum R2Manual {
    static func sections(for name: String) -> [(String, [String])] {
        name == "Ruler" ? [
            ("Rulers", ["Drag a ruler to move it and drag an end or corner to resize it.",
                        "Press ⌘N for another ruler. Use H or V to show or hide a wing, and ⌘` to cycle rulers.",
                        "Use U for units, F for floating, S for shadow, G for grouping, and O to align at the pointer."]),
            ("Settings", ["Press ⌘, to edit the active ruler. Press ⌥⌘, to edit defaults for new rulers.",
                          "Choose color, foreground and background opacity, dimensions, float, and shadow."]),
        ] : [
            ("Pick and Copy", ["Press Pick Color to start the native macOS sampler immediately.",
                               "The selected color is copied in your default format and saved to history."]),
        ]
    }
}

/// The shipped inline Ruler defaults, with the reset placement under test.
struct R2RulerSettings: View {
    let reset: R2Reset
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
        VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.blockGap) {
            VStack(alignment: .leading, spacing: 0) {
                if reset == .caption {
                    HStack {
                        OnePlusLinearEditorialCaption(title: "Defaults for new rulers")
                        Spacer()
                        Button("Reset") {}.buttonStyle(.plain)
                            .font(.system(size: OnePlusLinearMetrics.control))
                            .foregroundStyle(OnePlusLinearColor.destructiveText)
                    }
                    OnePlusLinearAppletGroup { defaults }
                } else {
                    OnePlusLinearAppletSection("Defaults for new rulers") {
                        defaults
                        if reset == .defaultsRow { resetButton }
                    }
                }
            }
            OnePlusLinearAppletSection("Behavior") {
                toggle("Float ruler above other applications", $floats)
                toggle("Show ruler shadow", $shadow)
                toggle("Move both wings together", $grouped)
            }
            OnePlusLinearAppletGroup {
                OnePlusLinearAppletRow("Settings for the active rulers", detail: "Each ruler keeps its own color, size, and opacity.") {
                    Button("Open Ruler Settings") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
                }
                if reset == .keep { OnePlusLinearAppletRow("") { resetButton } }
            }
            if reset == .ownGroup {
                VStack(alignment: .leading, spacing: 6) {
                    OnePlusLinearAppletGroup { resetButton }
                    Text("Resets the defaults for new rulers. Rulers on screen keep their own settings.")
                        .linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted)
                }
            }
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }

    @ViewBuilder private var defaults: some View {
        OnePlusLinearAppletRow("Unit") {
            OnePlusLinearSegmented(choices: [("px", "px"), ("mm", "mm"), ("in", "in")], selection: $unit, accessibilityLabel: "Unit")
        }
        OnePlusLinearAppletRow("Dimensions") {
            HStack(spacing: 6) {
                OnePlusStepperField("Width", value: $width, in: 1...10000)
                Text("×").linearText(color: OnePlusLinearColor.muted)
                OnePlusStepperField("Height", value: $height, in: 1...10000)
            }
        }
        OnePlusLinearAppletRow("Ruler color") { OnePlusLinearColorWell("Ruler color", color: $color) }
        OnePlusLinearAppletSliderRow("Foreground opacity", value: $foreground, in: 0.05...1)
        OnePlusLinearAppletSliderRow("Background opacity", value: $background, in: 0.05...1)
        OnePlusLinearAppletSliderRow("Border opacity", value: $border)
    }

    private var resetButton: some View {
        Button("Reset to Factory Defaults", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive))
            .frame(minHeight: OnePlusLinearEditorialMetrics.row)
    }

    private func toggle(_ label: String, _ isOn: Binding<Bool>) -> some View {
        OnePlusLinearAppletRow(label) { Toggle(label, isOn: isOn).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden() }
    }
}

/// The shipped Color Picker settings: the shortcut group, the saved colors group, and Clear All.
struct R2ColorSettings: View {
    @State private var enabled = true
    @State private var format = "hex"
    var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.blockGap) {
            OnePlusLinearAppletSection("Global shortcut") {
                OnePlusLinearAppletRow("Enable shortcut") {
                    Toggle("Enable shortcut", isOn: $enabled).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                }
                OnePlusLinearAppletRow("Keyboard shortcut", detail: "Works in every app.") { MWShortcutField(keys: "⌘⇧3") }
            }
            OnePlusLinearAppletSection("Saved colors") {
                OnePlusLinearAppletRow("Copy format") {
                    OnePlusLinearSelect(choices: [("hex", "HEX"), ("rgb", "RGB"), ("hsl", "HSL")], selection: $format,
                                        accessibilityLabel: "Copy format", width: 120)
                }
            }
            Button("Clear All Saved Colors", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive))
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}
