import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI
@testable import OnePlusUIShowcase

/// Round 3 main window options (owner, 2026-11-18), Light and Dark at 2x, with a manifest for the decision page.
/// Each panel is the shipped editorial page with the round 3 fixes (rows on the one leading edge, no hairline
/// under a group's last row, Quiet Raised toolbar switch); only the option under test changes.
@MainActor
final class MainWindowRound3RenderTests: XCTestCase {
    private static let output = "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-main-r3"
    private static let window = CGSize(width: 820, height: 660)
    private static let tall = CGSize(width: 820, height: 1170)

    private struct Option { let file: String; let name: String; let text: String; let size: CGSize; let view: AnyView }

    func testRenderRound3Options() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        func ruler(_ reset: R3Reset) -> AnyView {
            AnyView(R2Window(selected: "Ruler") { R3ToolPage(tool: .ruler, header: .keep, reset: reset) })
        }
        func page(_ tool: MWTool, _ header: R3Header) -> AnyView {
            AnyView(R2Window(selected: tool.name) { R3ToolPage(tool: tool, header: header, reset: .soft) })
        }
        let headers: [(R3Header, String, String, String)] = [
            (.product, "product", "Product page",
             "Like an App Store product page: a 96 pt icon, the name, one line, and a round Open button under it. A facts strip below shows the shortcut, the window kind, and one live number."),
            (.hero, "hero", "Color hero",
             "A soft band tinted with the icon's own colors, with a large blurred copy of the icon behind it, like a Raycast Store or Arc page. Open sits inside the band."),
            (.launchTile, "tile", "Launch tile",
             "The name and description on the left. On the right, one large soft tile that is the Open button and shows the shortcut, like a System Settings detail pane."),
            (.inlineFacts, "facts", "Inline facts",
             "A compact Linear-style header: the name with a row of small facts (shortcut, window, a live number) under it, and a quiet Open link at the right."),
            (.toolbarTitle, "toolbar", "Title in the toolbar",
             "No page header. The toolbar shows the tool name and Open beside the Enabled switch. The page starts with one large sentence, then the settings."),
            (.keep, "keep", "Keep as is",
             "The 56 pt icon, name, and description, with the soft Open button at the right end."),
        ]
        func headerGroup(_ tool: MWTool, _ key: String) -> [Option] {
            headers.map { header, file, name, text in
                Option(file: "header-\(file)-\(key)", name: name, text: text, size: Self.window, view: page(tool, header))
            }
        }
        let groups: [(String, [Option])] = [
            ("Ruler: Reset to Factory Defaults", [
                Option(file: "reset-soft", name: "Soft full-width button",
                       text: "One full-width soft gray button with red text, after the last settings group and above How to use. No line above or below it.",
                       size: Self.tall, view: ruler(.soft)),
                Option(file: "reset-soft-caption", name: "Soft button with a caption",
                       text: "The same soft full-width button, with one line under it: rulers on screen keep their own settings.",
                       size: Self.tall, view: ruler(.softCaption)),
                Option(file: "reset-bordered", name: "Bordered button",
                       text: "A full-width button with a 1 pt border, no fill, and red text. It fills on hover.",
                       size: Self.tall, view: ruler(.bordered)),
                Option(file: "reset-plain", name: "Plain red row",
                       text: "Full-width red text on the page's leading edge with a reset glyph, no fill and no border, like the red rows in System Settings.",
                       size: Self.tall, view: ruler(.plain)),
                Option(file: "reset-keep", name: "Keep as is",
                       text: "The red reset text is the second row of the group with Open Ruler Settings.",
                       size: Self.tall, view: ruler(.keep)),
            ]),
            ("Tool page header: Color Picker", headerGroup(.colorPicker, "color")),
            ("Tool page header: Ruler", headerGroup(.ruler, "ruler")),
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

enum R3Reset { case soft, softCaption, bordered, plain, keep }
enum R3Header { case product, hero, launchTile, inlineFacts, toolbarTitle, keep }

/// Mockup facts per tool: the shortcut and its action, the window kind, and one live number.
private struct R3Facts {
    let shortcut: String
    let action: String
    let window: String
    let windowNote: String
    let count: String
    let countNote: String
    let countGlyph: String
    static func of(_ tool: MWTool) -> R3Facts {
        tool.name == "Ruler"
            ? R3Facts(shortcut: "⌥⌘R", action: "Open Ruler", window: "Overlay", windowNote: "On every display",
                      count: "2", countNote: "rulers on screen", countGlyph: "ruler")
            : R3Facts(shortcut: "⌘⇧3", action: "Pick Color", window: "Applet", windowNote: "420 pt window",
                      count: "24", countNote: "saved colors", countGlyph: "swatchpalette")
    }
}

/// The two most saturated, clearly different colors of a tool icon, for the hero tint.
@MainActor
enum R3IconColors {
    private static let folder = "/Volumes/External1TB/dev/personal/powertoys/powertoys/Assets.xcassets"
    static func colors(_ asset: String) -> (Color, Color) {
        let fallback = (Color.gray, Color.gray)
        var image: NSImage?
        for file in ["icon.png", "icon.svg"] where image == nil {
            image = NSImage(contentsOfFile: "\(folder)/\(asset).imageset/\(file)")
        }
        guard let cg = image?.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return fallback }
        let side = 24
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                                          bytesPerRow: side * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return fallback }
        var samples: [NSColor] = []
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 220 {
            samples.append(NSColor(srgbRed: CGFloat(pixels[index]) / 255, green: CGFloat(pixels[index + 1]) / 255,
                                   blue: CGFloat(pixels[index + 2]) / 255, alpha: 1))
        }
        let ranked = samples.sorted { $0.saturationComponent * $0.brightnessComponent > $1.saturationComponent * $1.brightnessComponent }
        guard let first = ranked.first else { return fallback }
        let second = ranked.first { abs($0.hueComponent - first.hueComponent) > 0.1 && $0.saturationComponent > 0.3 } ?? first
        return (Color(nsColor: first), Color(nsColor: second))
    }
}

/// A full-width reset button for the round 3 options.
private struct R3ResetButtonStyle: ButtonStyle {
    let reset: R3Reset
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8)
        Group {
            switch reset {
            case .plain:
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 12, weight: .medium))
                    configuration.label.linearText(color: OnePlusLinearColor.destructiveText)
                }
                .frame(maxWidth: .infinity, minHeight: OnePlusLinearEditorialMetrics.row, alignment: .leading)
            default:
                configuration.label.linearText(weight: .medium, color: OnePlusLinearColor.destructiveText)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(reset == .bordered ? Color.clear : OnePlusLinearColor.softButton, in: shape)
                    .overlay { if reset == .bordered { shape.strokeBorder(OnePlusLinearColor.line, lineWidth: 1) } }
            }
        }
        .foregroundStyle(OnePlusLinearColor.destructiveText)
        .contentShape(shape)
    }
}

/// The shipped tool page with the round 3 fixes; the header and the Ruler reset placement vary.
struct R3ToolPage: View {
    let tool: MWTool
    let header: R3Header
    let reset: R3Reset
    @State private var on = true
    @State private var placement = "combined"

    var body: some View {
        VStack(spacing: 0) {
            OnePlusLinearPaneToolbar(title: header == .toolbarTitle ? tool.name : "", canGoBack: true, canGoForward: false,
                                     back: {}, forward: {}) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Enabled").linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                        Toggle("Enabled", isOn: $on).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden()
                    }
                    if header == .toolbarTitle { Button("Open") {}.buttonStyle(OnePlusLinearButtonStyle(.soft)) }
                }
            }
            OnePlusLinearEditorialBody {
                R3Header_(tool: tool, header: header)
                OnePlusLinearAppletGroup {
                    OnePlusLinearAppletRow("Menu bar icon") {
                        OnePlusLinearSegmented(choices: [("none", "None"), ("combined", "Combined"), ("separate", "Separate")],
                                               selection: $placement, accessibilityLabel: "Menu bar placement", sizing: .fitted)
                    }
                }
                if tool.name == "Ruler" { R3RulerSettings(reset: reset) } else { R2ColorSettings() }
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

// swiftlint:disable:next type_name
private struct R3Header_: View {
    let tool: MWTool
    let header: R3Header
    @Environment(\.colorScheme) private var scheme

    private var facts: R3Facts { R3Facts.of(tool) }
    private var icon: some View { MWIcons.icon(tool.asset).resizable().scaledToFit() }

    var body: some View {
        switch header {
        case .product: product
        case .hero: hero
        case .launchTile: launchTile
        case .inlineFacts: inlineFacts
        case .toolbarTitle:
            Text(tool.detail).font(.system(size: 17)).tracking(-0.2).foregroundStyle(OnePlusLinearColor.secondary)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        case .keep:
            OnePlusLinearToolHeader(tool.name, detail: tool.detail) { icon } actions: {
                Button("Open \(tool.name)") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
            }
        }
    }

    private func title(_ size: CGFloat) -> some View {
        Text(tool.name).font(.system(size: size, weight: .semibold)).tracking(-0.6).foregroundStyle(OnePlusLinearColor.ink)
    }

    private var capsuleOpen: some View {
        Button {} label: {
            Text("Open").linearText(weight: .semibold).padding(.horizontal, 22).frame(height: 28)
                .background(OnePlusLinearColor.softButton, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var product: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 20) {
                icon.frame(width: 96, height: 96).shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                VStack(alignment: .leading, spacing: 4) {
                    title(26)
                    Text(tool.summary).linearText(color: OnePlusLinearColor.secondary).lineLimit(1)
                    capsuleOpen.padding(.top, 10)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                fact("Shortcut", facts.shortcut, facts.action)
                divider
                fact("Window", facts.window, facts.windowNote)
                divider
                fact(facts.countNote.capitalized, facts.count, facts.countNote)
            }
        }
    }

    private var divider: some View { OnePlusLinearColor.line.frame(width: 1, height: 40) }

    private func fact(_ caption: String, _ value: String, _ note: String) -> some View {
        VStack(spacing: 3) {
            Text(caption.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(0.6)
                .foregroundStyle(OnePlusLinearColor.muted)
            Text(value).font(.system(size: 17, weight: .semibold)).foregroundStyle(OnePlusLinearColor.secondary)
            Text(note).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var hero: some View {
        let (first, second) = R3IconColors.colors(tool.asset)
        let strength = scheme == .dark ? 0.30 : 0.22
        let shape = RoundedRectangle(cornerRadius: 12)
        return VStack(alignment: .leading, spacing: 0) {
            icon.frame(width: 64, height: 64).shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            title(28).padding(.top, 14)
            Text(tool.detail).linearText(color: OnePlusLinearColor.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true).frame(maxWidth: 360, alignment: .leading).padding(.top, 4)
            Button("Open \(tool.name)") {}.buttonStyle(OnePlusLinearButtonStyle(.soft)).padding(.top, 16)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .trailing) {
                OnePlusLinearColor.window
                LinearGradient(colors: [first.opacity(strength), second.opacity(strength * 0.6)],
                               startPoint: .topTrailing, endPoint: .bottomLeading)
                icon.frame(width: 260, height: 260).blur(radius: 46).opacity(scheme == .dark ? 0.55 : 0.45)
                    .offset(x: 70, y: -10)
            }
            .clipShape(shape)
        }
        .overlay { shape.strokeBorder(OnePlusLinearColor.lineSoft, lineWidth: 1) }
    }

    private var launchTile: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                icon.frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    title(24)
                    Text(tool.detail).linearText(color: OnePlusLinearColor.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {} label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Open").linearText(weight: .semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(OnePlusLinearColor.secondary)
                    }
                    Spacer(minLength: 0)
                    Text(facts.shortcut).font(.system(size: 22, weight: .semibold)).foregroundStyle(OnePlusLinearColor.ink)
                    Text(facts.action).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.muted)
                }
                .padding(14)
                .frame(width: 176, height: 108)
                .background(OnePlusLinearColor.softButton, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var inlineFacts: some View {
        HStack(alignment: .center, spacing: 14) {
            icon.frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 5) {
                title(20)
                HStack(spacing: 16) {
                    inlineFact("command", facts.shortcut)
                    inlineFact("macwindow", facts.window)
                    inlineFact(facts.countGlyph, "\(facts.count) \(facts.countNote)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {} label: {
                HStack(spacing: 4) {
                    Text("Open").linearText(weight: .medium, color: OnePlusLinearColor.secondary)
                    Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(OnePlusLinearColor.secondary)
                }
                .padding(.horizontal, 10).frame(height: 26)
                .background(OnePlusLinearColor.softButton, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }

    private func inlineFact(_ glyph: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: glyph).font(.system(size: 11)).foregroundStyle(OnePlusLinearColor.muted)
            Text(text).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
        }
    }
}

/// The shipped inline Ruler defaults with the reset outside every group (or kept in place).
struct R3RulerSettings: View {
    let reset: R3Reset
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
                if reset == .keep {
                    OnePlusLinearAppletRow("") {
                        Button("Reset to Factory Defaults", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive))
                    }
                }
            }
            if reset != .keep {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Reset to Factory Defaults", role: .destructive) {}.buttonStyle(R3ResetButtonStyle(reset: reset))
                    if reset == .softCaption {
                        Text("Resets the defaults for new rulers. Rulers on screen keep their own settings.")
                            .linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func toggle(_ label: String, _ isOn: Binding<Bool>) -> some View {
        OnePlusLinearAppletRow(label) { Toggle(label, isOn: isOn).toggleStyle(OnePlusLinearSwitchStyle()).labelsHidden() }
    }
}
