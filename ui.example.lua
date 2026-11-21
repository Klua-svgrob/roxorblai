local UI_URL = "https://raw.githubusercontent.com/Klua-svgrob/roxorblai/main/ui.lua"
local source = game:HttpGet(UI_URL)
local chunk, compileError = loadstring(source, "AURA.UI")
assert(chunk, compileError)
local UI = chunk()

local window = UI:CreateWindow({
    Id = "aura-demo", Title = "aura", Subtitle = "为专注留一点空间",
    Footer = "AURA / PERSONAL SPACE", ToggleKey = Enum.KeyCode.RightAlt,
    Width = 916, Height = 612, Glass = true, Blur = 18, Transparency = 0.12,
    NotificationLimit = 3, NotificationDuration = 4,
})

local main = window:CreateTab({ Id = "main", Title = "概览", Icon = "grid", Description = "你的空间，由你定义。" })
main:AddHero()
local appearance = main:AddSection({ Title = "外观偏好", Description = "按照你的习惯，调整这个空间。" })
local focus = appearance:AddToggle({ Id = "focus", Title = "专注模式", Default = false })
focus:AddKeyPicker({ Id = "focus-key", Default = "None", Mode = "Toggle" })
appearance:AddToggle({ Id = "glass", Title = "毛玻璃", Description = "让背景柔和地融入界面", Default = true,
    Callback = function(value) window:SetGlass(value) end })
appearance:AddToggle({ Id = "motion", Title = "柔和动效", Default = true,
    Callback = function(value) window:SetMotion(value) end })
appearance:AddSlider({ Id = "blur", Title = "背景模糊", Min = 0, Max = 32, Default = 18,
    Callback = function(value) window:SetBlur(value) end })

local settings = window:CreateTab({ Id = "settings", Title = "界面设置", Icon = "settings", Description = "让这个空间更像你。" })
local display = settings:AddSection({ Title = "显示" })
display:AddSlider({ Id = "scale", Title = "窗口缩放", Min = 75, Max = 115, Default = 100, Suffix = "%",
    Callback = function(value) window:SetScale(value / 100) end })
display:AddSlider({ Id = "opacity", Title = "玻璃透明度", Min = 4, Max = 36, Default = 12, Suffix = "%",
    Callback = function(value) window:SetTransparency(value / 100) end })
display:AddColorPicker({ Id = "accent", Title = "强调色", Description = "拖动色彩面板选色，或点击预设色块", Expanded = true,
    Default = Color3.fromRGB(73, 102, 197), Callback = function(color) window:SetAccent(color) end })
display:AddToggle({ Id = "unlock-mouse", Title = "打开界面时解锁鼠标", Default = true, FeatureList = false,
    Callback = function(enabled) window:SetMouseUnlocked(enabled) end })
display:AddInput({ Id = "name", Title = "空间名称", Default = "aura", Placeholder = "输入名称…",
    Callback = function(value) window:SetTitle(value ~= "" and value or "aura") end })

local features = settings:AddSection({ Title = "已开启功能" })
features:AddToggle({ Id = "feature-display", Title = "显示已开启功能", Default = false, FeatureList = false,
    Callback = function(value) window:SetFeatureList({ Enabled = value }) end })
local featurePositions = { ["右下角"] = "BottomRight", ["左上角"] = "TopLeft", ["右上角"] = "TopRight", ["中下"] = "BottomCenter", ["中上"] = "TopCenter" }
features:AddDropdown({ Id = "feature-position", Title = "显示位置", Values = { "右下角", "左上角", "右上角", "中下", "中上" }, Default = "右上角",
    Callback = function(value) window:SetFeatureList({ Position = featurePositions[value] }) end })
features:AddToggle({ Id = "feature-scroll", Title = "滚动显示", Default = false, FeatureList = false,
    Callback = function(value) window:SetFeatureList({ Scrolling = value }) end })

local about = window:CreateTab({ Id = "about", Title = "关于", Icon = "info", Description = "简单一些，也可以很好。" })
about:AddHero({ Title = "轻一点，\n刚刚好。", Description = "把注意力，留给真正重要的事。" })
local actions = about:AddSection({ Title = "通知示例" })
actions:AddButton({ Id = "show-notice", Title = "显示通知", Text = "试试看", Primary = true,
    Callback = function()
        window:Notify({ Title = "已准备就绪", Content = "这是可暂停、可关闭的通知。", Type = "success", Duration = 5 })
    end })
actions:AddButton({ Title = "多条通知", Text = "查看堆叠",
    Callback = function()
        for _, kind in ipairs({ "info", "success", "warning", "error" }) do
            window:Notify({ Title = kind, Content = "最多显示三条，新通知会自动移除最旧的一条。", Type = kind })
        end
    end })
actions:AddButton({ Title = "暂时收起", Text = "收起界面", Callback = function() window:SetVisible(false) end })
actions:AddButton({ Title = "卸载界面", Text = "卸载", Callback = function() window:Destroy() end })

window:Notify({ Id = "startup", Title = "欢迎回来", Content = "界面已加载，RightAlt 显示 / 隐藏。", Type = "success" })
return window
