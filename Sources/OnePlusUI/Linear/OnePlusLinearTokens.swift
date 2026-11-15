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

    // Applets ("Filled groups"). Translucent values are measured on the group or window they sit on.
    public static let appletWindow = color("appletWindow", light: 0xFDFDFD, dark: 0x1A1A1D)
    public static let appletGroup = color("appletGroup", light: 0xF5F5F6, dark: 0x28282B)
    public static let appletLine = color("appletLine", light: 0x000000, lightAlpha: 0.05, dark: 0xFFFFFF, darkAlpha: 0.08)
    public static let appletField = color("appletField", light: 0xFFFFFF, dark: 0x28282C)
    public static let appletFieldLine = color("appletFieldLine", light: 0x000000, lightAlpha: 0.07, dark: 0xFFFFFF, darkAlpha: 0.10)
    // Applet controls, "Depth" (docs/design/v15/controls-depth.html): recessed tracks, raised caps, a fine top edge.
    /// A recessed track, field, or well: the fill, its inner top shade (0 1 2), its 0.5 pt inner ring, and the
    /// 1 pt lip of light below it.
    public static let depthRecess = color("depthRecess", light: 0xE7E7EA, dark: 0x0E0E10)
    public static let depthRecessShade = color("depthRecessShade", light: 0x000000, lightAlpha: 0.20, dark: 0x000000, darkAlpha: 0.70)
    public static let depthRecessRing = color("depthRecessRing", light: 0x000000, lightAlpha: 0.12, dark: 0xFFFFFF, darkAlpha: 0.05)
    public static let depthRecessLip = color("depthRecessLip", light: 0xFFFFFF, lightAlpha: 0.90, dark: 0xFFFFFF, darkAlpha: 0.06)
    /// A raised knob, thumb, or stepper cap: a top-to-bottom gradient, a 0.5 pt outer ring, a near (0 1 2) and a far
    /// (0 2 6) shadow, and a 1 pt highlight on its top edge. Hover deepens the ring and shadows only.
    public static let depthCapTop = color("depthCapTop", light: 0xFFFFFF, dark: 0x606067)
    public static let depthCapBottom = color("depthCapBottom", light: 0xEFEFF2, dark: 0x46464C)
    public static let depthCapPressedTop = color("depthCapPressedTop", light: 0xF2F2F4, dark: 0x55555C)
    public static let depthCapPressedBottom = color("depthCapPressedBottom", light: 0xE6E6EA, dark: 0x3E3E44)
    public static let depthCapRing = color("depthCapRing", light: 0x000000, lightAlpha: 0.20, dark: 0x000000, darkAlpha: 0.70)
    public static let depthCapShadow = color("depthCapShadow", light: 0x000000, lightAlpha: 0.16, dark: 0x000000, darkAlpha: 0.55)
    public static let depthCapGlow = color("depthCapGlow", light: 0x000000, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.35)
    public static let depthCapHighlight = color("depthCapHighlight", light: 0xFFFFFF, dark: 0xFFFFFF, darkAlpha: 0.24)
    public static let depthCapHoverRing = color("depthCapHoverRing", light: 0x000000, lightAlpha: 0.28, dark: 0x000000, darkAlpha: 0.70)
    public static let depthCapHoverShadow = color("depthCapHoverShadow", light: 0x000000, lightAlpha: 0.20, dark: 0x000000, darkAlpha: 0.60)
    public static let depthCapHoverGlow = color("depthCapHoverGlow", light: 0x000000, lightAlpha: 0.10, dark: 0x000000, darkAlpha: 0.45)
    public static let depthCapHoverHighlight = color("depthCapHoverHighlight", light: 0xFFFFFF, dark: 0xFFFFFF, darkAlpha: 0.32)
    /// The "rod": the switch's on track and a slider's filled part, with its own top highlight.
    public static let depthRodTop = color("depthRodTop", light: 0x45464D, dark: 0xF4F4F6)
    public static let depthRodBottom = color("depthRodBottom", light: 0x1C1D22, dark: 0xC9C9CE)
    public static let depthRodHighlight = color("depthRodHighlight", light: 0xFFFFFF, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.60)
    /// The inner ring of a color-well swatch.
    public static let depthSwatchRing = color("depthSwatchRing", light: 0x000000, lightAlpha: 0.20, dark: 0x000000, darkAlpha: 0.20)
    /// The primary "soft gray fill" button. Never the white or black fill.
    public static let softButton = color("softButton", light: 0xEBEBED, dark: 0x2C2C30)
    public static let softButtonHover = color("softButtonHover", light: 0xE2E2E5, dark: 0x34343A)
    public static let softButtonPressed = color("softButtonPressed", light: 0xD8D8DC, dark: 0x3C3C42)
    /// The full-width "red tint" destructive button: red at 10 percent (light) and 18 percent (dark), as rendered.
    public static let destructiveFill = color("destructiveFill", light: 0xE0493E, lightAlpha: 0.10, dark: 0xFF6B5E, darkAlpha: 0.18)
    public static let destructiveHover = color("destructiveHover", light: 0xE0493E, lightAlpha: 0.14, dark: 0xFF6B5E, darkAlpha: 0.23)
    public static let destructivePressed = color("destructivePressed", light: 0xE0493E, lightAlpha: 0.18, dark: 0xFF6B5E, darkAlpha: 0.28)
    /// Dark uses the rendered mockup value; the DESIGN.md `#FFA8A0` stays below APCA Lc 60 on the tint.
    public static let destructiveText = color("destructiveText", light: 0xB02D24, dark: 0xFFB8AF)
    /// Applet text on the lighter dark group fill: the mockup values, which keep Lc 60 and Lc 45 there.
    public static let appletSecondary = color("appletSecondary", light: 0x68686F, dark: 0xC1C1C7)
    public static let appletMuted = color("appletMuted", light: 0x82828A, dark: 0xAAABB2)
    /// The warning banner: an amber tint fill and its glyph. Banner text stays `ink`.
    public static let warningFill = color("warningFill", light: 0xE89B0C, lightAlpha: 0.14, dark: 0xF0B040, darkAlpha: 0.16)
    public static let warning = color("warning", light: 0xA86500, dark: 0xF2BC55)

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

    // Applets: traffic lights, title, and actions center on y 22 of a 48 pt title area.
    public static let appletTitlebar: CGFloat = 48
    public static let appletCenterline: CGFloat = 22
    public static let appletTitlebarTrailing: CGFloat = 13
    public static let appletActionGap: CGFloat = 8
    public static let appletGutter: CGFloat = 16
    public static let appletCaption: CGFloat = 12
    public static let appletCaptionHeight: CGFloat = 16
    public static let appletCaptionBelow: CGFloat = 6
    public static let appletSectionGap: CGFloat = 16
    public static let appletFooterGap: CGFloat = 20
    public static let appletBottom: CGFloat = 16
    public static let appletGroupRadius: CGFloat = 10
    public static let appletRow: CGFloat = 36
    public static let appletRowPadding: CGFloat = 12
    public static let appletRowGap: CGFloat = 10
    public static let appletTabStrip: CGFloat = 32
    public static let appletToolbarGap: CGFloat = 12
    public static let appletField: CGFloat = 26
    public static let appletButton: CGFloat = 24
    public static let appletDestructive: CGFloat = 30
    public static let appletDestructiveRadius: CGFloat = 8
    public static let appletSwatch: CGFloat = 20
    public static let appletRowAction: CGFloat = 24
    public static let appletRowActionsGap: CGFloat = 14
    public static let appletRowActionsTrailing: CGFloat = 6
}

extension View {
    /// The Linear text role: system font at `size` (13 pt body by default), body tracking, the color, tabular digits.
    public func linearText(_ size: CGFloat = OnePlusLinearMetrics.body, weight: Font.Weight = .regular, color: Color = OnePlusLinearColor.ink) -> some View {
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
