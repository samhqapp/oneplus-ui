# Changelog

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
