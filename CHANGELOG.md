# Changelog

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
