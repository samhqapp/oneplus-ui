import AppKit
import OnePlusUI
import SwiftUI

/// Version 15 applets: Ruler Defaults and Color Picker composed from the applet parts with the mockup data,
/// under the Quiet motion.
struct LinearAppletShowcase: View {
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 32) {
                LinearRulerDefaultsSample().frame(width: 420, height: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                LinearColorPickerSample().frame(width: 420, height: 362)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
            .onePlusLinearMotion(.quiet)
            LinearDepthContactSheet().clipShape(RoundedRectangle(cornerRadius: 12)).padding([.horizontal, .bottom], 24)
        }
        .background(OnePlusLinearColor.sidebar)
    }
}

/// Every Depth control in every state, on the applet group fill: off, on, hover, pressed, disabled, and focus
/// (as drawn under Full Keyboard Access).
struct LinearDepthContactSheet: View {
    enum Column: String, CaseIterable { case off = "Off", on = "On", hover = "Hover", pressed = "Pressed", disabled = "Disabled", focus = "Focus" }
    static let rows = ["Switch", "Segmented", "Slider", "Stepper", "Color well"]
    static let cell = CGSize(width: 176, height: 48)

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Text("").frame(width: 108)
                ForEach(Column.allCases, id: \.self) { column in
                    Text(column.rawValue).font(.system(size: 12, weight: .medium)).foregroundStyle(OnePlusLinearColor.muted)
                        .frame(width: Self.cell.width, height: 28)
                }
            }
            ForEach(Self.rows, id: \.self) { row in
                GridRow {
                    Text(row).font(.system(size: 13)).foregroundStyle(OnePlusLinearColor.ink)
                        .padding(.leading, 12).frame(width: 108, height: Self.cell.height, alignment: .leading)
                    ForEach(Column.allCases, id: \.self) { column in
                        control(row, column)
                            .environment(\.onePlusControlState, state(column))
                            .disabled(column == .disabled)
                            .frame(width: Self.cell.width, height: Self.cell.height)
                    }
                }
                .background(OnePlusLinearColor.appletGroup)
                .overlay(alignment: .top) { OnePlusLinearColor.appletLine.frame(height: 1).padding(.leading, 12) }
            }
        }
        .padding(.vertical, 12)
        .background(OnePlusLinearColor.appletWindow)
        .environment(\.onePlusLinearControlLook, .depth)
    }

    private func state(_ column: Column) -> OnePlusControlState {
        switch column {
        case .hover: .hover
        case .pressed: .pressed
        case .focus: .focus
        default: .rest
        }
    }

    @ViewBuilder private func control(_ row: String, _ column: Column) -> some View {
        let on = column != .off
        switch row {
        case "Switch":
            Toggle(row, isOn: .constant(on)).toggleStyle(OnePlusLinearSwitchStyle())
        case "Segmented":
            OnePlusLinearSegmented(choices: [("px", "px"), ("mm", "mm"), ("in", "in")], selection: .constant(on ? "mm" : "px"),
                                   accessibilityLabel: "Unit")
        case "Slider":
            OnePlusLinearSlider(row, value: .constant(on ? 0.6 : 0))
        case "Stepper":
            OnePlusStepperField("Width", value: .constant(1920), in: 1...10000, unit: "px")
        default:
            OnePlusLinearColorWell(row, color: .constant(NSColor(srgbRed: 1, green: 0.84, blue: 0.04, alpha: 1)))
        }
    }
}

/// Stand-in traffic lights at the native applet place (close at x 14, 12 pt, 8 pt apart, centered on y 22),
/// so a sample outside a real window compares with the mockup. A real applet window draws its own.
struct LinearSampleLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1, green: 0.373, blue: 0.341))
            Circle().fill(Color(red: 0.996, green: 0.737, blue: 0.180))
            Circle().fill(OnePlusLinearColor.switchOff)
        }
        .frame(width: 52, height: 12)
        .padding(.leading, 14).padding(.top, OnePlusLinearMetrics.appletCenterline - 6)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct LinearRulerDefaultsSample: View {
    @State private var unit = "px"
    @State private var width = 1920
    @State private var height = 1080
    @State private var color = NSColor(srgbRed: 1, green: 0.859, blue: 0, alpha: 1)
    @State private var foreground = 1.0
    @State private var background = 0.5
    @State private var border = 0.25
    @State private var floats = true
    @State private var shadow = false

    var body: some View {
        OnePlusLinearApplet("Ruler Defaults", actions: { EmptyView() }) {
            OnePlusLinearAppletForm {
                OnePlusLinearAppletSection("Measurement") {
                    OnePlusLinearAppletRow("Unit") {
                        OnePlusLinearSegmented(choices: [("px", "px"), ("mm", "mm"), ("in", "in")], selection: $unit,
                                               accessibilityLabel: "Unit")
                    }
                    OnePlusLinearAppletRow("Dimensions") {
                        HStack(spacing: 6) {
                            OnePlusStepperField("Width", value: $width, in: 1...10000, unit: unit)
                            Text("×").font(.system(size: OnePlusLinearMetrics.body)).foregroundStyle(OnePlusLinearColor.muted)
                                .fixedSize().accessibilityHidden(true)
                            OnePlusStepperField("Height", value: $height, in: 1...10000, unit: unit)
                        }
                    }
                }
                OnePlusLinearAppletSection("Appearance") {
                    OnePlusLinearAppletRow("Ruler color") { OnePlusLinearColorWell("Ruler color", color: $color) }
                    OnePlusLinearAppletSliderRow("Foreground opacity", value: $foreground)
                    OnePlusLinearAppletSliderRow("Background opacity", value: $background)
                    OnePlusLinearAppletSliderRow("Border opacity", value: $border)
                }
                OnePlusLinearAppletSection("Window") {
                    OnePlusLinearAppletRow("Float ruler above other applications") {
                        Toggle("Float ruler above other applications", isOn: $floats).toggleStyle(OnePlusLinearSwitchStyle())
                    }
                    OnePlusLinearAppletRow("Show ruler shadow") {
                        Toggle("Show ruler shadow", isOn: $shadow).toggleStyle(OnePlusLinearSwitchStyle())
                    }
                }
            } footer: {
                Button("Reset to Factory Defaults", role: .destructive, action: reset)
                    .buttonStyle(OnePlusLinearButtonStyle(.destructive))
            }
        }
        .overlay(alignment: .topLeading) { LinearSampleLights() }
        .environment(\.onePlusZoomTrailingX, 66)
    }

    private func reset() {
        unit = "px"; width = 1920; height = 1080; foreground = 1; background = 0.5; border = 0.25; floats = true; shadow = false
    }
}

struct LinearColorSample: Identifiable {
    let hex: String
    let age: String
    var id: String { hex }
    var color: Color {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        return Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
    static let history: [LinearColorSample] = [
        .init(hex: "#1C1C1C", age: "2 wks ago"), .init(hex: "#777777", age: "4 wks ago"), .init(hex: "#F7F8F7", age: "1 mo ago"),
        .init(hex: "#F6F6F3", age: "1 mo ago"), .init(hex: "#161616", age: "3 mos ago"), .init(hex: "#FDFDFD", age: "3 mos ago"),
    ]
}

struct LinearColorPickerSample: View {
    @State private var page = "history"
    @State private var settings = false
    @State private var project = "unfiled"
    @State private var query = ""
    @State private var format = "hex"

    var body: some View {
        OnePlusLinearApplet("Color Picker") {
            OnePlusLinearAppletSettingsButton(isActive: settings) { settings.toggle() }
            Button {} label: { Label("Pick Color", systemImage: "eyedropper") }
                .buttonStyle(OnePlusLinearButtonStyle(.soft))
        } content: {
            OnePlusLinearContentSwitch(settings) {
                if settings {
                    OnePlusLinearAppletForm {
                        OnePlusLinearAppletSection("Shortcut") {
                            OnePlusLinearAppletRow("Pick Color", value: "⌘⇧3")
                        }
                    }
                } else {
                    history
                }
            }
        }
        .overlay(alignment: .topLeading) { LinearSampleLights() }
        .environment(\.onePlusZoomTrailingX, 66)
    }

    private var history: some View {
        VStack(spacing: 0) {
            OnePlusLinearAppletTabRow(tabs: [OnePlusTab("history", "History", count: 6), OnePlusTab("projects", "Projects", count: 3)],
                                      selection: $page) {
                OnePlusLinearSelect(choices: [("unfiled", "Unfiled"), ("brand", "Brand")], selection: $project,
                                    accessibilityLabel: "Project", style: .text)
            }
            OnePlusLinearAppletToolbar {
                OnePlusLinearSearchField("Search colors", text: $query, style: .applet)
                OnePlusLinearSelect(choices: [("hex", "HEX"), ("rgb", "RGB"), ("hsl", "HSL")], selection: $format,
                                    accessibilityLabel: "Format", width: 92)
            }
            ScrollView {
                OnePlusLinearAppletGroup {
                    ForEach(LinearColorSample.history) { sample in
                        OnePlusLinearAppletListRow(sample.hex, monospaced: true, metadata: sample.age, actions: [
                            OnePlusLinearAction("Copy", systemImage: "doc.on.doc") {},
                            OnePlusLinearAction("Pin", systemImage: "pin") {},
                            OnePlusLinearAction("Delete", systemImage: "trash") {},
                        ]) { OnePlusLinearSwatch(sample.color) }
                    }
                }
                .padding(.horizontal, OnePlusLinearMetrics.appletGutter)
                .padding(.bottom, OnePlusLinearMetrics.appletBottom)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
