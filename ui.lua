local Environment = type(getgenv) == "function" and getgenv() or _G
local Registry = Environment.__AuraWindows or {}
Environment.__AuraWindows = Registry
local Library = { Version = "1.4.0" }

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local Mouse = Environment.__AuraMouse
if not Mouse then
    Mouse = { Owners = {}, Connections = {}, Binding = "AURA_MouseUnlock", Applying = false }
    Environment.__AuraMouse = Mouse
    function Mouse:Enforce()
        if self.Applying or next(self.Owners) == nil then return end
        self.Applying = true
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
        if not UserInputService.MouseIconEnabled then UserInputService.MouseIconEnabled = true end
        self.Applying = false
    end
    function Mouse:Acquire(owner)
        if self.Owners[owner] then return end
        local first = next(self.Owners) == nil
        self.Owners[owner] = true
        if first then
            self.Behavior = UserInputService.MouseBehavior
            self.IconEnabled = UserInputService.MouseIconEnabled

            for _, property in ipairs({ "MouseBehavior", "MouseIconEnabled" }) do
                table.insert(self.Connections, UserInputService:GetPropertyChangedSignal(property):Connect(function()
                    if self.Applying then return end
                    if property == "MouseBehavior" then
                        if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then return end
                        self.Behavior = UserInputService.MouseBehavior
                    else
                        if UserInputService.MouseIconEnabled then return end
                        self.IconEnabled = UserInputService.MouseIconEnabled
                    end
                    self:Enforce()
                end))
            end
            RunService:BindToRenderStep(self.Binding, Enum.RenderPriority.Last.Value + 1, function() self:Enforce() end)
        end
        self:Enforce()
    end
    function Mouse:Release(owner)
        if not self.Owners[owner] then return end
        self.Owners[owner] = nil
        if next(self.Owners) ~= nil then return end
        RunService:UnbindFromRenderStep(self.Binding)
        for _, connection in ipairs(self.Connections) do connection:Disconnect() end
        self.Connections = {}
        UserInputService.MouseBehavior = self.Behavior
        UserInputService.MouseIconEnabled = self.IconEnabled
    end
end

local COLORS = {
    Text = Color3.fromRGB(38, 43, 54),
    Secondary = Color3.fromRGB(119, 126, 141),
    Muted = Color3.fromRGB(162, 168, 181),
    Line = Color3.fromRGB(222, 227, 235),
    Track = Color3.fromRGB(226, 230, 237),
    Hover = Color3.fromRGB(238, 241, 247),
    White = Color3.fromRGB(255, 255, 255),
    Blue = Color3.fromRGB(73, 102, 197),
    Mint = Color3.fromRGB(47, 125, 109),
    Graphite = Color3.fromRGB(93, 103, 124),
}
local WIDTH, HEIGHT, SIDEBAR = 916, 612, 210
local FONT, MEDIUM, BOLD = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold

local function create(class, properties, parent)
    local instance = Instance.new(class)
    if instance:IsA("GuiObject") then
        instance.BorderSizePixel = 0
        instance.ZIndex = parent and parent:IsA("GuiObject") and parent.ZIndex + 1 or 1
    end
    for property, value in pairs(properties or {}) do instance[property] = value end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or COLORS.Line,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function label(parent, text, size, position, bounds, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1, Text = text or "", TextSize = size or 13,
        TextColor3 = color or COLORS.Text, Font = font or FONT,
        Position = position or UDim2.new(), Size = bounds or UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

local function button(parent, properties)
    local values = {
        AutoButtonColor = false, Text = "", BackgroundTransparency = 1,
        Font = MEDIUM, TextSize = 12, TextColor3 = COLORS.Text,
        Selectable = true,
    }
    for key, value in pairs(properties or {}) do values[key] = value end
    return create("TextButton", values, parent)
end

local function icon(parent, name, color, position)
    local group = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20),
        Position = position or UDim2.new(),
    }, parent)
    local parts = {}
    local function line(x, y, width, height, rotation, radius)
        local part = create("Frame", {
            BackgroundColor3 = color or COLORS.Secondary,
            Size = UDim2.fromOffset(width, height), Position = UDim2.fromOffset(x, y),
            Rotation = rotation or 0,
        }, group)
        corner(part, radius or 1)
        table.insert(parts, part)
        return part
    end
    if name == "success" then
        line(3, 10, 6, 1.8, 45); line(7, 8, 11, 1.8, -45)
    elseif name == "warning" then
        line(9, 3, 2, 9); line(9, 15, 2, 2)
    elseif name == "close" then
        line(3, 9, 14, 1.5, 45); line(3, 9, 14, 1.5, -45)
    elseif name == "minus" then
        line(4, 9, 12, 1.5)
    elseif name == "chevron" then
        line(4, 9, 7, 1.5, 45); line(9, 9, 7, 1.5, -45)
    elseif name == "settings" then
        line(2, 4, 16, 1.5); line(2, 10, 16, 1.5); line(2, 16, 16, 1.5)
        line(6, 2, 4, 5, 0, 2); line(12, 8, 4, 5, 0, 2); line(5, 14, 4, 5, 0, 2)
    elseif name == "info" then
        local ring = create("Frame", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(16, 16),
        }, group)
        corner(ring, 20)
        local outline = stroke(ring, color or COLORS.Secondary, 0, 1.4)
        table.insert(parts, outline)
        line(9, 6, 2, 2); line(9, 10, 2, 5)
    else
        for _, point in ipairs({ { 2, 2 }, { 12, 2 }, { 2, 12 }, { 12, 12 } }) do
            line(point[1], point[2], 6, 6, 0, 2)
        end
    end
    return group, parts
end

function Library:CreateWindow(options)
    options = options or {}
    assert(type(options) == "table", "CreateWindow expects an options table")
    assert(type(gethui) == "function", "AURA requires gethui().")
    local ok, container = pcall(gethui)
    assert(ok and typeof(container) == "Instance", "gethui() did not return a UI container.")
    local id = tostring(options.Id or "default")
    local previous = Registry[id]
    if previous then previous:Destroy() end
    local legacy = Environment.WhiteGlassUI
    if type(legacy) == "table" and legacy.Id == nil and type(legacy.Destroy) == "function" then legacy:Destroy() end
    local function number(value, fallback, minimum, maximum)
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then value = fallback end
        return math.clamp(value, minimum, maximum)
    end
    local WIDTH = number(options.Width, 916, 620, 1400)
    local HEIGHT = number(options.Height, 612, 440, 1000)
    local SIDEBAR = number(options.SidebarWidth, 210, 160, math.min(280, WIDTH * 0.35))

local Window = {
    Id = id, Library = self, Title = tostring(options.Title or "aura"),
    Tabs = {}, TabMap = {}, Controls = {}, Accent = typeof(options.Accent) == "Color3" and options.Accent or COLORS.Blue, Visible = false,
    Glass = options.Glass ~= false, Motion = options.Motion ~= false,
    UnlockMouse = options.UnlockMouse ~= false,
    Blur = number(options.Blur, 18, 0, 56), Transparency = number(options.Transparency, 0.12, 0, 0.8),
    Zoom = number(options.Scale, 1, 0.5, 1.5), ToggleKey = options.ToggleKey or Enum.KeyCode.RightAlt,
    NotificationLimit = math.floor(number(options.NotificationLimit, 3, 1, 3)),
    NotificationDuration = number(options.NotificationDuration, 4, 0, 3600),
    _notifications = {}, _notificationQueue = {}, _notificationMap = {}, _notificationCounter = 0,
    _destroyed = false, _connections = {}, _tasks = {}, _tweens = {}, _channels = {},
    _accentBindings = {}, _normalizedCenter = Vector2.new(0.5, 0.5), _scale = 1,
    OnDestroy = options.OnDestroy, Features = {}, _keyPickers = {},
    FeatureList = { Enabled = options.FeatureListEnabled == true, Position = "TopRight", Scrolling = false, Speed = 24, MaxHeight = 280 },
}

function Window:_listen(signal, callback)
    for connection in pairs(self._connections) do
        if not connection.Connected then self._connections[connection] = nil end
    end
    local connection = signal:Connect(function(...)
        if not self._destroyed then callback(...) end
    end)
    self._connections[connection] = true
    return connection
end

function Window:_later(seconds, callback)
    local thread
    thread = task.delay(seconds, function()
        self._tasks[thread] = nil
        if not self._destroyed then callback() end
    end)
    self._tasks[thread] = true
    return thread
end

function Window:_animate(object, properties, duration)
    if self._destroyed then return end
    local channels = self._channels[object]
    if channels then
        local cancelled = {}
        for property in pairs(properties) do
            local old = channels[property]
            if old and not cancelled[old] then cancelled[old] = true; old:Cancel() end
        end
    end
    if not self.Motion or (duration or 0.18) <= 0 then
        for property, value in pairs(properties) do object[property] = value end
        return
    end
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    channels = self._channels[object] or {}
    self._channels[object] = channels
    for property in pairs(properties) do channels[property] = tween end
    self._tweens[tween] = true
    tween.Completed:Once(function()
        self._tweens[tween] = nil
        for property in pairs(properties) do
            if channels[property] == tween then channels[property] = nil end
        end
        if self._channels[object] == channels and next(channels) == nil then self._channels[object] = nil end
    end)
    tween:Play()
end

function Window:_bindAccent(object, property, resolve)
    table.insert(self._accentBindings, { object = object, property = property, resolve = resolve })
    object[property] = resolve and resolve(self.Accent) or self.Accent
end

function Window:SetAccent(color)
    assert(typeof(color) == "Color3", "SetAccent expects Color3")
    self.Accent = color
    for _, entry in ipairs(self._accentBindings) do
        if entry.object.Parent then
            self:_animate(entry.object, { [entry.property] = entry.resolve and entry.resolve(color) or color })
        end
    end
    if self._layoutNotifications then self:_layoutNotifications() end
    if self._layoutFeatures then self:_layoutFeatures() end
end

function Window:_callback(callback, ...)
    if type(callback) ~= "function" or self._destroyed then return end
    local success, message = xpcall(callback, debug.traceback, ...)
    if not success then
        warn("[AURA callback] " .. tostring(message))
        self:Notify("操作未完成", "请查看控制台中的详细信息。")
    end
end

local screen = create("ScreenGui", {
    Name = "WhiteGlassUI_" .. id, ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 2147483000,
}, container)
Window.ScreenGui = screen

local blur = create("BlurEffect", { Name = "AURA_BackgroundBlur_" .. id, Size = 0, Enabled = false }, Lighting)
Window._blurEffect = blur

local host = create("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundTransparency = 1, Visible = false, ZIndex = 10,
}, screen)
Window.Frame = host
local uiScale = create("UIScale", { Scale = 1 }, host)

for layer = 9, 1, -1 do
    local spread = layer * 2
    local shadow = create("Frame", {
        Name = "Shadow", BackgroundColor3 = Color3.fromRGB(40, 51, 78),
        BackgroundTransparency = 0.983, Position = UDim2.fromOffset(-spread, 5 - spread),
        Size = UDim2.new(1, spread * 2, 1, spread * 2), ZIndex = 1,
    }, host)
    corner(shadow, 23 + spread)
end

local surface = create("CanvasGroup", {
    Name = "Glass", Size = UDim2.fromScale(1, 1), BackgroundColor3 = COLORS.White,
    BackgroundTransparency = Window.Transparency, ClipsDescendants = true, GroupTransparency = 1, Active = true, ZIndex = 10,
}, host)
corner(surface, 22)
stroke(surface, COLORS.White, 0.18)
create("UIGradient", {
    Rotation = 110, Color = ColorSequence.new(COLORS.White, Color3.fromRGB(245, 248, 254)),
}, surface)
Window._surface = surface

local sidebar = create("Frame", {
    Name = "Sidebar", Size = UDim2.new(0, SIDEBAR, 1, 0), BackgroundColor3 = COLORS.White,
    BackgroundTransparency = 0.35, ZIndex = 12,
}, surface)
create("Frame", {
    BackgroundColor3 = COLORS.Line, BackgroundTransparency = 0.5,
    Position = UDim2.new(1, -1, 0, 18), Size = UDim2.new(0, 1, 1, -36),
}, sidebar)

local brandMark = create("Frame", {
    Position = UDim2.fromOffset(28, 30), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Window.Accent,
}, sidebar)
corner(brandMark, 10)
Window:_bindAccent(brandMark, "BackgroundColor3")
local brandCenter = create("Frame", {
    BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.07,
    Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(12, 12), Rotation = 45,
}, brandMark)
corner(brandCenter, 4)
local brandTitle = label(sidebar, Window.Title, 23, UDim2.fromOffset(66, 28), UDim2.fromOffset(112, 32), COLORS.Text, BOLD)
brandTitle.TextTruncate = Enum.TextTruncate.AtEnd
label(sidebar, tostring(options.Subtitle or "为专注留一点空间"), 10, UDim2.fromOffset(29, 71), UDim2.fromOffset(156, 18), COLORS.Secondary)
label(sidebar, "工作空间", 10, UDim2.fromOffset(29, 118), UDim2.fromOffset(150, 18), COLORS.Muted, MEDIUM)

local nav = create("ScrollingFrame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 149), Size = UDim2.new(1, -32, 1, -245),
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 0, Active = true,
}, sidebar)
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, nav)

create("Frame", {
    Position = UDim2.new(0, 28, 1, -77), Size = UDim2.new(1, -56, 0, 1),
    BackgroundColor3 = COLORS.Line, BackgroundTransparency = 0.38,
}, sidebar)
local ready = create("Frame", {
    BackgroundColor3 = Color3.fromRGB(108, 166, 143), Position = UDim2.new(0, 30, 1, -48), Size = UDim2.fromOffset(6, 6),
}, sidebar)
corner(ready, 6)
label(sidebar, "一切就绪", 11, UDim2.new(0, 44, 1, -56), UDim2.fromOffset(100, 22), COLORS.Secondary)
label(sidebar, "01", 10, UDim2.new(1, -48, 1, -56), UDim2.fromOffset(25, 22), COLORS.Muted)

local header = create("Frame", {
    Name = "DragHandle", BackgroundTransparency = 1, Active = true,
    Position = UDim2.fromOffset(SIDEBAR, 0), Size = UDim2.new(1, -SIDEBAR - 100, 0, 86), ZIndex = 20,
}, surface)
local pageTitle = label(header, "概览", 15, UDim2.fromOffset(30, 27), UDim2.fromOffset(210, 22), COLORS.Text, MEDIUM)
local pageDescription = label(header, "你的空间，由你定义。", 11, UDim2.fromOffset(30, 52), UDim2.fromOffset(360, 18), COLORS.Secondary)

local function chromeButton(offset, name)
    local control = button(surface, {
        Position = UDim2.new(1, offset, 0, 27), Size = UDim2.fromOffset(30, 30), ZIndex = 35,
        BackgroundColor3 = COLORS.Hover,
    })
    corner(control, 9)
    icon(control, name, COLORS.Secondary, UDim2.fromOffset(5, 5))
    Window:_listen(control.MouseEnter, function() Window:_animate(control, { BackgroundTransparency = 0.15 }) end)
    Window:_listen(control.MouseLeave, function() Window:_animate(control, { BackgroundTransparency = 1 }) end)
    return control
end
local minimize = chromeButton(-89, "minus")
local close = chromeButton(-51, "close")

local pages = create("Frame", {
    Name = "Pages", Position = UDim2.fromOffset(SIDEBAR + 30, 96),
    Size = UDim2.new(1, -SIDEBAR - 60, 1, -139), BackgroundTransparency = 1, ZIndex = 20,
}, surface)
label(surface, tostring(options.Footer or "AURA  /  PERSONAL SPACE"), 9, UDim2.new(0, SIDEBAR + 31, 1, -29), UDim2.fromOffset(250, 14), COLORS.Muted)
local keyboardHint = label(surface, tostring(Window.ToggleKey):gsub("Enum.KeyCode.", "") .. "  显示 / 隐藏", 10, UDim2.new(1, -221, 1, -31), UDim2.fromOffset(190, 18), COLORS.Muted)
keyboardHint.TextXAlignment = Enum.TextXAlignment.Right

local launcher = button(screen, {
    Name = "RestoreWindow", Position = UDim2.new(0, 22, 1, -65), Size = UDim2.fromOffset(112, 42),
    BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.12, Text = Window.Title, TextSize = 15,
    Font = BOLD, TextTruncate = Enum.TextTruncate.AtEnd, Visible = false, ZIndex = 70,
})
corner(launcher, 15)
stroke(launcher, COLORS.White, 0.15)
local launcherDot = create("Frame", {
    Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Window.Accent,
}, launcher)
corner(launcherDot, 6)
Window:_bindAccent(launcherDot, "BackgroundColor3")

function Window:_viewport()
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function Window:_fit()
    if self._destroyed then return end
    self:_closeDropdown()
    local viewport = self:_viewport()
    if viewport.X < 1 or viewport.Y < 1 then return end
    self._scale = math.max(0.1, math.min(self.Zoom, (viewport.X - 32) / WIDTH, (viewport.Y - 32) / HEIGHT))
    uiScale.Scale = self._scale
    local half = Vector2.new(WIDTH, HEIGHT) * self._scale / 2
    local x = math.clamp(self._normalizedCenter.X * viewport.X, half.X + 12, math.max(half.X + 12, viewport.X - half.X - 12))
    local y = math.clamp(self._normalizedCenter.Y * viewport.Y, half.Y + 12, math.max(half.Y + 12, viewport.Y - half.Y - 12))
    host.Position = UDim2.fromOffset(x, y)
    if self._resizeNotifications then self:_resizeNotifications() end
    if self._layoutFeatures then self:_layoutFeatures() end
end

function Window:_safeArea()
    local viewport = self:_viewport()
    local left, top, right, bottom = 0, 58, 0, 0
    local ok, a, b = pcall(GuiService.GetGuiInset, GuiService)
    if ok and typeof(a) == "Vector2" and typeof(b) == "Vector2" then
        left, top, right, bottom = math.max(0, a.X), math.max(0, a.Y), math.max(0, b.X), math.max(0, b.Y)
    end
    local hasBar, bar = pcall(function() return GuiService.TopbarInset end)
    if hasBar and typeof(bar) == "Rect" then top = math.max(top, bar.Max.Y) end
    return left + 12, top + 12, math.max(left + 13, viewport.X - right - 12), math.max(top + 13, viewport.Y - bottom - 12)
end

local featureHost = create("ScrollingFrame", {
    Name = "EnabledFeatures", BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
    CanvasSize = UDim2.new(), ScrollBarThickness = 2, ScrollBarImageColor3 = COLORS.Muted,
    ScrollingDirection = Enum.ScrollingDirection.Y, Active = true, ZIndex = 120, ClipsDescendants = true,
}, screen)
Window.FeatureFrame = featureHost

function Window:_syncFeatureClock()
    local enabled = self.FeatureList.Enabled and self.FeatureList.Scrolling and (self._featureOverflow or 0) > 0
    if not enabled then
        if self._featureClock then self._featureClock:Disconnect(); self._connections[self._featureClock] = nil; self._featureClock = nil end
        return
    end
    if self._featureClock then return end
    self._featureClock = self:_listen(RunService.Heartbeat, function(dt)
        if type(dt) ~= "number" or dt ~= dt or dt <= 0 or self._featureHovered then return end
        local offset = (self._featureOffset or 0) + math.min(dt, 0.1) * self.FeatureList.Speed * (self._featureDirection or 1)
        local maximum = self._featureOverflow
        if offset >= maximum then offset = maximum; self._featureDirection = -1
        elseif offset <= 0 then offset = 0; self._featureDirection = 1 end
        self._featureOffset = offset
        featureHost.CanvasPosition = self._featureHorizontal and Vector2.new(offset, 0) or Vector2.new(0, offset)
    end)
end

function Window:_layoutFeatures()
    if self._destroyed then return end
    for _, child in ipairs(featureHost:GetChildren()) do child:Destroy() end
    local config, entries = self.FeatureList, {}
    local left, top, right, bottom = self:_safeArea()
    local availableWidth = math.max(1, right - left)
    for id, feature in pairs(self.Features) do
        local parent = feature.Parent and self.Controls[tostring(feature.Parent)]
        if feature.Enabled and (not feature.Parent or (parent and parent:GetValue())) then
            local ok, bounds = pcall(TextService.GetTextSize, TextService, feature.Title, 12, MEDIUM, Vector2.new(10000, 30))
            local measuredWidth = (ok and bounds.X or #feature.Title * 7) + 26
            table.insert(entries, { Id = id, Title = feature.Title, Width = math.min(availableWidth, measuredWidth), SortWidth = measuredWidth })
        end
    end
    table.sort(entries, function(a, b) if a.SortWidth == b.SortWidth then return a.Id < b.Id end; return a.SortWidth > b.SortWidth end)
    self._featureEntries = entries
    featureHost.Visible = config.Enabled and #entries > 0
    self._featureOffset, self._featureDirection = 0, 1
    featureHost.CanvasPosition = Vector2.new()
    local horizontal = config.Position == "TopCenter" or config.Position == "BottomCenter"
    self._featureHorizontal = horizontal
    if config.Position == "BottomRight" then
        for _, notice in ipairs(self._notifications) do bottom = bottom - notice.Height - 10 end
        bottom = math.max(top + 1, bottom - (#self._notifications > 0 and 8 or 0))
    end
    local total, widest = 0, 0
    for _, entry in ipairs(entries) do total = total + (horizontal and entry.Width + 6 or 32); widest = math.max(widest, entry.Width) end
    total = math.max(0, total - (horizontal and 6 or 4))
    local width = horizontal and math.min(availableWidth, total) or widest
    local height = horizontal and 28 or math.min(total, config.MaxHeight, math.max(1, bottom - top))
    width, height = math.max(1, width), math.max(1, height)
    local x = config.Position == "TopLeft" and left or horizontal and (left + right - width) / 2 or right - width
    local y = (config.Position == "BottomRight" or config.Position == "BottomCenter") and bottom - height or top
    featureHost.Position = UDim2.fromOffset(x, y)
    featureHost.Size = UDim2.fromOffset(width, height)
    featureHost.CanvasSize = horizontal and UDim2.fromOffset(total, height) or UDim2.fromOffset(width, total)
    featureHost.ScrollingDirection = horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
    self._featureOverflow = math.max(0, total - (horizontal and width or height))
    if config.Position == "BottomRight" and self._featureOverflow > 0 then
        self._featureOffset, self._featureDirection = self._featureOverflow, -1
        featureHost.CanvasPosition = Vector2.new(0, self._featureOverflow)
    end
    local offset = 0
    for index, entry in ipairs(entries) do
        local rowY = config.Position == "BottomRight" and total - 28 - offset or offset
        local chip = create("Frame", {
            Name = "Feature_" .. entry.Id, BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.12,
            Position = horizontal and UDim2.fromOffset(offset, 0) or UDim2.fromOffset(config.Position == "TopLeft" and 0 or width - entry.Width, rowY),
            Size = UDim2.fromOffset(entry.Width, 28), ZIndex = 121,
        }, featureHost)
        corner(chip, 7)
        local text = label(chip, entry.Title, 12, UDim2.fromOffset(12, 0), UDim2.new(1, -22, 1, 0), self.Accent, MEDIUM)
        text.TextTruncate = Enum.TextTruncate.AtEnd
        offset = offset + (horizontal and entry.Width + 6 or 32)
    end
    self:_syncFeatureClock()
end

function Window:SetFeature(id, title, enabled, parent)
    if self._destroyed then return self end
    self.Features[tostring(id)] = { Title = tostring(title), Enabled = enabled == true, Parent = parent }
    self:_layoutFeatures()
    return self
end

function Window:SetFeatureList(options)
    if self._destroyed then return self end
    assert(type(options) == "table", "SetFeatureList expects a table")
    local positions = { TopLeft = true, TopRight = true, BottomRight = true, TopCenter = true, BottomCenter = true }
    if options.Position ~= nil then assert(positions[options.Position], "Unsupported feature list position"); self.FeatureList.Position = options.Position end
    if options.Enabled ~= nil then self.FeatureList.Enabled = options.Enabled == true end
    if options.Scrolling ~= nil then self.FeatureList.Scrolling = options.Scrolling == true end
    self.FeatureList.Speed = number(options.Speed, self.FeatureList.Speed, 5, 120)
    self.FeatureList.MaxHeight = number(options.MaxHeight, self.FeatureList.MaxHeight, 28, 600)
    self:_layoutFeatures()
    return self
end

Window:_listen(featureHost.MouseEnter, function() Window._featureHovered = true end)
Window:_listen(featureHost.MouseLeave, function() Window._featureHovered = false end)
local insetSignalOK, insetSignal = pcall(GuiService.GetPropertyChangedSignal, GuiService, "TopbarInset")
if insetSignalOK then Window:_listen(insetSignal, function() Window:_layoutFeatures(); Window:_resizeNotifications() end) end

function Window:_refreshGlass()
    if self._destroyed then return end
    self:_animate(surface, { BackgroundTransparency = self.Glass and self.Transparency or 0 }, 0.24)
    local useBlur = self.Visible and self.Glass and self.Blur > 0
    if useBlur then blur.Enabled = true end
    self:_animate(blur, { Size = useBlur and self.Blur or 0 }, 0.24)
    self._blurVersion = (self._blurVersion or 0) + 1
    local version = self._blurVersion
    if not useBlur then
        self:_later(self.Motion and 0.25 or 0, function()
            if version == self._blurVersion then blur.Enabled = false end
        end)
    end
end

function Window:SetVisible(visible)
    if self._destroyed then return end
    self:_cancelKeyCapture()
    self.Visible = visible == true
    self:_syncMouse()
    self._visibilityVersion = (self._visibilityVersion or 0) + 1
    local version = self._visibilityVersion
    self:_closeDropdown()
    self._pointer = nil
    launcher.Visible = not self.Visible
    if self.Visible then
        host.Visible = true
        self:_fit()
        self:_animate(surface, { GroupTransparency = 0 }, 0.26)
    else
        self:_animate(surface, { GroupTransparency = 1 }, 0.18)
        self:_later(self.Motion and 0.19 or 0, function()
            if version == self._visibilityVersion and not self.Visible then host.Visible = false end
        end)
    end
    self:_refreshGlass()
end

local Notification = {}
Notification.__index = Notification
local NOTICE_COLORS = {
    success = Color3.fromRGB(47, 139, 106), warning = Color3.fromRGB(184, 132, 39),
    error = Color3.fromRGB(205, 85, 95),
}

function Window:_notificationCapacity()
    local _, top, _, bottom = self:_safeArea()
    return math.min(self.NotificationLimit, math.max(1, math.floor((bottom - top) / 152)))
end

function Window:_dropNotificationVisual(notice)
    for _, connection in ipairs(notice._connections or {}) do
        connection:Disconnect()
        self._connections[connection] = nil
    end
    notice._connections = {}
    if notice.Frame then notice.Frame:Destroy(); notice.Frame = nil end
    notice.Hovered = false
end

function Window:_measureNotification(notice)
    local width = math.max(96, math.min(360, self:_viewport().X - 32))
    local bodyWidth = math.max(24, width - 76)
    local measured, bounds = pcall(TextService.GetTextSize, TextService, notice.Content, 12, FONT, Vector2.new(bodyWidth, 10000))
    local bodyHeight = notice.Content == "" and 0 or math.clamp(measured and bounds.Y or 36, 18, 72)
    notice.Width, notice.Height = width, bodyHeight == 0 and 64 or 56 + bodyHeight
    if notice.Frame then
        notice.Frame.Size = UDim2.fromOffset(width, notice.Height)
        notice._body.Size = UDim2.new(1, -76, 0, bodyHeight)
        notice._body.Visible = bodyHeight > 0
    end
end

function Window:_refreshNotification(notice)
    if not notice.Frame then return end
    local kind = notice.Type == "success" and "success" or notice.Type == "warning" and "warning" or notice.Type == "error" and "close" or "info"
    if notice._kind ~= kind then
        if notice._glyph then notice._glyph:Destroy() end
        notice._glyph, notice._iconParts = icon(notice._badge, kind, self.Accent, UDim2.fromOffset(3.5, 3.5))
        notice._kind = kind
    end
    local color = NOTICE_COLORS[notice.Type] or self.Accent
    notice._title.Text = notice.Title
    notice._body.Text = notice.Content
    notice._badge.BackgroundColor3 = color
    for _, part in ipairs(notice._iconParts) do
        part[part:IsA("UIStroke") and "Color" or "BackgroundColor3"] = color
    end
    notice._progress.BackgroundColor3 = color
    notice._progressTrack.Visible = notice.Duration > 0
    notice._progress.Size = UDim2.fromScale(notice.Duration > 0 and math.clamp(notice.Remaining / notice.Duration, 0, 1) or 1, 1)
    self:_measureNotification(notice)
end

function Window:_renderNotification(notice)
    self:_measureNotification(notice)
    local toast = create("CanvasGroup", {
        Name = "Notification", AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 24, 1, -18), Size = UDim2.fromOffset(notice.Width, notice.Height),
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.045,
        GroupTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 100,
    }, screen)
    notice.Frame = toast
    corner(toast, 15); stroke(toast, COLORS.Line, 0.3)
    local badge = create("Frame", {
        Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(27, 27),
        BackgroundColor3 = self.Accent, BackgroundTransparency = 0.9,
    }, toast)
    corner(badge, 9)

    notice._badge, notice._iconParts = badge, {}
    notice._title = label(toast, notice.Title, 12, UDim2.fromOffset(54, 13), UDim2.new(1, -91, 0, 23), COLORS.Text, MEDIUM)
    notice._title.TextTruncate = Enum.TextTruncate.AtEnd
    notice._body = label(toast, notice.Content, 12, UDim2.fromOffset(54, 39), UDim2.new(1, -76, 0, 36), COLORS.Secondary)
    notice._body.TextYAlignment = Enum.TextYAlignment.Top
    notice._body.TextWrapped = true
    notice._body.TextTruncate = Enum.TextTruncate.AtEnd
    local dismiss = button(toast, {
        Position = UDim2.new(1, -30, 0, 12), Size = UDim2.fromOffset(21, 21),
        BackgroundColor3 = COLORS.Hover, ZIndex = 108,
    })
    corner(dismiss, 7)
    icon(dismiss, "close", COLORS.Muted, UDim2.fromOffset(0.5, 0.5))
    local progressTrack = create("Frame", {
        Position = UDim2.new(0, 15, 1, -9), Size = UDim2.new(1, -30, 0, 2),
        BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0.65,
    }, toast)
    corner(progressTrack, 3)
    notice._progressTrack = progressTrack
    notice._progress = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = self.Accent }, progressTrack)
    corner(notice._progress, 3)
    notice._connections = {
        self:_listen(dismiss.Activated, function() notice:Dismiss("manual") end),
        self:_listen(toast.MouseEnter, function() notice.Hovered = true end),
        self:_listen(toast.MouseLeave, function() notice.Hovered = false end),
        self:_listen(dismiss.MouseEnter, function() self:_animate(dismiss, { BackgroundTransparency = 0.15 }) end),
        self:_listen(dismiss.MouseLeave, function() self:_animate(dismiss, { BackgroundTransparency = 1 }) end),
    }
    self:_refreshNotification(notice)
end

function Window:_layoutNotifications()
    local offset = 18
    for index = #self._notifications, 1, -1 do
        local notice = self._notifications[index]
        if notice.Frame then
            self:_refreshNotification(notice)
            self:_animate(notice.Frame, { Position = UDim2.new(1, -18, 1, -offset), GroupTransparency = 0 }, 0.24)
            offset = offset + notice.Height + 10
        end
    end
    self:_layoutFeatures()
end

function Window:_syncNotificationClock()
    local needed = false
    for _, notice in ipairs(self._notifications) do
        if notice.Status == "active" and notice.Duration > 0 then needed = true; break end
    end
    if not needed then
        if self._notificationClock then
            self._notificationClock:Disconnect()
            self._connections[self._notificationClock] = nil
            self._notificationClock = nil
        end
        return
    end
    if self._notificationClock and self._notificationClock.Connected then return end
    self._notificationClock = self:_listen(RunService.Heartbeat, function(dt)
        if type(dt) ~= "number" or dt ~= dt or dt <= 0 then return end
        for _, notice in ipairs(table.clone(self._notifications)) do
            if notice.Status == "active" and notice.Duration > 0 and not (notice.PauseOnHover and notice.Hovered) then
                notice.Remaining = math.max(0, notice.Remaining - dt)
                notice._progress.Size = UDim2.fromScale(notice.Remaining / notice.Duration, 1)
                if notice.Remaining <= 0 then notice:Dismiss("timeout") end
            end
        end
    end)
end

function Window:_pumpNotifications()
    if self._destroyed or self._clearingNotifications then return end
    while #self._notificationQueue > 0 and #self._notifications < self:_notificationCapacity() do
        local notice = table.remove(self._notificationQueue, 1)
        notice.Status = "active"
        table.insert(self._notifications, notice)
        self:_renderNotification(notice)
    end
    self:_layoutNotifications()
    self:_syncNotificationClock()
end

function Window:_resizeNotifications()
    if self._destroyed then return end
    while #self._notifications > self:_notificationCapacity() do
        self._notifications[1]:Dismiss("overflow")
    end
    self:_pumpNotifications()
end

function Notification:Dismiss(reason)
    local ui = self.Window
    if self.Status == "closed" or ui._destroyed then return false end
    self.Status = "closed"
    for _, list in ipairs({ ui._notificationQueue, ui._notifications }) do
        local index = table.find(list, self)
        if index then table.remove(list, index) end
    end
    if ui._notificationMap[self.Id] == self then ui._notificationMap[self.Id] = nil end
    for _, connection in ipairs(self._connections or {}) do connection:Disconnect(); ui._connections[connection] = nil end
    self._connections = {}
    local frame = self.Frame
    self.Frame = nil
    if frame then
        if reason == "overflow" then frame:Destroy()
        else
            ui:_animate(frame, { GroupTransparency = 1, Position = UDim2.new(1, self.Width + 20, frame.Position.Y.Scale, frame.Position.Y.Offset) }, 0.18)
            ui:_later(ui.Motion and 0.19 or 0, function() frame:Destroy() end)
        end
    end
    ui:_pumpNotifications()
    ui:_callback(self.OnClose, reason or "manual")
    return true
end

function Notification:Update(options)
    if self.Status == "closed" or self.Window._destroyed then return self end
    assert(type(options) == "table", "Notification:Update expects a table")
    if options.Title ~= nil then self.Title = tostring(options.Title) end
    if options.Content ~= nil or options.Message ~= nil then self.Content = tostring(options.Content or options.Message or "") end
    if options.Type ~= nil then self.Type = tostring(options.Type):lower() end
    if options.Duration ~= nil then
        self.Duration = number(options.Duration, self.Window.NotificationDuration, 0, 3600)
        self.Remaining = self.Duration
    end
    if options.PauseOnHover ~= nil then self.PauseOnHover = options.PauseOnHover ~= false end
    if options.OnClose ~= nil then self.OnClose = options.OnClose end
    self.Window:_layoutNotifications()
    self.Window:_syncNotificationClock()
    return self
end

function Window:Notify(options, message, duration)
    if self._destroyed then return nil end
    if type(options) ~= "table" then options = { Title = options, Content = message, Duration = duration } end
    local explicitId = options.Id ~= nil and tostring(options.Id) or nil
    local existing = explicitId and self._notificationMap[explicitId]
    if existing then return existing:Update(options) end
    repeat self._notificationCounter = self._notificationCounter + 1
    until self._notificationMap["auto:" .. self._notificationCounter] == nil
    local notice = setmetatable({
        Window = self, Id = explicitId or ("auto:" .. self._notificationCounter), Status = "queued",
        Title = tostring(options.Title or "提示"), Content = tostring(options.Content or options.Message or ""),
        Type = tostring(options.Type or "info"):lower(), OnClose = options.OnClose,
        Duration = number(options.Duration, self.NotificationDuration, 0, 3600),
        PauseOnHover = options.PauseOnHover ~= false, Hovered = false,
    }, Notification)
    notice.Remaining = notice.Duration

    while #self._notifications >= self:_notificationCapacity() do self._notifications[1]:Dismiss("overflow") end
    self._notificationMap[notice.Id] = notice
    table.insert(self._notificationQueue, notice)
    self:_pumpNotifications()
    return notice
end

function Window:GetNotification(id)
    return self._notificationMap[tostring(id)]
end

function Window:ClearNotifications()
    self._clearingNotifications = true
    for _, list in ipairs({ table.clone(self._notifications), table.clone(self._notificationQueue) }) do
        for _, notice in ipairs(list) do notice:Dismiss("clear") end
    end
    self._clearingNotifications = false
    self:_pumpNotifications()
end

function Window:_closeDropdown()
    if self._dropdown then self._dropdown:Destroy(); self._dropdown = nil end
    self._dropdownOwner = nil
    local cleanup = self._dropdownCleanup
    self._dropdownCleanup = nil
    if cleanup then cleanup() end
end

function Window:_cancelKeyCapture()
    local picker = Environment.__AuraKeyCapture
    if picker and picker.Window == self then
        picker.Capturing = false
        Environment.__AuraKeyCapture = nil
        picker:_refresh()
    end
end

function Window:_releaseKeyHolds()
    self:_cancelKeyCapture()
    for _, picker in ipairs(self._keyPickers) do picker:_release() end
end

local function bindingName(value)
    if value == nil or value == false or value == "" or value == "None" then return "None" end
    if typeof(value) == "EnumItem" then
        if value.EnumType ~= Enum.KeyCode then return nil end
        value = value.Name
    end
    if value == "Escape" then return "None" end
    if type(value) ~= "string" then return nil end
    local ok, key = pcall(function() return Enum.KeyCode[value] end)
    if not ok or not key or key == Enum.KeyCode.Unknown then return nil end
    return key.Name
end

function Window:_addKeyPicker(toggle, row, options)
    assert(not self._destroyed, "This AURA window has been destroyed")
    assert(not toggle.KeyPicker, "This toggle already has a key picker")
    options = options or {}
    if options.Id ~= nil then assert(self.Controls[tostring(options.Id)] == nil, "Duplicate control Id: " .. tostring(options.Id)) end
    local mode = options.Mode or "Toggle"
    assert(mode == "Toggle" or mode == "Hold", "Key picker Mode must be Toggle or Hold")
    local initial = bindingName(options.Default)
    assert(initial, "Invalid default key binding")
    local ui = self
    local badge = button(row, {
        Name = "KeyBinding", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -74, 0.5, 0),
        Size = UDim2.fromOffset(62, 26), Text = "None", TextSize = 11, BackgroundColor3 = COLORS.White,
        BackgroundTransparency = 0.1, ZIndex = row.ZIndex + 8,
    })
    corner(badge, 7)
    local outline = stroke(badge, COLORS.Line, 0.15)
    local picker = { Window = self, Toggle = toggle, Button = badge, Value = initial, Mode = mode, Capturing = false, _down = false, _held = false }
    function picker:_refresh()
        if ui._destroyed then return end
        badge.Text = self.Capturing and "..." or self.Value
        local ok, bounds = pcall(TextService.GetTextSize, TextService, badge.Text, 11, MEDIUM, Vector2.new(500, 30))
        badge.Size = UDim2.fromOffset(math.clamp((ok and bounds.X or #badge.Text * 6) + 20, 54, 116), 26)
        outline.Color = self.Capturing and ui.Accent or COLORS.Line
        badge.TextColor3 = self.Capturing and ui.Accent or COLORS.Secondary
    end
    function picker:_release()
        self._down = false
        if self._held then self._held = false; toggle:SetValue(false) end
    end
    function picker:SetValue(value, silent)
        if ui._destroyed then return self end
        local name = bindingName(value)
        if not name then return self end
        self:_release()
        if Environment.__AuraKeyCapture == self then ui:_cancelKeyCapture() end
        self.Value = name
        self:_refresh()
        if not silent then ui:_callback(options.Callback, self.Value, self.Mode) end
        return self
    end
    function picker:GetValue() return self.Value end
    function picker:SetMode(value, silent)
        if ui._destroyed then return self end
        assert(value == "Toggle" or value == "Hold", "Key picker Mode must be Toggle or Hold")
        self:_release()
        self.Mode = value
        if value == "Hold" and toggle:GetValue() then toggle:SetValue(false) end
        if ui._dropdownOwner == self then ui:_closeDropdown() end
        if not silent then ui:_callback(options.Callback, self.Value, self.Mode) end
        return self
    end
    function picker:GetMode() return self.Mode end
    function picker:BeginCapture()
        if ui._destroyed or not ui.Visible then return self end
        local previous = Environment.__AuraKeyCapture
        if previous then previous.Window:_cancelKeyCapture() end
        ui:_closeDropdown()
        ui:_releaseKeyHolds()
        self.Capturing = true
        Environment.__AuraKeyCapture = self
        self:_refresh()
        return self
    end
    function picker:_begin()
        if self._down then return end
        self._down = true
        if self.Mode == "Hold" then self._held = true; toggle:SetValue(true)
        else toggle:SetValue(not toggle:GetValue()) end
    end
    function picker:OpenModeMenu()
        if ui._destroyed or not ui.Visible then return end
        ui:_cancelKeyCapture()
        local same = ui._dropdownOwner == self
        ui:_closeDropdown()
        if same then return end
        local overlay = button(screen, { Name = "KeyModeOverlay", Size = UDim2.fromScale(1, 1), ZIndex = 80 })
        ui._dropdown, ui._dropdownOwner = overlay, self
        ui._dropdownCleanup = function() self.Menu = nil end
        ui:_listen(overlay.Activated, function() ui:_closeDropdown() end)
        local viewport = ui:_viewport()
        local width, height = math.min(120, math.max(60, viewport.X - 16)), 80
        local x = math.clamp(badge.AbsolutePosition.X + badge.AbsoluteSize.X - width, 8, math.max(8, viewport.X - width - 8))
        local y = badge.AbsolutePosition.Y + badge.AbsoluteSize.Y + 5
        if y + height > viewport.Y - 8 then y = math.max(8, badge.AbsolutePosition.Y - height - 5) end
        local menu = create("Frame", { Name = "KeyModeMenu", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height), BackgroundColor3 = COLORS.White, ZIndex = 85 }, overlay)
        corner(menu, 10); stroke(menu, COLORS.Line, 0.15)
        self.Menu = menu
        for index, value in ipairs({ "Toggle", "Hold" }) do
            local item = button(menu, {
                Name = value, Position = UDim2.fromOffset(5, 5 + (index - 1) * 35), Size = UDim2.new(1, -10, 0, 35),
                Text = value, BackgroundColor3 = COLORS.Hover, BackgroundTransparency = self.Mode == value and 0 or 1,
                TextColor3 = self.Mode == value and ui.Accent or COLORS.Secondary, TextSize = 11, ZIndex = 86,
            })
            corner(item, 6)
            ui:_listen(item.Activated, function() self:SetMode(value) end)
        end
    end
    ui:_listen(badge.Activated, function() picker:BeginCapture() end)
    ui:_listen(badge.MouseButton2Click, function() picker:OpenModeMenu() end)
    picker:_refresh()
    if mode == "Hold" and toggle:GetValue() then toggle:SetValue(false) end
    table.insert(self._keyPickers, picker)
    toggle.KeyPicker = picker
    if options.Id ~= nil then self.Controls[tostring(options.Id)] = picker end
    return picker
end

function Window:SetTitle(title)
    if self._destroyed then return self end
    self.Title = tostring(title or "aura")
    brandTitle.Text, launcher.Text = self.Title, self.Title
    return self
end

function Window:SetGlass(enabled)
    if not self._destroyed then self.Glass = enabled == true; self:_refreshGlass() end
    return self
end

function Window:SetBlur(value)
    if not self._destroyed then self.Blur = number(value, self.Blur, 0, 56); self:_refreshGlass() end
    return self
end

function Window:SetMotion(enabled)
    self.Motion = enabled == true
    return self
end

function Window:SetTransparency(value)
    if not self._destroyed then self.Transparency = number(value, self.Transparency, 0, 0.8); self:_refreshGlass() end
    return self
end

function Window:SetScale(value)
    if not self._destroyed then self.Zoom = number(value, self.Zoom, 0.5, 1.5); self:_fit() end
    return self
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
    return self
end

function Window:_syncMouse()
    minimize.Modal = self.Visible and self.UnlockMouse and not self._destroyed
    if self.Visible and self.UnlockMouse and not self._destroyed then Mouse:Acquire(self)
    else Mouse:Release(self) end
end

function Window:SetMouseUnlocked(enabled)
    if self._destroyed then return self end
    self.UnlockMouse = enabled == true
    self:_syncMouse()
    return self
end

function Window:GetControl(id) return self.Controls[tostring(id)] end
function Window:GetTab(id) return self.TabMap[tostring(id)] end

function Window:SelectTab(tab)
    if type(tab) == "string" then tab = self.TabMap[tab] end
    if self._destroyed or not table.find(self.Tabs, tab) then return end
    self:_cancelKeyCapture()
    self:_closeDropdown()
    self._pointer = nil
    self._selectedTab = tab
    for _, item in ipairs(self.Tabs) do
        local selected = item == tab
        item.Page.Visible = selected
        self:_animate(item.Button, { BackgroundTransparency = selected and 0.82 or 1 })
        self:_animate(item.TitleLabel, { TextColor3 = selected and self.Accent or COLORS.Secondary })
        item.Indicator.Visible = selected
        for _, part in ipairs(item.IconParts) do
            self:_animate(part, { [part:IsA("UIStroke") and "Color" or "BackgroundColor3"] = selected and self.Accent or COLORS.Secondary })
        end
    end
    pageTitle.Text = tab.Title
    pageDescription.Text = tab.Description
end

local Tab, Section = {}, {}
Tab.__index, Section.__index = Tab, Section

function Window:CreateTab(options)
    assert(not self._destroyed, "This AURA window has been destroyed")
    options = options or {}
    local tabId = tostring(options.Id or options.Title or ("tab:" .. (#self.Tabs + 1)))
    assert(self.TabMap[tabId] == nil, "Duplicate tab Id: " .. tabId)
    local tab = setmetatable({
        Id = tabId, Window = self, Title = options.Title or "新页面", Description = options.Description or "你的空间，由你定义。",
    }, Tab)
    local navButton = button(nav, {
        Name = "Tab", LayoutOrder = #self.Tabs + 1, Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = self.Accent, BackgroundTransparency = 1,
    })
    corner(navButton, 11)
    self:_bindAccent(navButton, "BackgroundColor3")
    local _, parts = icon(navButton, options.Icon or "grid", COLORS.Secondary, UDim2.fromOffset(15, 11))
    local title = label(navButton, tab.Title, 12, UDim2.fromOffset(48, 0), UDim2.new(1, -68, 1, 0), COLORS.Secondary, MEDIUM)
    local indicator = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 16), BackgroundColor3 = self.Accent, Visible = false,
    }, navButton)
    corner(indicator, 3)
    self:_bindAccent(indicator, "BackgroundColor3")
    self:_bindAccent(title, "TextColor3", function(accent) return self._selectedTab == tab and accent or COLORS.Secondary end)
    for _, part in ipairs(parts) do
        self:_bindAccent(part, part:IsA("UIStroke") and "Color" or "BackgroundColor3", function(accent)
            return self._selectedTab == tab and accent or COLORS.Secondary
        end)
    end
    local page = create("ScrollingFrame", {
        Name = "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Muted, ScrollBarImageTransparency = 0.5,
        Visible = false, Active = true, ZIndex = 22,
    }, pages)
    create("UIPadding", { PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 1), PaddingLeft = UDim.new(0, 1) }, page)
    create("UIListLayout", { Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    tab.Page, tab.Button, tab.TitleLabel, tab.Indicator, tab.IconParts = page, navButton, title, indicator, parts
    tab._order = 0
    table.insert(self.Tabs, tab)
    self.TabMap[tabId] = tab
    self:_listen(navButton.Activated, function() self:SelectTab(tab) end)
    self:_listen(navButton.MouseEnter, function()
        if self._selectedTab ~= tab then self:_animate(navButton, { BackgroundTransparency = 0.94 }) end
    end)
    self:_listen(navButton.MouseLeave, function()
        if self._selectedTab ~= tab then self:_animate(navButton, { BackgroundTransparency = 1 }) end
    end)
    if #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function Tab:AddSection(options)
    options = options or {}
    self._order += 1
    local card = create("Frame", {
        Name = "Section", LayoutOrder = self._order, Size = UDim2.new(1, -1, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = COLORS.White,
        BackgroundTransparency = 0.3, ZIndex = 25,
    }, self.Page)
    corner(card, 16); stroke(card, COLORS.Line, 0.4)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
    local headerRow = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, options.Description and 72 or 51), LayoutOrder = 0,
    }, card)
    label(headerRow, options.Title or "偏好设置", 13, UDim2.fromOffset(20, 14), UDim2.new(1, -40, 0, 25), COLORS.Text, MEDIUM)
    if options.Description then
        label(headerRow, options.Description, 11, UDim2.fromOffset(20, 40), UDim2.new(1, -40, 0, 18), COLORS.Secondary)
    end
    return setmetatable({ Window = self.Window, Frame = card, _order = 0 }, Section)
end

function Section:_register(options, control)
    if options.Id ~= nil then
        local id = tostring(options.Id)
        assert(self.Window.Controls[id] == nil, "Duplicate control Id: " .. id)
        self.Window.Controls[id] = control
    end
    return control
end

function Section:_row(options, height)
    if options.Id ~= nil then assert(self.Window.Controls[tostring(options.Id)] == nil, "Duplicate control Id: " .. tostring(options.Id)) end
    self._order += 1
    local row = create("Frame", {
        Name = "Control", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 66), LayoutOrder = self._order,
    }, self.Frame)
    create("Frame", {
        BackgroundColor3 = COLORS.Line, BackgroundTransparency = 0.65,
        Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -40, 0, 1),
    }, row)
    local hasDescription = options.Description ~= nil
    local stacked = hasDescription or (height or 66) > 70
    local text = label(row, options.Title or "选项", 12, UDim2.fromOffset(20, stacked and 12 or 0),
        UDim2.new(1, -245, 0, stacked and 23 or (height or 66)), COLORS.Text, MEDIUM)
    text.TextTruncate = Enum.TextTruncate.AtEnd
    if hasDescription then
        local description = label(row, options.Description, 10, UDim2.fromOffset(20, 37), UDim2.new(1, -245, 0, 17), COLORS.Secondary)
        description.TextTruncate = Enum.TextTruncate.AtEnd
    end
    return row
end

function Section:AddToggle(options)
    options = options or {}
    local ui = self.Window
    local row = self:_row(options, 66)
    local hit = button(row, { Size = UDim2.fromScale(1, 1) })
    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -21, 0.5, 0),
        Size = UDim2.fromOffset(40, 23), BackgroundColor3 = COLORS.Track,
    }, hit)
    corner(track, 30)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(17, 17), BackgroundColor3 = COLORS.White,
    }, track)
    corner(knob, 30)
    local control = { Value = options.Default == true, Frame = row }
    function control:SetValue(value, silent)
        if ui._destroyed then return end
        self.Value = value == true
        ui:_animate(track, { BackgroundColor3 = self.Value and ui.Accent or COLORS.Track })
        ui:_animate(knob, { Position = UDim2.new(0, self.Value and 20 or 3, 0.5, 0) })
        if not silent then ui:_callback(options.Callback, self.Value) end
        if options.FeatureList ~= false then ui:SetFeature(options.Id or control._featureId, options.FeatureTitle or options.Title or "Toggle", self.Value, options.ParentFeature) end
    end
    function control:GetValue() return self.Value end
    function control:AddKeyPicker(keyOptions) return ui:_addKeyPicker(self, row, keyOptions) end
    ui:_bindAccent(track, "BackgroundColor3", function(accent) return control.Value and accent or COLORS.Track end)
    ui:_listen(hit.Activated, function() control:SetValue(not control.Value) end)
    control._featureId = "toggle:" .. tostring(row)
    control:SetValue(control.Value, true)
    return self:_register(options, control)
end

function Section:AddLabel(text)
    local row = self:_row({ Title = "" }, 42)
    return label(row, tostring(text), 11, UDim2.fromOffset(20, 0), UDim2.new(1, -40, 1, 0), COLORS.Secondary)
end

function Section:AddSlider(options)
    options = options or {}
    local ui = self.Window
    local minimum, maximum = options.Min or 0, options.Max or 100
    assert(maximum > minimum, "Slider Max must exceed Min")
    local precision = math.clamp(math.floor(options.Decimals or 0), 0, 4)
    local multiplier = 10 ^ precision
    local row = self:_row(options, options.Description and 92 or 79)
    local badge = label(row, "", 11, UDim2.new(1, -125, 0, 13), UDim2.fromOffset(104, 20), COLORS.Secondary, MEDIUM)
    badge.TextXAlignment = Enum.TextXAlignment.Right
    local hit = button(row, { Position = UDim2.new(0, 22, 1, -35), Size = UDim2.new(1, -44, 0, 25) })
    local track = create("Frame", {
        Position = UDim2.new(0, 0, 0.5, -2), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = COLORS.Track,
    }, hit)
    corner(track, 5)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ui.Accent }, track)
    corner(fill, 5); ui:_bindAccent(fill, "BackgroundColor3")
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(13, 13), BackgroundColor3 = COLORS.White,
    }, track)
    corner(knob, 20)
    ui:_bindAccent(stroke(knob, ui.Accent, 0, 2), "Color")
    local control = { Value = minimum }
    function control:SetValue(value, silent)
        if ui._destroyed then return end
        value = tonumber(value)
        if not value or value ~= value or math.abs(value) == math.huge then return end
        self.Value = math.clamp(math.floor(value * multiplier + 0.5) / multiplier, minimum, maximum)
        local fraction = (self.Value - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(fraction, 1)
        knob.Position = UDim2.fromScale(fraction, 0.5)
        badge.Text = string.format("%." .. precision .. "f", self.Value) .. (options.Suffix or "")
        if not silent then ui:_callback(options.Callback, self.Value) end
    end
    function control:GetValue() return self.Value end
    local function move(position)
        if hit.AbsoluteSize.X > 0 then
            local fraction = math.clamp((position.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
            control:SetValue(minimum + fraction * (maximum - minimum))
        end
    end
    ui:_listen(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ui._pointer = { input = input, move = move }
            move(input.Position)
        end
    end)
    control:SetValue(options.Default or minimum, true)
    return self:_register(options, control)
end

function Section:AddColorPicker(options)
    options = options or {}
    local ui = self.Window
    local baseHeight = options.Description and 82 or 66
    local row = self:_row(options, baseHeight)
    local field = button(row, {
        Name = "ColorPreview", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 17),
        Size = UDim2.fromOffset(180, 33), BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.25,
    })
    corner(field, 9); stroke(field, COLORS.Line, 0.25)
    local preview = create("Frame", {
        Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(17, 17), BackgroundColor3 = ui.Accent,
    }, field)
    corner(preview, 5); stroke(preview, COLORS.Line, 0.3)
    local hex = label(field, "", 11, UDim2.fromOffset(37, 0), UDim2.new(1, -68, 1, 0), COLORS.Secondary, MEDIUM)
    icon(field, "chevron", COLORS.Muted, UDim2.new(1, -28, 0.5, -10))
    local panel = create("Frame", {
        Name = "ColorPalette", BackgroundTransparency = 1, Visible = false,
        Position = UDim2.fromOffset(20, baseHeight), Size = UDim2.new(1, -40, 0, 210),
    }, row)
    local sv = button(panel, {
        Name = "SaturationValue", Size = UDim2.new(1, -42, 0, 160),
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0, ClipsDescendants = true,
    })
    corner(sv, 9)
    local spectrum = create("UIGradient", { Color = ColorSequence.new(COLORS.White, Color3.fromRGB(255, 0, 0)) }, sv)
    local shade = button(sv, {
        Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0,
    })
    corner(shade, 9)
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, shade)
    local marker = create("Frame", {
        Name = "Selection", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
    }, shade)
    corner(marker, 20); stroke(marker, COLORS.White, 0, 2)
    local dot = create("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 1 }, marker)
    corner(dot, 20); stroke(dot, COLORS.Text, 0.15, 1)
    local hue = button(panel, {
        Name = "HueSpectrum", Position = UDim2.new(1, -24, 0, 0), Size = UDim2.fromOffset(24, 160),
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0,
    })
    corner(hue, 8)
    local stops = {}
    for index = 0, 6 do stops[index + 1] = ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1)) end
    create("UIGradient", { Color = ColorSequence.new(stops), Rotation = 90 }, hue)
    local hueMarker = create("Frame", {
        Name = "HueSelection", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.new(1, 4, 0, 5), BackgroundTransparency = 1,
    }, hue)
    corner(hueMarker, 3); stroke(hueMarker, COLORS.White, 0, 2)
    local control = { Value = ui.Accent, Expanded = false, Frame = row, H = 0, S = 1, V = 1 }
    local function apply(h, s, v, silent)
        if ui._destroyed then return end
        control.H, control.S, control.V = h, s, v
        control.Value = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = control.Value
        spectrum.Color = ColorSequence.new(COLORS.White, Color3.fromHSV(h, 1, 1))
        marker.Position = UDim2.fromScale(s, 1 - v)
        hueMarker.Position = UDim2.fromScale(0.5, h)
        hex.Text = string.format("#%02X%02X%02X", math.floor(control.Value.R * 255 + 0.5), math.floor(control.Value.G * 255 + 0.5), math.floor(control.Value.B * 255 + 0.5))
        if not silent then ui:_callback(options.Callback, control.Value) end
    end
    function control:SetValue(value, silent)
        if typeof(value) ~= "Color3" then return end
        local h, s, v = value:ToHSV()
        apply(h, s, v, silent)
    end
    function control:GetValue() return self.Value end
    function control:SetExpanded(expanded)
        if ui._destroyed then return end
        self.Expanded = expanded == true
        if ui._pointer and ui._pointer.owner == self then ui._pointer = nil end
        row.Size = UDim2.new(1, 0, 0, baseHeight + (self.Expanded and 220 or 0))
        panel.Visible = self.Expanded
    end
    ui:_listen(field.Activated, function() control:SetExpanded(not control.Expanded) end)
    local function drag(area, move)
        ui:_listen(area.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                ui:_closeDropdown()
                ui._pointer = { input = input, move = move, owner = control }
                move(input.Position)
            end
        end)
    end
    drag(shade, function(position)
        local size, origin = shade.AbsoluteSize, shade.AbsolutePosition
        if size.X > 0 and size.Y > 0 then
            apply(control.H, math.clamp((position.X - origin.X) / size.X, 0, 1), 1 - math.clamp((position.Y - origin.Y) / size.Y, 0, 1))
        end
    end)
    drag(hue, function(position)
        if hue.AbsoluteSize.Y > 0 then apply(math.clamp((position.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1), control.S, control.V) end
    end)
    local presets = options.Presets or { COLORS.Blue, COLORS.Mint, Color3.fromRGB(174, 114, 199), Color3.fromRGB(221, 123, 144), Color3.fromRGB(224, 158, 83), COLORS.Graphite, COLORS.White, Color3.fromRGB(25, 29, 38) }
    for index, color in ipairs(presets) do
        if index > 8 then break end
        assert(typeof(color) == "Color3", "ColorPicker Presets must contain Color3 values")
        local swatch = button(panel, {
            Name = "Preset" .. index, Position = UDim2.new((index - 1) / 8, 0, 0, 177), Size = UDim2.new(1 / 8, -8, 0, 23),
            BackgroundColor3 = color, BackgroundTransparency = 0,
        })
        corner(swatch, 7); stroke(swatch, COLORS.Line, 0.25)
        ui:_listen(swatch.Activated, function() control:SetValue(color) end)
    end
    control:SetValue(options.Default or ui.Accent, true)
    control:SetExpanded(options.Expanded == true)
    return self:_register(options, control)
end

function Section:AddDropdown(options)
    options = options or {}
    assert(type(options.Values) == "table" and #options.Values > 0, "Dropdown requires Values")
    local ui = self.Window
    local row = self:_row(options, 66)
    local field = button(row, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(180, 33),
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.25,
    })
    corner(field, 9); stroke(field, COLORS.Line, 0.25)
    local text = label(field, "", 11, UDim2.fromOffset(12, 0), UDim2.new(1, -43, 1, 0), COLORS.Secondary)
    icon(field, "chevron", COLORS.Muted, UDim2.new(1, -28, 0.5, -10))
    local control = { Value = options.Default or options.Values[1] }
    function control:SetValue(value, silent)
        if ui._destroyed or not table.find(options.Values, value) then return end
        self.Value = value; text.Text = tostring(value)
        if not silent then ui:_callback(options.Callback, value) end
    end
    function control:GetValue() return self.Value end
    ui:_listen(field.Activated, function()
        local same = ui._dropdownOwner == control
        ui:_closeDropdown()
        if same then return end
        local overlay = button(screen, { Size = UDim2.fromScale(1, 1), ZIndex = 80 })
        ui._dropdown, ui._dropdownOwner = overlay, control
        ui:_listen(overlay.Activated, function() ui:_closeDropdown() end)
        local viewport = ui:_viewport()
        local itemHeight, padding = 34 * ui._scale, 6 * ui._scale
        local height = math.min(#options.Values * itemHeight + padding * 2, math.max(50, viewport.Y - 24))
        local width = field.AbsoluteSize.X
        local x = math.clamp(field.AbsolutePosition.X, 8, math.max(8, viewport.X - width - 8))
        local y = field.AbsolutePosition.Y + field.AbsoluteSize.Y + padding
        if y + height > viewport.Y - 8 then y = math.max(8, field.AbsolutePosition.Y - height - padding) end
        local menu = create("ScrollingFrame", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
            CanvasSize = UDim2.fromOffset(0, #options.Values * itemHeight + padding * 2),
            ScrollBarThickness = 2, BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.02, ZIndex = 85,
            ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
        }, overlay)
        corner(menu, 11); stroke(menu, COLORS.Line, 0.15)
        for index, value in ipairs(options.Values) do
            local item = button(menu, {
                Position = UDim2.fromOffset(padding, padding + (index - 1) * itemHeight),
                Size = UDim2.new(1, -padding * 2, 0, itemHeight), Text = tostring(value),
                TextSize = math.max(9, 11 * ui._scale),
                BackgroundColor3 = COLORS.Hover, BackgroundTransparency = value == control.Value and 0.15 or 1,
                TextColor3 = value == control.Value and ui.Accent or COLORS.Secondary, ZIndex = 86,
            })
            corner(item, 7)
            ui:_listen(item.Activated, function() control:SetValue(value); ui:_closeDropdown() end)
        end
    end)
    control:SetValue(control.Value, true)
    return self:_register(options, control)
end

function Section:AddInput(options)
    options = options or {}
    local ui = self.Window
    local row = self:_row(options, 66)
    local field = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(180, 33),
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.25, ClearTextOnFocus = false,
        Text = tostring(options.Default or ""), PlaceholderText = options.Placeholder or "输入内容…",
        Font = FONT, TextSize = 11, TextColor3 = COLORS.Text, PlaceholderColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    corner(field, 9)
    create("UIPadding", { PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11) }, field)
    local outline = stroke(field, COLORS.Line, 0.25)
    local control = { Value = field.Text, TextBox = field }
    function control:SetValue(value, silent)
        if ui._destroyed then return end
        self.Value = tostring(value or ""); field.Text = self.Value
        if not silent then ui:_callback(options.Callback, self.Value) end
    end
    function control:GetValue() return self.Value end
    ui:_listen(field.Focused, function() ui:_animate(outline, { Color = ui.Accent, Transparency = 0.1 }) end)
    ui:_listen(field.FocusLost, function(enterPressed)
        ui:_animate(outline, { Color = COLORS.Line, Transparency = 0.25 })
        control.Value = field.Text
        ui:_callback(options.Callback, control.Value, enterPressed)
    end)
    return self:_register(options, control)
end

function Section:AddButton(options)
    options = options or {}
    local ui = self.Window
    local row = self:_row(options, 66)
    local control = button(row, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(132, 33),
        BackgroundTransparency = options.Primary and 0 or 0.2,
        BackgroundColor3 = options.Primary and ui.Accent or COLORS.Hover,
        TextColor3 = options.Primary and COLORS.White or COLORS.Secondary, Text = options.Text or "执行",
    })
    corner(control, 9)
    if options.Primary then ui:_bindAccent(control, "BackgroundColor3") else stroke(control, COLORS.Line, 0.4) end
    ui:_listen(control.Activated, function() ui:_callback(options.Callback) end)
    ui:_listen(control.MouseEnter, function() ui:_animate(control, { BackgroundTransparency = options.Primary and 0.15 or 0 }) end)
    ui:_listen(control.MouseLeave, function() ui:_animate(control, { BackgroundTransparency = options.Primary and 0 or 0.2 }) end)
    return self:_register(options, control)
end

function Tab:AddHero(options)
    options = options or {}
    self._order += 1
    local hero = create("Frame", {
        Name = "Welcome", LayoutOrder = self._order, Size = UDim2.new(1, -1, 0, 154),
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.28, ClipsDescendants = true, ZIndex = 25,
    }, self.Page)
    corner(hero, 16); stroke(hero, COLORS.White, 0.15)
    label(hero, options.Eyebrow or "MAKE ROOM FOR WHAT MATTERS", 9, UDim2.fromOffset(23, 19), UDim2.new(1, -45, 0, 17), COLORS.Muted, MEDIUM)
    local title = label(hero, options.Title or "少一点干扰，\n多一点专注。", 24, UDim2.fromOffset(22, 44), UDim2.new(1, -160, 0, 67), COLORS.Text, BOLD)
    title.TextYAlignment = Enum.TextYAlignment.Top
    label(hero, options.Description or "轻盈、清晰，恰到好处。", 11, UDim2.fromOffset(24, 121), UDim2.new(1, -48, 0, 18), COLORS.Secondary)
    for index = 1, 3 do
        local size = 110 - (index - 1) * 29
        local circle = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -86, 0.5, 0),
            Size = UDim2.fromOffset(size, size), BackgroundTransparency = 0.93 + index * 0.015,
            BackgroundColor3 = self.Window.Accent, Rotation = index * 15,
        }, hero)
        corner(circle, 100)
        self.Window:_bindAccent(circle, "BackgroundColor3")
        self.Window:_bindAccent(stroke(circle, self.Window.Accent, 0.89, 1), "Color")
    end
    return hero
end

function Window:Destroy(skipGui)
    if self._destroyed or self._destroying then return end
    self._destroying = true
    self:_releaseKeyHolds()
    self._destroyed = true
    self:_syncMouse()
    self._pointer = nil
    for connection in pairs(self._connections) do connection:Disconnect() end
    self._connections = {}
    for thread in pairs(self._tasks) do
        if thread ~= coroutine.running() then pcall(task.cancel, thread) end
    end
    self._tasks = {}
    for tween in pairs(self._tweens) do tween:Cancel() end
    self._tweens, self._channels = {}, {}
    for _, notice in ipairs(self._notifications) do notice.Status = "closed" end
    for _, notice in ipairs(self._notificationQueue) do notice.Status = "closed" end
    self._notifications, self._notificationQueue, self._notificationMap = {}, {}, {}
    blur:Destroy()
    if not skipGui then screen:Destroy() end
    if Registry[id] == self then Registry[id] = nil end
    self._accentBindings = {}
    if Environment.WhiteGlassUI == self then Environment.WhiteGlassUI = nil end
    if type(self.OnDestroy) == "function" then
        local ok, message = xpcall(self.OnDestroy, debug.traceback)
        if not ok then warn("[AURA destroy] " .. tostring(message)) end
    end
end

Window:_listen(header.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    Window:_closeDropdown()
    local start = Vector2.new(input.Position.X, input.Position.Y)
    local center = Vector2.new(host.Position.X.Offset, host.Position.Y.Offset)
    Window._pointer = { input = input, move = function(position)
        local viewport = Window:_viewport()
        if viewport.X < 1 or viewport.Y < 1 then return end
        local nextCenter = center + Vector2.new(position.X, position.Y) - start
        Window._normalizedCenter = Vector2.new(nextCenter.X / viewport.X, nextCenter.Y / viewport.Y)
        Window:_fit()
    end }
end)
Window:_listen(UserInputService.InputChanged, function(input)
    local pointer = Window._pointer
    if not pointer then return end
    local mouse = pointer.input.UserInputType == Enum.UserInputType.MouseButton1
    if (mouse and input.UserInputType == Enum.UserInputType.MouseMovement) or (not mouse and input == pointer.input) then
        pointer.move(input.Position)
    end
end)
Window:_listen(UserInputService.InputEnded, function(input)
    if Environment.__AuraConsumedInput == input then Environment.__AuraConsumedInput = nil end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for _, picker in ipairs(Window._keyPickers) do
            if picker.Value ~= "None" and input.KeyCode == Enum.KeyCode[picker.Value] then picker:_release() end
        end
    end
    local pointer = Window._pointer
    if pointer and (input == pointer.input or (pointer.input.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseButton1)) then Window._pointer = nil end
end)
Window:_listen(UserInputService.WindowFocusReleased, function()
    Window._pointer = nil
    Window:_releaseKeyHolds()
    Window:_closeDropdown()
    Environment.__AuraConsumedInput = nil
end)
Window:_listen(UserInputService.InputBegan, function(input, processed)
    if Environment.__AuraConsumedInput == input then return end
    local capture = Environment.__AuraKeyCapture
    if capture then
        if capture.Window == Window and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                Environment.__AuraConsumedInput = input
                capture:SetValue("None")
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                Environment.__AuraConsumedInput = input
                capture:SetValue(input.KeyCode)
                capture._down = true
            end
        end
        return
    end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Escape and Window._dropdown then Window:_closeDropdown(); return end
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and not Window._dropdown then
        for _, picker in ipairs(Window._keyPickers) do
            if picker.Value ~= "None" and input.KeyCode == Enum.KeyCode[picker.Value] then picker:_begin() end
        end
    end
    if input.KeyCode == Window.ToggleKey and Registry[id] == Window then Window:SetVisible(not Window.Visible) end
end)
Window:_listen(minimize.Activated, function() Window:SetVisible(false) end)
Window:_listen(close.Activated, function() Window:Destroy() end)
Window:_listen(launcher.Activated, function() Window:SetVisible(true) end)
Window:_listen(screen.Destroying, function() Window:Destroy(true) end)

local function watchCamera()
    if Window._cameraConnection then Window._cameraConnection:Disconnect(); Window._cameraConnection = nil end
    local camera = Workspace.CurrentCamera
    if camera then Window._cameraConnection = Window:_listen(camera:GetPropertyChangedSignal("ViewportSize"), function() Window:_fit() end) end
    Window:_fit()
end
Window:_listen(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)

Registry[id] = Window
Environment.WhiteGlassUI = Window
watchCamera()
if options.Visible ~= false then Window:SetVisible(true) else launcher.Visible = true end
return Window
end

function Library:GetWindow(id)
    return Registry[tostring(id or "default")]
end

function Library:Destroy()
    local windows = {}
    for _, window in pairs(Registry) do if window.Library == self then table.insert(windows, window) end end
    for _, window in ipairs(windows) do window:Destroy() end
end

return Library
