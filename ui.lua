local Environment = type(getgenv) == "function" and getgenv() or _G
local Registry = Environment.__AuraWindows or {}
Environment.__AuraWindows = Registry
local Library = { Version = "1.4.6" }

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local Mouse = Environment.__AuraMouse
local previousMouse
if Mouse and Mouse.Version ~= 3 then
    previousMouse = Mouse
    RunService:UnbindFromRenderStep(Mouse.Binding)
    RunService:UnbindFromRenderStep(Mouse.Binding .. "_Input")
    for _, connection in ipairs(Mouse.Connections) do connection:Disconnect() end
    Mouse = nil
end
if not Mouse then
    Mouse = { Version = 3, Owners = {}, Connections = {}, Binding = "AURA_MouseUnlock", Applying = false }
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

if previousMouse then
    local owners, behavior, icon = previousMouse.Owners, previousMouse.Behavior, previousMouse.IconEnabled
    for key, value in pairs(Mouse) do previousMouse[key] = value end
    Mouse, Environment.__AuraMouse = previousMouse, previousMouse
    for owner in pairs(owners) do Mouse:Acquire(owner) end
    Mouse.Behavior, Mouse.IconEnabled = behavior, icon
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
    Tabs = {}, TabMap = {}, Controls = {}, _defaults = {}, _nilDefaults = {}, Accent = typeof(options.Accent) == "Color3" and options.Accent or COLORS.Blue, Visible = false,
    Glass = options.Glass ~= false, Motion = options.Motion ~= false,
    UnlockMouse = options.UnlockMouse ~= false,
    Blur = number(options.Blur, 18, 0, 56), Transparency = number(options.Transparency, 0.12, 0, 0.8),
    Zoom = number(options.Scale, 1, 0.5, 1.5), ToggleKey = options.ToggleKey or Enum.KeyCode.RightAlt,
    NotificationLimit = math.floor(number(options.NotificationLimit, 3, 1, 3)),
    NotificationDuration = number(options.NotificationDuration, 4, 0, 3600),
    _notifications = {}, _notificationQueue = {}, _notificationMap = {}, _notificationCounter = 0,
    _destroyed = false, _connections = {}, _tasks = {}, _tweens = {}, _channels = {},
    _accentBindings = {}, _normalizedCenter = Vector2.new(0.5, 0.5), _scale = 1,
    OnDestroy = options.OnDestroy, Features = {}, _keyPickers = {}, _floatingBalls = {},
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
local cursor = create("Frame", {
    Name = "MouseCursor", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(17, 17),
    BackgroundTransparency = 1, Active = false, Visible = false, ZIndex = 1000,
}, screen)
for index, size in ipairs({ Vector2.new(17, 3), Vector2.new(3, 17), Vector2.new(15, 1), Vector2.new(1, 15) }) do
    create("Frame", { Name = index <= 2 and "Outline" or "Cross", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundColor3 = index <= 2 and Color3.fromRGB(25, 28, 34) or Color3.fromRGB(255, 255, 255),
        Active = false, ZIndex = index <= 2 and 1001 or 1002,
    }, cursor)
end
Window.MouseCursor = cursor

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
local player = Players.LocalPlayer
local userId = player and player.UserId or 0
if userId > 0 then
    local avatar = create("ImageLabel", {
        Name = "LocalPlayerAvatar", BackgroundColor3 = COLORS.Hover,
        Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150",
    }, brandMark)
    corner(avatar, 10)
    brandCenter.Visible = false
end
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
    for _, ball in pairs(self._floatingBalls) do ball:_fit() end
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
    if not self.Visible and self._dialog then self._dialog:Close("hidden") end
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
                if not notice.Frame or not notice.Frame.Parent or not notice._progress or not notice._progress.Parent then
                    notice:Dismiss("invalid_visual")
                else
                    notice.Remaining = math.max(0, notice.Remaining - dt)
                    notice._progress.Size = UDim2.fromScale(notice.Remaining / notice.Duration, 1)
                    if notice.Remaining <= 0 then notice:Dismiss("timeout") end
                end
            end
        end
    end)
end

function Window:_pumpNotifications()
    if self._destroyed or self._clearingNotifications then return end
    while #self._notificationQueue > 0 and #self._notifications < self:_notificationCapacity() do
        local notice = table.remove(self._notificationQueue, 1)
        -- Rendering may yield in native text measurement. Publish only a complete visual.
        notice.Status = "rendering"
        local ok, message = pcall(self._renderNotification, self, notice)
        if ok and not self._destroyed and notice.Status == "rendering" then
            notice.Status = "active"
            table.insert(self._notifications, notice)
        else
            local failed = not ok and notice.Status ~= "closed"
            notice.Status = "closed"
            self:_dropNotificationVisual(notice)
            if self._notificationMap[notice.Id] == notice then self._notificationMap[notice.Id] = nil end
            if failed then warn("[AURA notification] " .. tostring(message)) end
        end
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
        if ui._destroyed or not ui.Visible or ui._dialog or self.Disabled or toggle.Disabled or toggle._destroyed then return self end
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
        if self.Disabled or toggle.Disabled or toggle._destroyed or toggle.Frame and toggle.Frame.Visible == false then return end
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
    if options.Id ~= nil then
        self.Controls[tostring(options.Id)] = picker
        self._defaults[tostring(options.Id)] = { Key = initial, Mode = mode }
    end
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

function Window:_updateMouseCursor()
    cursor.Visible = self.Visible and self.UnlockMouse and not self._destroyed
    if cursor.Visible then
        local position = UserInputService:GetMouseLocation()
        cursor.Position = UDim2.fromOffset(position.X, position.Y)
    end
end

function Window:_syncMouse()
    if self.Visible and self.UnlockMouse and not self._destroyed then
        Mouse:Acquire(self)
        minimize.Modal = true
    else
        minimize.Modal = false
        Mouse:Release(self)
    end
    self:_updateMouseCursor()
    if cursor.Visible then
        if not self._cursorConnection then
            self._cursorConnection = self:_listen(RunService.RenderStepped, function() self:_updateMouseCursor() end)
        end
    elseif self._cursorConnection then
        self._cursorConnection:Disconnect()
        self._connections[self._cursorConnection] = nil
        self._cursorConnection = nil
    end
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
    local body = create("Frame", { Name = "Controls", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, card)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, body)
    local section = setmetatable({ Window = self.Window, Frame = card, Body = body, Header = headerRow,
        Collapsed = false, _order = 0 }, Section)
    function section:SetCollapsed(value)
        if self.Window._destroyed then return end
        self.Collapsed = value == true
        self.Body.Visible = not self.Collapsed
        if self.CollapseButton then self.CollapseButton.Text = self.Collapsed and "+" or "−" end
        self.Window:_closeDropdown(); self.Window._pointer = nil
    end
    function section:SetVisible(value) if not self.Window._destroyed then self.Frame.Visible = value == true end end
    if options.Collapsible or options.Collapsed then
        section.CollapseButton = button(headerRow, { Text = "−", TextSize = 18,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 8), Size = UDim2.fromOffset(32, 34) })
        self.Window:_listen(section.CollapseButton.Activated, function() section:SetCollapsed(not section.Collapsed) end)
    end
    section:SetCollapsed(options.Collapsed == true)
    return section
end

function Section:_register(options, control)
    if options.Id ~= nil then
        local id = tostring(options.Id)
        assert(self.Window.Controls[id] == nil, "Duplicate control Id: " .. id)
        self.Window.Controls[id] = control
    end
    if type(control) == "table" and typeof(control) ~= "Instance" then
        local ui, row = self.Window, self._lastRow
        control.Frame = control.Frame or row
        control.Disabled = options.Disabled == true
        function control:SetVisible(value)
            if ui._destroyed or self._destroyed then return end
            self.Frame.Visible = value == true
            ui._pointer = nil; ui:_closeDropdown()
            if self.KeyPicker then self.KeyPicker:_release() end
            if self._release then self:_release() end
            if Environment.__AuraKeyCapture == self then ui:_cancelKeyCapture() end
        end
        function control:SetEnabled(value)
            if ui._destroyed or self._destroyed then return end
            self.Disabled = value ~= true
            if not self._disabledCover then
                self._disabledCover = button(self.Frame, { Name = "DisabledCover", Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.5, ZIndex = 70, Active = true })
            end
            self._disabledCover.Visible = self.Disabled
            ui._pointer = nil; ui:_closeDropdown()
            if self.KeyPicker then self.KeyPicker:_release() end
            if self._release then self:_release() end
            if Environment.__AuraKeyCapture == self then ui:_cancelKeyCapture() end
        end
        function control:SetTitle(text)
            if not ui._destroyed and not self._destroyed and row then
                for _, child in ipairs(row:GetChildren()) do
                    if child:IsA("TextLabel") then child.Text = tostring(text); break end
                end
                if self.FloatingBall then self.FloatingBall:SetTitle(text) end
            end
        end
        function control:Destroy()
            if self._destroyed then return end
            self:SetEnabled(false)
            local picker = self.KeyPicker or (self._release and self)
            if picker then
                picker:_release(); picker.Disabled = true
                if Environment.__AuraKeyCapture == picker then ui:_cancelKeyCapture() end
                local at = table.find(ui._keyPickers, picker)
                if at then table.remove(ui._keyPickers, at) end
                for key, value in pairs(ui.Controls) do
                    if value == picker then ui.Controls[key], ui._defaults[key] = nil, nil end
                end
            end
            self._destroyed = true
            if type(self._cleanup) == "function" then self:_cleanup() end
            self.Frame:Destroy()
            if options.Id ~= nil then
                local id = tostring(options.Id)
                if ui.Controls[id] == self then ui.Controls[id], ui._defaults[id], ui._nilDefaults[id], ui.Features[id] = nil, nil, nil, nil; ui:_layoutFeatures() end
            end
        end
        if type(control.GetValue) == "function" and type(control.SetValue) == "function" then
            local set = control.SetValue
            control.SetValue = function(self, ...)
                if not self._destroyed and not ui._destroyed then return set(self, ...) end
            end
            if options.Id ~= nil then
                local value = control:GetValue()
                ui._defaults[tostring(options.Id)] = type(value) == "table" and table.clone(value) or value
                if value == nil then ui._nilDefaults[tostring(options.Id)] = true end
            end
        end
        if options.Visible == false then control:SetVisible(false) end
        if control.Disabled then control:SetEnabled(false) end
    end
    return control
end

function Section:_row(options, height)
    if options.Id ~= nil then assert(self.Window.Controls[tostring(options.Id)] == nil, "Duplicate control Id: " .. tostring(options.Id)) end
    self._order += 1
    local row = create("Frame", {
        Name = "Control", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 66), LayoutOrder = self._order,
    }, self.Body or self.Frame)
    self._lastRow = row
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
        if self.FloatingBall then self.FloatingBall:_refresh() end
        if not silent then ui:_callback(options.Callback, self.Value) end
        if options.FeatureList ~= false then ui:SetFeature(options.Id or control._featureId, options.FeatureTitle or options.Title or "Toggle", self.Value, options.ParentFeature) end
    end
    function control:GetValue() return self.Value end
    function control:AddKeyPicker(keyOptions) return ui:_addKeyPicker(self, row, keyOptions) end
    ui:_bindAccent(track, "BackgroundColor3", function(accent) return control.Value and accent or COLORS.Track end)
    ui:_listen(hit.Activated, function() if not control.Disabled then control:SetValue(not control.Value) end end)
    control._featureId = "toggle:" .. tostring(row)
    control:SetValue(control.Value, true)
    self:_register(options, control)
    function control:AddFloatingBall(ballOptions)
        return ui:_attachFloatingBall(self, row, options.Title or "选项", ballOptions, true)
    end
    if options.FloatingBall then control:AddFloatingBall(type(options.FloatingBall) == "table" and options.FloatingBall or {}) end
    return control
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
        if control.Disabled or control._destroyed then return end
        if hit.AbsoluteSize.X > 0 then
            local fraction = math.clamp((position.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
            control:SetValue(minimum + fraction * (maximum - minimum))
        end
    end
    ui:_listen(hit.InputBegan, function(input)
        if control.Disabled then return end
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
    ui:_listen(field.Activated, function() if not control.Disabled then control:SetExpanded(not control.Expanded) end end)
    local function drag(area, move)
        ui:_listen(area.InputBegan, function(input)
            if control.Disabled then return end
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
        ui:_listen(swatch.Activated, function() if not control.Disabled then control:SetValue(color) end end)
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
    local multi = options.Multi == true
    options = table.clone(options)
    options.Values = table.clone(options.Values)
    local control = { Value = multi and {} or options.Default or options.Values[1], Button = field, _allowNil = not multi }
    function control:_isValidValue(value)
        if not multi then return value == nil or table.find(options.Values, value) ~= nil end
        if type(value) ~= "table" then return false end
        local count = 0
        for key, entry in pairs(value) do
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or not table.find(options.Values, entry) then return false end
            count += 1
        end
        return count == #value
    end
    local items = {}
    local function selected(value)
        return multi and table.find(control.Value, value) ~= nil or not multi and control.Value == value
    end
    local function refresh()
        text.Text = multi and (#control.Value == 0 and "未选择" or table.concat(control.Value, "、")) or (control.Value ~= nil and tostring(control.Value) or "未选择")
        for value, item in pairs(items) do
            item.BackgroundTransparency = selected(value) and 0.15 or 1
            item.TextColor3 = selected(value) and ui.Accent or COLORS.Secondary
            item.Text = (multi and (selected(value) and "✓ " or "   ") or "") .. tostring(value)
        end
    end
    function control:SetValue(value, silent)
        if ui._destroyed then return end
        if multi then
            if type(value) ~= "table" then return end
            local values = {}
            for _, option in ipairs(options.Values) do
                if table.find(value, option) then values[#values + 1] = option end
            end
            self.Value = values
        else
            if value ~= nil and not table.find(options.Values, value) then return end
            self.Value = value
        end
        refresh()
        if not silent then ui:_callback(options.Callback, multi and table.clone(self.Value) or self.Value) end
    end
    function control:GetValue() return multi and table.clone(self.Value) or self.Value end
    function control:SetValues(values, silent)
        if ui._destroyed or self._destroyed then return end
        assert(type(values) == "table", "Dropdown Values must be an array")
        local copied, seen = {}, {}
        for _, value in ipairs(values) do
            assert(type(value) == "string" or type(value) == "number" and value == value and math.abs(value) ~= math.huge, "Invalid dropdown value")
            if not seen[value] then copied[#copied + 1] = value; seen[value] = true end
        end
        ui:_closeDropdown(); items = {}; options.Values = copied
        if multi then self:SetValue(self.Value, silent)
        else
            self.Value = table.find(copied, self.Value) and self.Value or copied[1]
            refresh()
            if not silent then ui:_callback(options.Callback, self.Value) end
        end
    end
    ui:_listen(field.Activated, function()
        if control.Disabled or control._destroyed then return end
        local same = ui._dropdownOwner == control
        ui:_closeDropdown()
        items = {}
        if same then return end
        local overlay = button(screen, { Size = UDim2.fromScale(1, 1), ZIndex = 80 })
        ui._dropdown, ui._dropdownOwner = overlay, control
        ui._dropdownCleanup = function() items = {}; control.SearchBox, control.Menu = nil, nil end
        ui:_listen(overlay.Activated, function() ui:_closeDropdown() end)
        local viewport = ui:_viewport()
        local itemHeight, padding = 34 * ui._scale, 6 * ui._scale
        local searchHeight = options.Searchable and 36 * ui._scale or 0
        local height = math.min(math.max(44, #options.Values * itemHeight + padding * 2 + searchHeight), 280 * ui._scale, math.max(50, viewport.Y - 24))
        local width = math.min(field.AbsoluteSize.X, math.max(50, viewport.X - 16))
        local x = math.clamp(field.AbsolutePosition.X, 8, math.max(8, viewport.X - width - 8))
        local y = field.AbsolutePosition.Y + field.AbsoluteSize.Y + padding
        if y + height > viewport.Y - 8 then y = math.max(8, field.AbsolutePosition.Y - height - padding) end
        local panel = create("Frame", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
            BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.02, ZIndex = 85,
        }, overlay)
        corner(panel, 11); stroke(panel, COLORS.Line, 0.15)
        local menu = create("ScrollingFrame", {
            Position = UDim2.fromOffset(0, searchHeight), Size = UDim2.new(1, 0, 1, -searchHeight),
            CanvasSize = UDim2.fromOffset(0, #options.Values * itemHeight + padding * 2),
            ScrollBarThickness = 2, BackgroundTransparency = 1, ZIndex = 85,
            ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
        }, panel)
        control.Menu = menu
        local empty = label(menu, "没有匹配选项", 11, UDim2.fromOffset(padding, padding), UDim2.new(1, -padding * 2, 0, itemHeight), COLORS.Muted)
        empty.Visible = #options.Values == 0
        if options.Searchable then
            local search = create("TextBox", { Name = "Search", Text = "", PlaceholderText = "搜索…", ClearTextOnFocus = false,
                Font = FONT, TextSize = 11, TextColor3 = COLORS.Text, BackgroundTransparency = 1, ZIndex = 87,
                Position = UDim2.fromOffset(padding, 0), Size = UDim2.new(1, -padding * 2, 0, searchHeight) }, panel)
            control.SearchBox = search
            ui:_listen(search:GetPropertyChangedSignal("Text"), function()
                local count = 0
                for _, value in ipairs(options.Values) do
                    local item = items[value]
                    item.Visible = string.find(string.lower(tostring(value)), string.lower(search.Text), 1, true) ~= nil
                    if item.Visible then item.Position = UDim2.fromOffset(padding, padding + count * itemHeight); count += 1 end
                end
                empty.Visible = count == 0
                menu.CanvasSize = UDim2.fromOffset(0, count * itemHeight + padding * 2)
            end)
        end
        for index, value in ipairs(options.Values) do
            local item = button(menu, {
                Position = UDim2.fromOffset(padding, padding + (index - 1) * itemHeight),
                Size = UDim2.new(1, -padding * 2, 0, itemHeight), Text = tostring(value),
                TextSize = math.max(9, 11 * ui._scale),
                BackgroundColor3 = COLORS.Hover, BackgroundTransparency = value == control.Value and 0.15 or 1,
                TextColor3 = value == control.Value and ui.Accent or COLORS.Secondary, ZIndex = 86,
            })
            corner(item, 7)
            items[value] = item
            ui:_listen(item.Activated, function()
                if control.Disabled then return end
                if multi then
                    local values = control:GetValue()
                    local index = table.find(values, value)
                    if index then table.remove(values, index) else values[#values + 1] = value end
                    control:SetValue(values)
                else
                    control:SetValue(value)
                    ui:_closeDropdown()
                end
            end)
        end
        refresh()
    end)
    control:SetValue(multi and (options.Default or {}) or control.Value, true)
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
        if control.Disabled then field.Text = control.Value; return end
        control.Value = field.Text
        ui:_callback(options.Callback, control.Value, enterPressed)
    end)
    return self:_register(options, control)
end

function Window:GetFloatingBall(control)
    if type(control) == "string" or type(control) == "number" then control = self:GetControl(control) end
    return self._floatingBalls[control]
end

-- Native buttons keep their original return type; their ball is available through GetFloatingBall.
function Window:_attachFloatingBall(source, row, title, options, isToggle)
    assert(not self._destroyed, "This AURA window has been destroyed")
    assert(not self._floatingBalls[source], "This control already has a floating ball")
    options = options or {}
    local ui = self
    local handle = { Enabled = false, Locked = options.Locked == true, Width = 25, Height = 25,
        Title = tostring(options.Title or title), _center = Vector2.new(0.5, 0.5), _connections = {} }
    local function listen(signal, callback)
        local connection = ui:_listen(signal, function(...)
            if not handle._destroyed then callback(...) end
        end)
        table.insert(handle._connections, connection)
        return connection
    end
    local selector = button(row, { Name = "FloatingBallSwitch", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(78, 26), ZIndex = row.ZIndex + 10 })
    label(selector, "快捷球", 10, UDim2.new(), UDim2.fromOffset(39, 26), COLORS.Secondary)
    local track = create("Frame", { Position = UDim2.fromOffset(43, 5), Size = UDim2.fromOffset(28, 16),
        BackgroundColor3 = COLORS.Track }, selector)
    corner(track, 16)
    local knob = create("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = COLORS.White }, track)
    corner(knob, 12)
    local resized = {}
    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") then
            resized[child] = child.Size
            child.Size = UDim2.new(0.5, -69, child.Size.Y.Scale, child.Size.Y.Offset)
        end
    end
    local ball = button(screen, { Name = "FloatingBall", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(25, 25), Visible = false,
        BackgroundTransparency = 0, BackgroundColor3 = COLORS.White, Text = handle.Title,
        TextScaled = true, TextWrapped = true, TextColor3 = COLORS.Text, ZIndex = 75, Active = true })
    corner(ball, 100)
    stroke(ball, COLORS.Line, 0.15)
    create("UITextSizeConstraint", { MinTextSize = 5, MaxTextSize = 12 }, ball)
    handle.Button, handle.Switch = ball, selector
    function handle:_refresh()
        if self._destroyed or ui._destroyed then return end
        local active = isToggle and source:GetValue() or self._flashing == true
        ball.BackgroundColor3 = active and COLORS.Blue or COLORS.White
        ball.TextColor3 = active and COLORS.White or COLORS.Text
        track.BackgroundColor3 = self.Enabled and COLORS.Blue or COLORS.Track
        knob.Position = UDim2.fromOffset(self.Enabled and 14 or 2, 2)
    end
    function handle:_fit()
        if self._destroyed or ui._destroyed then return end
        local viewport = ui:_viewport()
        if viewport.X < 1 or viewport.Y < 1 then return end
        local width, height = math.min(self.Width, viewport.X), math.min(self.Height, viewport.Y)
        ball.Size = UDim2.fromOffset(width, height)
        ball.Position = UDim2.fromOffset(
            math.clamp(self._center.X * viewport.X, width / 2, viewport.X - width / 2),
            math.clamp(self._center.Y * viewport.Y, height / 2, viewport.Y - height / 2))
    end
    function handle:SetSize(width, height)
        if self._destroyed or ui._destroyed then return self end
        self.Width = math.floor(number(tonumber(width), self.Width, 16, 256) + 0.5)
        self.Height = math.floor(number(tonumber(height), self.Height, 16, 256) + 0.5)
        self:_fit()
        return self
    end
    function handle:SetTitle(value)
        if self._destroyed or ui._destroyed then return self end
        self.Title = tostring(value); ball.Text = self.Title
        return self
    end
    function handle:_cancelDrag()
        if ui._pointer and ui._pointer.owner == self then ui._pointer = nil end
    end
    function handle:SetEnabled(value)
        if self._destroyed or ui._destroyed then return self end
        self.Enabled = value == true
        ball.Visible = self.Enabled
        self:_cancelDrag()
        if not self.Enabled and ui._dropdownOwner == self then ui:_closeDropdown() end
        self:_refresh(); self:_fit()
        return self
    end
    function handle:SetLocked(value)
        if self._destroyed or ui._destroyed then return self end
        self.Locked = value == true
        self:_cancelDrag()
        if self.LockButton then self.LockButton.Text = self.Locked and "解除锁定" or "锁定" end
        return self
    end
    function handle:_pulse()
        if self._destroyed or ui._destroyed then return end
        local token = {}
        self._flashToken, self._flashing = token, true
        self:_refresh()
        ui:_later(0.25, function()
            if self._destroyed or self._flashToken ~= token then return end
            self._flashing = false; self:_refresh()
        end)
    end
    function handle:Activate()
        if self._destroyed or ui._destroyed or not self.Enabled or not self.Locked or ui._dialog then return end
        if isToggle then
            if not source.Disabled and not source._destroyed then source:SetValue(not source:GetValue()) end
        elseif source.Active ~= false and source.Interactable ~= false and source.Visible ~= false then
            self._activate()
        end
    end
    function handle:OpenMenu()
        if self._destroyed or ui._destroyed or not self.Enabled or ui._dialog then return end
        local wasOpen = ui._dropdownOwner == self
        ui:_closeDropdown(); self:_cancelDrag()
        if wasOpen then return end
        local viewport, width, height = ui:_viewport(), 208, 164
        local x = math.clamp(ball.Position.X.Offset + ball.Size.X.Offset / 2 + 6, 0, math.max(0, viewport.X - width))
        local y = math.clamp(ball.Position.Y.Offset - ball.Size.Y.Offset / 2, 0, math.max(0, viewport.Y - height))
        local overlay = button(screen, { Name = "FloatingBallOverlay", Size = UDim2.fromScale(1, 1), ZIndex = 80, Active = true })
        local menu = create("Frame", { Name = "FloatingBallMenu", Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, height), BackgroundColor3 = COLORS.White, Active = true, ZIndex = 85 }, overlay)
        corner(menu, 10); stroke(menu, COLORS.Line, 0.15)
        self.Menu = menu
        ui._dropdown, ui._dropdownOwner = overlay, self
        local menuConnections = {}
        local function menuListen(signal, callback)
            table.insert(menuConnections, ui:_listen(signal, callback))
        end
        ui._dropdownCleanup = function()
            self.Menu, self.LockButton = nil, nil
            for _, connection in ipairs(menuConnections) do connection:Disconnect(); ui._connections[connection] = nil end
        end
        menuListen(overlay.Activated, function() ui:_closeDropdown() end)
        local lock = button(menu, { Name = "Lock", Text = self.Locked and "解除锁定" or "锁定",
            Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(93, 29),
            BackgroundColor3 = COLORS.Hover, BackgroundTransparency = 0 })
        local closeBall = button(menu, { Name = "CloseBall", Text = "关闭快捷球", Position = UDim2.fromOffset(107, 7),
            Size = UDim2.fromOffset(93, 29), BackgroundColor3 = COLORS.Hover, BackgroundTransparency = 0 })
        corner(lock, 6); corner(closeBall, 6); self.LockButton = lock
        label(menu, "宽 × 高（16–256）", 10, UDim2.fromOffset(10, 42), UDim2.fromOffset(188, 20), COLORS.Secondary)
        local function field(name, value, x)
            local box = create("TextBox", { Name = name, Text = tostring(value), ClearTextOnFocus = false,
                Font = FONT, TextSize = 12, TextColor3 = COLORS.Text, BackgroundColor3 = COLORS.Hover,
                Position = UDim2.fromOffset(x, 66), Size = UDim2.fromOffset(85, 29) }, menu)
            corner(box, 6)
            return box
        end
        local widthBox, heightBox = field("Width", self.Width, 10), field("Height", self.Height, 113)
        label(menu, "×", 12, UDim2.fromOffset(98, 66), UDim2.fromOffset(12, 29), COLORS.Secondary)
        local function applySize()
            self:SetSize(widthBox.Text, heightBox.Text)
            widthBox.Text, heightBox.Text = tostring(self.Width), tostring(self.Height)
        end
        local apply = button(menu, { Name = "ApplySize", Text = "应用大小", Position = UDim2.fromOffset(10, 104),
            Size = UDim2.fromOffset(188, 26), BackgroundColor3 = COLORS.Blue, BackgroundTransparency = 0, TextColor3 = COLORS.White })
        corner(apply, 6)
        label(menu, "未锁定：长按拖动 · 锁定：点击执行", 9, UDim2.fromOffset(10, 136), UDim2.fromOffset(188, 20), COLORS.Secondary)
        menuListen(lock.Activated, function() self:SetLocked(not self.Locked) end)
        menuListen(closeBall.Activated, function() self:SetEnabled(false) end)
        menuListen(widthBox.FocusLost, applySize); menuListen(heightBox.FocusLost, applySize)
        menuListen(apply.Activated, applySize)
    end
    function handle:Destroy()
        if self._destroyed then return end
        self:_cancelDrag()
        if ui._dropdownOwner == self then ui:_closeDropdown() end
        self._destroyed, self.Enabled = true, false
        for _, connection in ipairs(self._connections) do connection:Disconnect(); ui._connections[connection] = nil end
        self._connections = {}
        ball:Destroy(); selector:Destroy()
        for child, original in pairs(resized) do
            if child.Parent then child.Size = original end
        end
        ui._floatingBalls[source] = nil
        if isToggle then source.FloatingBall = nil end
    end
    listen(selector.Activated, function() handle:SetEnabled(not handle.Enabled) end)
    listen(ball.Activated, function() handle:Activate() end)
    listen(ball.MouseButton2Click, function() handle:OpenMenu() end)
    listen(ball.InputBegan, function(input)
        if not handle.Enabled or handle.Locked or ui._dialog or ui._dropdown then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local start = Vector2.new(input.Position.X, input.Position.Y)
        local center = Vector2.new(ball.Position.X.Offset, ball.Position.Y.Offset)
        local pointer = { input = input, owner = handle, ready = false }
        local latest = input.Position
        pointer.move = function(position)
            latest = position
            if not pointer.ready then return end
            local viewport = ui:_viewport()
            if viewport.X < 1 or viewport.Y < 1 then return end
            local nextCenter = center + Vector2.new(position.X, position.Y) - start
            local half = Vector2.new(ball.Size.X.Offset, ball.Size.Y.Offset) / 2
            handle._center = Vector2.new(math.clamp(nextCenter.X, half.X, viewport.X - half.X) / viewport.X,
                math.clamp(nextCenter.Y, half.Y, viewport.Y - half.Y) / viewport.Y)
            handle:_fit()
        end
        ui._pointer = pointer
        ui:_later(0.2, function()
            if ui._pointer == pointer then pointer.ready = true; pointer.move(latest) end
        end)
    end)
    listen(row.Destroying, function() handle:Destroy() end)
    if not isToggle then listen(source.Destroying, function() handle:Destroy() end) end
    ui._floatingBalls[source] = handle
    if isToggle then source.FloatingBall = handle end
    handle:SetSize(options.Width or 25, options.Height or 25)
    handle:SetEnabled(options.Enabled == true)
    return handle
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
    local function activate()
        if control.Active == false or control.Interactable == false then return end
        local ball = ui:GetFloatingBall(control)
        if ball then ball:_pulse() end
        ui:_callback(options.Callback)
    end
    ui:_listen(control.Activated, activate)
    ui:_listen(control.MouseEnter, function() ui:_animate(control, { BackgroundTransparency = options.Primary and 0.15 or 0 }) end)
    ui:_listen(control.MouseLeave, function() ui:_animate(control, { BackgroundTransparency = options.Primary and 0 or 0.2 }) end)
    self:_register(options, control)
    if options.FloatingBall then
        local ball = ui:_attachFloatingBall(control, row, options.Title or options.Text or "执行",
            type(options.FloatingBall) == "table" and options.FloatingBall or {}, false)
        ball._activate = activate
    end
    return control
end

local function finiteNumber(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or math.abs(value) == math.huge then return fallback end
    return value
end

local function choiceValues(values, allowEmpty)
    assert(type(values) == "table", "Values must be an array")
    local result, seen = {}, {}
    for _, value in ipairs(values) do
        assert(type(value) == "string" or type(value) == "number" and finiteNumber(value) ~= nil, "Choices must be strings or finite numbers")
        if not seen[value] then seen[value] = true; result[#result + 1] = value end
    end
    assert(allowEmpty or #result > 0, "Values must not be empty")
    return result
end

function Section:AddCheckbox(options)
    options = options or {}
    local ui, row = self.Window, self:_row(options, 58)
    local hit = button(row, { Size = UDim2.fromScale(1, 1) })
    local square = button(hit, { Name = "Checkbox", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -22, 0.5, 0), Size = UDim2.fromOffset(23, 23), Text = "", TextSize = 16,
        TextColor3 = COLORS.White, BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0 })
    corner(square, 6)
    local control = { Value = false, Button = square }
    function control:SetValue(value, silent)
        self.Value = value == true
        square.Text = self.Value and "✓" or ""
        square.BackgroundColor3 = self.Value and ui.Accent or COLORS.Track
        if not silent then ui:_callback(options.Callback, self.Value) end
    end
    function control:GetValue() return self.Value end
    ui:_bindAccent(square, "BackgroundColor3", function(accent) return control.Value and accent or COLORS.Track end)
    local function toggle() if not control.Disabled then control:SetValue(not control.Value) end end
    ui:_listen(hit.Activated, toggle); ui:_listen(square.Activated, toggle)
    control:SetValue(options.Default, true)
    return self:_register(options, control)
end

function Section:AddNumberInput(options)
    options = options or {}
    local ui, row = self.Window, self:_row(options, 66)
    local minimum, maximum = finiteNumber(options.Min, -1e9), finiteNumber(options.Max, 1e9)
    assert(maximum >= minimum, "NumberInput Max must be >= Min")
    local precision = math.clamp(math.floor(finiteNumber(options.Decimals, 0)), 0, 6)
    local step, factor = finiteNumber(options.Step, 1), 10 ^ precision
    assert(step > 0 and step * factor >= 1, "Step must be positive and fit Decimals")
    local field = create("TextBox", { Name = "NumberInput", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -55, 0.5, 0), Size = UDim2.fromOffset(110, 33), Text = "",
        ClearTextOnFocus = false, Font = FONT, TextSize = 12, TextColor3 = COLORS.Text,
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.2 }, row)
    corner(field, 8); stroke(field, COLORS.Line, 0.25)
    local less = button(row, { Name = "Decrease", Text = "−", TextSize = 18, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -170, 0.5, 0), Size = UDim2.fromOffset(30, 33), BackgroundColor3 = COLORS.Hover, BackgroundTransparency = 0 })
    local more = button(row, { Name = "Increase", Text = "+", TextSize = 18, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(30, 33), BackgroundColor3 = COLORS.Hover, BackgroundTransparency = 0 })
    corner(less, 8); corner(more, 8)
    local control = { Value = minimum, TextBox = field, Increase = more, Decrease = less }
    function control:SetValue(value, silent)
        value = finiteNumber(value)
        if not value then field.Text = string.format("%." .. precision .. "f", self.Value); return end
        self.Value = math.clamp(math.floor(value * factor + 0.5) / factor, minimum, maximum)
        field.Text = string.format("%." .. precision .. "f", self.Value)
        if not silent then ui:_callback(options.Callback, self.Value) end
    end
    function control:GetValue() return self.Value end
    ui:_listen(less.Activated, function() if not control.Disabled then control:SetValue(control.Value - step) end end)
    ui:_listen(more.Activated, function() if not control.Disabled then control:SetValue(control.Value + step) end end)
    ui:_listen(field.FocusLost, function() control:SetValue(control.Disabled and control.Value or field.Text, control.Disabled) end)
    control:SetValue(options.Default or 0, true)
    return self:_register(options, control)
end

function Section:AddTextArea(options)
    options = options or {}
    local height = math.clamp(finiteNumber(options.Height, 110), 60, 500)
    local ui, row = self.Window, self:_row(options, height + 52)
    local maxLength = math.max(0, math.floor(finiteNumber(options.MaxLength, 4000)))
    local field = create("TextBox", { Name = "TextArea", Position = UDim2.fromOffset(20, 43), Size = UDim2.new(1, -40, 0, height),
        Text = "", PlaceholderText = options.Placeholder or "输入多行文本…", MultiLine = true, TextWrapped = true,
        TextEditable = options.ReadOnly ~= true, ClearTextOnFocus = false, Font = FONT, TextSize = 12,
        TextColor3 = COLORS.Text, PlaceholderColor3 = COLORS.Muted, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.2 }, row)
    corner(field, 9); stroke(field, COLORS.Line, 0.25)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9) }, field)
    local control = { Value = "", TextBox = field }
    function control:SetValue(value, silent)
        value = tostring(value or "")
        local count = utf8.len(value)
        if not count then return end
        if count > maxLength then value = value:sub(1, (utf8.offset(value, maxLength + 1) or (#value + 1)) - 1) end
        self.Value, field.Text = value, value
        if not silent then ui:_callback(options.Callback, value) end
    end
    function control:GetValue() return self.Value end
    function control:SetReadOnly(value)
        if not ui._destroyed and not self._destroyed then options.ReadOnly = value == true; field.TextEditable = not options.ReadOnly end
    end
    ui:_listen(field.FocusLost, function(enter)
        if control.Disabled or options.ReadOnly then field.Text = control.Value; return end
        control:SetValue(field.Text, true); ui:_callback(options.Callback, control.Value, enter)
    end)
    control:SetValue(options.Default or "", true)
    return self:_register(options, control)
end

function Section:AddParagraph(options)
    options = options or {}
    local ui, row = self.Window, self:_row({ Id = options.Id, Title = "" }, 80)
    local title = label(row, options.Title or "说明", 12, UDim2.fromOffset(20, 13), UDim2.new(1, -40, 0, 22), COLORS.Text, MEDIUM)
    local content = label(row, "", 11, UDim2.fromOffset(20, 39), UDim2.new(1, -40, 0, 24), COLORS.Secondary)
    content.TextWrapped, content.TextYAlignment = true, Enum.TextYAlignment.Top
    local control = { Label = content, TitleLabel = title }
    function control:SetText(text)
        if ui._destroyed or self._destroyed then return end
        content.Text = tostring(text or "")
        local function measure()
            local width = math.max(80, row.AbsoluteSize.X / math.max(0.01, ui._scale) - 40)
            local bounds = TextService:GetTextSize(content.Text, 11, FONT, Vector2.new(width, 100000))
            content.Size = UDim2.new(1, -40, 0, math.max(22, bounds.Y + 2))
            row.Size = UDim2.new(1, 0, 0, math.max(75, bounds.Y + 55))
        end
        measure()
    end
    ui:_listen(row:GetPropertyChangedSignal("AbsoluteSize"), function() control:SetText(content.Text) end)
    control:SetText(options.Content or options.Text or "")
    local result = self:_register(options, control)
    function result:SetTitle(text) if not ui._destroyed and not self._destroyed then title.Text = tostring(text) end end
    return result
end

function Section:AddDivider(options)
    if type(options) == "string" then options = { Title = options } end
    options = options or {}
    local row = self:_row({ Id = options.Id, Title = "" }, options.Title and 42 or 18)
    local text = label(row, options.Title or "", 10, UDim2.fromOffset(20, 0), UDim2.new(1, -40, 1, 0), COLORS.Muted, MEDIUM)
    local control = self:_register(options, { Label = text })
    local ui = self.Window
    function control:SetTitle(value) if not self._destroyed and not ui._destroyed then text.Text = tostring(value) end end
    return control
end

function Section:AddProgress(options)
    options = options or {}
    local ui, row = self.Window, self:_row(options, 78)
    local minimum, maximum = finiteNumber(options.Min, 0), finiteNumber(options.Max, 100)
    assert(maximum > minimum, "Progress Max must exceed Min")
    local valueLabel = label(row, "", 11, UDim2.new(1, -130, 0, 11), UDim2.fromOffset(108, 23), COLORS.Secondary)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local track = create("Frame", { Position = UDim2.fromOffset(20, 49), Size = UDim2.new(1, -40, 0, 7), BackgroundColor3 = COLORS.Track }, row)
    corner(track, 6)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ui.Accent }, track)
    corner(fill, 6); ui:_bindAccent(fill, "BackgroundColor3")
    local control = { Value = minimum, Fill = fill, Label = valueLabel, _excludeConfig = true }
    function control:SetValue(value, silent)
        value = finiteNumber(value)
        if not value then return end
        self.Value = math.clamp(value, minimum, maximum)
        local ratio = (self.Value - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(ratio, 1)
        valueLabel.Text = options.Format and tostring(options.Format(self.Value, ratio)) or string.format("%d%%", math.floor(ratio * 100 + 0.5))
        if not silent then ui:_callback(options.Callback, self.Value) end
    end
    function control:GetValue() return self.Value end
    control:SetValue(options.Default or minimum, true)
    return self:_register(options, control)
end

function Section:AddSelect(options)
    options = options or {}
    local values = choiceValues(options.Values, false)
    assert(#values <= 6, "Select supports up to six segments; use a dropdown or list for more")
    local ui, row = self.Window, self:_row(options, 92)
    local host = create("Frame", { Position = UDim2.fromOffset(20, 44), Size = UDim2.new(1, -40, 0, 33), BackgroundColor3 = COLORS.Track }, row)
    corner(host, 9)
    local control = { Value = values[1], Buttons = {} }
    function control:_isValidValue(value) return table.find(values, value) ~= nil end
    function control:SetValue(value, silent)
        if not table.find(values, value) then return end
        self.Value = value
        for option, item in pairs(self.Buttons) do
            item.BackgroundTransparency = option == value and 0 or 1
            item.TextColor3 = option == value and ui.Accent or COLORS.Secondary
        end
        if not silent then ui:_callback(options.Callback, value) end
    end
    function control:GetValue() return self.Value end
    for index, value in ipairs(values) do
        local item = button(host, { Name = tostring(value), Position = UDim2.new((index - 1) / #values, 2, 0, 2),
            Size = UDim2.new(1 / #values, -4, 1, -4), Text = tostring(value), BackgroundColor3 = COLORS.White, TextSize = 11 })
        corner(item, 7); control.Buttons[value] = item
        ui:_bindAccent(item, "TextColor3", function(accent) return control.Value == value and accent or COLORS.Secondary end)
        ui:_listen(item.Activated, function() if not control.Disabled then control:SetValue(value) end end)
    end
    control:SetValue(options.Default or values[1], true)
    return self:_register(options, control)
end

function Section:AddButtonGroup(options)
    options = options or {}
    assert(type(options.Buttons) == "table" and #options.Buttons > 0 and #options.Buttons <= 4, "ButtonGroup needs one to four buttons")
    local ui, row = self.Window, self:_row(options, 91)
    local control = { Buttons = {} }
    for index, entry in ipairs(options.Buttons) do
        local item = button(row, { Name = tostring(entry.Id or index), Text = entry.Text or entry.Title or "执行",
            Position = UDim2.new((index - 1) / #options.Buttons, 20, 0, 43), Size = UDim2.new(1 / #options.Buttons, -40, 0, 33),
            BackgroundColor3 = entry.Primary and ui.Accent or COLORS.Hover, BackgroundTransparency = 0,
            TextColor3 = entry.Primary and COLORS.White or COLORS.Secondary })
        corner(item, 8)
        if entry.Primary then ui:_bindAccent(item, "BackgroundColor3") end
        control.Buttons[entry.Id or index] = item
        ui:_listen(item.Activated, function() if not control.Disabled then ui:_callback(entry.Callback) end end)
    end
    return self:_register(options, control)
end

function Section:AddList(options)
    options = options or {}
    local values = choiceValues(options.Values or {}, true)
    local ui, row = self.Window, self:_row(options, 270)
    local searchEnabled = options.Searchable ~= false
    local height = math.clamp(finiteNumber(options.Height, 160), 60, 400)
    row.Size = UDim2.new(1, 0, 0, height + (searchEnabled and 92 or 55))
    local search
    if searchEnabled then
        search = create("TextBox", { Name = "Search", Text = "", PlaceholderText = options.Placeholder or "搜索选项…",
            ClearTextOnFocus = false, Position = UDim2.fromOffset(20, 41), Size = UDim2.new(1, -40, 0, 30),
            BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.2, Font = FONT, TextSize = 11, TextColor3 = COLORS.Text }, row)
        corner(search, 8); stroke(search, COLORS.Line, 0.3)
    end
    local list = create("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(20, searchEnabled and 79 or 42),
        Size = UDim2.new(1, -40, 0, height), CanvasSize = UDim2.new(), ScrollBarThickness = 3,
        BackgroundColor3 = COLORS.White, BackgroundTransparency = 0.3, Active = true, ScrollingDirection = Enum.ScrollingDirection.Y }, row)
    corner(list, 8)
    local empty = label(list, options.EmptyText or "没有匹配选项", 11, UDim2.fromOffset(10, 8), UDim2.new(1, -20, 0, 28), COLORS.Muted)
    local multi = options.Multi == true
    local control = { Value = multi and {} or nil, Items = {}, SearchBox = search, List = list, Query = "", _itemConnections = {}, _allowNil = not multi }
    function control:_isValidValue(value)
        if not multi then return value == nil or table.find(values, value) ~= nil end
        if type(value) ~= "table" then return false end
        local count = 0
        for key, entry in pairs(value) do
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or not table.find(values, entry) then return false end
            count += 1
        end
        return count == #value
    end
    local function refresh()
        local count = 0
        for _, value in ipairs(values) do
            local item = control.Items[value]
            local selected = multi and table.find(control.Value, value) ~= nil or not multi and control.Value == value
            item.Text = (multi and (selected and "✓  " or "    ") or "") .. tostring(value)
            item.TextColor3 = selected and ui.Accent or COLORS.Secondary
            item.BackgroundTransparency = selected and 0.1 or 1
            item.Visible = string.find(string.lower(tostring(value)), string.lower(control.Query), 1, true) ~= nil
            if item.Visible then item.Position = UDim2.fromOffset(5, 5 + count * 32); count += 1 end
        end
        empty.Visible = count == 0
        list.CanvasSize = UDim2.fromOffset(0, math.max(38, count * 32 + 10))
    end
    function control:SetValue(value, silent)
        if multi then
            if type(value) ~= "table" then return end
            local selected = {}
            for _, option in ipairs(values) do if table.find(value, option) then selected[#selected + 1] = option end end
            self.Value = selected
        else
            if value ~= nil and not table.find(values, value) then return end
            self.Value = value
        end
        refresh()
        if not silent then ui:_callback(options.Callback, self:GetValue()) end
    end
    function control:GetValue() return multi and table.clone(self.Value) or self.Value end
    function control:SetSearch(query)
        if ui._destroyed or self._destroyed then return end
        self.Query = tostring(query or "")
        if search and search.Text ~= self.Query then search.Text = self.Query end
        refresh()
    end
    function control:_cleanup()
        for _, connection in ipairs(self._itemConnections) do connection:Disconnect(); ui._connections[connection] = nil end
        self._itemConnections = {}
    end
    function control:SetValues(newValues, silent)
        if ui._destroyed or self._destroyed then return end
        values = choiceValues(newValues, true)
        self:_cleanup()
        for _, item in pairs(self.Items) do item:Destroy() end
        self.Items = {}
        for _, value in ipairs(values) do
            local item = button(list, { Name = tostring(value), Size = UDim2.new(1, -10, 0, 30), TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 11, BackgroundColor3 = COLORS.Hover })
            corner(item, 6); self.Items[value] = item
            self._itemConnections[#self._itemConnections + 1] = ui:_listen(item.Activated, function()
                if self.Disabled or self._destroyed then return end
                if multi then
                    local selected = self:GetValue(); local at = table.find(selected, value)
                    if at then table.remove(selected, at) else selected[#selected + 1] = value end
                    self:SetValue(selected)
                else self:SetValue(value) end
            end)
        end
        self:SetValue(multi and self.Value or table.find(values, self.Value) and self.Value or nil, silent)
    end
    if search then ui:_listen(search:GetPropertyChangedSignal("Text"), function() control:SetSearch(search.Text) end) end
    control:SetValues(values, true)
    control:SetValue(options.Default or (multi and {} or nil), true)
    ui:_bindAccent(list, "ScrollBarImageColor3", function(accent) refresh(); return accent end)
    return self:_register(options, control)
end

function Section:AddKeybind(options)
    options = options or {}
    local ui, row = self.Window, self:_row(options, 66)
    local proxy = { Value = false }
    function proxy:GetValue() return self.Value end
    function proxy:SetValue(value) self.Value = value == true; ui:_callback(options.Callback, self.Value) end
    local pickerOptions = table.clone(options); pickerOptions.Id, pickerOptions.Callback = nil, options.Changed
    local picker = ui:_addKeyPicker(proxy, row, pickerOptions)
    picker.Button.Position = UDim2.new(1, -22, 0.5, 0)
    local result = self:_register(options, picker)
    if options.Id then ui._defaults[tostring(options.Id)] = { Key = picker.Value, Mode = picker.Mode } end
    return result
end

function Window:GetValues()
    local values = {}
    for id, control in pairs(self.Controls) do
        if typeof(control) ~= "Instance" and type(control.GetValue) == "function" and not control._excludeConfig and not control._destroyed then
            values[id] = control:GetValue()
        end
    end
    return values
end

function Window:SetValues(values, silent)
    assert(type(values) == "table", "SetValues expects a table")
    local failed = {}
    for id, value in pairs(values) do
        local control = self.Controls[tostring(id)]
        if control and typeof(control) ~= "Instance" and type(control.SetValue) == "function" and not control._excludeConfig then
            local ok, message = pcall(control.SetValue, control, value, silent == true)
            if not ok then failed[tostring(id)] = tostring(message) end
        end
    end
    return failed
end

function Window:ExportConfig()
    local values = {}
    for id, control in pairs(self.Controls) do
        if typeof(control) ~= "Instance" and type(control.GetValue) == "function" and type(control.SetValue) == "function"
            and not control._excludeConfig and not control._destroyed then
            local value = control:GetValue()
            if value == nil then values[id] = { Type = "Nil" }
            elseif typeof(value) == "Color3" then values[id] = { Type = "Color3", Value = { value.R, value.G, value.B } }
            elseif control.GetMode then values[id] = { Type = "Keybind", Value = value, Mode = control:GetMode() }
            else values[id] = { Type = "Value", Value = type(value) == "table" and table.clone(value) or value } end
        end
    end
    return { Version = 1, Values = values }
end

function Window:ImportConfig(config, silent)
    assert(type(config) == "table" and config.Version == 1 and type(config.Values) == "table", "Unsupported AURA config")
    local values, modes, nils = {}, {}, {}
    local failed = {}
    for id, entry in pairs(config.Values) do
        local control = self.Controls[tostring(id)]
        if control and typeof(control) ~= "Instance" and type(control.GetValue) == "function" and type(control.SetValue) == "function"
            and not control._excludeConfig and type(entry) == "table" then
            local current = control:GetValue()
            if entry.Type == "Color3" and typeof(current) == "Color3" then
                local v = entry.Value
                if type(v) == "table" and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number"
                    and finiteNumber(v[1]) and finiteNumber(v[2]) and finiteNumber(v[3]) then
                    values[id] = Color3.new(math.clamp(v[1], 0, 1), math.clamp(v[2], 0, 1), math.clamp(v[3], 0, 1))
                else failed[tostring(id)] = "Invalid color" end
            elseif entry.Type == "Keybind" and control.GetMode then
                if bindingName(entry.Value) and (entry.Mode == "Toggle" or entry.Mode == "Hold") then
                    values[id], modes[id] = entry.Value, entry.Mode
                else failed[tostring(id)] = "Invalid keybind" end
            elseif entry.Type == "Nil" and control._allowNil then
                nils[id] = true
            elseif entry.Type == "Value" and not control.GetMode
                and (type(current) == type(entry.Value) and typeof(current) == typeof(entry.Value) or current == nil and control._allowNil)
                and (type(entry.Value) ~= "number" or finiteNumber(entry.Value) ~= nil) then
                if control._isValidValue and not control:_isValidValue(entry.Value) then failed[tostring(id)] = "Invalid choice"
                else values[id] = entry.Value end
            else failed[tostring(id)] = "Value type mismatch" end
        end
    end
    -- Set key modes before replaying values so Hold bindings cannot restore a latched key.
    for id, mode in pairs(modes) do self.Controls[tostring(id)]:SetMode(mode, true) end
    for id in pairs(values) do
        local control = self.Controls[tostring(id)]
        if control.KeyPicker and control.KeyPicker:GetMode() == "Hold" then values[id] = false end
    end
    for id, message in pairs(self:SetValues(values, silent)) do failed[id] = message end
    for id in pairs(nils) do
        local ok, message = pcall(self.Controls[tostring(id)].SetValue, self.Controls[tostring(id)], nil, silent == true)
        if not ok then failed[id] = tostring(message) end
    end
    return failed
end

function Window:ResetValues(silent)
    local values = {}
    for id, default in pairs(self._defaults) do
        local control = self.Controls[id]
        if control and control.GetMode and type(default) == "table" and default.Key then
            control:SetMode(default.Mode, true); values[id] = default.Key
        else values[id] = type(default) == "table" and table.clone(default) or default end
    end
    for id in pairs(values) do
        local control = self.Controls[id]
        if control and control.KeyPicker and control.KeyPicker:GetMode() == "Hold" then values[id] = false end
    end
    local failed = self:SetValues(values, silent)
    for id in pairs(self._nilDefaults) do
        local control = self.Controls[id]
        if control then
            local ok, message = pcall(control.SetValue, control, nil, silent == true)
            if not ok then failed[id] = tostring(message) end
        end
    end
    return failed
end

function Window:Dialog(options)
    options = options or {}
    if self._destroyed then return nil end
    if self._dialog then self._dialog:Close("replaced") end
    self:_cancelKeyCapture(); self:_closeDropdown(); self:_releaseKeyHolds(); self._pointer = nil
    self:SetVisible(true)
    local ui = self
    local viewport = self:_viewport()
    local width = math.min(420, math.max(160, viewport.X - 32))
    local bodyHeight = TextService:GetTextSize(tostring(options.Content or ""), 12, FONT, Vector2.new(width - 44, 10000)).Y
    local height = math.min(math.max(170, bodyHeight + 130), math.max(140, viewport.Y - 32))
    local overlay = button(screen, { Name = "DialogOverlay", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = COLORS.Graphite, BackgroundTransparency = 0.6, ZIndex = 120, Active = true, Modal = true })
    local panel = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height), BackgroundColor3 = COLORS.White, ZIndex = 121 }, overlay)
    corner(panel, 16); stroke(panel, COLORS.Line, 0.2)
    label(panel, tostring(options.Title or "提示"), 16, UDim2.fromOffset(22, 15), UDim2.new(1, -44, 0, 30), COLORS.Text, MEDIUM)
    local scroll = create("ScrollingFrame", { Position = UDim2.fromOffset(22, 53), Size = UDim2.new(1, -44, 1, -113),
        BackgroundTransparency = 1, CanvasSize = UDim2.fromOffset(0, bodyHeight), ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y, Active = true }, panel)
    local content = label(scroll, tostring(options.Content or ""), 12, UDim2.new(), UDim2.new(1, -5, 0, bodyHeight), COLORS.Secondary)
    content.TextWrapped, content.TextYAlignment = true, Enum.TextYAlignment.Top
    local handle = { Frame = panel, Closed = false }
    function handle:Close(reason)
        if self.Closed then return end
        self.Closed, self.Reason = true, reason or "closed"
        overlay:Destroy()
        if ui._dialog == self then ui._dialog = nil end
        ui:_callback(options.OnClose, self.Reason)
    end
    function handle:Confirm()
        if self.Closed or ui._destroyed then return end
        self:Close("confirmed"); ui:_callback(options.Callback, true)
    end
    function handle:Cancel()
        if self.Closed or ui._destroyed then return end
        self:Close("cancelled"); ui:_callback(options.Callback, false)
    end
    local cancel = button(panel, { Text = options.CancelText or "取消", Position = UDim2.new(0.5, -4, 1, -49),
        AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0.5, -22, 0, 32), BackgroundColor3 = COLORS.Hover, BackgroundTransparency = 0 })
    local confirm = button(panel, { Text = options.ConfirmText or "确定", Position = UDim2.new(0.5, 4, 1, -49),
        Size = UDim2.new(0.5, -26, 0, 32), BackgroundColor3 = ui.Accent, BackgroundTransparency = 0, TextColor3 = COLORS.White })
    corner(cancel, 8); corner(confirm, 8); ui:_bindAccent(confirm, "BackgroundColor3")
    self:_listen(cancel.Activated, function() handle:Cancel() end)
    self:_listen(confirm.Activated, function() handle:Confirm() end)
    handle.ConfirmButton, handle.CancelButton = confirm, cancel
    self._dialog = handle
    return handle
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
    if self._dialog then self._dialog:Close("destroyed") end
    local balls = {}
    for _, ball in pairs(self._floatingBalls) do table.insert(balls, ball) end
    for _, ball in ipairs(balls) do ball:Destroy() end
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
    if input.UserInputType == Enum.UserInputType.MouseMovement then Window:_updateMouseCursor() end
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
    if Window._dialog then
        if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.Escape then Window._dialog:Cancel() end
        return
    end
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
