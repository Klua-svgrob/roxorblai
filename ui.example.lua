local UI_URL = "https://raw.githubusercontent.com/Klua-svgrob/roxorblai/main/ui.lua"
local source
if type(isfile) == "function" and type(readfile) == "function" then
    for _, path in ipairs({ "现代化luauui/ui.lua", "ui.lua" }) do
        local ok, text = pcall(function() if isfile(path) then return readfile(path) end end)
        if ok and type(text) == "string" then source = text; break end
    end
end
source = source or game:HttpGet(UI_URL)
local chunk, compileError = loadstring(source, "AURA.UI")
assert(chunk, compileError)
local UI = chunk()
local patchVersion = type(UI) == "table" and type(UI.Version) == "string" and tonumber(UI.Version:match("^1%.4%.(%d+)$"))
assert(patchVersion and patchVersion >= 6, "此示例需要 AURA 1.4.6+，请更新本地或远程 ui.lua")

local window = UI:CreateWindow({
    Id = "aura-demo", Title = "aura", Subtitle = "为专注留一点空间",
    Footer = "AURA / PERSONAL SPACE", ToggleKey = Enum.KeyCode.RightAlt,
    Width = 916, Height = 612, Glass = true, Blur = 18, Transparency = 0.12,
    NotificationLimit = 3, NotificationDuration = 4,
})

local main = window:CreateTab({ Id = "main", Title = "概览", Icon = "grid", Description = "你的空间，由你定义。" })
main:AddHero()
local appearance = main:AddSection({ Title = "外观偏好", Description = "按照你的习惯，调整这个空间。" })
local focus = appearance:AddToggle({ Id = "focus", Title = "专注模式", Default = false, FloatingBall = true })
focus:AddKeyPicker({ Id = "focus-key", Default = "None", Mode = "Toggle" })
appearance:AddToggle({ Id = "glass", Title = "毛玻璃", Description = "让背景柔和地融入界面", Default = true,
    Callback = function(value) window:SetGlass(value) end })
appearance:AddToggle({ Id = "motion", Title = "柔和动效", Default = true,
    Callback = function(value) window:SetMotion(value) end })
appearance:AddSlider({ Id = "blur", Title = "背景模糊", Min = 0, Max = 32, Default = 18,
    Callback = function(value) window:SetBlur(value) end })

local components = window:CreateTab({ Id = "components", Title = "控件展示", Icon = "grid", Description = "输入、选择、反馈与配置。" })
local inputs = components:AddSection({ Title = "常用输入", Collapsible = true })
inputs:AddCheckbox({ Id = "demo-check", Title = "启用提示", Default = true })
local progress = inputs:AddProgress({ Id = "demo-progress", Title = "完成度", Default = 35 })
inputs:AddNumberInput({ Id = "demo-number", Title = "调整进度", Min = 0, Max = 100, Step = 5, Default = 35,
    Callback = function(value) progress:SetValue(value) end })
inputs:AddSelect({ Id = "demo-select", Title = "运行模式", Values = { "安静", "均衡", "性能" }, Default = "均衡" })
inputs:AddTextArea({ Id = "demo-notes", Title = "备注", Default = "支持多行文本。\n这里可以记录你的设置。", MaxLength = 500 })
inputs:AddKeybind({ Id = "demo-key", Title = "独立快捷键", Default = "None", Mode = "Toggle",
    Callback = function(active) window:Notify({ Title = "快捷键", Content = active and "已激活" or "已释放" }) end })
local choices = components:AddSection({ Title = "动态选项", Collapsible = true })
choices:AddDropdown({ Id = "demo-dropdown", Title = "搜索下拉框", Values = { "默认配置", "日常使用", "测试配置" }, Searchable = true })
local list = choices:AddList({ Id = "demo-list", Title = "多选列表", Values = { "通知", "快捷键", "自动保存", "显示状态" },
    Multi = true, Default = { "通知", "快捷键" }, Searchable = true, Height = 130 })
choices:AddDivider("操作")
choices:AddButtonGroup({ Id = "demo-list-actions", Title = "列表操作", Buttons = {
    { Id = "refresh", Text = "刷新选项", Callback = function() list:SetValues({ "通知", "快捷键", "新的选项" }) end },
    { Id = "clear", Text = "清空选择", Callback = function() list:SetValue({}) end },
} })
local config = components:AddSection({ Title = "配置快照", Collapsible = true })
config:AddParagraph({ Title = "保存与恢复", Content = "导出返回普通Lua表，可自行用HttpService转JSON保存。本例只保存在内存中。" })
local snapshot
config:AddButtonGroup({ Id = "demo-config-actions", Title = "配置操作", Buttons = {
    { Id = "save", Text = "保存快照", Primary = true, Callback = function()
        snapshot = window:ExportConfig()
        window:Notify({ Title = "配置", Content = "已保存当前控件快照。" })
    end },
    { Id = "load", Text = "恢复快照", Callback = function()
        if snapshot then window:ImportConfig(snapshot) else window:Notify({ Title = "配置", Content = "请先保存快照。" }) end
    end },
    { Id = "reset", Text = "恢复默认", Callback = function()
        window:Dialog({ Title = "恢复默认设置", Content = "将已注册的输入和选项恢复到创建时的默认值。", ConfirmText = "恢复",
            Callback = function(confirmed) if confirmed then window:ResetValues() end end })
    end },
} })

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
actions:AddButton({ Id = "show-notice", Title = "显示通知", Text = "试试看", Primary = true, FloatingBall = true,
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
