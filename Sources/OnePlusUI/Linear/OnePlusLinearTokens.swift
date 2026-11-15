import AppKit
import SwiftUI

/// DESIGN.md v15 ("Linear style"). Values come from the owner-approved mockups in
/// `macpowertoys/docs/design/v15/`. Dark text roles are raised where the mockup missed the APCA minimums.
public enum OnePlusLinearColor {
    /// A dynamic sRGB color with its own alpha per appearance. Increase Contrast strengthens translucent lines.
    public static func dynamic(_ name: String, light: UInt32, lightAlpha: Double = 1,
                               dark: UInt32, darkAlpha: Double = 1) -> NSColor {
        NSColor(name: NSColor.Name("OnePlusLinear.\(name)")) { appearance in
            resolve(appearance: appearance, increasedContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast,
                    light: light, lightAlpha: lightAlpha, dark: dark, darkAlpha: darkAlpha)
        }
    }

    static func resolve(appearance: NSAppearance, increasedContrast: Bool, light: UInt32, lightAlpha: Double,
                        dark: UInt32, darkAlpha: Double) -> NSColor {
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let highContrast = increasedContrast || appearance.name == .accessibilityHighContrastAqua
            || appearance.name == .accessibilityHighContrastDarkAqua
        let hex = isDark ? dark : light
        let alpha = isDark ? darkAlpha : lightAlpha
        return NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                       blue: CGFloat(hex & 255) / 255, alpha: highContrast && alpha < 1 ? min(1, alpha * 2.5) : alpha)
    }

    private static func color(_ name: String, light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) -> Color {
        Color(nsColor: dynamic(name, light: light, lightAlpha: lightAlpha, dark: dark, darkAlpha: darkAlpha))
    }

    // Surfaces
    public static let window = color("window", light: 0xFCFCFD, dark: 0x141416)
    public static let sidebar = color("sidebar", light: 0xF5F5F6, dark: 0x101012)
    public static let field = color("field", light: 0xFFFFFF, dark: 0x1B1B1E)
    public static let hover = color("hover", light: 0x000000, lightAlpha: 0.035, dark: 0xFFFFFF, darkAlpha: 0.03)
    public static let pressed = color("pressed", light: 0x000000, lightAlpha: 0.07, dark: 0xFFFFFF, darkAlpha: 0.06)
    public static let selection = color("selection", light: 0x000000, lightAlpha: 0.06, dark: 0xFFFFFF, darkAlpha: 0.065)
    public static let track = color("track", light: 0x000000, lightAlpha: 0.045, dark: 0xFFFFFF, darkAlpha: 0.05)
    public static let segmentSelected = color("segmentSelected", light: 0xFFFFFF, dark: 0x2C2C30)
    public static let segmentRing = color("segmentRing", light: 0x000000, lightAlpha: 0.12, dark: 0xFFFFFF, darkAlpha: 0.07)
    public static let segmentShadow = color("segmentShadow", light: 0x000000, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.5)
    public static let kbd = color("kbd", light: 0xFFFFFF, dark: 0xFFFFFF, darkAlpha: 0.06)
    public static let panelShell = color("panelShell", light: 0xFBFBFC, dark: 0x141416)
    public static let panelTile = color("panelTile", light: 0xFFFFFF, dark: 0x1A1A1D)
    public static let panelFooter = color("panelFooter", light: 0xF5F5F7, dark: 0x111113)
    public static let button = color("button", light: 0xFFFFFF, dark: 0x1E1E21)
    public static let buttonRing = color("buttonRing", light: 0x000000, lightAlpha: 0.16, dark: 0xFFFFFF, darkAlpha: 0.10)
    /// Light: a soft 1 pt drop. Dark: a 1 pt black halo outside the ring.
    public static let buttonDrop = color("buttonDrop", light: 0x000000, lightAlpha: 0.06, dark: 0x000000, darkAlpha: 0)
    public static let buttonHalo = color("buttonHalo", light: 0x000000, lightAlpha: 0, dark: 0x000000, darkAlpha: 0.5)

    // Lines
    public static let line = color("line", light: 0x000000, lightAlpha: 0.085, dark: 0xFFFFFF, darkAlpha: 0.075)
    public static let lineSoft = color("lineSoft", light: 0x000000, lightAlpha: 0.06, dark: 0xFFFFFF, darkAlpha: 0.055)
    public static let lineStrong = color("lineStrong", light: 0x000000, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.12)
    public static let barTrack = color("barTrack", light: 0x000000, lightAlpha: 0.075, dark: 0xFFFFFF, darkAlpha: 0.085)
    public static let iconOutline = color("iconOutline", light: 0x000000, lightAlpha: 0.1, dark: 0xFFFFFF, darkAlpha: 0.1)

    // Text (APCA: labels Lc 60, captions Lc 45 on every v15 surface)
    public static let ink = color("ink", light: 0x1B1B1F, dark: 0xEDEDEF)
    public static let secondary = color("secondary", light: 0x55555C, dark: 0xB4B4BA)
    public static let muted = color("muted", light: 0x7A7A82, dark: 0x9999A1)
    public static let panelMuted = color("panelMuted", light: 0x6E6E76, dark: 0x9999A1)
    /// Glyphs only (chevrons), never text.
    public static let tertiary = color("tertiary", light: 0x9A9AA2, dark: 0x66666E)
    public static let accent = color("accent", light: 0xE0493E, dark: 0xEE5B50)

    // Controls
    public static let switchOff = color("switchOff", light: 0x000000, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.14)
    public static let switchOn = color("switchOn", light: 0x1C1D22, dark: 0xE6E6E8)
    public static let knobOn = color("knobOn", light: 0xFFFFFF, dark: 0x141416)
    public static let knobOff = color("knobOff", light: 0xFFFFFF, dark: 0xFFFFFF)

    // Data
    public static let cpu = color("cpu", light: 0x2A7DE1, dark: 0x4C8FE6)
    /// CPU numbers as text. Dark is lighter than the chart line to reach Lc 60.
    public static let cpuText = color("cpuText", light: 0x2A7DE1, dark: 0x8DB8EF)
    public static let gpu = color("gpu", light: 0x8A63D2, dark: 0x9A88D2)
    public static let memory = color("memory", light: 0xD2508F, dark: 0xC97FA4)
    public static let disk = color("disk", light: 0x5A64D8, dark: 0x8890E0)
    public static let battery = color("battery", light: 0x2AA855, dark: 0x4FBE76)
    public static let networkDown = color("networkDown", light: 0x1A9FB0, dark: 0x45B8C4)
    public static let networkUp = color("networkUp", light: 0xE07F2A, dark: 0xD9925A)
    /// Area fill under a history line: series color at this opacity.
    public static let chartFillOpacity = (light: 0.09, dark: 0.10)
}

public enum OnePlusLinearMetrics {
    // Type
    public static let body: CGFloat = 13
    public static let bodyTracking: CGFloat = -0.08
    public static let control: CGFloat = 12
    public static let caption: CGFloat = 11
    public static let sectionCaption: CGFloat = 11.5
    public static let tileValue: CGFloat = 22
    public static let tileValueLine: CGFloat = 26

    // Main window
    public static let sidebarWidth: CGFloat = 215
    public static let sidebarTop: CGFloat = 44
    public static let sidebarInset: CGFloat = 8
    public static let searchHeight: CGFloat = 28
    public static let searchBelow: CGFloat = 8
    public static let navRow: CGFloat = 28
    public static let navPadding: CGFloat = 8
    public static let navIcon: CGFloat = 16
    public static let navGlyph: CGFloat = 14
    public static let navIconGap: CGFloat = 8
    public static let navCaption: CGFloat = 28
    public static let navCaptionTop: CGFloat = 6
    public static let radius: CGFloat = 6
    public static let toolbar: CGFloat = 44
    public static let toolbarLeading: CGFloat = 16
    public static let toolbarTrailing: CGFloat = 24
    public static let toolbarButton: CGFloat = 24
    public static let tabGap: CGFloat = 16
    public static let tabCountGap: CGFloat = 5
    public static let tabUnderline: CGFloat = 2
    public static let bodyTop: CGFloat = 14
    public static let gutter: CGFloat = 24
    public static let sectionGap: CGFloat = 16
    public static let sectionCaptionHeight: CGFloat = 20
    public static let sectionCaptionBelow: CGFloat = 6
    public static let listRadius: CGFloat = 8
    public static let toolRow: CGFloat = 36
    public static let toolRowPadding: CGFloat = 12
    public static let toolRowGap: CGFloat = 12
    public static let toolIcon: CGFloat = 20
    public static let toolNameWidth: CGFloat = 124
    public static let starSlot: CGFloat = 16
    public static let switchSize = CGSize(width: 26, height: 16)
    public static let knob: CGFloat = 12

    // Menu panel
    public static let panelWidth: CGFloat = 356
    public static let panelRadius: CGFloat = 8
    public static let panelBodyTop: CGFloat = 6
    public static let panelBodyInset: CGFloat = 9
    public static let panelBodyBottom: CGFloat = 12
    public static let panelBlockGap: CGFloat = 12
    public static let panelHeader: CGFloat = 24
    public static let panelRowInset: CGFloat = 10
    public static let bentoGap: CGFloat = 8
    public static let tileRadius: CGFloat = 6
    public static let tilePadding: CGFloat = 10
    public static let tile: CGFloat = 86
    public static let tallTile: CGFloat = 146
    public static let shortTile: CGFloat = 56
    public static let chart: CGFloat = 30
    public static let tallChart: CGFloat = 68
    public static let usageBar: CGFloat = 5
    public static let usageRowBottom: CGFloat = 12
    public static let controlRow: CGFloat = 32
    public static let processRow: CGFloat = 30
    public static let processIcon: CGFloat = 16
    public static let cpuColumn: CGFloat = 40
    public static let memoryColumn: CGFloat = 52
    public static let rowGap: CGFloat = 8
    public static let segment = CGSize(width: 40, height: 18)
    public static let actionBar: CGFloat = 28
    public static let footer: CGFloat = 44
    public static let footerInset: CGFloat = 9
    public static let iconTab: CGFloat = 26
    public static let iconButton: CGFloat = 28
    public static let button: CGFloat = 28
}

extension View {
    func linearText(_ size: CGFloat = OnePlusLinearMetrics.body, weight: Font.Weight = .regular, color: Color = OnePlusLinearColor.ink) -> some View {
        font(.system(size: size, weight: weight)).tracking(size == OnePlusLinearMetrics.body ? OnePlusLinearMetrics.bodyTracking : 0)
            .foregroundStyle(color).monospacedDigit()
    }

    /// A 1 pt ring outside the shape's edge, like CSS `box-shadow: 0 0 0 1px`.
    func linearOuterRing(_ color: Color, radius: CGFloat) -> some View {
        overlay { RoundedRectangle(cornerRadius: radius + 0.5).stroke(color, lineWidth: 1).padding(-0.5).allowsHitTesting(false) }
    }

    /// The raised button chrome: 0.5 pt ring, light drop shadow, dark outer halo.
    func linearRaised(radius: CGFloat, fill: Color = OnePlusLinearColor.button) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius).fill(fill)
                .shadow(color: OnePlusLinearColor.buttonDrop, radius: 1, y: 1)
                .overlay { RoundedRectangle(cornerRadius: radius + 0.5).stroke(OnePlusLinearColor.buttonHalo, lineWidth: 1).padding(-0.5) }
                .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(OnePlusLinearColor.buttonRing, lineWidth: 0.5) }
        }
    }

    /// Selected segment or tab chrome.
    func linearSegmentSelected(_ selected: Bool, radius: CGFloat) -> some View {
        background {
            if selected {
                RoundedRectangle(cornerRadius: radius).fill(OnePlusLinearColor.segmentSelected)
                    .shadow(color: OnePlusLinearColor.segmentShadow, radius: 1, y: 1)
                    .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(OnePlusLinearColor.segmentRing, lineWidth: 0.5) }
            }
        }
    }

    /// The quiet track that holds a segmented control or icon tab group.
    func linearTrack(radius: CGFloat) -> some View {
        padding(2)
            .background(OnePlusLinearColor.track, in: RoundedRectangle(cornerRadius: radius))
            .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(OnePlusLinearColor.lineSoft, lineWidth: 1) }
    }
}
