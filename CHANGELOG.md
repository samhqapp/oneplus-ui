# Changelog

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
