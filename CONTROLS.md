# AURA 1.4.7 控件与配置

本次保持 gethui 挂载、右Alt显隐和现有1.4.x调用方式。旧AddButton/AddLabel继续返回原生实例；其他控件返回可操作的Lua表。示例见[ui.example.lua](ui.example.lua)。

## 新增控件

| 方法 | 参数与用途 |
|---|---|
| `section:AddCheckbox(options)` | 方形复选框；Default、Callback(boolean) |
| `section:AddNumberInput(options)` | 数字输入与加减步进；Min、Max、Step=1、Decimals=0、Default |
| `section:AddTextArea(options)` | 多行文本；Default、Height=110、MaxLength=4000、ReadOnly、Placeholder |
| `section:AddSelect(options)` | 1–6个分段单选按钮；Values、Default |
| `section:AddList(options)` | 滚动单选/多选列表；Values={}、Default、Multi=false、Searchable=true、Height=160、EmptyText |
| `section:AddProgress(options)` | 进度显示；Min=0、Max=100、Default、可选Format(value,fraction) |
| `section:AddParagraph(options)` | 自动换行说明段落；Title、Content或Text |
| `section:AddDivider(optionsOrTitle)` | 分隔线与可选标题；字符串或{Id,Title} |
| `section:AddButtonGroup(options)` | 1–4个并排操作按钮；Buttons={{Id,Text,Primary,Callback},…} |
| `section:AddKeybind(options)` | 独立快捷键；Default="None"、Mode="Toggle"/"Hold"、Callback(active)、Changed(keyName,mode) |

可编辑值控件提供 `SetValue(value, silent)`、`GetValue()`，创建时默认值不触发回调。`silent=true` 只同步控件，不执行功能回调。

数字输入拒绝无效及非有限值，限制范围并按Decimals舍入。Step必须为正且符合小数精度。文本框按Unicode字符截断，不截坏中文；提交时机为失去焦点。TextArea Height范围60–500，列表Height范围60–400。

选择值使用字符串或有限数字。列表与分段选择自动去重。列表搜索不区分英文字母大小写，使用字面子串匹配，不执行Lua pattern；支持中文子串。多选GetValue和Callback取得独立数组，修改数组不会改坏内部状态。单选列表默认可以没有选择。

复选框是普通值，不自动加入已开启功能列表。需要功能跟踪及行内快捷键时继续使用AddToggle。独立快捷键左键录入、Escape清空、右键选择Toggle/Hold；Toggle每按一次交替回调true/false，Hold按下true、松开false。输入框聚焦和已处理输入不会激活快捷键，禁用/隐藏/销毁会释放正在保持的Hold动作。

## 动态控件与布局

```lua
local section = tab:AddSection({Title="目标", Collapsible=true, Collapsed=false})
local list = section:AddList({Id="players", Title="玩家", Values={}, Multi=true})
list:SetValues({"玩家A", "玩家B"}, true)
list:SetSearch("玩家")
list:SetValue({"玩家B"})

local dropdown = section:AddDropdown({
    Id="preset", Title="预设", Values={"默认", "练习"}, Searchable=true,
})
dropdown:SetValues({"练习", "新预设"}, true)

section:SetCollapsed(true)
section:SetVisible(true)
```

List:SetValues会释放旧条目的事件连接并保留仍有效的选择，单选值被移除后清空。Dropdown:SetValues保留有效选择，否则选择第一项；刷新为空数组时清空。Dropdown初次创建仍要求非空Values；Searchable=true为弹出菜单增加搜索框。

表类型控件句柄支持：

| 方法 | 行为 |
|---|---|
| `SetVisible(boolean)` | 显示/隐藏整行，不改控件值 |
| `SetEnabled(boolean)` | 用禁用遮罩阻挡操作；程序仍可SetValue |
| `SetTitle(text)` | 动态修改标题 |
| `Destroy()` | 删除控件行和注册信息，释放相关快捷键；后续SetValue忽略 |

创建选项 `Visible=false`、`Disabled=true` 设置初始状态。原生AddButton/AddLabel不附加Lua方法，用原生属性与Destroy；需要整体状态操作的按钮使用AddButtonGroup。Section.Frame是整张卡片，Header是标题区域，Body是控件容器。

专用方法与引用：

- Paragraph：SetText(text)、SetTitle(text)、Label、TitleLabel。
- TextArea：SetReadOnly(boolean)、TextBox。
- NumberInput：TextBox、Increase、Decrease。
- Progress：Fill、Label；不参与配置保存和恢复。
- Select/ButtonGroup：Buttons[valueOrId]。
- List：Items[value]、SearchBox（启用时）、List。
- Dropdown：Button；Menu/SearchBox仅在菜单打开期间存在。

## 确认弹窗

```lua
window:Dialog({
    Title="恢复默认", Content="将当前控件恢复为创建时的默认值。",
    ConfirmText="恢复", CancelText="取消",
    Callback=function(confirmed)
        if confirmed then window:ResetValues() end
    end,
    OnClose=function(reason) print(reason) end,
})
```

每个窗口同时最多一个弹窗，长内容内部滚动。返回句柄包含Confirm()、Cancel()、Close(reason)、Closed、Reason、Frame、ConfirmButton、CancelButton。确定/取消只回调一次；直接Close只触发OnClose。Escape取消，替换/隐藏/销毁分别以replaced/hidden/destroyed关闭。打开弹窗会展开所属窗口并暂停其功能快捷键。

## 配置快照

```lua
local config = window:ExportConfig() -- {Version=1, Values={...}}
local failures = window:ImportConfig(config, true)
window:ResetValues(true)

local values = window:GetValues()
window:SetValues({enabled=false, speed=50}, true)

-- 本地文件配置（设置页自动提供同样操作）：
window:CreateSettingsTab() -- 已有“设置”页时自动添加，无需重复创建
local ok, path = window:SaveConfig("日常")
local loaded, failures = window:LoadConfig("日常")
local names, message = window:ListConfigs()
window:DeleteConfig("日常")
print(window:GetConfigFolder()) -- robluauui/<创建窗口时的Title>
```

导出包含有Id的可编辑控件和快捷键模式；Color3转RGB数组，空选择使用显式Nil条目。按钮、段落、进度等不参与。GetValues返回当前值映射，保留原生Color3且省略nil；需要跨会话保存时使用ExportConfig。

ImportConfig核对版本、类型、颜色、键名、模式和当前可选值，返回按控件Id列出的错误表，未知Id忽略。数值继续按控件范围/精度处理。Hold快捷键不会恢复为一直按住。ResetValues恢复创建时记录的默认值；动态选项如果已改变，先恢复列表数据，旧默认值才可能重新有效。

默认会调用控件Callback；silent=true仅改UI状态，调用方需同步自身功能状态。ExportConfig/ImportConfig仍为内存接口；SaveConfig/LoadConfig访问执行器工作区文件，不上传、不执行配置内容，也不自动加载功能状态。

设置页自动增加“配置”分类：配置名称、已有配置列表、保存／覆盖、加载、刷新、删除、恢复默认。识别Id为settings、标题为Settings或中文包含“设置”的页面；其他页面可调用window:AddConfigSection(tab)。新脚本可使用window:CreateSettingsTab()创建，CreateWindow({Configs=false})可关闭自动添加。

配置文件为robluauui/<创建窗口时Title>/<配置名>.json。创建时获取的标题作为固定目录，之后SetTitle只更改显示。普通中文标题直接保留；斜杠等非法路径字符可逆编码，避免简单替换字符造成目录重名。文件内再次校验所属标题；配置名拒绝路径跳转和系统保留名称。保存后已有同名配置会覆写。缺少文件接口或读写失败会在界面显示原因。

有Id的功能、快捷键和快捷球参与保存；自动为控件配对且无独立Id的KeyPicker也会随功能Id保存。快捷球保存显示状态、锁定、宽高和相对屏幕位置。加载Hold配置不会把功能恢复为一直按住。管理界面自身的配置名称、列表不进入配置文件。恢复默认会重置快捷键和快捷球布局，但保留配置管理器输入。

## 独立悬浮球（快捷球）

按钮和开关可通过 `FloatingBall=true` 启用此控件，会在原控件行中间添加「快捷球」开关；默认关闭。开启后，功能名称显示在屏幕中央的25×25小球中，主窗口收起后仍然显示。

```lua
local feature = section:AddToggle({
    Id = "feature", Title = "功能名称", Default = false,
    FloatingBall = true,
    Callback = function(enabled) print(enabled) end,
})

local action = section:AddButton({
    Id = "action", Title = "执行操作",
    FloatingBall = { Enabled = false, Locked = false, Width = 25, Height = 25 },
    Callback = function() print("执行") end,
})

-- 已创建的开关也可后续添加；每个控件最多一个快捷球。
-- local ball = anotherToggle:AddFloatingBall({ Width = 25, Height = 35 })
local ball = window:GetFloatingBall("feature") -- 也接受控件本身
-- 开关亦可使用 feature.FloatingBall；action继续返回原生TextButton。
ball:SetEnabled(true)
ball:SetLocked(false)
ball:SetSize(25, 35)
-- ball:SetTitle("自定义名称")
-- ball:Destroy() -- 删除快捷球及行内开关，保留原功能控件
```

未锁定时，左键点击不执行功能，长按0.2秒后可拖动；锁定后，左键点击执行按钮或切换功能，不能拖动。右键菜单提供锁定／解除锁定、关闭快捷球、宽高输入与应用大小，宽高分别限制为16–256像素。触摸长按支持拖动，锁定后轻触执行。

带AddKeyPicker的开关和AddKeybind独立快捷键会自动配对快捷球，默认隐藏；已显式创建的球会复用，FloatingBall=false可关闭自动配对。Toggle模式共享同一个开关状态；Hold模式的锁定球按住生效、松开释放，失焦、关闭球或解除锁定也会释放。

关闭快捷球只隐藏它并关闭对应「快捷球」开关，不会关闭Toggle功能；正在按住的Hold功能会释放。重新开启保留当前会话的位置、锁定状态和大小。功能开关关闭为白底、开启为蓝底，普通UI点击、快捷键、SetValue及配置恢复都会同步；无持续状态的按钮执行时短暂变蓝0.25秒。禁用源控件或打开模态弹窗时，小球不能执行功能。控件或窗口销毁时自动清理小球、菜单和监听。快捷球的显示、位置、尺寸和锁定状态已纳入配置快照。

示例的「专注模式」和「显示通知」提供「快捷球」开关。自动配对和文件配置需要AURA 1.4.7+。

## 验证与边界

`python ui-checks/run_checks.py`验证现有与新增控件的真实库源码、严格原生成员访问、搜索过滤、动态刷新、配置、弹窗、键盘和清理。EMDEN与家庭防御各自的集成检查也已通过。离线测试不能替代Roblox中的实际字体布局、触屏体验及执行器兼容性验证。
