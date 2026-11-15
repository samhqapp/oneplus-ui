import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI
@testable import OnePlusUIShowcase

/// Version 15 geometry against the mockup numbers (`macpowertoys/docs/design/v15/`), in both appearances at 1x and 2x.
@MainActor
final class OnePlusLinearTests: XCTestCase {
    private static let appearances: [NSAppearance.Name] = [.aqua, .darkAqua]
    private static let output = ProcessInfo.processInfo.environment["ONEPLUS_V15_RENDERS"]
        ?? "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-package"

    func testRowAndBarHeightsMatchTheMockup() {
        let cases: [(String, AnyView, CGFloat)] = [
            ("nav row", AnyView(OnePlusLinearNavRow("Color Picker", systemImage: "eyedropper") {}), OnePlusLinearMetrics.navRow),
            ("nav caption", AnyView(OnePlusLinearNavCaption("System")), 28),
            ("toolbar", AnyView(OnePlusLinearPaneToolbar(title: "All tools", canGoBack: true, canGoForward: false, back: {}, forward: {})), 44),
            ("section caption", AnyView(OnePlusLinearSectionCaption("System", count: 6)), 20),
            ("tool row", AnyView(OnePlusLinearToolRow("Ruler", summary: "Measure", icon: Image(systemName: "ruler"),
                                                      isEnabled: .constant(true), isFavorite: .constant(false)) {}), 36),
            ("panel header", AnyView(OnePlusLinearPanelHeader.processes()), 24),
            ("control row", AnyView(OnePlusLinearControlRow("Fan", systemImage: "fan", status: "3,472 RPM") {
                OnePlusLinearSegmented(choices: [(0, "Auto"), (1, "Cool"), (2, "Max")], selection: .constant(0), accessibilityLabel: "Fan")
            }), 32),
            ("process row", AnyView(OnePlusLinearProcessRow("Xcode", icon: nil, cpu: "4.8", memory: "3.9 GB")), 30),
            ("action bar", AnyView(OnePlusLinearActionBar([OnePlusLinearAction("Ruler", systemImage: "ruler") {}])), 28),
            ("footer", AnyView(OnePlusLinearPanelFooter { Text("tabs") } trailing: { Text("Open App") }), 44),
            ("segmented", AnyView(OnePlusLinearSegmented(choices: [(0, "Auto")], selection: .constant(0), accessibilityLabel: "Fan")), 22),
            ("icon tabs", AnyView(OnePlusLinearIconTabs(tabs: [OnePlusMenuTab(0, "Home", systemImage: "house")], selection: .constant(0))), 30),
            ("switch", AnyView(Toggle("Kwake", isOn: .constant(true)).toggleStyle(OnePlusLinearSwitchStyle())), 16),
            ("search", AnyView(OnePlusLinearSearchField(text: .constant(""))), 28),
            ("raised button", AnyView(Button("Open App") {}.buttonStyle(OnePlusLinearButtonStyle(.raised))), 28),
        ]
        for (name, view, height) in cases {
            XCTAssertEqual(NSHostingView(rootView: view.frame(width: 338)).fittingSize.height, height, accuracy: 0.01, name)
        }
        let segmented = NSHostingView(rootView: OnePlusLinearSegmented(choices: [(0, "Auto"), (1, "Cool"), (2, "Max")],
                                                                       selection: .constant(0), accessibilityLabel: "Fan"))
        XCTAssertEqual(segmented.fittingSize.width, 3 * 40 + 2 * 2 + 4, accuracy: 0.01)
        let tabs = NSHostingView(rootView: OnePlusLinearIconTabs(tabs: LinearPanelSampleTabs.tabs, selection: .constant("home")))
        XCTAssertEqual(tabs.fittingSize.width, 5 * 26 + 4 * 2 + 4, accuracy: 0.01)
    }

    func testTilesLineUpInTwoEqualColumns() {
        for (height, expected) in [(OnePlusLinearMetrics.tile, 86.0), (OnePlusLinearMetrics.tallTile, 146), (OnePlusLinearMetrics.shortTile, 56)] {
            let tile = NSHostingView(rootView: OnePlusLinearTile(height: height) { Text("CPU") }.frame(width: 165))
            XCTAssertEqual(tile.fittingSize.height, expected, accuracy: 0.01)
        }
        let markers = [NSView(), NSView()]
        let host = NSHostingView(rootView: OnePlusLinearBento {
            OnePlusLinearTile(height: OnePlusLinearMetrics.tallTile) { Probe(view: markers[0]).frame(width: 1, height: 1) }
            OnePlusLinearTile(height: OnePlusLinearMetrics.shortTile) { Text("Disk") }
            OnePlusLinearTile(height: OnePlusLinearMetrics.shortTile) { Text("Battery") }
        } trailing: {
            OnePlusLinearTile { Probe(view: markers[1]).frame(width: 1, height: 1) }
            OnePlusLinearTile { Text("Memory") }
            OnePlusLinearTile { Text("Network") }
        }.frame(width: 338))
        let window = attach(host, size: CGSize(width: 338, height: 274))
        defer { window.close() }
        XCTAssertEqual(host.fittingSize.height, 274, accuracy: 0.01)
        let left = markers[0].convert(markers[0].bounds, to: host), right = markers[1].convert(markers[1].bounds, to: host)
        XCTAssertEqual(left.minX, 10, accuracy: 0.01)
        XCTAssertEqual(right.minX, 165 + 8 + 10, accuracy: 0.01)
        XCTAssertEqual(left.minY, right.minY, accuracy: 0.01)
    }

    func testPanelMatchesMockupSizeAndInsets() {
        let host = NSHostingView(rootView: LinearPanelSample())
        XCTAssertEqual(host.fittingSize.width, 356, accuracy: 0.01)
        XCTAssertEqual(host.fittingSize.height, 602, accuracy: 0.5)
    }

    func testSelectedTabUnderlineSitsOnTheToolbarLine() throws {
        for appearance in Self.appearances {
            for scale: CGFloat in [1, 2] {
                let host = NSHostingView(rootView: OnePlusLinearPaneToolbar(title: "All tools", canGoBack: true, canGoForward: false,
                                                                            back: {}, forward: {}) {
                    OnePlusLinearTextTabs(tabs: [OnePlusTab("all", "All", count: 13), OnePlusTab("on", "Enabled", count: 9)],
                                          selection: .constant("all"))
                }.frame(width: 400).background(OnePlusLinearColor.window))
                let render = try bitmap(host, size: CGSize(width: 400, height: 44), scale: scale, appearance: appearance)
                let accent = NSColor(srgbRed: appearance == .darkAqua ? 0xEE / 255 : 0xE0 / 255, green: appearance == .darkAqua ? 0x5B / 255 : 0x49 / 255,
                                     blue: appearance == .darkAqua ? 0x50 / 255 : 0x3E / 255, alpha: 1)
                let rows = (0..<Int(44 * scale)).filter { y in
                    (0..<Int(400 * scale)).contains { x in close(render.colorAt(x: x, y: y), accent) }
                }
                XCTAssertEqual(rows.first.map { CGFloat($0) / scale }, 42, "\(appearance) \(scale)x")
                XCTAssertEqual(rows.last.map { CGFloat($0 + 1) / scale }, 44, "\(appearance) \(scale)x")
            }
        }
    }

    func testRowsHoverAcrossTheFullWidth() throws {
        let rows: [(String, (OnePlusControlState) -> AnyView, CGFloat)] = [
            ("tool row", { state in AnyView(OnePlusLinearToolRow("Ruler", summary: "Measure", icon: Image(systemName: "ruler"),
                                                                 isEnabled: .constant(true), isFavorite: .constant(false)) {}
                .environment(\.onePlusControlState, state)) }, 36),
            ("process row", { state in AnyView(OnePlusLinearProcessRow("Xcode", icon: nil, cpu: "4.8", memory: "3.9 GB")
                .environment(\.onePlusControlState, state)) }, 30),
            ("control row", { state in AnyView(OnePlusLinearControlRow("Kwake", systemImage: "eye") {
                Toggle("Kwake", isOn: .constant(true)).toggleStyle(OnePlusLinearSwitchStyle())
            }.environment(\.onePlusControlState, state)) }, 32),
        ]
        for appearance in Self.appearances {
            for (name, make, height) in rows {
                let size = CGSize(width: 338, height: height)
                let renders = try [OnePlusControlState.rest, .hover].map { state in
                    try bitmap(NSHostingView(rootView: make(state).frame(width: 338).background(OnePlusLinearColor.panelTile)),
                               size: size, scale: 2, appearance: appearance)
                }
                for x in [1, 337] {
                    let rest = try XCTUnwrap(renders[0].colorAt(x: x * 2, y: 2)?.usingColorSpace(.sRGB))
                    let hover = try XCTUnwrap(renders[1].colorAt(x: x * 2, y: 2)?.usingColorSpace(.sRGB))
                    XCTAssertGreaterThan(abs(rest.redComponent - hover.redComponent), 0.004, "\(name) \(appearance) x \(x)")
                }
            }
        }
    }

    func testUnsetFavoriteStarStaysInTheAccessibilityTreeAtRest() throws {
        var favorite = false
        let binding = Binding(get: { favorite }, set: { favorite = $0 })
        let host = NSHostingView(rootView: OnePlusLinearToolRow("Ruler", summary: "Measure", icon: Image(systemName: "ruler"),
                                                                isEnabled: .constant(true), isFavorite: binding) {}
            .environment(\.onePlusControlState, .rest).frame(width: 338))
        let window = attach(host, size: CGSize(width: 338, height: 36))
        defer { window.close() }
        let nodes = accessibilityTree(of: host, in: window)
        // Open, Favorite, and Enable each keep a key-loop proxy.
        XCTAssertEqual(host.subviews.filter(\.canBecomeKeyView).count, 3)
        let star = try XCTUnwrap(nodes.first { $0.accessibilityLabel() == "Favorite" })
        XCTAssertEqual(star.accessibilityValue() as? String, "Off")
        XCTAssertTrue(star.accessibilityPerformPress())
        XCTAssertTrue(favorite)
    }

    func testDisabledSegmentTakesNoClickAndArrowKeysSkipIt() throws {
        var fan = "Auto"
        let binding = Binding(get: { fan }, set: { fan = $0 })
        let host = NSHostingView(rootView: OnePlusLinearSegmented(choices: [("Auto", "Auto"), ("Cool", "Cool"), ("Max", "Max")],
                                                                  selection: binding, accessibilityLabel: "Fan",
                                                                  isChoiceEnabled: { $0 != "Cool" }))
        let window = attach(host, size: CGSize(width: 128, height: 22))
        defer { window.close() }
        let elements = accessibilityTree(of: host, in: window)
        let cool = try XCTUnwrap(elements.first { $0.accessibilityLabel() == "Cool" })
        XCTAssertFalse(cool.isAccessibilityEnabled())
        _ = cool.accessibilityPerformPress()
        XCTAssertEqual(fan, "Auto")
        XCTAssertTrue(try XCTUnwrap(elements.first { $0.accessibilityLabel() == "Max" }).accessibilityPerformPress())
        XCTAssertEqual(fan, "Max")
        let enabled: (String) -> Bool = { $0 != "Cool" }
        let order = ["Auto", "Cool", "Max"]
        XCTAssertEqual(OnePlusSegmented<String>.nextSelection(in: order, current: "Max", direction: -1, isChoiceEnabled: enabled), "Auto")
        XCTAssertEqual(OnePlusSegmented<String>.nextSelection(in: order, current: "Auto", direction: 1, isChoiceEnabled: enabled), "Max")
    }

    /// SwiftUI builds its accessibility nodes only for a window on screen (here offscreen, behind every
    /// window, never key) once an assistive client asks, as VoiceOver does.
    private func accessibilityTree(of host: NSView, in window: NSWindow) -> [NSAccessibilityElement] {
        window.orderBack(nil)
        NSApp.accessibilitySetValue(true, forAttribute: NSAccessibility.Attribute(rawValue: "AXEnhancedUserInterface"))
        func walk(_ children: [Any]?) -> [NSAccessibilityElement] {
            // The SwiftUI node class answers the NSAccessibility methods without declaring the protocol.
            let nodes = (children ?? []).map { unsafeBitCast($0 as AnyObject, to: NSAccessibilityElement.self) }
            return nodes + nodes.flatMap { walk($0.accessibilityChildren()) }
        }
        return walk(host.accessibilityChildren())
    }

    func testTextTokensMeetAPCAOnEveryV15Surface() throws {
        let surfaces = [OnePlusLinearColor.window, OnePlusLinearColor.sidebar, OnePlusLinearColor.panelShell,
                        OnePlusLinearColor.panelTile, OnePlusLinearColor.panelFooter, OnePlusLinearColor.button]
        let roles: [(String, Color, Double)] = [
            ("ink", OnePlusLinearColor.ink, 60), ("secondary", OnePlusLinearColor.secondary, 60),
            ("cpuText", OnePlusLinearColor.cpuText, 60), ("muted", OnePlusLinearColor.muted, 45),
            ("panelMuted", OnePlusLinearColor.panelMuted, 45), ("networkUp", OnePlusLinearColor.networkUp, 45),
        ]
        for name in Self.appearances {
            try XCTUnwrap(NSAppearance(named: name)).performAsCurrentDrawingAppearance {
                for surface in surfaces {
                    let ground = NSColor(surface).usingColorSpace(.sRGB)!
                    for (role, ink, minimum) in roles {
                        XCTAssertGreaterThanOrEqual(abs(apcaLc(NSColor(ink).usingColorSpace(.sRGB)!, ground)), minimum, "\(role) \(name)")
                    }
                }
            }
        }
    }

    /// Writes the full main pane and the full panel for side-by-side review with the reference renders.
    func testRenderFullMainWindowAndPanel() throws {
        let icons = "/Volumes/External1TB/dev/personal/powertoys/powertoys/Assets.xcassets"
        if FileManager.default.fileExists(atPath: icons) { setenv("ONEPLUS_SHOWCASE_ICONS", icons, 1) }
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        for appearance in Self.appearances {
            for scale: CGFloat in [1, 2] {
                let suffix = "\(appearance == .darkAqua ? "dark" : "light")-\(Int(scale))x"
                for (name, view, size) in [("main-window", AnyView(LinearMainWindowSample().frame(width: 820, height: 660)), CGSize(width: 820, height: 660)),
                                           ("menu-panel", AnyView(LinearPanelSample()), CGSize(width: 356, height: 602))] {
                    let render = try bitmap(NSHostingView(rootView: view), size: size, scale: scale, appearance: appearance)
                    XCTAssertEqual(render.pixelsWide, Int(size.width * scale))
                    let data = try XCTUnwrap(render.representation(using: .png, properties: [:]))
                    try data.write(to: URL(fileURLWithPath: "\(Self.output)/\(name)-\(suffix).png"))
                }
            }
        }
    }

    private func attach<V: View>(_ host: NSHostingView<V>, size: CGSize, appearance: NSAppearance.Name = .darkAqua) -> NSWindow {
        let window = NSWindow(contentRect: CGRect(origin: CGPoint(x: -10000, y: -10000), size: size),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: appearance)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        return window
    }

    private func bitmap<V: View>(_ host: NSHostingView<V>, size: CGSize, scale: CGFloat, appearance: NSAppearance.Name) throws -> NSBitmapImageRep {
        let window = attach(host, size: size, appearance: appearance)
        defer { window.close() }
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                                                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                                    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        bitmap.size = size
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return bitmap
    }

    private func close(_ color: NSColor?, _ target: NSColor) -> Bool {
        guard let color = color?.usingColorSpace(.sRGB), let target = target.usingColorSpace(.sRGB) else { return false }
        return abs(color.redComponent - target.redComponent) < 0.06 && abs(color.greenComponent - target.greenComponent) < 0.06
            && abs(color.blueComponent - target.blueComponent) < 0.06
    }

    // APCA 0.0.98G lightness contrast, as in OnePlusButtonAlignmentTests.
    private func apcaLc(_ text: NSColor, _ background: NSColor) -> Double {
        func luminance(_ rgb: NSColor) -> Double {
            let y = 0.2126729 * pow(rgb.redComponent, 2.4) + 0.7151522 * pow(rgb.greenComponent, 2.4) + 0.0721750 * pow(rgb.blueComponent, 2.4)
            return y < 0.022 ? y + pow(0.022 - y, 1.414) : y
        }
        let ink = luminance(text), ground = luminance(background)
        if ground > ink {
            let s = (pow(ground, 0.56) - pow(ink, 0.57)) * 1.14
            return s < 0.1 ? 0 : (s - 0.027) * 100
        }
        let s = (pow(ground, 0.65) - pow(ink, 0.62)) * 1.14
        return s > -0.1 ? 0 : (s + 0.027) * 100
    }
}

@MainActor
private enum LinearPanelSampleTabs {
    static let tabs = ["home", "input", "care", "net", "sync"].map { OnePlusMenuTab($0, $0, systemImage: "square") }
}

private struct Probe: NSViewRepresentable {
    let view: NSView
    func makeNSView(context: Context) -> NSView { view }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
