import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI
@testable import OnePlusUIShowcase

/// Round 4 shipped tool pages (owner picks 2026-11-19): the "Launch tile" header and the bordered reset block,
/// Ruler, Color Picker, and Kwake, Light and Dark at 2x. The page mirrors MacPowerToys `ToolAboutView`.
@MainActor
final class MainWindowRound4RenderTests: XCTestCase {
    private static let output = "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-main-r4"
    private static let tall = CGSize(width: 820, height: 1170)

    func testRenderRound4ToolPages() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        let pages: [(String, AnyView)] = [
            ("ruler", AnyView(R2Window(selected: "Ruler") {
                R4ToolPage(tool: .ruler, shortcut: nil, caption: "Open Ruler") { R4RulerSettings() }
            })),
            ("color-picker", AnyView(R2Window(selected: "Color Picker") {
                R4ToolPage(tool: .colorPicker, shortcut: "⇧⌘3", caption: "Pick Color") { R4ColorSettings() }
            })),
            ("kwake", AnyView(R2Window(selected: "Kwake") {
                R4ToolPage(tool: .kwake, shortcut: nil, caption: nil) { R4KwakeSettings() }
            })),
        ]
        for (file, view) in pages {
            for appearance: NSAppearance.Name in [.aqua, .darkAqua] {
                let host = NSHostingView(rootView: view.frame(width: Self.tall.width, height: Self.tall.height))
                let render = try LinearRender.bitmap(host, size: Self.tall, scale: 2, appearance: appearance)
                let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
                try data.write(to: URL(fileURLWithPath: "\(Self.output)/\(file)-\(appearance == .darkAqua ? "dark" : "light").png"))
            }
        }
    }
}

private struct R4ToolPage<Settings: View>: View {
    let tool: MWTool
    let shortcut: String?
    let caption: String?
    @ViewBuilder let settings: Settings
    @State private var on = true
    @State private var placement = "combined"

    var body: some View {
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: "", canGoBack: true, canGoForward: false, back: {}, forward: {}) {
                HStack(spacing: 8) {
                    Text("Enabled").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                    Toggle("Enabled", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                }
            }
            OnePlusLinearEditorialBody {
                OnePlusLinearToolHeader(tool.name, detail: tool.detail) {
                    MWIcons.icon(tool.asset).resizable().scaledToFit()
                } actions: {
                    if let caption { OnePlusLinearLaunchTile(shortcut: shortcut, caption: caption) {} }
                }
                OnePlusLinearAppletGroup {
                    OnePlusLinearAppletRow("Menu bar icon") {
                        OnePlusLinearSegmented(choices: [("none", "None"), ("combined", "Combined"), ("separate", "Separate")],
                                               selection: $placement, accessibilityLabel: "Menu bar placement", sizing: .fitted)
                    }
                }
                settings
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
                                    .padding(.vertical, 11)
                                    .frame(minHeight: OnePlusLinearEditorialMetrics.row)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The shipped inline Ruler defaults with the reset block after the last group.
private struct R4RulerSettings: View {
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
            OnePlusLinearAppletSection("Defaults for new rulers") {
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
            OnePlusLinearAppletSection("Behavior") {
                toggle("Float ruler above other applications", $floats)
                toggle("Show ruler shadow", $shadow)
                toggle("Move both wings together", $grouped)
            }
            OnePlusLinearAppletGroup {
                OnePlusLinearAppletRow("Settings for the active rulers", detail: "Each ruler keeps its own color, size, and opacity.") {
                    Button("Open Ruler Settings") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))
                }
            }
            Button("Reset to Factory Defaults", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.resetBlock))
        }
    }

    private func toggle(_ label: String, _ isOn: Binding<Bool>) -> some View {
        OnePlusLinearAppletRow(label) { Toggle(label, isOn: isOn).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden() }
    }
}

/// The shipped Color Picker settings: groups at the applet section gap, then the clear block 20 pt below.
private struct R4ColorSettings: View {
    @State private var enabled = true
    @State private var format = "hex"
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: OnePlusLinearMetrics.appletSectionGap) {
                OnePlusLinearAppletSection("Global shortcut") {
                    OnePlusLinearAppletRow("Enable shortcut") {
                        Toggle("Enable shortcut", isOn: $enabled).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                    }
                    OnePlusLinearAppletRow("Keyboard shortcut", detail: "Works in every app.") { MWShortcutField(keys: "⇧⌘3") }
                }
                OnePlusLinearAppletSection("Saved colors") {
                    OnePlusLinearAppletRow("Copy format") {
                        OnePlusLinearSelect(choices: [("hex", "HEX"), ("rgb", "RGB"), ("hsl", "HSL")], selection: $format,
                                            accessibilityLabel: "Copy format", width: 120)
                    }
                }
            }
            Button("Clear All Saved Colors", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.resetBlock))
                .padding(.top, OnePlusLinearMetrics.appletFooterGap)
        }
        .environment(\.onePlusLinearControlLook, .quietRaised)
    }
}

/// A Kwake stand-in: one session group. The page has no launch tile.
private struct R4KwakeSettings: View {
    @State private var awake = false
    var body: some View {
        OnePlusLinearAppletSection("Session") {
            OnePlusLinearAppletRow("Keep this Mac awake") {
                Toggle("Keep this Mac awake", isOn: $awake).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
            }
        }
    }
}
