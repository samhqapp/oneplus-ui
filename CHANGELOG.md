# Changelog

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
