import AppKit
import SwiftUI

/// DESIGN.md v15 ("Linear style"). Values come from the mockups in
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
    public static let window = color("window", light: 0xF3F3F5, dark: 0x141416)
    public static let sidebar = color("sidebar", light: 0xEBEBED, dark: 0x101012)
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

    // Menu panel "Fill steps": no lines; parts separate by a step in fill and by spacing.
    public static let fillShell = color("fillShell", light: 0xF0F0F2, dark: 0x151517)
    /// Tiles, lists, and action buttons.
    public static let fillGroup = color("fillGroup", light: 0xFFFFFF, dark: 0x1F1F22)
    public static let fillRowHover = color("fillRowHover", light: 0xF0F0F2, dark: 0x2A2A2E)
    public static let fillTrack = color("fillTrack", light: 0xEBEBEE, dark: 0x2A2A2E)
    public static let fillThumb = color("fillThumb", light: 0xFFFFFF, dark: 0x48484E)
    public static let fillButtonHover = color("fillButtonHover", light: 0xE4E4E8, dark: 0x2C2C30)
    public static let fillButtonPressed = color("fillButtonPressed", light: 0xDADADF, dark: 0x34343A)
    /// A segment on the `fillTrack` well under the pointer: a clear step (about 1.2:1 Light, 1.3:1 Dark against the
    /// well), darker in Light and lighter in Dark; pressed is one step back toward the well.
    public static let fillSegmentHover = color("fillSegmentHover", light: 0xD6D6DB, dark: 0x3C3C42)
    public static let fillSegmentPressed = color("fillSegmentPressed", light: 0xCDCDD2, dark: 0x343439)
    /// Bento "Floating tiles with wash": one soft drop and a contact shade under all tiles.
    public static let fillTileShadow = color("fillTileShadow", light: 0x000000, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.5)
    public static let fillTileContact = color("fillTileContact", light: 0x000000, lightAlpha: 0.06, dark: 0x000000, darkAlpha: 0.35)
    /// The data-color wash at a tile's top: tint at this opacity, fading to clear at 75% of the tile height.
    public static let fillTileWashOpacity = (light: 0.09, dark: 0.16)

    // Panel tabs "Soft keys": a sunken track and a raised key for the selected tab.
    // Top and Bottom are the vertical gradient ends; Edge is the 1 pt border gradient.
    // Dark (round 8, "Quieter key, fainter dividers"): a deep track with a lit bottom lip and a quieter key.
    public static let softKeyTrackTop = color("softKeyTrackTop", light: 0xDADADE, dark: 0x050506)
    public static let softKeyTrackBottom = color("softKeyTrackBottom", light: 0xE6E6EA, dark: 0x09090A)
    public static let softKeyTrackEdgeTop = color("softKeyTrackEdgeTop", light: 0x000000, lightAlpha: 0.06, dark: 0x000000, darkAlpha: 0.7)
    public static let softKeyTrackEdgeBottom = color("softKeyTrackEdgeBottom", light: 0xFFFFFF, lightAlpha: 0.9, dark: 0xFFFFFF, darkAlpha: 0.12)
    public static let softKeyTrackShade = color("softKeyTrackShade", light: 0x000000, lightAlpha: 0.2, dark: 0x000000, darkAlpha: 0.9)
    /// The track's inner shade: radius and y offset per appearance.
    public static let softKeyTrackShadeGeometry = (light: (radius: 2.0, y: 1.0), dark: (radius: 2.5, y: 1.5))
    /// Badge wells (Portman port badge "Sunken well"): a lighter, shallower soft-key track,
    /// so every Portman port ink keeps 4.5:1 on both gradient ends. It reuses the track's edge gradient.
    public static let badgeWellTop = color("badgeWellTop", light: 0xEBEBEE, dark: 0x111113)
    public static let badgeWellBottom = color("badgeWellBottom", light: 0xF0F0F3, dark: 0x161618)
    public static let badgeWellShade = color("badgeWellShade", light: 0x000000, lightAlpha: 0.12, dark: 0x000000, darkAlpha: 0.6)
    /// An inset tile inside a group, such as a Portman host's stat tile.
    public static let insetTile = color("insetTile", light: 0xF4F4F6, dark: 0x27272B)
    public static let softKeyTop = color("softKeyTop", light: 0xFFFFFF, dark: 0x313136)
    public static let softKeyBottom = color("softKeyBottom", light: 0xEEEEF1, dark: 0x28282C)
    public static let softKeyEdgeTop = color("softKeyEdgeTop", light: 0xFFFFFF, dark: 0xFFFFFF, darkAlpha: 0.08)
    public static let softKeyEdgeBottom = color("softKeyEdgeBottom", light: 0x000000, lightAlpha: 0.15, dark: 0xFFFFFF, darkAlpha: 0)
    public static let softKeyShadow = color("softKeyShadow", light: 0x000000, lightAlpha: 0.2, dark: 0x000000, darkAlpha: 0.55)
    /// A raised text button's lit edge and drop: the soft key's in Light; none in Dark, like the menu panel's row keys.
    public static let buttonKeyEdgeTop = color("buttonKeyEdgeTop", light: 0xFFFFFF, dark: 0xFFFFFF, darkAlpha: 0)
    public static let buttonKeyShadow = color("buttonKeyShadow", light: 0x000000, lightAlpha: 0.2, dark: 0x000000, darkAlpha: 0)
    /// Main-window controls in Light (`.raisedKeys`): a flat fill and one hairline, no gradient, edge, or shadow.
    /// Dark keeps the soft-key gradients; the menu panel keeps `softKey*` in both appearances.
    public static let flatKey = color("flatKey", light: 0xF6F6F7, dark: 0x313136)
    public static let flatThumb = color("flatThumb", light: 0xFFFFFF, dark: 0x313136)
    public static let flatWell = color("flatWell", light: 0xEEEEF1, dark: 0x1B1B1E)
    public static let flatLine = color("flatLine", light: 0x000000, lightAlpha: 0.10, dark: 0xFFFFFF, darkAlpha: 0.10)
    public static let softKeyInk = color("softKeyInk", light: 0x1B1B1F, dark: 0xC4C4CA)
    public static let softKeyTrackInk = color("softKeyTrackInk", light: 0x55555C, dark: 0x9A9AA1)
    /// 1 pt line between two unselected tabs, fading out at both ends. Dark only.
    public static let softKeyDivider = color("softKeyDivider", light: 0xFFFFFF, lightAlpha: 0, dark: 0xFFFFFF, darkAlpha: 0.12)

    // Panel open key ("Ink key"): a 26 pt key, dark ink in Light and light ink in Dark, with a lit top edge and a short drop.
    public static let openKeyTop = color("openKeyTop", light: 0x34343A, dark: 0xEDEDEF)
    public static let openKeyBottom = color("openKeyBottom", light: 0x1C1D22, dark: 0xD2D2D7)
    public static let openKeyInk = color("openKeyInk", light: 0xFFFFFF, dark: 0x141416)
    public static let openKeyEdgeTop = color("openKeyEdgeTop", light: 0xFFFFFF, lightAlpha: 0.16, dark: 0xFFFFFF, darkAlpha: 0.6)
    public static let openKeyEdgeBottom = color("openKeyEdgeBottom", light: 0x000000, lightAlpha: 0.25, dark: 0x000000, darkAlpha: 0.15)
    public static let openKeyShadow = color("openKeyShadow", light: 0x000000, lightAlpha: 0.18, dark: 0x000000, darkAlpha: 0.5)
    /// One surface step toward the middle gray: lighter on the dark Light key, darker on the light Dark key.
    public static let openKeyHover = color("openKeyHover", light: 0xFFFFFF, lightAlpha: 0.07, dark: 0x000000, darkAlpha: 0.05)
    public static let openKeyPressed = color("openKeyPressed", light: 0xFFFFFF, lightAlpha: 0.12, dark: 0x000000, darkAlpha: 0.1)

    // Panel action buttons: Light soft keys with regular labels (round 8); Dark keeps the flat group fill.
    public static let actionKeyTop = color("actionKeyTop", light: 0xFFFFFF, dark: 0x1F1F22)
    public static let actionKeyBottom = color("actionKeyBottom", light: 0xEEEEF1, dark: 0x1F1F22)
    public static let actionKeyHoverTop = color("actionKeyHoverTop", light: 0xF7F7F9, dark: 0x2C2C30)
    public static let actionKeyHoverBottom = color("actionKeyHoverBottom", light: 0xE6E6EA, dark: 0x2C2C30)
    /// Light keys: one even hairline edge and no shadow.
    public static let actionKeyEdgeTop = color("actionKeyEdgeTop", light: 0x000000, lightAlpha: 0.12, dark: 0xFFFFFF, darkAlpha: 0)
    public static let actionKeyEdgeBottom = color("actionKeyEdgeBottom", light: 0x000000, lightAlpha: 0.12, dark: 0x000000, darkAlpha: 0)
    public static let actionKeyShadow = color("actionKeyShadow", light: 0x000000, lightAlpha: 0, dark: 0x000000, darkAlpha: 0)
    /// Hover never moves a key. Light shows a soft drop; Dark, where a drop does not show, a faint light rim.
    public static let actionKeyHoverShadow = color("actionKeyHoverShadow", light: 0x000000, lightAlpha: 0.12, dark: 0x000000, darkAlpha: 0)
    public static let actionKeyHoverRim = color("actionKeyHoverRim", light: 0xFFFFFF, lightAlpha: 0, dark: 0xFFFFFF, darkAlpha: 0.10)
    public static let actionKeyLabelWeight = (light: Font.Weight.regular, dark: Font.Weight.medium)

    // Lines
    public static let line = color("line", light: 0x000000, lightAlpha: 0.065, dark: 0xFFFFFF, darkAlpha: 0.075)
    /// The menu panel's rings and dividers: the panel keeps its own line when the main window's changes.
    public static let panelLine = color("panelLine", light: 0x000000, lightAlpha: 0.085, dark: 0xFFFFFF, darkAlpha: 0.075)
    public static let lineSoft = color("lineSoft", light: 0x000000, lightAlpha: 0.06, dark: 0xFFFFFF, darkAlpha: 0.055)
    public static let lineStrong = color("lineStrong", light: 0x000000, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.12)
    public static let barTrack = color("barTrack", light: 0x000000, lightAlpha: 0.075, dark: 0xFFFFFF, darkAlpha: 0.085)
    /// The light band that sweeps over loading placeholder bars.
    public static let placeholderSheen = color("placeholderSheen", light: 0xFFFFFF, lightAlpha: 0.75, dark: 0xFFFFFF, darkAlpha: 0.08)
    public static let iconOutline = color("iconOutline", light: 0x000000, lightAlpha: 0.1, dark: 0xFFFFFF, darkAlpha: 0.1)

    // Text (APCA: labels Lc 60, captions Lc 45 on every v15 surface)
    public static let ink = color("ink", light: 0x1B1B1F, dark: 0xEDEDEF)
    public static let secondary = color("secondary", light: 0x55555C, dark: 0xB4B4BA)
    public static let muted = color("muted", light: 0x7A7A82, dark: 0x9999A1)
    public static let panelMuted = color("panelMuted", light: 0x6E6E76, dark: 0x9999A1)
    /// Glyphs only (chevrons), never text.
    public static let tertiary = color("tertiary", light: 0x9A9AA2, dark: 0x66666E)
    public static let accent = color("accent", light: 0xD94F45, dark: 0xEE5B50)

    // CPU temperature steps (DESIGN.md "CPU temperature"). Normal temperatures use `panelMuted`, except on a heat
    // scale such as the Fan chart's line, which starts at `temperatureCool`.
    public static let temperatureCool = color("temperatureCool", light: 0x008CBF, dark: 0x63D1FF)
    public static let temperatureWarm = color("temperatureWarm", light: 0xA67C00, dark: 0xF2C94C)
    public static let temperatureHot = color("temperatureHot", light: 0xCC610C, dark: 0xF59A4A)
    public static let temperatureVeryHot = color("temperatureVeryHot", light: 0xD03A2C, dark: 0xFF7466)
    public static let temperatureCritical = color("temperatureCritical", light: 0x9A1717, dark: 0xFF3B30)

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
    // Applet controls, "Quiet Raised" (showcase ControlStyleOptions.swift). The "on" fill is `accent`.
    /// A sunken switch, slider, or segment track: the fill, a soft 1 pt inner top shade, and a 1 px inner line.
    public static let quietTrack = color("quietTrack", light: 0xE7E7EA, dark: 0x111113)
    public static let quietTrackLine = color("quietTrackLine", light: 0x000000, lightAlpha: 0.07, dark: 0xFFFFFF, darkAlpha: 0.07)
    public static let quietTrackShade = color("quietTrackShade", light: 0x000000, lightAlpha: 0.05, dark: 0x000000, darkAlpha: 0.50)
    /// A field: the stepper, color well, search, select, and text field.
    public static let quietField = color("quietField", light: 0xFFFFFF, dark: 0x1E1E21)
    public static let quietFieldLine = color("quietFieldLine", light: 0x000000, lightAlpha: 0.09, dark: 0xFFFFFF, darkAlpha: 0.07)
    /// A knob: one solid part with a 1 px line and one soft contact shadow. Press darkens it one step.
    public static let quietKnob = color("quietKnob", light: 0xFFFFFF, dark: 0xE4E4E8)
    public static let quietKnobOn = color("quietKnobOn", light: 0xFFFFFF, dark: 0xF2F2F4)
    public static let quietKnobPressed = color("quietKnobPressed", light: 0xF0F0F2, dark: 0xD2D2D7)
    public static let quietKnobLine = color("quietKnobLine", light: 0x000000, lightAlpha: 0.06, dark: 0x000000, darkAlpha: 0.30)
    public static let quietKnobShadow = color("quietKnobShadow", light: 0x000000, lightAlpha: 0.16, dark: 0x000000, darkAlpha: 0.45)
    /// The selected segment thumb, with the knob shadow.
    public static let quietThumb = color("quietThumb", light: 0xFFFFFF, dark: 0x45454C)
    public static let quietThumbPressed = color("quietThumbPressed", light: 0xF0F0F2, dark: 0x3C3C42)
    public static let quietThumbLine = color("quietThumbLine", light: 0x000000, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.35)
    /// The faded divider between unselected segments.
    public static let quietDivider = color("quietDivider", light: 0x000000, lightAlpha: 0.30, dark: 0xFFFFFF, darkAlpha: 0.26)
    /// The inner line of a color-well swatch.
    public static let quietSwatchLine = color("quietSwatchLine", light: 0x000000, lightAlpha: 0.10, dark: 0x000000, darkAlpha: 0.25)
    /// The primary "soft gray fill" button. Never the white or black fill.
    public static let softButton = color("softButton", light: 0xEBEBED, dark: 0x2C2C30)
    public static let softButtonHover = color("softButtonHover", light: 0xE2E2E5, dark: 0x34343A)
    public static let softButtonPressed = color("softButtonPressed", light: 0xD8D8DC, dark: 0x3C3C42)
    /// The destructive action: plain red text with no fill and no border, on the applet window. Dark is raised from
    /// the reference `#FF8A80` to keep APCA Lc 60 there. Press moves the text one step away from the window.
    public static let destructiveText = color("destructiveText", light: 0xC4342B, dark: 0xFF9A91)
    public static let destructivePressedText = color("destructivePressedText", light: 0x9E2A22, dark: 0xFFB8B1)
    /// Applet text on the lighter dark group fill: the mockup values, which keep Lc 60 and Lc 45 there.
    public static let appletSecondary = color("appletSecondary", light: 0x68686F, dark: 0xC1C1C7)
    public static let appletMuted = color("appletMuted", light: 0x82828A, dark: 0xAAABB2)
    /// The warning banner (macOS 15 notice look, owner pick 2026-11-26): a light gray fill, a thin gray line, and
    /// the yellow multicolor triangle. Banner text stays `ink` and `appletSecondary`.
    public static let warningFill = color("warningFill", light: 0xF7F7F7, dark: 0x2A2A2A)
    public static let warningLine = color("warningLine", light: 0x000000, lightAlpha: 0.07, dark: 0xFFFFFF, darkAlpha: 0.07)
    /// Warning state as text or a chart color, such as "Retrying". Not used by the banner.
    public static let warning = color("warning", light: 0xA86500, dark: 0xF2BC55)
    /// A native macOS push button (`.push`): gray in Dark with a thin line and a soft drop shadow. In Light it is
    /// flat: the white fill and the 1 pt `flatLine`, no shadow (the prominent key has no line).
    public static let pushButton = color("pushButton", light: 0xFFFFFF, dark: 0x5F5F62)
    public static let pushButtonLine = color("pushButtonLine", light: 0x000000, lightAlpha: 0.14, dark: 0xFFFFFF, darkAlpha: 0.10)
    public static let pushButtonShadow = color("pushButtonShadow", light: 0x000000, lightAlpha: 0.14, dark: 0x000000, darkAlpha: 0.35)
    /// The default push button (`.pushProminent`): system blue with white text.
    public static let pushProminent = color("pushProminent", light: 0x007AFF, dark: 0x0A84FF)
    public static let pushProminentLine = color("pushProminentLine", light: 0x000000, lightAlpha: 0, dark: 0xFFFFFF, darkAlpha: 0.12)
    public static let pushProminentInk = color("pushProminentInk", light: 0xFFFFFF, dark: 0xFFFFFF)
    /// The error banner: a red tint fill. Its glyph and text use `destructiveText`.
    public static let destructiveFill = color("destructiveFill", light: 0xD64035, lightAlpha: 0.10, dark: 0xFF6F64, darkAlpha: 0.14)
    /// A finished state as text, such as "Completed". Keeps Lc 60 on the window and the group fill.
    public static let success = color("success", light: 0x237A40, dark: 0x6CCB8C)

    // Data
    public static let cpu = color("cpu", light: 0x2A7DE1, dark: 0x4C8FE6)
    /// CPU numbers as text. Dark is lighter than the chart line to reach Lc 60.
    public static let cpuText = color("cpuText", light: 0x2A7DE1, dark: 0x8DB8EF)
    /// The paid tier on an About window: `cpuText`, one step darker in Light to keep Lc 60 on the gray window.
    public static let upgradeText = color("upgradeText", light: 0x1F6FD1, dark: 0x8DB8EF)
    public static let gpu = color("gpu", light: 0x8A63D2, dark: 0x9A88D2)
    public static let memory = color("memory", light: 0xD2508F, dark: 0xC97FA4)
    public static let disk = color("disk", light: 0x5A64D8, dark: 0x8890E0)
    public static let battery = color("battery", light: 0x2AA855, dark: 0x4FBE76)
    public static let networkDown = color("networkDown", light: 0x1A9FB0, dark: 0x45B8C4)
    public static let networkUp = color("networkUp", light: 0xE07F2A, dark: 0xD9925A)
    /// Area fill under a history line: series color at this opacity.
    public static let chartFillOpacity = (light: 0.09, dark: 0.10)
    /// Instrument chart: series color at this opacity under the line's peak, fading to clear at the bottom.
    public static let chartFadeOpacity = (light: 0.16, dark: 0.20)
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
    /// Dark only: a key well's 1 pt lit bottom lip reads as outside the hole, so its text and glyphs center 0.5 pt
    /// higher. Light's flat well has no lip, so its text sits on the true center.
    public static let keyWellContentLift: CGFloat = 0.5
    /// A native macOS push button: 22 pt tall, 11 pt side padding, radius 5, 0.5 pt line, 8 pt between keys.
    public static let pushButton: CGFloat = 22
    public static let pushButtonPadding: CGFloat = 11
    public static let pushButtonRadius: CGFloat = 5
    public static let pushButtonLine: CGFloat = 0.5
    public static let pushButtonGap: CGFloat = 8

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
    /// Each tab pads its label and count by this much, so the underline runs past both ends of the text.
    public static let tabPadding: CGFloat = 8
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
    public static let panelBodyTopUnderToolbar: CGFloat = 12
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
    /// The inset stat tile (Portman host card): tile height, chart height, radius, and padding.
    public static let insetTile: CGFloat = 66
    public static let insetTileChart: CGFloat = 26
    public static let insetTileRadius: CGFloat = 8
    public static let insetTilePadding = CGSize(width: 8, height: 7)
    /// A long tile reading such as "↑ 289 KB/s" shrinks this far before it truncates.
    public static let insetTileMetaScale: CGFloat = 0.8
    /// A badge (a port number in a sunken well): height, side padding, and radius.
    public static let badge: CGFloat = 18
    public static let badgePadding: CGFloat = 5
    public static let badgeRadius: CGFloat = 5
    /// A host icon: the outlined 16 pt box with a 10 pt glyph and a 7 pt status dot on a 1.5 pt ring.
    public static let hostIcon: CGFloat = 16
    public static let hostIconRadius: CGFloat = 4
    public static let hostIconGlyph: CGFloat = 10
    public static let hostIconDot: CGFloat = 7
    public static let hostIconDotRing: CGFloat = 1.5
    public static let hostIconDotOutset: CGFloat = 3
    /// A tree card's guide line: its x from the card edge and the tick to each child row.
    public static let guideLine: CGFloat = 18
    public static let guideTick: CGFloat = 10
    public static let treeChildInset: CGFloat = 34
    public static let treeChildRow: CGFloat = 32
    public static let tallChart: CGFloat = 68
    /// Instrument bento: value size, the newest-point dot radius, and the left-edge fade width of a chart.
    public static let instrumentValue: CGFloat = 26
    public static let chartDot: CGFloat = 2.5
    public static let chartEdgeFade: CGFloat = 16
    public static let usageBar: CGFloat = 5
    public static let usageRowBottom: CGFloat = 12
    public static let controlRow: CGFloat = 32
    /// A panel row with a second line (a transfer, a remote): name over a caption.
    public static let panelTwoLineRow: CGFloat = 40
    /// A disclosure row's accessory slot and the compact panel key height (`OnePlusLinearKeyButtonStyle`).
    public static let panelAccessory: CGFloat = 22
    public static let panelKey: CGFloat = 24
    public static let processRow: CGFloat = 30
    public static let processIcon: CGFloat = 16
    public static let cpuColumn: CGFloat = 40
    /// Fits `1,023.7 MB`, the widest memory string, at the 12 pt process text.
    public static let memoryColumn: CGFloat = 68
    public static let rowGap: CGFloat = 8
    /// A status glyph beside a row's control (the Fan row thermometer): 10 pt regular, `rowGap` before the control.
    public static let rowStatusGlyph: CGFloat = 10
    public static let segment = CGSize(width: 40, height: 18)
    public static let actionBar: CGFloat = 28
    public static let actionDivider: CGFloat = 14
    public static let footer: CGFloat = 44
    public static let footerInset: CGFloat = 9
    public static let iconTab: CGFloat = 26
    public static let iconButton: CGFloat = 28
    public static let button: CGFloat = 28
    /// Cap height of the 12 pt medium control text, for centering a label on its capitals.
    public static let controlCapHeight = NSFont.systemFont(ofSize: control, weight: .medium).capHeight

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
    /// The plain red text action: one 13 pt line.
    public static let appletDestructive: CGFloat = 16
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

    /// Selected tab chrome. It appears on the new tab at once; it never slides.
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

/// About surfaces (DESIGN.md "About"): Settings > About hero, and the free, Pro, and Classic About windows.
public enum OnePlusAboutMetrics {
    public struct Shadow: Sendable {
        public let opacity: Double; public let radius: CGFloat; public let y: CGFloat
        /// Light mode opacity when it differs: a dark shadow on a light window reads too heavy.
        public var lightOpacity: Double? = nil
    }

    public static let freeWindow = CGSize(width: 380, height: 410)
    public static let proWindow = CGSize(width: 420, height: 560)
    public static let classicWindow = CGSize(width: 440, height: 580)

    public static let heroTop: CGFloat = 10
    public static let heroIcon: CGFloat = 84
    public static let heroIconShadow = Shadow(opacity: 0.18, radius: 8, y: 4)
    public static let heroTitle: CGFloat = 20
    public static let heroTitleTop: CGFloat = 10
    public static let taglineTop: CGFloat = 3
    public static let versionTop: CGFloat = 6
    public static let buttonsTop: CGFloat = 14
    public static let linkArrow: CGFloat = 9
    public static let linkArrowGap: CGFloat = 4

    public static let windowIcon: CGFloat = 104
    public static let windowIconShadow = Shadow(opacity: 0.25, radius: 14, y: 7, lightOpacity: 0.15)
    public static let noShadow = Shadow(opacity: 0, radius: 0, y: 0)
    public static let windowTitle: CGFloat = 21
    public static let windowButtonTop: CGFloat = 20
    public static let footerBottom: CGFloat = 18
    public static let footerGap: CGFloat = 6
    public static let updateGlyphGap: CGFloat = 5

    /// The color field: a blurred copy of the icon plus two icon tints, faded out toward the name.
    public static let fieldHeight: CGFloat = 230
    public static let fieldBlurIcon: CGFloat = 460
    public static let fieldBlur: CGFloat = 60
    public static let fieldIconOpacity = (light: 0.3, dark: 0.45)
    public static let fieldTintOpacity = (first: 0.4, second: 0.3)
    public static let fieldTintRadius = (first: CGFloat(260), second: CGFloat(240))
    /// The glow breathes between these tint opacities, `glowBreath` seconds each way.
    public static let glow: CGFloat = 200
    public static let glowOpacity = (min: 0.35, max: 0.55)
    public static let glowBreath: Double = 2.4

    public static let proHeader: CGFloat = 180
    public static let proHeaderTop: CGFloat = 26
    public static let proIcon: CGFloat = 96
    public static let proTitle: CGFloat = 22
    public static let activityHeight: CGFloat = 140
    public static let activityOffset: CGFloat = 16
    public static let activityPeriod: CGFloat = 420
    public static let activityPhase: CGFloat = 0.2
    public static let activityFill: Double = 0.22
    public static let activityStroke: CGFloat = 1.6

    public static let groupRadius: CGFloat = 10
    public static let cardInset: CGFloat = 28
    public static let cardTop: CGFloat = 22
    public static let cardPadding: CGFloat = 14
    public static let cardHeader: CGFloat = 46
    public static let cardRow: CGFloat = 32
    public static let cardGlyphGap: CGFloat = 10
    public static let sealGlyph: CGFloat = 20

    public static let classicHeaderTop: CGFloat = 46
    public static let classicHeaderGap: CGFloat = 14
    public static let classicIcon: CGFloat = 64
    public static let classicTitle: CGFloat = 19
    public static let compareHeadTop: CGFloat = 22
    public static let compareTop: CGFloat = 6
    public static let compareRow: CGFloat = 36
    public static let compareColumn: CGFloat = 56
    public static let compareNoteTop: CGFloat = 12
    public static let upgradeIcon: CGFloat = 34
    public static let footer: CGFloat = 68
    public static let footerPadding: CGFloat = 20
}
