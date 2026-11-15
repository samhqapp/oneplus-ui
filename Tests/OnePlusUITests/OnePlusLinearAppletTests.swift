import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI
@testable import OnePlusUIShowcase

/// Version 15 applet parts against the mockup renders `macpowertoys/docs/design/v15/applet-*.png`
/// (measured at 2x), in both appearances at 1x and 2x, and the Quiet motion.
@MainActor
final class OnePlusLinearAppletTests: XCTestCase {
    private static let appearances: [NSAppearance.Name] = [.aqua, .darkAqua]
    private static let output = ProcessInfo.processInfo.environment["ONEPLUS_V15_APPLET_RENDERS"]
        ?? "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-applets"

    private func size<V: View>(_ view: V, width: CGFloat? = nil) -> CGSize {
        NSHostingView(rootView: view.environment(\.onePlusLinearControlLook, .depth).frame(width: width)).fittingSize
    }

    func testPartSizesMatchTheMockup() {
        let rows: [(String, AnyView, CGFloat)] = [
            ("titlebar", AnyView(OnePlusLinearAppletTitlebar("Color Picker") { EmptyView() }), 48),
            ("row", AnyView(OnePlusLinearAppletRow("Unit", value: "px")), 36),
            ("slider row", AnyView(OnePlusLinearAppletSliderRow("Border opacity", value: .constant(0.25))), 36),
            ("list row", AnyView(OnePlusLinearAppletListRow("#1C1C1C", monospaced: true, metadata: "2 wks ago",
                                                            actions: [OnePlusLinearAction("Copy", systemImage: "doc.on.doc") {}]) {
                OnePlusLinearSwatch(.black) }), 36),
            ("section", AnyView(OnePlusLinearAppletSection("Window") {
                OnePlusLinearAppletRow("A", value: "1"); OnePlusLinearAppletRow("B", value: "2") }), 16 + 6 + 72),
            ("tab row", AnyView(OnePlusLinearAppletTabRow(tabs: [OnePlusTab(0, "History", count: 6)], selection: .constant(0))), 32),
            ("toolbar", AnyView(OnePlusLinearAppletToolbar { OnePlusLinearSearchField("Search colors", text: .constant(""), style: .applet) }), 12 + 26 + 12),
            ("select", AnyView(OnePlusLinearSelect(choices: [(0, "HEX")], selection: .constant(0), accessibilityLabel: "Format", width: 92)), 26),
            ("soft button", AnyView(Button("Pick Color") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))), 24),
            ("destructive", AnyView(Button("Reset to Factory Defaults") {}.buttonStyle(OnePlusLinearButtonStyle(.destructive))), 30),
        ]
        for (name, view, height) in rows { XCTAssertEqual(size(view, width: 388).height, height, accuracy: 0.01, name) }

        let controls: [(String, AnyView, CGSize)] = [
            ("segmented", AnyView(OnePlusLinearSegmented(choices: [(0, "px"), (1, "mm"), (2, "in")], selection: .constant(0),
                                                         accessibilityLabel: "Unit")), CGSize(width: 112, height: 24)),
            ("switch", AnyView(Toggle("Shadow", isOn: .constant(true)).toggleStyle(OnePlusLinearSwitchStyle())), CGSize(width: 40, height: 24)),
            ("color well", AnyView(OnePlusLinearColorWell("Ruler color", color: .constant(.yellow))), CGSize(width: 44, height: 24)),
            ("slider", AnyView(OnePlusLinearSlider("Opacity", value: .constant(0.5))), CGSize(width: 140, height: 24)),
        ]
        for (name, view, expected) in controls {
            let measured = size(view)
            XCTAssertEqual(measured.width, expected.width, accuracy: 0.01, name)
            XCTAssertEqual(measured.height, expected.height, accuracy: 0.01, name)
        }
        XCTAssertEqual(size(OnePlusStepperField("Width", value: .constant(1920), in: 1...10000, unit: "px")).height, 24, accuracy: 0.01)
    }

    /// The Depth controls draw their labels on the recessed fill.
    func testDepthLabelsMeetAPCAOnTheRecess() {
        for name in Self.appearances {
            let recess = LinearRender.resolve(OnePlusLinearColor.depthRecess, in: name)
            XCTAssertGreaterThanOrEqual(abs(LinearRender.apcaLc(LinearRender.resolve(OnePlusLinearColor.secondary, in: name), recess)), 60, "segment \(name)")
            XCTAssertGreaterThanOrEqual(abs(LinearRender.apcaLc(LinearRender.resolve(OnePlusLinearColor.ink, in: name), recess)), 60, "value \(name)")
            XCTAssertGreaterThanOrEqual(abs(LinearRender.apcaLc(LinearRender.resolve(OnePlusLinearColor.muted, in: name), recess)), 45, "unit \(name)")
        }
    }

    func testPanelSegmentedKeepsItsSizeWithoutTheAppletLook() {
        let panel = NSHostingView(rootView: OnePlusLinearSegmented(choices: [(0, "Auto"), (1, "Cool"), (2, "Max")],
                                                                   selection: .constant(0), accessibilityLabel: "Fan"))
        XCTAssertEqual(panel.fittingSize, CGSize(width: 128, height: 22))
    }

    /// Group, field, and button edges at the mockup lines, scanned down x = 24 (inside the corners, left of the text).
    /// The first run is the sample close light (a chord near its right edge); 59 to 69 is the "i" of History.
    func testRulerDefaultsAndColorPickerSurfacesLandOnTheMockupLines() throws {
        let cases: [(String, AnyView, CGSize, [ClosedRange<CGFloat>])] = [
            ("ruler", AnyView(LinearRulerDefaultsSample()), CGSize(width: 420, height: 500), [17...27, 70...142, 180...324, 362...434, 454...484]),
            ("color picker", AnyView(LinearColorPickerSample()), CGSize(width: 420, height: 362),
             [17...27, 59...69, 78...80, 92...118, 130...346]),
        ]
        for appearance in Self.appearances {
            for scale: CGFloat in [1, 2] {
                for (name, view, canvas, expected) in cases {
                    let render = try LinearRender.bitmap(NSHostingView(rootView: view.frame(width: canvas.width, height: canvas.height)),
                                                         size: canvas, scale: scale, appearance: appearance)
                    let ground = LinearRender.resolve(OnePlusLinearColor.appletWindow, in: appearance)
                    var runs: [ClosedRange<CGFloat>] = []
                    var start: Int?
                    for y in 0...Int(canvas.height * scale) {
                        let inside = y < Int(canvas.height * scale) && !LinearRender.close(render.colorAt(x: Int(24 * scale), y: y), ground, tolerance: 0.004)
                        if inside, start == nil { start = y }
                        if !inside, let first = start { runs.append(CGFloat(first) / scale...CGFloat(y) / scale); start = nil }
                    }
                    XCTAssertEqual(runs.count, expected.count, "\(name) \(appearance) \(scale)x \(runs)")
                    for (run, line) in zip(runs, expected) {
                        XCTAssertEqual(run.lowerBound, line.lowerBound, accuracy: 0.51, "\(name) \(appearance) \(scale)x top")
                        XCTAssertEqual(run.upperBound, line.upperBound, accuracy: 0.51, "\(name) \(appearance) \(scale)x bottom")
                    }
                }
            }
        }
    }

    func testAppletTextAndButtonsMeetAPCA() {
        for name in Self.appearances {
            for surface in [OnePlusLinearColor.appletWindow, OnePlusLinearColor.appletGroup] {
                let ground = LinearRender.resolve(surface, in: name)
                for (role, ink, minimum) in [("ink", OnePlusLinearColor.ink, 60.0), ("secondary", OnePlusLinearColor.appletSecondary, 60),
                                             ("muted", OnePlusLinearColor.appletMuted, 45)] {
                    XCTAssertGreaterThanOrEqual(abs(LinearRender.apcaLc(LinearRender.resolve(ink, in: name), ground)), minimum, "\(role) \(name)")
                }
            }
            for fill in [OnePlusLinearColor.softButton, OnePlusLinearColor.softButtonHover, OnePlusLinearColor.softButtonPressed] {
                let ground = LinearRender.resolve(fill, in: name)
                XCTAssertGreaterThanOrEqual(abs(LinearRender.apcaLc(LinearRender.resolve(OnePlusLinearColor.ink, in: name), ground)), 60, "soft \(name)")
            }
            for fill in [OnePlusLinearColor.destructiveFill, OnePlusLinearColor.destructiveHover, OnePlusLinearColor.destructivePressed] {
                let ground = LinearRender.resolve(fill, over: OnePlusLinearColor.appletWindow, in: name)
                XCTAssertGreaterThanOrEqual(abs(LinearRender.apcaLc(LinearRender.resolve(OnePlusLinearColor.destructiveText, in: name), ground)), 60,
                                            "destructive \(name)")
            }
        }
    }

    func testAppletTokensStayDynamicForAppKitHosts() {
        let light = LinearRender.resolve(OnePlusLinearColor.appletWindow, in: .aqua)
        let dark = LinearRender.resolve(OnePlusLinearColor.appletWindow, in: .darkAqua)
        XCTAssertEqual(light.redComponent * 255, 0xFD, accuracy: 0.5)
        XCTAssertEqual(dark.redComponent * 255, 0x1A, accuracy: 0.5)
        XCTAssertEqual(LinearRender.resolve(OnePlusLinearColor.destructiveFill, over: OnePlusLinearColor.appletWindow, in: .aqua).greenComponent * 255,
                       0xEB, accuracy: 1)
    }

    func testQuietMotionTokens() {
        XCTAssertEqual(OnePlusLinearMotion.curve, .bezier(startControlPoint: UnitPoint(x: 0.25, y: 1), endControlPoint: UnitPoint(x: 0.5, y: 1)))
        for duration in [OnePlusLinearMotion.knob, OnePlusLinearMotion.slider, OnePlusLinearMotion.contentIn, OnePlusLinearMotion.contentOut] {
            XCTAssertTrue((0.12...0.16).contains(duration))
        }
        XCTAssertEqual(OnePlusLinearMotion.knob, 0.14)
        XCTAssertEqual(OnePlusLinearMotion.contentOffset, 4)
        XCTAssertNil(OnePlusLinearMotion.resolved(0.14, style: .instant, reduceMotion: false))
        XCTAssertNil(OnePlusLinearMotion.resolved(0.14, style: .quiet, reduceMotion: true))
        XCTAssertNotNil(OnePlusLinearMotion.resolved(0.14, style: .quiet, reduceMotion: false))
        XCTAssertEqual(EnvironmentValues().onePlusLinearMotion, .instant)
        XCTAssertNil(EnvironmentValues().onePlusLinearControlLook)
    }

    func testSliderMapsThePointerAndClampsToTheRange() {
        XCTAssertEqual(OnePlusLinearSlider.value(at: 0.5, in: 0...1, step: 0.01), 0.5, accuracy: 1e-9)
        XCTAssertEqual(OnePlusLinearSlider.value(at: -0.3, in: 0...1, step: 0.01), 0)
        XCTAssertEqual(OnePlusLinearSlider.value(at: 1.4, in: 0...1, step: 0.01), 1)
        XCTAssertEqual(OnePlusLinearSlider.value(at: 0.337, in: 0...100, step: 5), 35)
        XCTAssertEqual(OnePlusLinearSlider.fraction(of: 25, in: 0...100), 0.25)
    }

    /// Quiet moves (mid-move frames differ from rest); each move, also one interrupted halfway, ends exactly in the
    /// rest layout. An instant surface is at rest on the next frame.
    func testQuietMotionEndsInTheRestLayout() throws {
        let canvas = CGSize(width: 420, height: 180)
        for appearance in Self.appearances {
            let rest = MotionModel()
            rest.flip()
            let still = try LinearRender.bitmap(NSHostingView(rootView: MotionProbe(model: rest)), size: canvas, scale: 2, appearance: appearance)
            for (style, interrupted) in [(OnePlusLinearMotionStyle.quiet, false), (.quiet, true), (.instant, false)] {
                let model = MotionModel()
                let host = NSHostingView(rootView: MotionProbe(model: model).onePlusLinearMotion(style))
                let window = LinearRender.attach(host, size: canvas, appearance: appearance)
                defer { window.close() }
                window.orderBack(nil)
                host.frame = CGRect(origin: .zero, size: canvas)
                pump(0.05)
                model.flip()
                pump(0.04)
                let early = differences(try LinearRender.capture(host, size: canvas, scale: 2), still)
                if style == .quiet { XCTAssertGreaterThan(early, 0, "\(appearance) Quiet moves") } else { XCTAssertEqual(early, 0, "\(appearance) instant") }
                if interrupted { pump(0.02); model.flip(); pump(0.03); model.flip() }
                // A busy suite can delay frames, so wait up to 2 s for the end state; it must then equal rest exactly.
                var remaining = differences(try LinearRender.capture(host, size: canvas, scale: 2), still)
                let deadline = Date().addingTimeInterval(2)
                while remaining > 0, Date() < deadline {
                    pump(0.1)
                    remaining = differences(try LinearRender.capture(host, size: canvas, scale: 2), still)
                }
                XCTAssertEqual(remaining, 0, "\(appearance) \(style) interrupted \(interrupted)")
            }
        }
    }

    private func differences(_ a: NSBitmapImageRep, _ b: NSBitmapImageRep) -> Int {
        var count = 0
        for y in 0..<b.pixelsHigh {
            for x in 0..<b.pixelsWide where !LinearRender.close(a.colorAt(x: x, y: y), b.colorAt(x: x, y: y)!, tolerance: 0.02) { count += 1 }
        }
        return count
    }

    private func pump(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// Writes the Depth contact sheet (every control in every state) at 2x in both appearances.
    func testRenderDepthContactSheet() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        let size = CGSize(width: 96 + 12 + 6 * LinearDepthContactSheet.cell.width, height: 24 + 28 + 5 * LinearDepthContactSheet.cell.height)
        for appearance in Self.appearances {
            let render = try LinearRender.bitmap(NSHostingView(rootView: LinearDepthContactSheet().frame(width: size.width, height: size.height)),
                                                 size: size, scale: 2, appearance: appearance)
            let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: "\(Self.output)/depth-sheet-\(appearance == .darkAqua ? "dark" : "light").png"))
        }
    }

    /// Writes the 1.2.1 applet parts sheet at 2x in both appearances.
    func testRenderAppletPartsSheet() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        for appearance in Self.appearances {
            let size = LinearAppletPartsSheet.size
            let render = try LinearRender.bitmap(NSHostingView(rootView: LinearAppletPartsSheet()), size: size, scale: 2, appearance: appearance)
            let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: "\(Self.output)/parts-121-\(appearance == .darkAqua ? "dark" : "light").png"))
        }
    }

    /// Writes both samples for side-by-side review with the reference renders.
    func testRenderAppletSamples() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        for appearance in Self.appearances {
            for scale: CGFloat in [1, 2] {
                let suffix = "\(appearance == .darkAqua ? "dark" : "light")-\(Int(scale))x"
                for (name, view, size) in [("applet-ruler-defaults", AnyView(LinearRulerDefaultsSample()), CGSize(width: 420, height: 500)),
                                           ("applet-color-picker", AnyView(LinearColorPickerSample()), CGSize(width: 420, height: 362))] {
                    let render = try LinearRender.bitmap(NSHostingView(rootView: view.frame(width: size.width, height: size.height)),
                                                         size: size, scale: scale, appearance: appearance)
                    // The capture holds sRGB values; tag them so viewers show the same colors as the sRGB references.
                    let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
                    try data.write(to: URL(fileURLWithPath: "\(Self.output)/\(name)-\(suffix).png"))
                }
            }
        }
    }
}

@MainActor @Observable
private final class MotionModel {
    var on = false
    var unit = "px"
    var value = 0.25
    var page = 0
    func flip() {
        on.toggle(); unit = unit == "px" ? "in" : "px"; value = value == 0.25 ? 1 : 0.25; page = 1 - page
    }
}

private struct MotionProbe: View {
    let model: MotionModel
    var body: some View {
        OnePlusLinearApplet("Motion", actions: { EmptyView() }) {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Shadow", isOn: Binding(get: { model.on }, set: { model.on = $0 })).toggleStyle(OnePlusLinearSwitchStyle())
                OnePlusLinearSegmented(choices: [("px", "px"), ("mm", "mm"), ("in", "in")],
                                       selection: Binding(get: { model.unit }, set: { model.unit = $0 }), accessibilityLabel: "Unit")
                OnePlusLinearSlider("Opacity", value: Binding(get: { model.value }, set: { model.value = $0 }))
                OnePlusLinearContentSwitch(model.page) {
                    Text(model.page == 0 ? "Home" : "Settings").linearText()
                }
            }
            .padding(16)
        }
    }
}
