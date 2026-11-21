# AURA — Modern Luau UI

A native white glass UI library for Roblox Luau. Includes reusable controls, inline key bindings, a visual color picker, notifications, an enabled-feature overlay, responsive scaling, and automatic mouse unlocking. Version **1.4.3**.

The interface mounts under `gethui()`. It uses native Roblox UI objects and gradients, with no external UI dependencies. The top-left icon automatically displays the local player's Roblox avatar headshot through a built-in thumbnail URI, preserving the rounded shape and title layout. Studio players without a positive user ID retain the original icon. Loading the library returns an API; it does not create a demo window.

## Quick start

The library is hosted in [Klua-svgrob/roxorblai](https://github.com/Klua-svgrob/roxorblai). Load `ui.lua` directly from its **Raw URL**:

```lua
local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Klua-svgrob/roxorblai/main/ui.lua"
))()

local window = UI:CreateWindow({ Id = "my-script", Title = "My Script" })
local main = window:CreateTab({ Id = "main", Title = "Home", Icon = "grid" })
local section = main:AddSection({ Title = "Features" })

section:AddToggle({
    Id = "enabled", Title = "Enable feature", Default = false,
    Callback = function(value) print("Enabled:", value) end,
})

window:Notify({ Title = "Ready", Content = "Everything is set up.", Type = "success" })
```

To pin a version, replace `main` with a commit SHA or tag. If you fork the repository or move `ui.lua`, update the owner, repository, branch, or file path in the URL. A GitHub `blob` page returns HTML; use its Raw URL instead.

See [ui.example.lua](ui.example.lua) for a complete example with three tabs, appearance controls, a color picker, mouse unlocking, and notifications. Its loader already points to this repository.

## Library

| API | Behavior |
|---|---|
| `UI:CreateWindow(options)` | Creates a window; cleans up an existing window with the same `Id` first |
| `UI:GetWindow(id)` | Looks up a window in the shared executor registry; defaults to `"default"` |
| `UI:Destroy()` | Destroys every window created by this library instance |
| `UI.Version` | `"1.4.3"` |

Loading another copy of the library preserves existing windows. Different window IDs can coexist. Give windows different toggle keys if you want to control them independently.

## CreateWindow

| Option | Default | Description |
|---|---|---|
| `Id` | `"default"` | Unique window identifier |
| `Title` / `Subtitle` / `Footer` | AURA text | Brand title, sidebar subtitle, and footer text |
| `Width` / `Height` | `916` / `612` | Logical size; automatically scales down to fit the viewport |
| `SidebarWidth` | `210` | Sidebar width |
| `ToggleKey` | `Enum.KeyCode.RightAlt` | Show/hide shortcut; ignored while a text box is focused |
| `Visible` | `true` | Initially expanded; a restore button remains available when hidden |
| `UnlockMouse` | `true` | Frees the mouse and shows the cursor while expanded |
| `Accent` | `Color3.fromRGB(73, 102, 197)` | Accent color |
| `Glass` / `Motion` | `true` / `true` | Glass appearance and animations |
| `Blur` | `18` | Native scene blur strength, from 0 to 56 |
| `Transparency` | `0.12` | White panel transparency, from 0 to 0.8 |
| `Scale` | `1` | Scale multiplier, from 0.5 to 1.5; still limited by viewport size |
| `NotificationLimit` | `3` | Visible notification limit, from 1 to 3; reduced on short screens |
| `NotificationDuration` | `4` | Default duration in seconds; 0 keeps a notification open until dismissed |
| `FeatureListEnabled` | `false` | Show enabled toggle features as a separate overlay |
| `OnDestroy` | `nil` | Cleanup callback, invoked once after the window is destroyed |

The library creates and manages its own `BlurEffect`. Destroying a window removes that effect without changing the game's existing Lighting settings. Roblox blur affects the 3D scene; translucent panels provide the glass surface.

## Window

| Method | Behavior |
|---|---|
| `CreateTab({ Id, Title, Description, Icon })` | Creates a tab; supported icons: `grid`, `settings`, `info` |
| `SelectTab(tabOrId)` | Selects a tab by object or ID |
| `GetTab(id)` / `GetControl(id)` | Looks up a registered tab or control |
| `SetTitle(text)` | Updates the brand title and restore button |
| `SetVisible(boolean)` / `Toggle()` | Shows, hides, or toggles the window |
| `SetMouseUnlocked(boolean)` | Enables or disables mouse unlocking while the window is visible |
| `SetGlass(boolean)` / `SetMotion(boolean)` | Updates the glass appearance or subsequent animations |
| `SetAccent(Color3)` | Updates accent bindings and accent-colored notifications |
| `SetBlur(number)` / `SetTransparency(number)` / `SetScale(number)` | Updates display settings |
| `Notify(options)` | Creates or updates a notification and returns its handle |
| `GetNotification(id)` | Looks up an active notification |
| `ClearNotifications()` | Dismisses all active notifications |
| `SetFeatureList(options)` | Configures overlay visibility, position, and scrolling |
| `SetFeature(id, title, enabled, parentId)` | Registers or updates a custom feature; optional parentId references a toggle |
| `Destroy()` | Cleans up the UI, blur, listeners, mouse ownership, notifications, tweens, tasks, and registry entry |

For compatibility, the most recently created window is also stored in `getgenv().WhiteGlassUI`. For access across files, use `UI:GetWindow("my-script")` or keep the window reference.

### Mouse unlocking

Opening a window automatically frees the cursor, so you can interact without pressing Esc. The original native button modality, mouse property listeners, and late render callback handle first-person locking, Shift Lock, and repeated `LockCenter` assignments. While a window is visible with mouse unlocking enabled, a small white cross with a dark outline follows the mouse in screen coordinates. This cursor uses native Frames under gethui(), remains visible even if a game hides its system pointer, and disappears when the window is hidden, unlocking is disabled, or the window is destroyed. It is a mouse pointer rather than a fixed center-screen aiming reticle.

Hiding the window stops its mouse override. Destroying it also removes its ownership. Visible windows from separately loaded library instances share mouse management; the cursor remains free until the last eligible window releases it. An initially hidden window never takes mouse ownership.

Set `UnlockMouse = false` when creating a window to opt out. Use `window:SetMouseUnlocked(false)` to release the cursor override immediately. Passing `true` enables unlocking while the window is visible; it does not keep the cursor unlocked while hidden.

## Tabs and sections

```lua
local section = main:AddSection({ Title = "Settings", Description = "Optional description" })
main:AddHero({ Eyebrow = "WELCOME", Title = "Hello,\nwelcome back.", Description = "Your personal space." })
```

Controls share the options `Id`, `Title`, `Description`, and `Callback`. Control IDs are optional but must be unique within a window when provided. Tab IDs must also be unique within a window.

Use `section:AddLabel("Text")` for a non-interactive hint. Toggle controls are automatically tracked by the feature overlay, including silent value updates and callbacks that roll a toggle back after failure. Pass `FeatureList = false` to exclude a toggle, `FeatureTitle` to use a shorter overlay title, or `ParentFeature = "parent-toggle-id"` to show a child option only while its parent toggle is enabled.

```lua
local toggle = section:AddToggle({ Id = "on", Title = "Enabled", Default = false,
    Callback = function(enabled) end })

local slider = section:AddSlider({ Id = "amount", Title = "Amount", Min = 0, Max = 10,
    Default = 2, Decimals = 1, Suffix = "x", Callback = function(value) end })

local dropdown = section:AddDropdown({ Id = "mode", Title = "Mode",
    Values = { "Auto", "Manual" }, Default = "Auto", Callback = function(value) end })

local palette = section:AddColorPicker({ Id = "accent", Title = "Accent color",
    Default = Color3.fromRGB(73, 102, 197), Expanded = true,
    Callback = function(color) window:SetAccent(color) end })

local input = section:AddInput({ Id = "name", Title = "Name", Default = "",
    Placeholder = "Enter a name...", Callback = function(text, enterPressed) end })

local button = section:AddButton({ Id = "apply", Title = "Apply", Text = "Apply settings",
    Primary = true, Callback = function() end })
```

Toggle, Slider, Dropdown, Input, and ColorPicker return controls with `GetValue()` and `SetValue(value, silent)`. Initial creation does not call `Callback`. `SetValue` calls it by default; pass `true` as the second argument to update silently.

Input submits when focus is lost or Enter is pressed. Its second callback argument indicates whether Enter was pressed; API calls through `SetValue` pass `nil` for that argument. Button returns a native `TextButton`.

```lua
window:GetControl("on"):SetValue(true)
window:GetControl("amount"):SetValue(3.5, true)
print(window:GetControl("mode"):GetValue())
```

## Inline key bindings

Attach a key badge to a toggle without creating an extra settings row:

```lua
local toggle = section:AddToggle({
    Id = "feature", Title = "Feature", Default = false,
    Callback = function(enabled) print(enabled) end,
})

local key = toggle:AddKeyPicker({
    Id = "feature-key", Default = "None", Mode = "Toggle",
})
```

The badge appears immediately before the switch. Left-click `None` or an existing key to show `...` and capture the next keyboard key. Press **Escape** during capture to clear the binding back to `None`. The captured press does not activate the feature or the window visibility shortcut.

Right-click the badge to open a small menu containing exactly two modes: **Toggle** switches the feature on or off once per key press; **Hold** enables it while pressed and disables it on release. Escape outside capture closes the mode menu without clearing the binding. Clicking outside the menu also closes it.

| API | Description |
|---|---|
| `toggle:AddKeyPicker(options)` | Attaches one picker to the toggle and returns its handle |
| `Default` | Key name, `Enum.KeyCode` item, or `"None"`; defaults to `"None"` |
| `Mode` | `"Toggle"` or `"Hold"`; defaults to `"Toggle"` |
| `Id` | Optional unique control ID for `window:GetControl(id)` |
| `Callback(keyName, mode)` | Optional notification when binding or mode changes |
| `key:GetValue()` / `key:SetValue(value, silent)` | Reads or changes the binding; `nil`, `"None"`, or Escape clears it |
| `key:GetMode()` / `key:SetMode(mode, silent)` | Reads or changes the input mode |
| `key:BeginCapture()` | Starts keyboard capture while the window is visible |

Keyboard shortcuts work while the main window is hidden. Focused text boxes and processed gameplay input do not trigger them. Release events still end Hold even when processed. Losing application focus, rebinding, switching modes, or destroying the window releases held features. Focus loss, hiding the window, or changing tabs cancels an unfinished capture while keeping the existing binding. Capture ownership is shared across windows and separately loaded copies of the library.

```lua
key:SetValue(Enum.KeyCode.F8)
key:SetMode("Hold")
key:SetValue("None", true)
```

## Visual color picker

`section:AddColorPicker(options)` draws a two-dimensional color plane and rainbow hue strip using native `UIGradient` objects. Click the preview to expand or collapse it. Move horizontally across the plane to change saturation and vertically to change brightness. Use the rainbow strip to select hue, or choose a preset swatch below the plane.

The picker supports mouse and touch dragging. Its preview shows the selected color and hexadecimal value without requiring separate RGB sliders.

| Option or method | Description |
|---|---|
| `Default` | Initial `Color3`; defaults to the window's current accent |
| `Expanded` | Whether to start expanded; defaults to `false` |
| `Presets` | Optional `Color3` array; displays up to eight colors, or built-in colors if omitted |
| `Callback(color)` | Receives a `Color3` when selected, dragged, or updated through a non-silent API call |
| `GetValue()` / `SetValue(Color3, silent)` | Reads or sets the color; invalid types are ignored |
| `SetExpanded(boolean)` | Expands or collapses the picker; collapsing cancels its current drag |

```lua
palette:SetValue(Color3.fromRGB(47, 125, 109), true)
palette:SetExpanded(true)
```

The picker updates its own value. Connect its callback to `window:SetAccent(color)` or another feature to apply the chosen color.

## Notifications

```lua
local notice = window:Notify({
    Id = "download",
    Title = "Loading", Content = "Please wait...",
    Type = "info",
    Duration = 0,
    PauseOnHover = true,
    OnClose = function(reason) print(reason) end,
})

notice:Update({ Title = "Complete", Content = "Loaded successfully.", Type = "success", Duration = 3 })
```

| Option | Description |
|---|---|
| `Id` | Optional unique ID; notifying again with the same ID updates the existing notification |
| `Title` | Heading text |
| `Content` / `Message` | Body text; `Message` is an alias |
| `Type` | `info`, `success`, `warning`, or `error` |
| `Duration` | Seconds to remain visible; 0 requires manual dismissal |
| `PauseOnHover` | Pauses the countdown while hovered; defaults to `true` |
| `OnClose(reason)` | Called after dismissal, except during window destruction |

Notifications stack at the bottom right. At most three cards are visible. When the limit is reached, a new notification immediately removes the oldest card with the close reason `overflow`; messages do not wait in a queue. Updating an existing ID preserves the other cards. Short viewports reduce the visible count and keep the newest messages. Long content wraps to the available width and is truncated after approximately six lines.

Each card includes a status icon, color, close button, and remaining-time bar. Timers share one on-demand Heartbeat connection per window, which disconnects when no active notification requires a countdown.

`Update(options)` changes only supplied fields. Only supplying `Duration` resets the remaining time. Calling `Notify` again with the same ID is equivalent to updating the handle.

| Handle API | Description |
|---|---|
| `notice:Update(options)` | Updates the notification and returns the same handle |
| `notice:Dismiss()` | Manually dismisses the notification |
| `notice.Status` | Read-only status: `active` or `closed` |
| `notice.Remaining` | Read-only remaining duration in seconds |

Look up a handle with `window:GetNotification("download")`, or clear all messages with `window:ClearNotifications()`.

Close reasons are `manual`, `timeout`, `clear`, and `overflow`. Destroying a window silently cleans up its notifications without invoking `OnClose`. The legacy signature `window:Notify("Title", "Message", 3)` is also supported.

## Enabled-feature overlay

The overlay remains visible when the main window is hidden. Its settings controls are included in the example and in EMDEN's Settings tab.

```lua
window:SetFeatureList({
    Enabled = true,
    Position = "TopRight",
    Scrolling = true,
    MaxHeight = 280,
    Speed = 24,
})

window:SetFeature("custom-feature", "Custom feature", true)
```

| Option | Description |
|---|---|
| `Enabled` | Show or hide the feature overlay |
| `Position` | `BottomRight`, `TopLeft`, `TopRight`, `BottomCenter`, or `TopCenter`; default `TopRight` |
| `Scrolling` | Automatically scroll overflowing content; default `false` |
| `MaxHeight` | Vertical list height limit, from 28 to 600 pixels; default 280 |
| `Speed` | Automatic scroll speed, from 5 to 120 pixels per second; default 24 |

Top corners use a vertical list sorted by measured text width, longest first. Bottom-right reverses the vertical order, placing the longest entry at the bottom. Center positions use a horizontal row from left to right. `BottomLeft` is intentionally unavailable to keep the UI restore button accessible.

Top positions reserve space using `GuiService:GetGuiInset()` and `GuiService.TopbarInset`. The overlay recalculates placement when the top bar or viewport changes. These insets describe Roblox's official top bar and screen margins; a game's custom HUD may require additional positioning. Bottom-right also moves above visible notifications.

Overflow remains manually scrollable. Automatic scrolling moves vertically at corners and horizontally at center positions, reverses at the ends, and pauses while hovered. Its Heartbeat listener is only active when scrolling is enabled and content overflows.

## EMDEN integration

EMDEN now uses this library directly for its six tabs, controls, visual color picker, notifications, mouse unlocking, and enabled-feature settings. Closing its window also unloads its runtime. Saved-location refresh removes entire old button rows.

Upload the **1.4.2** `ui.lua` to the repository before running the updated EMDEN script. EMDEN first checks for a local executor file in the packaged subfolder or at the root-level `ui.lua`, then falls back to this repository's Raw URL. It checks the library version to avoid loading an older API. Its silent-aim shortcut now uses an inline `None` badge with custom keyboard capture and Toggle/Hold modes instead of a separate dropdown.

## Validation

The library and example pass compilation with the official Luau compiler. The offline harness covers 443 API, color picker, mouse, and notification assertions, 90 feature layout and replacement assertions, 110 inline keyboard capture and Toggle/Hold assertions, and 177 example and cleanup assertions. EMDEN also passes 163 integration assertions using the actual UI source with mocked native services, including its vehicle boost lifecycle.

These checks use mocked Roblox services and a local replacement for the network loader. The updated 1.4.2 files in this package still need to be uploaded to the repository. Live Roblox rendering, executor compatibility, and game cursor scripts have not been verified.
