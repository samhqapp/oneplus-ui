import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// Shipped All tools rows (owner picks 2026-11-19): the shortcut key chip right-aligned against the fixed star
/// column, the radius 8 hover fill wider than the row, and hairlines that fade at both ends. The page mirrors
/// MacPowerToys `AllToolsGridView`; Portman is hovered. Light and Dark, 820 x 660 at 2x.
@MainActor
final class MainShortcutsRenderTests: XCTestCase {
    private static let output = "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/main-shortcuts-r2"
    private static let size = CGSize(width: 820, height: 660)

    func testRenderAllToolsRows() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        for appearance: NSAppearance.Name in [.aqua, .darkAqua] {
            let host = NSHostingView(rootView: MSWindow().frame(width: Self.size.width, height: Self.size.height))
            let render = try LinearRender.bitmap(host, size: Self.size, scale: 2, appearance: appearance)
            let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: "\(Self.output)/all-tools-\(appearance == .darkAqua ? "dark" : "light").png"))
        }
    }
}

private struct MSTool: Identifiable {
    let name: String
    let summary: String
    let asset: String
    let glyph: String
    var on = true
    var favorite = false
    var shortcut: String?
    var id: String { name }

    static let groups: [(String, [MSTool])] = [
        ("System", [MSTool(name: "Awake", summary: "Keep your Mac awake for a set time", asset: "AwakeLogo", glyph: "Kwake", shortcut: "⌃⌥⌘A"),
                    MSTool(name: "Mac Tweaks", summary: "Hidden macOS settings with one switch each", asset: "MacTweaksLogo", glyph: "MacTweaks"),
                    MSTool(name: "Event Viewer", summary: "Read app and system logs in one place", asset: "LogsLogo", glyph: "EventViewer", on: false),
                    MSTool(name: "Input Devices", summary: "Separate mouse and trackpad scrolling", asset: "InputDevicesLogoA", glyph: "InputDevices")]),
        ("Developer", [MSTool(name: "Ruler", summary: "Measure on-screen distances in px, mm, or in", asset: "RulerLogo", glyph: "Ruler"),
                       MSTool(name: "Portman", summary: "See and stop processes that hold ports", asset: "PortmanLogo", glyph: "Portman", shortcut: "⌥⌘P"),
                       MSTool(name: "Color Picker", summary: "Pick and save colors from anywhere on screen", asset: "ColorPickerLogo",
                              glyph: "ColorPicker", favorite: true, shortcut: "⇧⌘3")]),
        ("Text", [MSTool(name: "Text Extractor", summary: "Copy text from any part of the screen", asset: "TextExtractorLogo",
                         glyph: "TextExtractor", shortcut: "⇧⌘2")]),
        ("Files", [MSTool(name: "RSync UI", summary: "Sync folders to cloud and remote storage", asset: "CloudSyncLogo", glyph: "RSync")]),
    ]

    static func glyph(_ name: String) -> Image {
        let path = "/Volumes/External1TB/dev/organization/samhq/macpowertoys/powertoys/Assets.xcassets/SidebarGlyph\(name).imageset/glyph.svg"
        let image = NSImage(contentsOfFile: path) ?? NSImage()
        image.isTemplate = true
        return Image(nsImage: image)
    }
}

private struct MSWindow: View {
    @State private var tab = "all"
    var body: some View {
        let all = MSTool.groups.flatMap(\.1)
        HStack(spacing: 0) {
            OnePlusLinearSidebar {
                OnePlusLinearSearchField(text: .constant(""))
            } navigation: {
                OnePlusLinearNavRow("All tools", glyph: MSTool.glyph("AllTools"), selected: true) {}
                ForEach(MSTool.groups, id: \.0) { title, tools in
                    OnePlusLinearNavCaption(title)
                    ForEach(tools) { tool in
                        OnePlusLinearNavRow(tool.name, glyph: MSTool.glyph(tool.glyph), selected: false, dimmed: !tool.on) {}
                    }
                }
            } bottom: {
                OnePlusLinearNavRow("Settings", glyph: Image(systemName: "gearshape"), symbol: true, shortcut: "⌘,") {}
                OnePlusLinearNavRow("Exit", glyph: Image(systemName: "power"), symbol: true, shortcut: "⌘Q") {}
            }
            VStack(spacing: 0) {
                OnePlusLinearPaneToolbar(title: "All tools", canGoBack: false, canGoForward: true, back: {}, forward: {}) {
                    OnePlusLinearTextTabs(tabs: [OnePlusTab("all", "All", count: all.count),
                                                 OnePlusTab("enabled", "Enabled", count: all.filter(\.on).count),
                                                 OnePlusTab("favorites", "Favorites", count: all.filter(\.favorite).count)],
                                          selection: $tab)
                }
                OnePlusLinearEditorialBody {
                    OnePlusLinearPageTitle("All tools", subtitle: "\(all.count) tools, \(all.filter(\.on).count) on")
                    ForEach(MSTool.groups, id: \.0) { title, tools in
                        OnePlusLinearSection(title) {
                            ForEach(tools) { tool in
                                OnePlusLinearEditorialToolRow(tool.name, summary: tool.summary, icon: MWIcons.icon(tool.asset),
                                                              isOn: tool.on, shortcut: tool.shortcut,
                                                              isFavorite: .constant(tool.favorite)) {}
                                    .environment(\.onePlusControlState, tool.name == "Portman" ? .hover : .rest)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(OnePlusLinearColor.window)
        }
        .overlay(alignment: .topLeading) { MWLights() }
    }
}
