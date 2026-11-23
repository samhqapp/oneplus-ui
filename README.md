<h1 align="center">OnePlusUI</h1>

<p align="center">
  Dark, quiet, native SwiftUI components for macOS tools.<br>
  The window, page, card, control, and menu bar panel kit behind MacPowerToys and NetToys.
</p>

<p align="center">
  Swift Package · macOS 15+ · Swift 6.2 · MIT
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/samhqapp/macpowertoys/main/docs/screenshots/macpowertoys-launcher.png" width="100%" alt="The MacPowerToys launcher built with OnePlusUI: sidebar, page header, tabs, and tool cards">
</p>

## Install

```swift
.package(url: "https://github.com/samhqapp/oneplus-ui.git", exact: "1.0.2")
```

Add `OnePlusUI` to your target's dependencies, then `import OnePlusUI`. Run
`swift run OnePlusUIShowcase` to see every component.

## About

OnePlusUI implements
[DESIGN.md v14](https://github.com/samhqapp/macpowertoys/blob/main/DESIGN.md): fixed canvases, dynamic colors, two densities,
native controls, and static texture.

Views never restyle a component locally. Add a named variant to this package
when a surface needs different geometry or behavior. Keep approved tool icon
artwork unchanged. Existing `OnePlusTheme`, `OnePlusPanel`, `OnePlusSegments`,
`OnePlusControlButtonStyle`, and `onePlusControl` call sites remain supported.

## Window structure

```swift
import OnePlusUI

Window("Cloud Sync", id: "rclone") {
    OnePlusWindowRoot(canvas: .rclone) {
        OnePlusSidebar(title: "Cloud Sync") {
            OnePlusSidebarSearch(text: $query)
        } navigation: {
            OnePlusNavRow("Transfers", systemImage: "arrow.triangle.2.circlepath",
                          selected: page == "transfers") { page = "transfers" }
        } bottom: {
            OnePlusNavRow("Settings", systemImage: "gearshape") { page = "settings" }
        }
    } content: {
        OnePlusPage {
            OnePlusPageHeader(title: "Transfers")
        } content: {
            OnePlusCard { OnePlusCardHeader("Recent transfers") }
        }
    }
}
.defaultSize(OnePlusWindowCanvas.rclone.size)
.windowResizability(.contentSize)
.windowStyle(.hiddenTitleBar)
```

Set `NSApp.appearance` once for the app. Do not force a color scheme on a tool.
`OnePlusWindowRoot` supplies the window fill, one fixed texture layer, sidebar
line, density, and native chrome. Do not add another root texture.

For an existing root, use `.onePlusFixedCanvas(.logs)`. Applet canvases keep
their fixed width and use the 22 pt title centerline. Color Picker and Text
Extractor keep their content-driven height. All other canvases fix both axes.
Canvas sizes describe the visible window, including the hidden titlebar.
The shared modifier subtracts its measured inset once, including nested roots.
Chrome keeps all three native traffic lights visible and disables zoom and
full screen. It measures the zoom button for the title's 14 pt gap.

Read `@Environment(\.onePlusIsVisible)` before publishing live data to a view.
Fixed canvases supply it automatically. It becomes false when the host window
is occluded, minimized, ordered off screen, or closed, without polling. Apply
`.onePlusLiveUpdates()` to a custom native host that does not use a fixed
canvas. Samplers may keep collecting while their views stop observing.

Page titles start at `OnePlusMetrics.contentTop` (16 pt from the visible
window top). Sidebar content still starts at 54 pt. Header actions center on
the title's first line. `contentGap` is the separate 16 pt body gap; use it
for padding between page regions. Applet titlebars keep their 22 pt centerline.
Applets never use `contentTop`. Their first body element starts `contentGap`
below the 40 pt titlebar or tab strip. Use `OnePlusPage(layout: .applet)` to
get that gap and the 16 pt side gutters. Fixed toolbars and footers also use
`contentGap`, in both applets and workspaces.

## Table and list pages

Use `scrolls: false` when the content already owns scrolling. Header, tabs,
toolbar, and footer stay fixed. The content fills the remaining height.
Slots are optional; the page supplies the gutters and 16 pt content gap.
Fixed bodies end at the density gutter: 24 pt regular, 20 pt compact.
An empty conditional footer keeps that gutter and adds no footer gap.

```swift
OnePlusPage(scrolls: false) {
    OnePlusPageHeader(title: "Processes")
} toolbar: {
    OnePlusSearchField(prompt: "Find a process", text: $query)
} footer: {
    OnePlusStatus("\(rows.count) processes")
} content: {
    Table(rows) {
        TableColumn("Name", value: \.name)
        TableColumn("PID", value: \.pid)
    }
    .onePlusNativeTable()
}
```

Place an inspector beside the table inside `content`; only the table rows
scroll. For settings cards, keep the default `scrolls: true`. Embedded
settings supply only cards and inherit this page's single scroll container.
The page proposes its full overlay viewport width to content. A legacy
scrollbar preference does not reduce the card width or add a side gutter.

Menu panels also own their scrolling. Pass natural-height content to
`OnePlusMenuPanel`; do not wrap it in a screen-height scroll view. The shell
measures each active tab, shrinks for short content, and caps long content at
90 percent of the visible screen. Apply `.onePlusScrollIndicators()` to any
separate row scroll region; it keeps overlay style after native replacement.
Use the optional `toolbar` and `footer` builders for search, forms, and
summaries that must stay fixed. These slots sit outside the capped scroller.
Empty slots reserve no height. Closed panels keep layout mounted and stop live
observation. The shell measures the body synchronously and disables layout
animation. Native hosts use `.onOnePlusMenuHeightChange` to set their content
size in that layout pass. Measure the host before showing it.

Apply `.onePlusFocusPolicy()` at standalone roots. Window chrome, sheets,
popup menus, and menu panels already apply it. Focus paint is enabled only
while Full Keyboard Access or VoiceOver is on. The shared native policy keeps
the window as the opening responder, rejects pointer focus on nontext
controls, and preserves text editing and keyboard operation.

For SwiftUI `Table`, share `OnePlusGridColumn` values between
`.onePlusTableCell(column, position: .first)` and
`.onePlusNativeTable(columns: columns)`. Use `.last` for the final cell;
middle cells use the default position. The model sets alignment, insets,
`textRole`, and optional `textColor`. A header starts at its cells' leading
edge, also when the cells start with a glyph. Keep Time at `.mono`; path columns can use `.mono`
with `textColor: OnePlusColor.ink` for primary identity text.

## Component catalog

| API | Use |
| --- | --- |
| `OnePlusColor` | Use a dynamic token, such as `.panel`, `.ink`, `.line`, `.chartSeries`, or `.storageSeries`. |
| `OnePlusTheme` | Use the compatibility namespace; `card` maps to `panel`. |
| `OnePlusMetrics` | Read shared geometry, radii, spacing, and centerline math. |
| `OnePlusWindowCanvas` | Choose one of the 13 tool canvases or construct a fixed preview canvas. |
| `OnePlusDensity` / `.onePlusDensity(_:)` | Set `.regular` or `.compact` at the window or panel root. |
| `OnePlusTextRole` / `.onePlusText(_:)` | Apply one of the 15 type roles with density, color, tracking, and case. |
| `OnePlusMotion.animation(reduceMotion:duration:)` | Returns `nil`; hover, press, selection, and content changes are instant. |
| `OnePlusFixedWindowChrome` | Apply native fixed-window policy; its measured zoom callback is optional. |
| `OnePlusWindowRoot` | Compose `canvas`, `sidebar`, and `content` once per window. |
| `onePlusIsVisible` / `.onePlusLiveUpdates()` | Suspend live observation while hidden; keep the layout tree mounted. |
| `OnePlusFocusPolicy` / `.onePlusFocusPolicy()` | Apply the live accessibility focus policy at a root. |
| `OnePlusWindowTexture` | Draw the fixed root ribbon; normally supplied by the root. |
| `OnePlusTextureAsset` | Access the four cached reference PNGs through `.image`. |
| `.onePlusGrain(opacity:)` | Add static corner grain before clipping to the final card shape. |
| `OnePlusDitherTexture` | Use the compatible standalone corner texture view. |
| `OnePlusSidebar` | Supply search, scrolling navigation, and bottom navigation slots. |
| `OnePlusSidebarTitle` | Position a title from the measured native traffic lights. |
| `OnePlusSidebarSearch` | Bind a native search field with the Command-K hint and shortcut. |
| `OnePlusNavRow` | Supply title, icon, selection, optional count, and action. |
| `OnePlusNavCaption` | Label a navigation section in its fixed slot. |
| `OnePlusNavBadge` | Display a text-only navigation count. |
| `OnePlusPageHeader` | Supply title, subtitle, `.system` or `.dotMatrix`, and actions. |
| `OnePlusToolPageHeader` | Place a 40 pt tool icon beside the title at the shared 16 pt content top. |
| `OnePlusCatalogMetrics` | Read fixed catalog card, list, icon, and action geometry. |
| `OnePlusTab` / `OnePlusTabStrip` | Bind selection to underline tabs with counts and trailing tools. |
| `OnePlusPage` | Keep header, tabs, toolbar, and footer fixed; use `scrolls: false` for a table that fills the remaining height. |
| `OnePlusCard` | Group natural-height content with a shared fill, line, and radius. |
| `OnePlusPanel` | Use the compatible natural-height card. Flexible content such as tables, scroll views, or inspector spacers still fills its proposed height. Pair cards in a top-aligned `HStack`. |
| `OnePlusCardHeader` | Add a 40 pt title row with an optional icon and accessory. |
| `OnePlusSettingRow` | Supply label, caption, help, reset, and a 160 or 180 pt control column. |
| `OnePlusSectionTitle` | Label a section with an optional trailing link action. |
| `OnePlusButtonStyle` | Choose a variant; omitted size follows density, while regular and small force 28 or 24 pt. |
| `OnePlusMenuButton` | Build an action menu with a ghost, neutral, or `borderedIcon` trigger. Pass `systemImage` for the icon; the title supplies its tooltip and accessible name. |
| `.onePlusNeutralControls()` | Give native menus and template images neutral tint. |
| `OnePlusInteractionStyle` | Add shared interaction feedback to caller-owned row geometry. |
| `OnePlusControlLabel` | Style a native Menu label with the same button geometry. |
| `OnePlusControlState` | Show deterministic rest, hover, pressed, and focus samples in the showcase. |
| `OnePlusSwitchStyle` | Style a native Toggle binding with the compact switch shell. |
| `OnePlusCheckboxStyle` | Keep native checkbox behavior and shared type. |
| `OnePlusRadio` | Bind a native radio-group Picker to typed choices. |
| `OnePlusSegmented` | Bind typed choices; pass `width: 160` or `180` to fill the control column. |
| `OnePlusSegments` | Use the compatible intrinsic-width segmented control. |
| `OnePlusSelect` / `OnePlusMenuLabel` | Bind choices in the shared neutral popup. |
| `OnePlusStepperField` | Edit a bounded integer with validation and a non-repeating native stepper. |
| `OnePlusTextField` | Edit a line with a label, optional error, and submit action. |
| `OnePlusSearchField` | Bind native search with Escape-to-clear and an optional focus trigger. |
| `OnePlusTextEditor` | Edit plain text in NSTextView with native undo, selection, and IME support. |
| `OnePlusMetricTile` | Show a metric, unit, caption, optional chart, and optional action. |
| `OnePlusSparkline` | Draw a cached line from samples and a range. |
| `OnePlusAreaChart` | Add a cached four-point ordered-dot fill and grid to a chart. |
| `OnePlusUsageBar` | Show one clamped usage fraction in a five-point track. |
| `OnePlusSegmentBar` | Show proportional categories from values and series colors. |
| `OnePlusStatus` | Pair neutral status text with a dot; request `.success` explicitly for green. |
| `OnePlusBadge` | Show a count, with an optional pending state. |
| `OnePlusKeyValueRow` | Align a label and selectable value. |
| `OnePlusTable` / `.onePlusTableHeader()` / `.onePlusTableRow(selected:)` | Share native Table and List row geometry. |
| `.onePlusTableCell(column, position:)` / `.onePlusNativeTable(columns:)` | Use one `OnePlusGridColumn` model for SwiftUI cell roles, insets, alignment, and headers. |
| `OnePlusGridColumn` / `OnePlusGridTable` | Show a small read-only table with fixed column widths. |
| `OnePlusNativeTable` / `.onePlusNativeTable()` | Share 9 pt uppercase native headers and 34 or 28 pt rows. |
| `OnePlusEmptyState` | Show an icon, title, explanation, and optional action. |
| `OnePlusDotTitle` | Draw a cached 5 × 7 title with one accessibility label. |
| `OnePlusToast` | Show a message and post an accessibility announcement; the caller owns its lifetime. |
| `OnePlusSheet` / `OnePlusSheetWidth` | Supply header, body, and footer inside native `.sheet`. |
| `OnePlusBanner` | Show an inline information, warning, or error row with an optional action. |
| `OnePlusMenuPanel` | Supply tabs, actions, optional fixed toolbar/footer, and a natural body with a 90 percent screen ceiling. |
| `.onOnePlusMenuHeightChange(_:)` | Commit a native host size during the final panel layout pass. |
| `OnePlusMenuMetrics` | Read the 356 pt panel geometry and span-aware column widths. |
| `OnePlusMenuTab` / `OnePlusMenuTabStrip` | Bind 26 pt tabs; use `onMove` to store their order. |
| `OnePlusMenuTile` | Supply compact metric content in one, two, or three columns. |
| `OnePlusMenuControlRow` | Place Fan or Awake controls beside an icon, label, and status. |
| `OnePlusMenuSectionHeader` | Add a menu section line, title, and optional link. |
| `OnePlusMenuMetric` / `OnePlusMenuItemCard` | Show a host header, metric cells, detail, and trailing actions. Both accept optional `systemImage` glyphs. `online: false` uses muted readings and a hollow status dot. |
| `OnePlusMenuOpenApp` | Supply the ghost Open App action. |
| `OnePlusAppletTitlebar` | Add a 40 pt bar with title and actions on the 22 pt centerline. |
| `OnePlusAppletSettingsButton` | Place a ghost gear icon button in the applet titlebar, left of the primary action. It shows a selected state while Settings is open. |
| `.onePlusScrollIndicators(axes:)` / `OnePlusOverlayScroller` | Keep full viewport width and thin overlay thumbs on the requested axes. |

Catalogs can use `OnePlusSegmented(iconChoices:selection:accessibilityLabel:)`
for labeled icon segments and `OnePlusButtonStyle.catalogOpen` for 26 pt Open
actions. `OnePlusNavRow(muted:)` dims a label while keeping navigation active.
`OnePlusSidebarSearch(alternateShortcut:)` adds a shortcut beside Command-K.
`OnePlusNavCaption(spacing: .sectionStart)` adds 16 pt before a later section.
`OnePlusTab(countDigits:)` reserves three digits by default for stable counts.
`OnePlusNavBadge(minimumDigits:)` supplies the same slot in other navigation.
`OnePlusButtonStyle(.borderedIcon)` paints the raised square for report actions.
`OnePlusActionMenu` keeps SwiftUI command builders and uses the shared popup.
Its legacy width argument remains valid; the trigger fits its label. Native
submenu commands appear under named section headers in the current popup.

## Version 15 (Linear style)

DESIGN.md v15 parts for the MacPowerToys main window and combined menu panel.
They sit beside the v14 components; nothing in v14 changes. Tokens are
`OnePlusLinearColor` (dynamic, per-appearance alpha) and `OnePlusLinearMetrics`.
The reference renders are in `macpowertoys/docs/design/v15/`, and the
showcase page **Version 15** composes both surfaces with the mockup data.

| Part | Use |
|---|---|
| `OnePlusLinearSidebar { search } navigation: { } bottom: { }` | 215 pt sidebar; Settings and Exit go in `bottom`. |
| `OnePlusLinearSearchField(_:text:)` | 28 pt sidebar search with the `⌘K` chip; Command-K focuses it. |
| `OnePlusLinearNavRow(_:image:selected:dimmed:count:action:)` | 28 pt tool row with its icon artwork; trailing muted count; `dimmed` mutes a disabled name. |
| `OnePlusLinearNavRow(_:systemImage:selected:dimmed:count:shortcut:action:)` | Glyph row with a trailing count or shortcut hint (`⌘,`, `⌘Q`). |
| `OnePlusLinearNavCaption(_:count:)` | Sidebar group caption. |
| `OnePlusLinearPaneToolbar(title:canGoBack:canGoForward:back:forward:) { }` | 44 pt toolbar; back and forward use Command-[ and Command-]. |
| `OnePlusLinearPaneToolbar(title:) { }` | The same toolbar without back and forward; the title starts on the 24 pt gutter. |
| `OnePlusLinearTextTabs(tabs:selection:)` | Text tabs with counts and the accent underline on the toolbar line. |
| `OnePlusLinearPaneBody { }` | Scrolling body with the 24 pt gutter and 16 pt section gap. |
| `OnePlusLinearSection(_:count:) { rows }` | Section caption plus a grouped list. |
| `OnePlusLinearToolRow(_:summary:icon:isEnabled:isFavorite:open:)` | 36 pt tool row: star on hover, focus, or when set; switch; chevron. At rest the unset star is unpainted but stays a "Favorite" toggle for VoiceOver and the keyboard. |
| `OnePlusLinearList(style:) { rows }` | Grouped rows with hairline separators (`.window`, `.panel`). |
| `OnePlusLinearPanel { blocks } footer: { }` | 356 pt panel shell with no top bar. |
| `OnePlusLinearPanelHeader(_:note:columns:)`, `.processes()` | 24 pt block header with right-aligned column titles. |
| `OnePlusLinearBento { } trailing: { }` | Two tile columns; fixed tile heights keep both 274 pt. |
| `OnePlusLinearTile(height:chart:usage:) { }` | Metric tile; `OnePlusLinearChart` draws history, `OnePlusLinearUsage` a bar. |
| `OnePlusLinearTileLabel`, `OnePlusLinearTileValue`, `OnePlusLinearTileSplit`, `OnePlusLinearInlineValue` | Tile content rows. |
| `OnePlusLinearControlRow(_:systemImage:status:) { control }` | 32 pt Fan or Kwake row. |
| `OnePlusLinearSegmented(choices:selection:accessibilityLabel:isChoiceEnabled:)` | 40 x 18 segments in a quiet track. A choice where `isChoiceEnabled` is false dims to 0.38 and takes no click, hover, or arrow key; the others stay active. |
| `OnePlusLinearSwitchStyle()` | 26 x 16 switch for `Toggle`. |
| `OnePlusLinearProcessRow(_:icon:cpu:memory:color:)` | 30 pt process row; CPU number and `%` in the data color. |
| `OnePlusLinearActionBar([OnePlusLinearAction])` | One joined action bar with full-segment hover. |
| `OnePlusLinearPanelFooter { } trailing: { }`, `OnePlusLinearIconTabs(tabs:selection:onMove:)` | Footer with the panel tabs as icons. |
| `OnePlusLinearIconButton(systemImage:help:size:action:)`, `OnePlusLinearButtonStyle(.raised)` | Footer gear and `Open App`. |

Dark text roles are lighter than the mockup so they meet APCA Lc 60 for labels
and Lc 45 for captions. CPU numbers use `cpuText`, which is lighter than the
`cpu` chart line in Dark.

### Applets

The v15 applet look ("Filled groups") for the small tool and settings windows.
The showcase page **Version 15 applets** composes Ruler Defaults and Color
Picker from these parts. Reference renders: `docs/design/v15/applet-*.png`.

| Part | Use |
|---|---|
| `OnePlusLinearApplet(_:canvas:actions:content:)` | Shell: body-colored 48 pt title area with no line, title after the lights, trailing actions. With a `canvas` it applies the fixed-window chrome. Sets the `.quiet` control look. |
| `OnePlusLinearAppletTitlebar(_:actions:)` | The title area alone, for a custom shell. |
| `OnePlusLinearAppletSettingsButton(isActive:action:)` | 24 pt gear left of the primary action; Command-comma. |
| `OnePlusLinearAppletForm { sections } footer: { }` | Scrolling body: 16 pt gutter, sections 16 pt apart, footer 20 pt below. |
| `OnePlusLinearAppletSection(_:) { rows }`, `OnePlusLinearAppletGroup { rows }` | Caption above a filled group (10 pt radius, no border); hairlines start at the text edge. |
| `OnePlusLinearAppletRow(_:detail:) { control }`, `OnePlusLinearAppletRow(_:value:)` | 36 pt row: label (and second line) leading, control or value trailing. |
| `OnePlusLinearAppletSliderRow(_:value:in:step:format:)` | Label, 150 pt slider, live value in a 36 pt column. |
| `OnePlusLinearAppletListRow(_:monospaced:metadata:actions:leading:)`, `OnePlusLinearSwatch(_:)` | List row with swatch or icon, metadata, icon actions, full-row hover. |
| `OnePlusLinearAppletTabRow(tabs:selection:trailing:)` | Text tabs with counts and the accent underline on a 32 pt row. |
| `OnePlusLinearAppletToolbar { }` | Fixed search and select row, 12 pt above and below. |
| `OnePlusLinearSearchField(_:text:style: .applet)` | 26 pt search with a magnifier; Command-F. |
| `OnePlusLinearSelect(choices:selection:accessibilityLabel:style:width:)` | `.field` (26 pt bezel) or `.text` (tab-row filter); opens `OnePlusPopupMenu`. |
| `OnePlusLinearButtonStyle(.soft)` | Primary action: soft gray fill, 24 pt, no border. |
| `OnePlusLinearButtonStyle(.destructive)` | Plain red text with no fill and no border, on the group's row text edge. Guard it with a native confirmation. |
| `OnePlusLinearButtonStyle(.ghost)` | Secondary text action: `.soft` geometry, no fill until hover. |
| `OnePlusLinearTextField(_:text:error:onSubmit:)` | 22 pt text field; focus line only under Full Keyboard Access or VoiceOver. |
| `OnePlusLinearEmptyState(_:systemImage:message:action:)` | Centered glyph, title, line, and optional action. |
| `OnePlusLinearBanner(.info / .warning, title:message:action:)` | Filled banner with a glyph; warning uses an amber tint. |
| `OnePlusLinearSegmented`, `OnePlusLinearSwitchStyle`, `OnePlusLinearSlider(_:value:in:step:)`, `OnePlusStepperField`, `OnePlusLinearColorWell(_:color:showsAlpha:)` | Controls; inside an applet they take the control look. `OnePlusLinearSegmented(..., sizing: .fitted)` sizes segments to their labels. |

Text roles: `View.linearText(_:weight:color:)` is public; use it with
`OnePlusLinearMetrics.body` / `.control` / `.caption` and the
`OnePlusLinearColor` text tokens instead of copying fonts.

Control look: `OnePlusLinearControlLook` in `\.onePlusLinearControlLook` is
the one style point for the applet controls. The applet sets `.quietRaised`,
the owner's pick: quiet sunken tracks, one solid knob with one soft shadow,
and the coral accent only for an "on" state (`OnePlusLinearColor.quiet*`
tokens). Segment labels center their x-height, and short dividers that fade
at both ends separate unselected segments. Sizes: controls 22 pt high;
segmented 112 x 22 (36 x 18 segments), switch 32 x 18 with a 14 pt knob in a
40 x 24 hit area, slider 140 pt with a 4 pt track and 14 pt knob, stepper one
field with 22 pt minus and plus columns (104 pt without a unit), color well
40 x 22. Reference: the showcase `ControlStyleOptions.swift`. Without a look,
the segmented control and switch keep their panel look.

AppKit hosts (the Ruler windows) use the same dynamic tokens:
`NSColor(OnePlusLinearColor.appletWindow)` for the window background and the
`OnePlusLinearMetrics.applet*` numbers, or host the SwiftUI groups.

### Motion

`OnePlusLinearMotion` holds the "Quiet" tokens: curve `cubic-bezier(0.25, 1,
0.5, 1)`, `knob` 0.14 s, `slider` 0.16 s, `contentIn` 0.16 s, `contentOut`
0.12 s, `contentOffset` 4 pt.

- `.onePlusLinearMotion(.quiet)` turns the motion on for a surface. The
  default is `.instant`, so the main window and the menu panel do not move
  until the app turns it on. Reduce Motion makes every change instant.
- With Quiet on, the switch knob and the segment thumb slide, the slider knob
  slides on a change from code (it follows the pointer while dragged), and
  `OnePlusLinearContentSwitch(value) { }` fades new content in with a 4 pt
  rise. Nothing moves on hover or press, nothing staggers, and numbers change
  at once. Every move can be interrupted and ends in the rest layout.

## About surfaces

Settings > About and the About window for every samhq app (DESIGN.md "About").
Values are `OnePlusAboutMetrics`.

| Part | Use |
|---|---|
| `OnePlusAboutInfo(tagline:website:releaseNotes:support:license:credits:)` | Name, version, build, and icon from the bundle; two tints from the icon. |
| `OnePlusAboutUpdate(_:check:)` | Update state (`.current`, `.available`, ...) and the app's own check action. |
| `OnePlusAboutSettingsSection(info:update:) { app sections }` | Centered hero, Links, Credits, the Animation switch, copyright. |
| `OnePlusAboutColorField(info:update:)` | Free app window, 380 x 480: color field, breathing glow, update line, links. |
| `OnePlusAboutProLicense(info:update:rows:manage:)` | Paid app window, 420 x 560: activity line and the license card. |
| `OnePlusAboutCompare(info:freeName:rows:upgrade:)` | Free app with a paid sibling, 440 x 580: compare table and Buy now. |
| `OnePlusAboutWindow.show(size:) { view }` | One fixed, close-only window with an autosaved position. |

## Add a variant

1. Read the corresponding `DESIGN.md` recipe and check the existing component.
2. Add a named variant in that component's file. Keep its current defaults.
3. Reuse tokens and native behavior. Keep hover, press, and focus geometry fixed.
4. Add the variant and its applicable states to the showcase.
5. Check dark and light appearances, keyboard behavior, and accessibility labels.
6. Add a small test when the variant introduces logic or geometry calculations.

Textures decode once. Chart patterns and title paths are cached. No component
uses an idle animation loop; the About glow breathes only while its window is
active and the Animation switch is on. A temporary task or observer must end when its
owner disappears. Native menus, sheets, text editing, and Full Keyboard Access
keep their platform behavior. Data loading, empty, and error states belong to
the containing card, not every leaf control.

## Build and review

```sh
swift build
swift test
swift run OnePlusUIShowcase
```

The showcase opens a 1240 × 840 window in the background. Its pages cover
tokens, type, controls, data, settings, Task Manager, menu panels, applets, and
feedback. Use the header appearance control to check dark and light. All
sample actions change local state. Quit through the sidebar or window close.
The app does not read MacPowerToys settings, accounts, or credentials.


## Compact and native forms

`OnePlusTabStrip(layout: .applet)` uses the 16 pt applet gutter.
The default workspace gutter stays unchanged.
`OnePlusMenuTab` accepts an optional accessibility identifier for native tests.

Set `environment(\.onePlusControlHeight, OnePlusMetrics.controlHeight)`
to use 28 pt fields, select menus, segmented controls, and regular buttons
inside a compact menu panel. Small buttons remain 24 pt.

Native XIB forms can use these classes with module `OnePlusUI`:

- `OnePlusNativeWindowView`: opaque window body with window tokens.
- `OnePlusNativeCardView`: panel fill, border, and 8 pt radius.
- `OnePlusNativeCaptionLabel`: section caption style.
- `OnePlusNativeSwitchButton`: NSButton state and target/action with a switch.
- `OnePlusNativeStepperField`: editable number and native stepper. The
  existing number formatter supplies its limits. Target/action stays intact.

Call `OnePlusNativeForm.style` after loading a reusable controls nib.
Native titles, localization, accessibility labels, and key loops stay in
the owning application. These variants add no timers or observers.
