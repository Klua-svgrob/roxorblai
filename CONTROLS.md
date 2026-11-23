# AURA 1.4.5 控件与配置

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

-- 如需持久化，由调用方选择路径并处理文件权限：
local json = game:GetService("HttpService"):JSONEncode(config)
```

导出包含有Id的可编辑控件和快捷键模式；Color3转RGB数组，空选择使用显式Nil条目。按钮、段落、进度等不参与。GetValues返回当前值映射，保留原生Color3且省略nil；需要跨会话保存时使用ExportConfig。

ImportConfig核对版本、类型、颜色、键名、模式和当前可选值，返回按控件Id列出的错误表，未知Id忽略。数值继续按控件范围/精度处理。Hold快捷键不会恢复为一直按住。ResetValues恢复创建时记录的默认值；动态选项如果已改变，先恢复列表数据，旧默认值才可能重新有效。

默认会调用控件Callback；silent=true仅改UI状态，调用方需同步自身功能状态。配置接口不自动访问磁盘、不上传、不执行配置内容。它是可JSON序列化的值快照，而非自动保存管理器。

## 验证与边界

`python ui-checks/run_checks.py`验证现有与新增控件的真实库源码、严格原生成员访问、搜索过滤、动态刷新、配置、弹窗、键盘和清理。EMDEN与家庭防御各自的集成检查也已通过。离线测试不能替代Roblox中的实际字体布局、触屏体验及执行器兼容性验证。
