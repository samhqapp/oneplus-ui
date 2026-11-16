import AppKit
import OnePlusUI
import SwiftUI

/// Round 3 control-style options for the applet controls, shown in the full Ruler Defaults applet.
/// Review-only: the library keeps the shipped look until the owner picks one.
enum ControlStyleOption: String, CaseIterable, Identifiable {
    case quietRaised, native, refinedDepth, linearFlat, raycast
    var id: String { rawValue }
}

private func tone(_ light: UInt32, _ dark: UInt32, light lightAlpha: Double = 1, dark darkAlpha: Double = 1) -> Color {
    Color(nsColor: OnePlusLinearColor.dynamic("option.\(light).\(lightAlpha).\(dark).\(darkAlpha)", light: light, lightAlpha: lightAlpha, dark: dark, darkAlpha: darkAlpha))
}

/// One look for every custom control, so the switch, slider, segment, stepper, and well share their colors.
struct ControlSkin {
    enum Stepper { case chevrons, minusPlus }
    var track: Color
    var trackLine: Color
    /// A soft 1 pt inner top shade on tracks and fields; nil keeps them flat.
    var recessShade: Color?
    var on: Color
    var knob: Color
    var knobOn: Color
    var knobLine: Color
    var knobShadow: Color
    var thumb: Color
    var thumbLine: Color
    var field: Color
    var fieldLine: Color
    var switchSize: CGSize
    var knob_: CGFloat
    var sliderTrack: CGFloat
    var sliderKnob: CGFloat
    var stepper: Stepper
    var segmentDividers = false
    var divider: Color = .clear

    static let height: CGFloat = 22
    static let radius: CGFloat = 6
    static let inset: CGFloat = 2

    static func of(_ option: ControlStyleOption) -> ControlSkin? {
        let blackLine = tone(0x000000, 0xFFFFFF, light: 0.07, dark: 0.07)
        switch option {
        case .native: return nil
        case .quietRaised:
            return ControlSkin(track: tone(0xE7E7EA, 0x111113), trackLine: blackLine, recessShade: tone(0, 0, light: 0.05, dark: 0.5),
                               on: OnePlusLinearColor.accent, knob: tone(0xFFFFFF, 0xE4E4E8), knobOn: tone(0xFFFFFF, 0xF2F2F4),
                               knobLine: tone(0, 0, light: 0.06, dark: 0.30), knobShadow: tone(0, 0, light: 0.16, dark: 0.45),
                               thumb: tone(0xFFFFFF, 0x45454C), thumbLine: tone(0, 0, light: 0.08, dark: 0.35),
                               field: tone(0xFFFFFF, 0x1E1E21), fieldLine: tone(0x000000, 0xFFFFFF, light: 0.09, dark: 0.07),
                               switchSize: CGSize(width: 32, height: 18), knob_: 14, sliderTrack: 4, sliderKnob: 14, stepper: .minusPlus,
                               segmentDividers: true, divider: tone(0x000000, 0xFFFFFF, light: 0.30, dark: 0.26))
        case .refinedDepth:
            return ControlSkin(track: tone(0xE3E3E6, 0x111113), trackLine: blackLine, recessShade: tone(0, 0, light: 0.10, dark: 0.55),
                               on: tone(0x46464D, 0x6C6C74), knob: tone(0xFFFFFF, 0xCDCDD3), knobOn: tone(0xFFFFFF, 0xE2E2E6),
                               knobLine: tone(0, 0, light: 0.10, dark: 0.35), knobShadow: tone(0, 0, light: 0.16, dark: 0.5),
                               thumb: tone(0xFFFFFF, 0x404047), thumbLine: tone(0, 0, light: 0.08, dark: 0.35),
                               field: tone(0xE3E3E6, 0x111113), fieldLine: blackLine,
                               switchSize: CGSize(width: 32, height: 18), knob_: 14, sliderTrack: 4, sliderKnob: 14, stepper: .chevrons)
        case .linearFlat:
            return ControlSkin(track: tone(0xE4E4E8, 0x35353A), trackLine: tone(0x000000, 0xFFFFFF, light: 0.04, dark: 0.04), recessShade: nil,
                               on: OnePlusLinearColor.accent, knob: tone(0xFFFFFF, 0xFFFFFF), knobOn: tone(0xFFFFFF, 0xFFFFFF),
                               knobLine: tone(0, 0, light: 0.14, dark: 0), knobShadow: .clear,
                               thumb: tone(0xFFFFFF, 0x4A4A51), thumbLine: tone(0x000000, 0xFFFFFF, light: 0.12, dark: 0.06),
                               field: tone(0xFFFFFF, 0x222225), fieldLine: tone(0x000000, 0xFFFFFF, light: 0.12, dark: 0.09),
                               switchSize: CGSize(width: 28, height: 16), knob_: 12, sliderTrack: 2, sliderKnob: 12, stepper: .chevrons)
        case .raycast:
            return ControlSkin(track: tone(0x000000, 0xFFFFFF, light: 0.08, dark: 0.10), trackLine: tone(0x000000, 0xFFFFFF, light: 0.05, dark: 0.07),
                               recessShade: nil, on: tone(0x1B1B1F, 0xF2F2F4), knob: tone(0xFFFFFF, 0xF2F2F4), knobOn: tone(0xFFFFFF, 0x1A1A1D),
                               knobLine: tone(0, 0, light: 0.12, dark: 0.55), knobShadow: tone(0, 0, light: 0.14, dark: 0.4),
                               thumb: tone(0xFFFFFF, 0xFFFFFF, light: 1, dark: 0.15), thumbLine: tone(0x000000, 0xFFFFFF, light: 0.08, dark: 0.10),
                               field: tone(0x000000, 0xFFFFFF, light: 0.035, dark: 0.06), fieldLine: tone(0x000000, 0xFFFFFF, light: 0.08, dark: 0.09),
                               switchSize: CGSize(width: 30, height: 18), knob_: 14, sliderTrack: 4, sliderKnob: 14, stepper: .minusPlus)
        }
    }
}

/// A track or field: fill, an optional soft inner top shade, and a 1 physical pixel inner line.
private struct SkinWell<S: InsettableShape>: View {
    let shape: S
    let fill: Color
    let line: Color
    let shade: Color?
    @Environment(\.displayScale) private var scale
    var body: some View {
        Group {
            if let shade { shape.fill(fill.shadow(.inner(color: shade, radius: 1, y: 0.5))) } else { shape.fill(fill) }
        }
        .overlay { shape.strokeBorder(line, lineWidth: 1 / max(scale, 1)) }
    }
}

/// A knob or thumb: one solid part with a 1 physical pixel line and one soft contact shadow.
private struct SkinCap<S: InsettableShape>: View {
    let shape: S
    let fill: Color
    let line: Color
    let shadow: Color
    @Environment(\.displayScale) private var scale
    var body: some View {
        shape.fill(fill)
            .overlay { shape.strokeBorder(line, lineWidth: 1 / max(scale, 1)) }
            .shadow(color: shadow, radius: 1, y: 0.5)
    }
}

private struct SkinSwitch: View {
    let skin: ControlSkin
    @Binding var isOn: Bool
    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                if isOn { Capsule().fill(skin.on) } else { SkinWell(shape: Capsule(), fill: skin.track, line: skin.trackLine, shade: skin.recessShade) }
                SkinCap(shape: Circle(), fill: isOn ? skin.knobOn : skin.knob, line: skin.knobLine, shadow: skin.knobShadow)
                    .frame(width: skin.knob_, height: skin.knob_)
                    .padding((skin.switchSize.height - skin.knob_) / 2)
            }
            .frame(width: skin.switchSize.width, height: skin.switchSize.height)
        }
        .buttonStyle(.plain)
    }
}

private struct SkinSlider: View {
    let skin: ControlSkin
    @Binding var value: Double
    static let width: CGFloat = 140
    var body: some View {
        let travel = Self.width - skin.sliderKnob
        ZStack(alignment: .leading) {
            SkinWell(shape: Capsule(), fill: skin.track, line: skin.trackLine, shade: nil)
                .overlay(alignment: .leading) { Capsule().fill(skin.on).frame(width: skin.sliderKnob / 2 + travel * value) }
                .frame(height: skin.sliderTrack)
            SkinCap(shape: Circle(), fill: skin.knob, line: skin.knobLine, shadow: skin.knobShadow)
                .frame(width: skin.sliderKnob, height: skin.sliderKnob)
                .padding(.leading, travel * value)
        }
        .frame(width: Self.width, height: ControlSkin.height)
    }
}

private struct SkinSegmented: View {
    let skin: ControlSkin
    @Binding var selection: String
    let choices = ["px", "mm", "in"]
    @Environment(\.displayScale) private var scale
    var body: some View {
        let inner = ControlSkin.radius - ControlSkin.inset
        let pixel = 1 / max(scale, 1)
        HStack(spacing: 0) {
            ForEach(Array(choices.indices), id: \.self) { index in
                let choice = choices[index]
                let on = choice == selection
                // Classic macOS: a short divider that fades out at both ends, hidden beside the selected segment.
                let divided = skin.segmentDividers && index > 0 && !on && choices[index - 1] != selection
                Button { selection = choice } label: {
                    Text(choice).linearText(weight: on ? .medium : .regular, color: on ? OnePlusLinearColor.ink : OnePlusLinearColor.appletSecondary)
                        // Lowercase labels have no cap height: center the x-height, which sits 1.25 pt below the line box center.
                        .offset(y: skin.segmentDividers ? -1.25 : 0)
                        .frame(width: 36, height: ControlSkin.height - 2 * ControlSkin.inset)
                        .background { if on { SkinCap(shape: RoundedRectangle(cornerRadius: inner), fill: skin.thumb, line: skin.thumbLine, shadow: skin.knobShadow) } }
                        .overlay(alignment: .leading) {
                            if divided {
                                LinearGradient(colors: [.clear, skin.divider, .clear], startPoint: .top, endPoint: .bottom)
                                    .frame(width: pixel, height: 12).offset(x: -pixel / 2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ControlSkin.inset)
        .background { SkinWell(shape: RoundedRectangle(cornerRadius: ControlSkin.radius), fill: skin.track, line: skin.trackLine, shade: skin.recessShade) }
    }
}

private struct SkinStepper: View {
    let skin: ControlSkin
    @Binding var value: Int
    @Environment(\.displayScale) private var scale
    var body: some View {
        let hairline = skin.fieldLine.frame(width: 1 / max(scale, 1)).padding(.vertical, 5)
        HStack(spacing: 0) {
            switch skin.stepper {
            case .minusPlus:
                glyphButton("minus", -1).frame(width: 22)
                hairline
                valueText.frame(maxWidth: .infinity)
                hairline
                glyphButton("plus", 1).frame(width: 22)
            case .chevrons:
                valueText.frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 7)
                hairline
                VStack(spacing: 0) {
                    glyphButton("chevron.up", 1)
                    glyphButton("chevron.down", -1)
                }
                .frame(width: 18)
                .padding(.vertical, 3)
            }
        }
        .frame(width: 104, height: ControlSkin.height)
        .background { SkinWell(shape: RoundedRectangle(cornerRadius: ControlSkin.radius), fill: skin.field, line: skin.fieldLine, shade: skin.recessShade) }
    }

    private var valueText: some View {
        Text(String(value)).linearText().lineLimit(1)
    }

    private func glyphButton(_ symbol: String, _ step: Int) -> some View {
        Button { value += step } label: {
            Image(systemName: symbol).font(.system(size: symbol.hasPrefix("chevron") ? 7 : 9, weight: .semibold))
                .foregroundStyle(OnePlusLinearColor.appletSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SkinWell2: View {
    let skin: ControlSkin
    let color: NSColor
    @Environment(\.displayScale) private var scale
    var body: some View {
        let swatch = RoundedRectangle(cornerRadius: ControlSkin.radius - 3)
        swatch.fill(Color(nsColor: color))
            .overlay { swatch.strokeBorder(tone(0, 0, light: 0.10, dark: 0.25), lineWidth: 1 / max(scale, 1)) }
            .padding(3)
            .frame(width: 40, height: ControlSkin.height)
            .background { SkinWell(shape: RoundedRectangle(cornerRadius: ControlSkin.radius), fill: skin.field, line: skin.fieldLine, shade: skin.recessShade) }
    }
}

/// Round 3 options for the destructive "Reset to Factory Defaults" action.
enum ResetStyle: String, CaseIterable, Identifiable {
    case quietPush, mutedAccent, classicPush, softGray, plainText
    var id: String { rawValue }
}

private enum ResetColor {
    static let text = tone(0xC4342B, 0xFF8A80)
    static let gradientTop = tone(0xD3574D, 0xB8473F)
    static let gradientBottom = tone(0xC0433A, 0xA33A33)
    static let gradientLine = tone(0x9E2F27, 0x000000, light: 0.55, dark: 0.45)
}

/// The reset action in one style. Full-width styles span the group; the others sit at the trailing edge
/// like a classic macOS dialog button, or on the row text edge for the plain text link.
private struct ResetButton: View {
    let style: ResetStyle
    @Environment(\.displayScale) private var scale
    var body: some View {
        let title = "Reset to Factory Defaults"
        let pixel = 1 / max(scale, 1)
        switch style {
        case .classicPush:
            Button(title, role: .destructive) {}
                .buttonStyle(.bordered).controlSize(.regular).foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .trailing)
        case .mutedAccent:
            Button {} label: {
                Text(title).linearText(weight: .medium, color: .white)
                    .padding(.horizontal, 12).frame(height: 24)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: ControlSkin.radius)
                        shape.fill(LinearGradient(colors: [ResetColor.gradientTop, ResetColor.gradientBottom], startPoint: .top, endPoint: .bottom))
                            .overlay { shape.strokeBorder(ResetColor.gradientLine, lineWidth: pixel) }
                            .shadow(color: tone(0, 0, light: 0.14, dark: 0.4), radius: 1, y: 0.5)
                    }
            }
            .buttonStyle(.plain).frame(maxWidth: .infinity, alignment: .trailing)
        case .quietPush:
            Button {} label: {
                Text(title).linearText(weight: .medium, color: ResetColor.text)
                    .padding(.horizontal, 12).frame(height: 24)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: ControlSkin.radius)
                        shape.fill(tone(0xFFFFFF, 0x3A3A40))
                            .overlay { shape.strokeBorder(tone(0, 0, light: 0.10, dark: 0.35), lineWidth: pixel) }
                            .shadow(color: tone(0, 0, light: 0.10, dark: 0.4), radius: 1, y: 0.5)
                    }
            }
            .buttonStyle(.plain).frame(maxWidth: .infinity, alignment: .trailing)
        case .softGray:
            Button {} label: {
                Text(title).linearText(weight: .medium, color: ResetColor.text)
                    // The 1.2 full-width button geometry, as reviewed in round 3.
                    .frame(maxWidth: .infinity).frame(height: 30)
                    .background(tone(0xEBEBED, 0x2C2C30), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        case .plainText:
            Button {} label: { Text(title).linearText(color: ResetColor.text) }
                .buttonStyle(.plain)
                .padding(.leading, OnePlusLinearMetrics.appletRowPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The Ruler Defaults applet with the same content as `LinearRulerDefaultsSample`, drawn in one control style.
struct ControlStyleRulerDefaults: View {
    let option: ControlStyleOption
    var reset: ResetStyle? = nil
    @State private var unit = "px"
    @State private var width = 1920
    @State private var height = 1080
    @State private var color = NSColor(srgbRed: 1, green: 0.859, blue: 0, alpha: 1)
    @State private var foreground = 0.9
    @State private var background = 0.5
    @State private var border = 0.25
    @State private var floats = true
    @State private var shadow = false

    var body: some View {
        OnePlusLinearApplet("Ruler Defaults", actions: { EmptyView() }) {
            OnePlusLinearAppletForm {
                OnePlusLinearAppletSection("Measurement") {
                    OnePlusLinearAppletRow("Unit") { segmented }
                    OnePlusLinearAppletRow("Dimensions") {
                        HStack(spacing: 6) {
                            stepper($width)
                            Text("×").linearText(color: OnePlusLinearColor.appletMuted).fixedSize().accessibilityHidden(true)
                            stepper($height)
                        }
                    }
                }
                OnePlusLinearAppletSection("Appearance") {
                    OnePlusLinearAppletRow("Ruler color") { well }
                    sliderRow("Foreground opacity", $foreground)
                    sliderRow("Background opacity", $background)
                    sliderRow("Border opacity", $border)
                }
                OnePlusLinearAppletSection("Window") {
                    OnePlusLinearAppletRow("Float ruler above other applications") { toggle("Float ruler above other applications", $floats) }
                    OnePlusLinearAppletRow("Show ruler shadow") { toggle("Show ruler shadow", $shadow) }
                }
            } footer: {
                if let reset { ResetButton(style: reset) } else {
                    Button("Reset to Factory Defaults", role: .destructive) {}
                        .buttonStyle(OnePlusLinearButtonStyle(.destructive))
                }
            }
        }
        .overlay(alignment: .topLeading) { LinearSampleLights() }
        .environment(\.onePlusZoomTrailingX, 66)
    }

    private var skin: ControlSkin? { ControlSkin.of(option) }

    @ViewBuilder private var segmented: some View {
        if let skin { SkinSegmented(skin: skin, selection: $unit) } else {
            Picker("Unit", selection: $unit) { ForEach(["px", "mm", "in"], id: \.self) { Text($0).tag($0) } }
                .pickerStyle(.segmented).labelsHidden().frame(width: 120).controlSize(.small)
        }
    }

    @ViewBuilder private func stepper(_ value: Binding<Int>) -> some View {
        if let skin { SkinStepper(skin: skin, value: value) } else {
            HStack(spacing: 2) {
                TextField("", value: value, format: .number.grouping(.never)).textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing).frame(width: 64)
                Stepper("", value: value, in: 1...10000).labelsHidden()
            }
            .controlSize(.small)
        }
    }

    @ViewBuilder private var well: some View {
        if let skin { SkinWell2(skin: skin, color: color) } else {
            ColorPicker("Ruler color", selection: Binding { Color(nsColor: color) } set: { color = NSColor($0) }, supportsOpacity: false)
                .labelsHidden().controlSize(.small)
        }
    }

    private func sliderRow(_ label: String, _ value: Binding<Double>) -> some View {
        OnePlusLinearAppletRow(label) {
            HStack(spacing: 8) {
                if let skin { SkinSlider(skin: skin, value: value) } else {
                    Slider(value: value, in: 0...1).labelsHidden().controlSize(.small).frame(width: SkinSlider.width)
                }
                Text("\(Int((value.wrappedValue * 100).rounded()))%").linearText(color: OnePlusLinearColor.appletSecondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }

    @ViewBuilder private func toggle(_ label: String, _ isOn: Binding<Bool>) -> some View {
        if let skin { SkinSwitch(skin: skin, isOn: isOn).accessibilityLabel(label) } else {
            Toggle(label, isOn: isOn).toggleStyle(.switch).labelsHidden().controlSize(.small).tint(OnePlusLinearColor.accent)
        }
    }
}
