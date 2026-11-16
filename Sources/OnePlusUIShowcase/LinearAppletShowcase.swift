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
            LinearQuietContactSheet().clipShape(RoundedRectangle(cornerRadius: 12)).padding([.horizontal, .bottom], 24)
            LinearAppletPartsSheet().clipShape(RoundedRectangle(cornerRadius: 12)).padding([.horizontal, .bottom], 24)
        }
        .background(OnePlusLinearColor.sidebar)
    }
}

/// Every Quiet Raised control in every state, on the applet group fill: off, on, hover, pressed, disabled, and
/// focus (as drawn under Full Keyboard Access).
struct LinearQuietContactSheet: View {
    enum Column: String, CaseIterable { case off = "Off", on = "On", hover = "Hover", pressed = "Pressed", disabled = "Disabled", focus = "Focus" }
    static let rows = ["Switch", "Segmented", "Slider", "Stepper", "Color well", "Reset"]
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
        .environment(\.onePlusLinearControlLook, .quietRaised)
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
            OnePlusStepperField("Width", value: .constant(1920), in: 1...10000)
        case "Color well":
            OnePlusLinearColorWell(row, color: .constant(NSColor(srgbRed: 1, green: 0.84, blue: 0.04, alpha: 1)))
        default:
            Button("Reset", role: .destructive) {}.buttonStyle(OnePlusLinearButtonStyle(.destructive)).fixedSize()
        }
    }
}

/// The 1.2.1 applet parts: stepper units in a tight row, list-row metadata gap, text field, fitted segments,
/// ghost button, nav row count and dimmed name, pane toolbar without navigation, empty state, and banners.
struct LinearAppletPartsSheet: View {
    static let size = CGSize(width: 860, height: 450)
    @State private var mode = "accurate"
    @State private var tab = 0

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: OnePlusLinearMetrics.appletSectionGap) {
                OnePlusLinearAppletSection("Timer") {
                    OnePlusLinearAppletRow("Duration") {
                        HStack(spacing: OnePlusLinearMetrics.appletActionGap) {
                            OnePlusStepperField("Hours", value: .constant(2), in: 0...168, unit: "h")
                            OnePlusStepperField("Minutes", value: .constant(30), in: 0...59, step: 5, unit: "min")
                            Button("Start") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                        }
                    }
                    OnePlusLinearAppletRow("Mode") {
                        OnePlusLinearSegmented(choices: [("fast", "Fast"), ("accurate", "Accurate"), ("custom", "Custom")],
                                               selection: $mode, accessibilityLabel: "Mode", sizing: .fitted)
                    }
                    OnePlusLinearAppletRow("Name") { OnePlusLinearTextField("Project name", text: .constant("")).frame(width: 180) }
                    OnePlusLinearAppletRow("Focused") {
                        OnePlusLinearTextField("Path", text: .constant("~/Downloads")).frame(width: 180)
                            .environment(\.onePlusControlState, .focus)
                    }
                }
                OnePlusLinearAppletSection("Projects") {
                    OnePlusLinearAppletListRow("A very long project name that has to truncate before its count", metadata: "128 colors",
                                               actions: [OnePlusLinearAction("Export", systemImage: "square.and.arrow.up") {}]) {
                        OnePlusLinearSwatch(.orange)
                    }
                }
                HStack(spacing: OnePlusLinearMetrics.appletActionGap) {
                    Button("Cancel") {}.buttonStyle(OnePlusLinearButtonStyle(.ghost))
                    Button("Hover") {}.buttonStyle(OnePlusLinearButtonStyle(.ghost)).environment(\.onePlusControlState, .hover)
                    Button {} label: { Label("Pick Color", systemImage: "eyedropper") }.buttonStyle(OnePlusLinearButtonStyle(.soft))
                }
                OnePlusLinearBanner(.info, title: "Accessibility access is on", message: "Scrolling follows your profiles.")
                OnePlusLinearBanner(.warning, title: "Accessibility access needed", message: "Custom scrolling is paused.") {
                    Button("Open Settings") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                }
            }
            .padding(OnePlusLinearMetrics.appletGutter)
            .frame(width: 460)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(OnePlusLinearColor.appletWindow)
            .environment(\.onePlusLinearControlLook, .quietRaised)

            VStack(alignment: .leading, spacing: 0) {
                OnePlusLinearPaneToolbar(title: "Settings") {
                    OnePlusLinearTextTabs(tabs: [OnePlusTab(0, "General"), OnePlusTab(1, "About")], selection: $tab)
                }
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 2) {
                        OnePlusLinearNavRow("Transfers", systemImage: "arrow.up.arrow.down", selected: true, count: 3) {}
                        OnePlusLinearNavRow("Remotes", systemImage: "externaldrive", count: 12) {}
                        OnePlusLinearNavRow("Dev Sync", systemImage: "arrow.triangle.2.circlepath", dimmed: true) {}
                    }
                    .padding(OnePlusLinearMetrics.sidebarInset)
                    .frame(width: 180)
                    .background(OnePlusLinearColor.sidebar)
                    OnePlusLinearEmptyState("No transfers", systemImage: "tray",
                                            message: "Start a transfer to see its progress here.") {
                        Button("New Transfer") {}.buttonStyle(OnePlusLinearButtonStyle(.soft))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: 400)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(OnePlusLinearColor.window)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
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
                            OnePlusStepperField("Width", value: $width, in: 1...10000)
                            Text("×").font(.system(size: OnePlusLinearMetrics.body)).foregroundStyle(OnePlusLinearColor.muted)
                                .fixedSize().accessibilityHidden(true)
                            OnePlusStepperField("Height", value: $height, in: 1...10000)
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
