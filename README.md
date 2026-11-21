# AURA — Modern Luau UI

A native white glass UI library for Roblox Luau. Includes reusable controls, a visual color picker, queued notifications, responsive scaling, and automatic mouse unlocking. Version **1.2.0**.

The interface mounts under `gethui()`. It uses native Roblox UI objects and gradients, with no external images or UI dependencies. Loading the library returns an API; it does not create a demo window.

## Quick start

The library is hosted in [2762779980q-svg/roxorblai](https://github.com/2762779980q-svg/roxorblai). Load `ui.lua` directly from its **Raw URL**:

```lua
local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/2762779980q-svg/roxorblai/main/ui.lua"
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
| `UI.Version` | `"1.2.0"` |

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
| `NotificationLimit` | `3` | Visible notification limit, from 1 to 5; reduced on short screens |
| `NotificationDuration` | `4` | Default duration in seconds; 0 keeps a notification open until dismissed |

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
| `GetNotification(id)` | Looks up a queued or active notification |
| `ClearNotifications()` | Dismisses all active and queued notifications |
| `Destroy()` | Cleans up the UI, blur, listeners, mouse ownership, notifications, tweens, tasks, and registry entry |

For compatibility, the most recently created window is also stored in `getgenv().WhiteGlassUI`. For access across files, use `UI:GetWindow("my-script")` or keep the window reference.

### Mouse unlocking

Opening a window automatically frees the cursor, so you can interact without pressing Esc. Native button modality, mouse property listeners, and a late render callback handle first-person locking, Shift Lock, and repeated `LockCenter` assignments.

Hiding the window stops its mouse override. Destroying it also removes its ownership. Visible windows from separately loaded library instances share mouse management; the cursor remains free until the last eligible window releases it. An initially hidden window never takes mouse ownership.

Set `UnlockMouse = false` when creating a window to opt out. Use `window:SetMouseUnlocked(false)` to release the cursor override immediately. Passing `true` enables unlocking while the window is visible; it does not keep the cursor unlocked while hidden.

## Tabs and sections

```lua
local section = main:AddSection({ Title = "Settings", Description = "Optional description" })
main:AddHero({ Eyebrow = "WELCOME", Title = "Hello,\nwelcome back.", Description = "Your personal space." })
```

Controls share the options `Id`, `Title`, `Description`, and `Callback`. Control IDs are optional but must be unique within a window when provided. Tab IDs must also be unique within a window.

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

Notifications stack at the bottom right. Additional messages enter a queue and only start their timers when displayed. Three notifications are visible by default, with up to 32 pending messages. Short viewports reduce the visible count. Long content wraps to the available width and is truncated after approximately six lines.

Each card includes a status icon, color, close button, and remaining-time bar. Timers share one on-demand Heartbeat connection per window, which disconnects when no active notification requires a countdown.

`Update(options)` changes only supplied fields. Only supplying `Duration` resets the remaining time. Calling `Notify` again with the same ID is equivalent to updating the handle.

| Handle API | Description |
|---|---|
| `notice:Update(options)` | Updates the notification and returns the same handle |
| `notice:Dismiss()` | Manually dismisses the notification |
| `notice.Status` | Read-only status: `queued`, `active`, or `closed` |
| `notice.Remaining` | Read-only remaining duration in seconds |

Look up a handle with `window:GetNotification("download")`, or clear all messages with `window:ClearNotifications()`.

Close reasons are `manual`, `timeout`, `clear`, and `overflow`. Destroying a window silently cleans up its notifications without invoking `OnClose`. The legacy signature `window:Notify("Title", "Message", 3)` is also supported.

## Validation

The library and example pass compilation with the official Luau compiler. The offline test harness covers 237 API, color picker, mouse, and notification assertions, plus 154 example and cleanup assertions. Coverage includes color coordinates and boundaries, mouse and touch dragging, notification queues, repeated cursor locking, ownership across windows, and cleanup on hiding or destruction.

These checks use mocked Roblox services and a local replacement for the example's network loader. The public library Raw URL has also been checked and matches the local library source. Live Roblox rendering, executor compatibility, and game cursor scripts have not been verified.
