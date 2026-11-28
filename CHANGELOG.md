# Changelog

## 1.9.11

- Equal segments never truncate a label: every segment takes the look's width, or the widest label plus 7 pt a
  side when that is wider (`OnePlusLinearSegmented`, `.equal` sizing). "Custom" in a 36 pt segment showed "Cust…".
  Short labels such as "Off", "On", "mm" keep their 36 and 40 pt segments.

## 1.9.10

- Segmented text is smaller and crisp, like native: 12 pt on a page (was 13), 11 pt in the menu panel (was 11.5),
  regular weight when selected (was medium), no tracking (was -0.08). Labels move onto the optical center in
  whole device pixels (was a 1.25 pt offset, a half pixel at 2x that blurred the glyphs). Date parts match.
- Hover corners are concentric: a middle segment's hover fill uses a 2 pt radius
  (`OnePlusLinearMetrics.segmentHoverRadius`); the first and last segments match the track only on their outer side.
  Covers `OnePlusLinearSegmented`, `OnePlusSegmented`, and the panel icon tabs. Popup menu rows use 5 pt (menu 10
  minus its 5 pt padding, was 6).
- The selection key glides on `OnePlusMotion.glideCurve` (ease-out 0, 0, 0.58, 1, 200 ms): the old curve moved a
  third of the way in the first frame, then crawled. Dividers now draw under the key, so they never flash on top of
  it while it slides. The text tabs underline and the page section rise use the same curve.
- The page section rise and the placeholder push move in whole device pixels, so text does not shimmer while it
  moves on a 1x display.

## 1.9.9

- `OnePlusContextMenu`: a right-click menu with optional pickers on top ("Pickers on top", owner pick 2026-11-28).
  It opens at the click in a non-activating panel, so it never steals focus; arrow keys, Return, and Esc work; it
  closes on a click outside or a pick and stays 4 pt inside the screen. 236 pt min width, 12 pt corners, 24 pt rows,
  a 130 ms scale-in from the click point and a 90 ms fade out. Header parts: `OnePlusContextMenuTile`,
  `OnePlusContextMenuSwatch`, `OnePlusContextMenuSeparator`.
- `OnePlusFloatingToolbar`: a small 30 pt capsule of 26 x 24 buttons, such as a text format pill over a selection.
  It rises 4 pt and scales from 0.96 over 140 ms.

## 1.9.8

- Segmented controls take the "macOS native key" look (owner pick 2026-11-28): segments touch on the track, one
  raised key sits 2 pt inside with a concentric radius (track radius - 2), a 0.5 pt ring and a soft shadow, and a
  short `segmentDivider` line separates unlit segments; it hides beside the key and a hovered segment. Covers
  `OnePlusLinearSegmented` (24 and 28 pt, so `DenseSegmented` too), `OnePlusSegmented` (radius 4), and the menu
  panel icon tabs' dividers.
- The key is one view placed from the selected segment's bounds, so a click or arrow key slides it 200 ms ease-out
  in either direction. A value set from code lands at once; Reduce Motion never slides.
- Hover and press fills no longer draw on top of the selected key.
- New tests: key inset and concentric radius, divider height, and divider hiding beside the key and hover.

## 1.9.7

- Fields, selects, search fields, and steppers are the height of the button beside them in every size step: 28 pt
  on a page (Raised keys), 24 pt in an applet and in the menu panel. `OnePlusLinearMetrics.appletField` is 24.
- Under Raised keys, Dark fields draw the same flat well as Light (`flatWell` with the `flatLine` hairline), not a
  near-black sunken hole, so a field and the soft key beside it read as one family. Text sits on the true center.
- Applet text fields use the select's face (`quietField` with its hairline) instead of the bare track.
- Removed `OnePlusLinearControlLook.quietRaisedActionRow` and `OnePlusLinearMetrics.keyWellContentLift`: every
  applet row is now the same 24 pt, and no well lifts its text.
- New test: a field, select, search, or stepper fails if it is not the button's height in its size step.

## 1.9.6

- The "Pro" tag is drawn from glyph outlines with even space around the letters, a whole-point pill and a 1 pt inset
  border, so its edge no longer shimmers and the text no longer touches the left side (`OnePlusProTag`).
- Inset groups clip their content to the rounded shape, so a full-width band no longer pokes out of the corners.

## 1.9.5

- `OnePlusLinearSelect(prefix:)` puts the setting's name inside the field, dim before the value ("Speed: Normal"),
  so a toolbar needs no separate label beside each select.

## 1.9.4

- `OnePlusKeyWell` is public, so an app's own field (a search field with a clear button) can sit in the same sunken
  key well as the raised-keys fields and selects.

## 1.9.3

- Fix: picking a segment in a `.fitted` or `.snug` `OnePlusLinearSegmented` (and a date field part) moved its
  neighbors, because the label turned medium and grew. New `linearSteadyText(_:selected:color:)` holds the medium
  width with an invisible copy. `OnePlusSteadyTextTests` guards it.

## 1.9.2

- Settings rows follow macOS System Settings (owner pick, 2026-11-28): `OnePlusLinearAppletRow` is 36 pt with one
  line (tool pages were 40). With a second line it has 10 pt above and below (about 52 pt), the detail at 11 pt, and
  the glyph and control sit on the title line, not centered. New `appletRowTwoLinePad` and `appletRowTitleLine`;
  `OnePlusLinearEditorialMetrics.row` is 36.
- Calm feature card (Marketplace Pro): `OnePlusLinearCalmCard`, `OnePlusLinearCalmCardItem`, `OnePlusLinearAddTile`,
  `onePlusShadedTile(_:)`, `onePlusProTag(_:)`, `OnePlusLinearCalmCardMetrics`, and the `proCoral`,
  `proCoralGradient`, and `calmCard*` colors.

## 1.9.1

- Fix: a pointer click on `OnePlusLinearEditorialToolRow` and `OnePlusLinearToolRow` did nothing. The open button's
  clear label had no content shape, so only AXPress and Return reached it. `OnePlusToolRowClickTests` clicks the
  row's text and checks that a clear label without a content shape takes no click.
- "Soft spring" page switch: the old page leaves at once (never two pages on screen) and the new one fades in, while
  `OnePlusLinearEditorialBody` and `OnePlusLinearPaneBody` bring each block in one after another (fade plus a 6 pt
  rise, 180 ms ease-out, 30 ms apart, at most 5 steps). New `springSection*` tokens. Reduce Motion: instant.

## 1.9.0

- Tool page header "Small icon in the name line" (owner pick, 2026-11-27): `OnePlusLinearToolHeader` draws a 28 pt
  icon 10 pt before the 24 pt name in a 32 pt line, then a 15 pt description of at most 3 lines, with or without a
  tile. Replaces the "Big header" and the 48 pt "Icon beside the title".
- "Short tile": `OnePlusLinearLaunchTile` is 148 x 72 with 12 pt padding, `Open` and the arrow over the shortcut
  caps (or the tool name in 15 pt). The caption is now the tooltip and accessibility label, not a visible line.
- New `headerName*`, `headerDetail*` metrics; removed `headerTileIcon`, `launchHeader*`, and `launchTileKey*`.

## 1.8.1

- "Big header" (owner pick, 2026-11-27): `OnePlusLinearToolHeader` with actions (a launch tile) draws a 108 pt icon,
  a 28 pt title, and a 15 pt description of at most 3 lines centered on the icon, the tile's height. Without
  actions it is unchanged. New `launchHeader*` metrics and a sized `icon: (CGFloat) -> Icon` init.
  `OnePlusLinearToolHeaderTests` checks the height, that no 70-character description is cut, and the plain look.

## 1.8.0

- Light main window (owner picks, 2026-11-26): `window` `#F3F3F5`, `sidebar` `#EBEBED`, group `line` 6.5%, so
  white cards stand out on a gray window.
- Light "Hairline only" controls under `.raisedKeys`: push, primary, keys, segments, selects, fields, steppers, and
  toggles are a flat fill plus one 1 pt line. No gradient, edge, or drop shadow. New `flatKey`, `flatThumb`,
  `flatWell`, `flatLine`, and `OnePlusFieldWell`. Dark and the menu panel are unchanged.
- New `panelLine` keeps the panel's rings at their old weight. New `upgradeText` for the About paid tier.
- Field and select text lift 0.5 pt only in Dark; in Light it sat 0.8 pt high. New
  `OnePlusLinearLabelCenteringTests` fails when a push, primary, key, segment, or select label is more than 0.5 pt
  off center.

## 1.7.2

- `onePlusPopover` sizes its window from the content's fitting size before it shows, so the open animation no
  longer ends on a default-sized window with empty space above the content.

## 1.7.1

- Sheet close light starts on the content's left edge (sheet inset), still on the title's centerline.
- Compact sheet footer: 12 pt above and below, push-key gap. New `OnePlusMetrics.sheetFooterGap`.
- Every `onePlusScrollIndicators` scroll inside a sheet fades over 16 pt at an edge with more content past it, and
  the fade leaves at the end of the scroll. Paint only; Reduce Transparency shows a hairline, Reduce Motion no
  animation. New `sheetScrollFade`, `sheetScrollHairline`.

## 1.7.0

- One sheet frame (owner pick, 2026-11-26): `OnePlusSheet` takes the native macOS sheet look: no header bar and no
  lines, a small centered title, and a 14 pt red close light at the window close-light spot (× on hover, Esc
  closes, no focus ring), both on the 22 pt centerline of a 44 pt row. Footer keys sit right with no line.
  The sheet stays within 90% of its window's height; the middle scrolls.
- `OnePlusLinearSheet` is now a thin wrapper: `OnePlusSheet` plus the editorial controls.
- New tokens: `OnePlusMetrics.sheet*`, `OnePlusColor.closeLight`, `closeLightEdge`, `closeLightGlyph`.

## 1.6.0

- Warning banners use the macOS 15 notice look (owner pick, 2026-11-26): `OnePlusLinearBanner(.warning)` and
  `OnePlusBanner` `.warning` get a light gray `warningFill`, a 1 pt `warningLine`, and the yellow multicolor
  triangle, in place of the amber tint. `OnePlusLinearColor.warning` stays for warning text and charts.
- New `OnePlusLinearButtonStyle(.push)` and `(.pushProminent)`: native macOS push keys (22 pt, radius 5), white
  or gray and system blue, for banner actions.

## 1.5.2

- Popup menus open like the menu bar panel (owner, 2026-11-26): a 140 ms fade with a 4 pt move out of the
  trigger, and a 100 ms fade out. A picked row still closes at once. Reduce Motion fades only.
- New `View.onePlusPopover(isPresented:arrowEdge:content:)`: an opaque popover with the same fast open and
  close, in place of SwiftUI's slower system zoom.
- `OnePlusButtonStyle(.link)` has no side padding, so a link lines up with the text around it.

## 1.5.1

- Popups are fully opaque (owner, 2026-11-25): `OnePlusPopupColor.background` drops its transparency, so
  every `OnePlusPopupMenu` panel is solid in Light and Dark.
- New `View.onePlusOpaquePopover()`: put it on the content of a SwiftUI `.popover` and the popover, arrow
  included, gets the same solid fill instead of the see-through system material. The `OnePlusCard` help
  popover uses it.

## 1.5.0

- `OnePlusPopupMenu` (every `OnePlusSelect`, `OnePlusLinearSelect`, `OnePlusMenuButton`, and
  `OnePlusActionMenu`) takes the owner's "Picked row stays filled" look: no checkmark column; the picked row
  keeps a soft fill with medium text, the hover is a fainter fill, and both glide between rows on a 0.28 s
  spring. A pick glides the fill to the new row for 0.14 s before the menu closes (instant under Reduce
  Motion). Panel radius 10, 0.5 pt inset ring, 26 pt rows, 6 pt row radius.
- Menus with more than 10 items show a search field on top. Typed keys filter the list (sections stay with
  their matches), Delete removes a character, and the panel shrinks to the matches.
- No public API change. Removed internal `OnePlusPopupMetrics.checkColumn`.

## 1.4.11

- `OnePlusLinearTreeCardPlaceholder`: a loading stand-in shaped like a tree card (40 pt header over 32 pt child
  rows) with a light sheen sweep every 1.4 s; Reduce Motion shows it still. New `placeholderSheen` color.
- `onePlusPush(trigger:from:)`: a 200 ms list to detail push. The new page is in its final layout at once and
  slides 16 pt in from the side it comes from while it fades in. Reduce Motion makes it instant.
- Motion tokens `push`, `pushOffset`, `sheenSweep`, and `placeholderFade`.

## 1.4.10

- `OnePlusLinearSheet` at `.panel` width uses 12 pt side and bottom insets instead of the 24 pt window gutter.

## 1.4.9

- `OnePlusAboutColorField` is 380 x 410: one raised Check for Updates button 20 pt under the version line (none when
  the app has no updater), and the quiet `Website · Licenses · ©` text-link footer of the Pro window.
  `windowButtonsBottom` becomes `windowButtonTop`.
- `windowIconShadow` is lighter in Light mode (opacity 0.15, Dark stays 0.25) through the new `Shadow.lightOpacity`.

## 1.4.8

- `OnePlusAboutColorField` puts its Check for Updates, Website, and Licenses buttons at the bottom, just above the
  copyright line, like the footer links of the other About windows. `windowButtonsTop` becomes `windowButtonsBottom`.

## 1.4.7

- `OnePlusCheckboxStyle` disabled and on draws the neutral well with a gray check, not the accent at low opacity
  (which read as a red warning tint). Disabled and off still dims.

## 1.4.6

- `OnePlusLinearList(maxHeight:)` scrolls its rows inside the group, so the group's ring stays whole on all four
  sides. A list wrapped in an outside `ScrollView` lost its right and bottom ring to the clip.

## 1.4.5

- `OnePlusSheetWidth.panel` (340 pt) fits a sheet inside the 356 pt menu panel; `.small` (420 pt) spilled past
  its sides.

## 1.4.4

- `OnePlusLinearSelect` takes a `placeholder`, shown while the selection matches no choice. A pick-to-fill select
  (such as Portman's Hosts) lists only real choices, with no fake checked first item.

## 1.4.3

- `OnePlusLinearToolHeader` also top-aligns the icon with the title block, so the icon's top edge is level with
  the tile's top edge even when the description wraps to 2 lines.

## 1.4.2

- `OnePlusLinearToolHeader` top-aligns the icon, title, and description block with the trailing tile: the
  icon's top edge sits level with the tile's top edge.

## 1.4.1

- `OnePlusLinearToolHeader` now puts the 48 pt icon beside the title (16 pt gap) instead of above it. The icon,
  title, and description sit as one block, centered on the trailing tile. The description has at most 2 lines
  (`headerDetailLines`), with tail truncation as a last-resort guard. Removed `headerIconGap`.
- `OnePlusLinearPageTitle(_:subtitle:subtitleLines:)` takes an optional line limit for the subtitle.

## 1.4.0

- About surfaces for every samhq app (DESIGN.md "About", tokens `OnePlusAboutMetrics`):
  `OnePlusAboutSettingsSection` (Settings > About centered hero with Links, Credits, and the About window Animation
  switch), `OnePlusAboutColorField` (free app window, a color field and breathing glow taken from the icon),
  `OnePlusAboutProLicense` (paid app license card), `OnePlusAboutCompare` (free vs paid table with Buy now), and
  `OnePlusAboutWindow.show(size:content:)` (one fixed, close-only window with an autosaved position).
- `OnePlusAboutInfo` reads name, version, build, and icon from the bundle. The glow breathes only while
  `OnePlusAbout.animationKey` is on, Reduce Motion is off, and the window is active.

## 1.3.49

- Nothing moves on hover or press: the metric tile, panel action keys, main window launch tile, and tool row
  chevron no longer lift, sink, scale, or nudge. Tile hover fades only its wash (180 / 240 ms); keys get a soft
  drop in Light (`actionKeyHoverShadow`) and a faint rim in Dark (`actionKeyHoverRim`). Removed `tileLift`,
  `keyLift`, `keyPress`, `springChevronNudge`, and the `springTile*` tokens.
- `OnePlusLinearButtonStyle(.segment)` with `fillSegmentHover` (`#D6D6DB` / `#3C3C42`) and `fillSegmentPressed`:
  segmented hover now stands off the well (1.22:1 Light, 1.31:1 Dark, was 1.08 / 1.10).
- `OnePlusLinearMetrics.rowStatusGlyph` (10 pt): a status glyph beside a row's control.

## 1.3.46

- `OnePlusLinearIconButton`: `arrow.up.right` draws 2 pt smaller and 0.5 pt down-left, so it matches the gear's
  optical size and its ink sits within 0.5 pt of the cell center.

## 1.3.45

- `OnePlusLinearIconTrack`: panel bar actions (Settings, Open App) as 26 pt icon buttons in the same sunken
  track as `OnePlusLinearIconTabs`.

## 1.3.44

- `OnePlusLinearColor.temperatureCool` (`#008CBF` Light, `#63D1FF` Dark): the cool end of a heat scale, such as
  the Fan chart's temperature-colored line.
- `OnePlusLinearButtonStyle(.inlineDestructive)`: the `.inline` caption action in coral `destructiveText`, for
  a reset inside a hint line.

## 1.3.43

- `OnePlusLinearTextField` and `OnePlusLinearColorWell` sit on the stepper's flat `fillTrack` well instead of the
  sunken key well, so every field on a page has one fill. In Dark the text field was near-black beside gray steppers.

## 1.3.42

- Raised text buttons (`.raised` and `.soft` under `.raisedKeys`, the app list price key) drop the lit top edge
  and the drop shadow in Dark, like the menu panel's row keys. Light is unchanged. New tokens `buttonKeyEdgeTop`
  and `buttonKeyShadow`; `OnePlusRaisedKey(button: true)`.

## 1.3.41

- `OnePlusLinearButtonStyle(.inline)`: a text action inside a caption line, such as the Fan chart's `Reset Curve`.
  Caption type in `secondary` ink, `ink` on hover and press, no fill and no padding.

## 1.3.40

- `OnePlusCheckboxStyle` draws its own 14 pt rounded square: the track well with a hairline when off, the accent
  with a white check when on. Hover shades it one `pressed` step, press two, and it follows a sampled
  `onePlusControlState`. No native checkbox and no focus ring.
- `OnePlusLinearTextField` takes `autofocus: true` to put the cursor in the field when it appears.

## 1.3.39

- `OnePlusWindowContent` applies `onePlusFocusPolicy()`, so every scene window that uses it has no focus ring.
- `OnePlusMenuButton`, the applet settings button and row actions, icon tabs, the action bar, icon buttons,
  nav rows, menu tiles and actions, card reset and section actions, the switch, account and disk rows all set
  `focusEffectDisabled()` themselves, so no system focus ring shows even outside a policy root.

## 1.3.38

- `OnePlusLinearColor.accent` Light is `#D94F45`, matching DESIGN.md (was `#E0493E`).
- `OnePlusLinearTextField` takes `secure: true` for passwords.
- `OnePlusMenuButton` `.hostTitle` and `.hostIcon` take the host's button style.
- `OnePlusStepperField` on a page is at most one control column wide and starts at the leading edge, so it
  lines up with the select and segmented control in a narrower column.
- `OnePlusLinearDateField` draws AM and PM in the same ink as the time.

## 1.3.37

- New `OnePlusLinearDateField`: date, hour, and minute segments on the stepper well; the chevron key and the
  arrow keys step the picked segment. It replaces the native `DatePicker`.
- `OnePlusMenuButton` `.raised`: the page's raised button with a down chevron, opening `OnePlusPopupMenu`.
- `OnePlusLinearSelect` takes the row look's height on a page, so it matches the 22 pt controls beside it.
- `OnePlusLinearStepper` hugs its content; `OnePlusLinearSegmented` takes an optional `width` to fill a
  control column.

## 1.3.36

- `OnePlusLinearSegmented` draws the menu panel look in every context: segments touching on a `fillTrack`
  well with a flat `fillThumb` thumb. Pages keep their look's height and 13 pt labels.
- `OnePlusLinearSelect` `.field` draws the panel's white field with a hairline in every look, and shows a
  sampled hover.
- New `OnePlusLinearStepper`: the value on the `fillTrack` well and a 16 pt `fillThumb` key with chevron up
  and down halves, hover and press fills, and arrow keys. `OnePlusStepperField` uses it in every look; the
  native `NSStepper` and the minus and plus columns are gone.

## 1.3.35

- `.snug` segments size to their label plus 8 pt a side with no fixed width, so a long label such as
  "Custom" gets the same room as "Auto". The whole segment is the hit target.

## 1.3.34

- Remove the unused `fanTile` fill; the Fan page now uses its own icon asset.

## 1.3.33

- `OnePlusLinearSegmentSizing.snug`: segments keep the fixed width; a longer
  label widens only its own segment, to the label plus 6 pt a side.
- CPU temperature tokens `temperatureWarm`, `temperatureHot`,
  `temperatureVeryHot`, `temperatureCritical`, and the `fanTile` fill.

## 1.3.32

- No focus rings, ever. `onePlusFocusPolicy()` always applies
  `focusEffectDisabled()` and is the root modifier for every scene, panel,
  popover, and sheet. AppKit views under the policy get `focusRingType = .none`.
- Keyboard focus shows only a style's own subtle fill: buttons, tabs, linear
  controls, quiet keys, switches, fields, and selects lose their focus stroke.

## 1.3.31

- Add `OnePlusLinearToolPages`: `OnePlusLinearSpace` and
  `OnePlusLinearControlWidth` scales, `linearGroupRowHover(selected:)`,
  `onePlusLinearEditorialPage()`, `OnePlusLinearEditorialFixedBody`, and
  `OnePlusLinearSheet` for editorial tool windows and their sheets.
- Tables (`onePlusTableRow`, `OnePlusTableSkin`, `OnePlusNativeTable`) follow
  the editorial look under `onePlusLinearEditorial`: group fill, `lineSoft`
  row lines, `selection` fill, no zebra stripes. `OnePlusTablePalette` holds
  both palettes.
- `OnePlusLinearList(.window)` renders an inset group under editorial.
- `OnePlusLinearBanner` gains `.error` and selectable text.
- Linear tokens gain `destructiveFill` and `success`.

## 1.3.30

- Add `OnePlusLinearMenuPanel`, the Home variant of `OnePlusMenuPanel` for a
  one-tool status item: the fill-steps panel with the Home top bar, a body that
  scrolls only at the screen ceiling, and the same height reporting.

## 1.3.29

- Add `OnePlusLinearDisclosureRow`: a 32 pt panel row with glyph, name,
  trailing detail, optional accessory, and a turning chevron. It uses the
  Home row hover, so the fill overflows the text by 6 pt on each side.
- Add `OnePlusLinearKeyButtonStyle` (the Home action key) with `.compact`,
  a 24 pt row key that rests one soft step above the group fill.
- Add `OnePlusLinearUsageBar`, the tile usage bar on its own, for panel rows.
- Add `OnePlusLinearPlainRowStyle` for rows that draw their own hover.
- `OnePlusLinearControlRow` takes `titleWidth: nil` for a natural-width name.

## 1.3.28

- `OnePlusStepperField` in the linear looks right-aligns its value with or
  without a unit, so every stepper lines up.
- Add `OnePlusLinearControlLook.quietRaisedActionRow`: Quiet Raised with
  24 pt fields, for an applet row where a field sits beside a soft button.

## 1.3.27

- `OnePlusPopupMenu` scrolls only for the wheel and for arrow keys. Pointer
  hover no longer scrolls the list (it caused a scroll and hover loop). Long
  item titles truncate in the middle and show the full title as help.
- `OnePlusStepperField` in the linear looks is one control column wide
  (160 pt). The value and its unit right-align, so "4 hours", "3 days", and
  "3 sec" line up.
- `OnePlusLinearIconButton(busy:)` swaps its glyph for a small spinner in
  the same frame. The accessibility label becomes the busy text, such as
  "Scanning".

## 1.3.26

- Breaking: the "Apps by Sam" parts take the owner's round 3-5 picks.
  `OnePlusLinearAppAction` is the App Store GET or OPEN capsule,
  `OnePlusLinearFeaturedApp` is the floating banner with the raised Paid key,
  and `OnePlusLinearAppRow` is an open 64 pt row (no price word, optional
  separator). Adds `OnePlusLinearAppCoverCard` (half-width card with its cover
  edge to edge across the top) and `OnePlusLinearAppShelf` (banner, caption,
  two cover cards side by side, then the rows).

## 1.3.17

- The fill-steps panel open key becomes the "Ink key" (owner pick): a dark
  ink key with a white label in Light, a light ink key with a near-black label
  in Dark. Adds `openKeyInk`, `openKeyHover`, and `openKeyPressed`.

## 1.3.15

- Add the "Apps by Sam" parts (owner pick "Featured Pro, then a list"):
  `OnePlusLinearFeaturedApp`, `OnePlusLinearAppRow`, `OnePlusLinearAppAction`
  (a soft Open or Get button, disabled when its action is nil), and
  `OnePlusLinearAppListMetrics`.

## 1.3.0

- Breaking: the applet control look `.depth` becomes `.quietRaised` (owner
  pick): quiet sunken tracks, one solid knob with one soft shadow, and the
  accent only for an "on" state. It covers the switch, slider, segmented
  control (equal and fitted), stepper field, color well, select, search, and
  text field. Controls are 22 pt high. The `depth*` tokens are replaced by
  `quiet*` tokens; the look drops `segmentHeight` storage, `segmentTrackRadius`,
  `stepperCap`, and `stepperCapRadius`, and adds `stepperButton`.
- Segment labels without capitals or digits center their x-height. Short
  dividers that fade at both ends separate unselected segments.
  `OnePlusLinearSegmented.opticalOffset(_:)` is public for AppKit ports.
- The stepper field is one field with plain minus and plus columns.
- Breaking: `OnePlusLinearButtonStyle(.destructive)` is plain red text with no
  fill and no border, on the group's row text edge. `destructiveFill`,
  `destructiveHover`, `destructivePressed`, and `appletDestructiveRadius` are
  removed; `destructivePressedText` is added; `appletDestructive` is 16 pt.
- Add the showcase `ControlStyleOptions.swift`, the round 3 reference renders.

## 1.2.1

- Fix: the Depth `OnePlusStepperField` keeps its unit in a tight row; the row
  label truncates instead.
- Fix: `OnePlusLinearAppletListRow` puts the 10 pt row gap before its metadata
  and truncates the title first.
- Add `OnePlusLinearTextField`, `OnePlusLinearEmptyState`, `OnePlusLinearBanner`
  (`.info`, `.warning`), the `.ghost` button kind, `sizing: .fitted` on
  `OnePlusLinearSegmented`, `count` and `dimmed` on `OnePlusLinearNavRow`, and
  `OnePlusLinearPaneToolbar(title:)` without back and forward.
- `.soft` and `.ghost` labels never truncate.
- Make `View.linearText(_:weight:color:)` public. Add the `warning` and
  `warningFill` tokens.
- Add the showcase parts sheet `LinearAppletPartsSheet`.

## 1.2.0

- Add the DESIGN.md v15 applet parts ("Filled groups"): `OnePlusLinearApplet`
  shell and titlebar, settings gear, form, captioned filled groups, rows,
  slider rows, list rows with swatches and icon actions, tab row, toolbar,
  applet search (`style: .applet`), `OnePlusLinearSelect`, the `.soft`
  primary and `.destructive` button kinds, `OnePlusLinearSlider`, and
  `OnePlusLinearColorWell`, with the applet tokens.
- Add `OnePlusLinearControlLook` (`.depth`), the one style point for the applet
  controls: recessed tracks, gently raised knobs and caps, a fine top highlight.
  `OnePlusLinearSegmented`, `OnePlusLinearSwitchStyle`, and `OnePlusStepperField`
  take it inside an applet; without it they look as before.
- Add the "Quiet" motion: `OnePlusLinearMotion` tokens, the
  `.onePlusLinearMotion(_:)` switch (default `.instant`), and
  `OnePlusLinearContentSwitch`. The switch knob and segment thumb slide under
  Quiet; instant surfaces do not change.
- Add the showcase page "Version 15 applets" and render, APCA, and motion tests.

## 1.1.1

- `OnePlusLinearToolRow`: the unset favorite star hides only its paint at rest,
  so VoiceOver and Full Keyboard Access still reach it. It is a toggle labeled
  "Favorite" with the value On or Off. Rest layout and hover look are unchanged.
- `OnePlusLinearSegmented`: add `isChoiceEnabled:` (default all enabled). A
  disabled choice dims to 0.38 and takes no click, hover, or arrow-key
  selection; the other choices stay active.

## 1.1.0

- Add the DESIGN.md v15 (Linear style) parts for the main window and the menu
  panel: `OnePlusLinearColor`, `OnePlusLinearMetrics`, sidebar, search, nav
  rows, pane toolbar, text tabs, sections, tool rows, panel shell, bento tiles,
  history charts, control rows, segmented control, switch, process rows,
  joined action bar, and panel footer with icon tabs.
- Add the showcase page "Version 15" and render tests in both appearances at
  1x and 2x.
- No v14 component changes its look or API.
