---
title: "World of Warcraft AuraContainer：AI 技术参考"
language: "zh-CN"
game_flavor: "Mainline PTR"
interface_version: "12.1.0"
verified_build: "12.1.0.68914"
verified_date: "2026-07-24"
stability: "PTR API，正式服上线前仍可能变化"
primary_topic: "CustomAuraContainerTemplate / CustomAuraButtonTemplate"
---

# World of Warcraft AuraContainer：AI 技术参考

> 本文面向需要生成、审查或解释 WoW 插件 Lua 代码的 AI。  
> 结论以 **12.1.0 PTR build 68914** 的界面源码为准，不应把较早 PTR 周次的示例当成最终接口。

## 1. 一句话定义

`AuraContainer` 是 12.1.0 提供的安全光环显示系统：

- Blizzard 的安全代码负责读取、刷新、筛选、排序和分配光环。
- 插件负责声明“显示哪些光环”以及“每个光环按钮长什么样”。
- 插件应把 `Texture`、`FontString`、`Cooldown`、`StatusBar` 等显示对象注册给 `CustomAuraButton`，而不是自行读取可能属于 secret 的光环数据。

最常用入口是：

```lua
local container = CreateFrame(
    "AuraContainer",
    nil,
    parent,
    "CustomAuraContainerTemplate"
)
```

随后：

```lua
container:SetUnit("target")
container:AddAuraGroup("debuffs", "HARMFUL", options)
```

## 2. AI 必须遵守的核心规则

生成代码时，优先遵守以下规则：

1. 使用 `CustomAuraContainerTemplate` 创建容器。
2. 使用 `AddAuraGroup` 显示多个光环；使用 `AddAuraSlot` 显示优先级最高的单个光环。
3. 只在 `initializeFrame(button)` 中创建并注册按钮的显示子对象。
4. 注册给按钮的显示对象必须是该按钮的直接或间接子对象。
5. 不要创建自定义 `OnUpdate` 去轮询 `C_UnitAuras`。
6. 不要依赖读取 `button` 内部光环数据、私有字段或安全实现细节。
7. 不要直接创建 `CustomAuraButtonTemplate` 按钮；让容器创建和管理按钮。
8. SpellID 过滤使用集合形式：`{ [spellID] = true }`，不是 `{ spellID }`。
9. 剩余时间颜色曲线应注册到 `SetDurationText`；不能假设普通 `Texture` 或图标支持持续时间颜色绑定。
10. 12.1.0 当前参数名是 `textColor`，不是较早 PTR 示例中的 `textColorCurve`。

## 3. 对象模型

```text
CustomAuraContainerTemplate
├─ AuraGroup（0..N 个动态 AuraButton，自动参与流式布局）
│  ├─ CustomAuraButton
│  │  ├─ Icon Texture
│  │  ├─ Duration FontString
│  │  ├─ Duration Cooldown
│  │  ├─ Duration StatusBar
│  │  ├─ Application Count / Bar
│  │  └─ Dispel Type Textures / Text
│  └─ ...
├─ AuraSlot（恰好一个 AuraButton，需手动锚定）
└─ ItemEnchantment（武器临时附魔显示）
```

### 3.1 AuraGroup

- 接收所有通过过滤器的光环。
- 根据排序规则分配前 `maxFrameCount` 个按钮。
- 动态按钮参与容器的流式布局。
- 容器会按内容自动修改自己的尺寸。

### 3.2 AuraSlot

- 从候选光环中选择排序最靠前的一个。
- 返回一个按钮对象。
- 不参与动态流式布局，插件必须手动设置位置。
- 适合特定 SpellID、驱散提示、重要减伤等单指示器。

### 3.3 CustomAuraButton

- 由容器创建。
- 插件通过 `initializeFrame` 配置。
- 安全代码把当前光环的图标、持续时间、层数、驱散类型等写入已注册的显示对象。
- 按钮可能受到 secret/forbidden 访问限制；不要在光环分配后尝试检查内部状态。

## 4. 安全模型

12.1.0 的重点不是“换了一组读取 API”，而是把光环数据处理转移到受控容器中。

### 4.1 正确模式

```text
插件声明过滤和显示结构
          ↓
AuraContainer 安全代码读取光环
          ↓
安全代码过滤、排序、分配
          ↓
安全代码更新已注册的显示对象
```

### 4.2 错误模式

```text
UNIT_AURA / OnUpdate
          ↓
插件读取光环剩余时间或 SpellID
          ↓
插件自己决定显示内容和颜色
```

后者在 secret 光环环境中可能不可用，也违背 AuraContainer 的设计目的。

### 4.3 初始化时机

`initializeFrame` 在按钮创建时调用。容器会预先成批创建按钮，以降低通过按钮创建次数推断光环数量的可能性。

建议：

- 在插件加载阶段或进入世界前完成结构初始化。
- 尽量不要在战斗中首次创建整套容器。
- 在 `initializeFrame` 中一次性创建所有子对象和绑定。
- 后续只通过容器公开的 setter 修改过滤、排序或布局。

## 5. 容器基础接口

来自基础 `AuraContainer`：

| 方法 | 用途 |
|---|---|
| `SetUnit(unitToken)` | 设置观察单位，例如 `"player"`、`"target"`、`"party1"` |
| `GetUnit()` | 返回当前单位 |
| `SetEnabled(enabled)` | 启用或禁用刷新 |
| `IsEnabled()` | 查询启用状态 |
| `UpdateAllAuras()` | 请求完整刷新 |

来自 `CustomAuraContainer`：

| 方法 | 返回值/用途 |
|---|---|
| `AddAuraGroup(groupKey, filterString, options)` | 添加动态光环组 |
| `HasAuraGroup(groupKey)` | 是否存在指定组 |
| `GetAuraGroupFrame(groupKey, frameIndex)` | 获取组中指定索引的按钮 |
| `GetAuraGroupFrameCount(groupKey)` | 获取组当前按钮数 |
| `SetAuraGroupFilterString(groupKey, filterString)` | 修改标准光环过滤字符串 |
| `SetAuraGroupMaxFrameCount(groupKey, count)` | 修改最多显示数量 |
| `SetAuraGroupCandidateFilters(groupKey, filters)` | 修改候选过滤 |
| `SetAuraGroupSortMethod(groupKey, method, direction)` | 修改排序 |
| `SetAuraGroupLayout(groupKey, layout)` | 修改该组布局 |
| `AddAuraSlot(slotKey, filterString, options)` | 添加单光环槽并返回按钮 |
| `SetAuraSlotFilterString(slotKey, filterString)` | 修改槽位标准过滤字符串 |
| `SetAuraSlotCandidateFilters(slotKey, filters)` | 修改槽位候选过滤 |
| `SetAuraSlotSortMethod(slotKey, method, direction)` | 修改槽位排序 |
| `AddItemEnchantment(slot, options)` | 添加武器临时附魔显示并返回按钮 |
| `SetItemEnchantmentSortMethod(method, direction)` | 设置附魔排序 |
| `SetItemEnchantmentLayout(layout)` | 设置附魔布局 |
| `ResetItemEnchantmentLayout()` | 恢复附魔默认布局 |
| `GetAuraProcessingPolicy()` | 读取附加光环处理策略 |
| `SetAuraProcessingPolicy(policy, options)` | 设置附加光环处理策略 |

当前没有公开的 `ClearAuraGroups()`。需要变化时，优先使用各类 `SetAuraGroup*` 方法重新配置。

## 6. 标准 filterString

`filterString` 先由标准光环过滤逻辑处理，之后才应用 `candidateFilters`。

常见值：

```lua
"HELPFUL"
"HARMFUL"
"HELPFUL|PLAYER"
"HARMFUL|PLAYER"
```

必须传入能被 `AuraUtil.IsValidFilterString` 接受的字符串。不要把 `candidateFilters` 的字段拼进 `filterString`。

## 7. AddAuraGroup

签名：

```lua
container:AddAuraGroup(groupKey, filterString, options)
```

### 7.1 options

```lua
local options = {
    templateNames = nil,
    initializeFrame = nil,
    candidateFilters = nil,
    sortMethod = AuraContainerSortMethod.Default,
    sortDirection = AuraContainerSortDirection.Normal,
    layout = nil,
    maxFrameCount = math.huge,
}
```

| 字段 | 类型 | 默认值 | 含义 |
|---|---:|---:|---|
| `templateNames` | `table\|nil` | `nil` | 按钮额外继承的模板名数组 |
| `initializeFrame` | `function\|nil` | `nil` | 每个新按钮创建后的初始化回调 |
| `candidateFilters` | `table\|nil` | `nil` | 标准 filterString 之后的额外过滤 |
| `sortMethod` | enum | `Default` | 光环排序方法 |
| `sortDirection` | enum | `Normal` | 正序或反序 |
| `layout` | `table\|nil` | `nil` | 该组流式布局选项 |
| `maxFrameCount` | 非负整数或 `math.huge` | `math.huge` | 最多显示按钮数 |

要求：

- `groupKey` 必须是非空且在当前容器中唯一的字符串。
- `initializeFrame` 可能一次收到一批预创建按钮；不要把调用次数解释为可见光环数量。
- `CustomAuraButtonTemplate` 已自动继承，不要重复放入 `templateNames`。

## 8. candidateFilters 完整参考

示例：

```lua
candidateFilters = {
    includeSpellIDs = {
        [12345] = true,
        [67890] = true,
    },
    excludeDispelTypes = {
        Curse = true,
    },
    isFromPlayerOrPlayerPet = true,
    maxDuration = 30,
}
```

### 8.1 字段

| 字段 | 类型 | 判断 |
|---|---|---|
| `includeSpellIDs` | `map<number, truthy>` | 只保留集合中的 SpellID |
| `excludeSpellIDs` | `map<number, truthy>` | 排除集合中的 SpellID |
| `includeDispelTypes` | `map<string, truthy>` | 只保留指定驱散类型 |
| `excludeDispelTypes` | `map<string, truthy>` | 排除指定驱散类型 |
| `maxDuration` | 非负数字 | 总持续时间必须小于等于此值 |
| `processedAuraType` | `AuraUtil.AuraUpdateChangedType` | 匹配 `AuraUtil.ProcessAura` 分类 |
| `isFromPlayerOrPlayerPet` | boolean | 是否来自玩家或玩家宠物 |
| `isRoleAura` | boolean | 是否为职责光环 |
| `isPriorityAura` | boolean | 是否为优先级光环 |
| `isStealable` | boolean | 是否可偷取 |
| `nameplateShowAll` | boolean | 匹配同名光环字段 |
| `nameplateShowPersonal` | boolean | 匹配同名光环字段 |
| `canApplyAura` | boolean | 玩家是否可施加 |
| `isBossAura` | boolean | 是否为首领光环 |
| `isBossOrRoleAura` | boolean | 是否为首领或职责光环 |

布尔字段是精确匹配：

- 写 `true`：只保留值为 true 的光环。
- 写 `false`：只保留值为 false 的光环。
- 省略或 `nil`：不按此字段过滤。

### 8.2 SpellID 过滤能否使用？

能，但有限制。

允许进行身份类过滤的常规场景：

- 可协助/友方单位上的 `HELPFUL` 光环。
- 不可协助/敌方单位上的 `HARMFUL` 光环。

默认禁止的场景：

- 友方或可协助单位上的 `HARMFUL` 光环。
- 敌方或不可协助单位上的 `HELPFUL` 光环。

标记为 `Enum.SecrecyLevel.NeverSecret` 的法术不受上述限制。

重要行为：当身份类过滤不被允许时，`includeSpellIDs` 和 `excludeSpellIDs` 不会按通常方式筛掉光环。AI 不应承诺“任何单位、任何正负面光环都可以按 SpellID 精确过滤”。

正确集合：

```lua
includeSpellIDs = {
    [12345] = true,
}
```

错误数组：

```lua
includeSpellIDs = {
    12345, -- 实际键为 1，不是 12345
}
```

### 8.3 maxDuration 的含义

`maxDuration` 检查的是光环的**总持续时间**，不是当前剩余时间。

```lua
maxDuration = 30
```

含义是“只保留总持续时间不超过 30 秒的光环”，不是“只在剩余 30 秒时显示”。

任何非 `nil` 的 `maxDuration` 还会排除永久光环，因为永久光环的持续时间为 0。

### 8.4 processedAuraType

只有先启用处理策略才有意义：

```lua
container:SetAuraProcessingPolicy(
    CustomAuraContainerAuraProcessingPolicy.ProcessAura,
    {
        displayOnlyDispellableDebuffs = false,
        ignoreBuffs = false,
        ignoreDebuffs = false,
        ignoreDispelDebuffs = false,
    }
)
```

随后可使用：

```lua
candidateFilters = {
    processedAuraType = AuraUtil.AuraUpdateChangedType.Debuff,
}
```

若未使用 `ProcessAura` 策略却设置 `processedAuraType`，所有光环都会因没有对应元数据而被隐藏。

## 9. 排序

可用 `AuraContainerSortMethod`：

```lua
AuraContainerSortMethod.Default
AuraContainerSortMethod.BigDefensive
AuraContainerSortMethod.UnitFrameDebuff
AuraContainerSortMethod.ImportantOnly
AuraContainerSortMethod.Expiration
AuraContainerSortMethod.ExpirationOnly
AuraContainerSortMethod.Name
AuraContainerSortMethod.NameOnly
AuraContainerSortMethod.AuraInstanceIDOnly
```

方向：

```lua
AuraContainerSortDirection.Normal
AuraContainerSortDirection.Reverse
```

`Reverse` 通过交换比较器两侧参数实现。不要假设每种排序都只比较字段名称所暗示的一个字段；部分比较器包含回退排序。

## 10. 布局

组布局默认值：

```lua
layout = {
    elementSpacing = 0,
    lineSpacing = 0,
    groupSpacing = 0,
    groupLineSpacing = 0,
    forceNewLine = false,
    elementWidth = nil,
    elementHeight = nil,
    layoutIndex = nil,
}
```

| 字段 | 含义 |
|---|---|
| `elementSpacing` | 同一行相邻按钮间距 |
| `lineSpacing` | 行间距 |
| `groupSpacing` | 同一行组间距 |
| `groupLineSpacing` | 组换行时的间距 |
| `forceNewLine` | 此组是否强制从新行开始 |
| `elementWidth` | 布局计算使用的宽度覆盖值 |
| `elementHeight` | 布局计算使用的高度覆盖值 |
| `layoutIndex` | 不同组之间的布局顺序 |

容器级默认布局：

- 从 `TOPLEFT` 开始。
- 水平向右增长。
- 垂直向下换行。
- 内边距均为 0。
- 默认最大行宽为 `math.huge`。

容器会在布局完成后自动 `SetSize(width, height)`。因此，直接给容器设置固定尺寸不能可靠地把它当作裁切视口。

## 11. CustomAuraButton 显示通道

所有传给下列 setter 的对象都必须是该按钮的子孙对象。

| 显示内容 | 注册方法 | 对象类型 |
|---|---|---|
| 图标 | `SetIcon(texture)` | `Texture` |
| 法术名称 | `SetSpellName(fontString)` | `FontString` |
| 持续时间文本/颜色 | `SetDurationText(fontString, options)` | `FontString` |
| 冷却转圈 | `SetDurationCooldown(cooldown)` | `Cooldown` |
| 持续时间条 | `SetDurationBar(statusBar, options)` | `StatusBar` |
| 层数文本 | `SetApplicationCount(fontString, options)` | `FontString` |
| 层数条 | `SetApplicationBar(statusBar, options)` | `StatusBar` |
| 驱散类型文字 | `SetDispelTypeText(fontString, options)` | `FontString` |
| 驱散类型纹理 | `AddDispelTypeTexture(texture, options)` | `Texture` |

相应内容通常有 `Get*` 和 `Clear*` 方法；驱散纹理支持多个，并提供：

```lua
button:GetDispelTypeTextureCount()
button:GetDispelTypeTexture(index)
button:RemoveDispelTypeTexture(index)
button:ClearDispelTypeTextures()
```

兼容别名：

- `SetAuraBorder` 是 `AddDispelTypeTexture` 相关旧别名。
- `SetAuraSymbol` 是 `SetDispelTypeText` 的旧别名。

源码已注明这些别名会在 12.1 之后移除。新代码应使用 `DispelType` 命名。

## 12. 剩余时间颜色曲线

### 12.1 结论

可以把光环剩余时间映射成平滑颜色曲线，但当前受支持的直接载体是注册给 `SetDurationText` 的 `FontString`。

当前正确选项结构：

```lua
button:SetDurationText(fontString, {
    textColor = {
        curve = colorCurve,
        property = Enum.DurationTextBindingProperty.RemainingDuration,
    },
})
```

较早 PTR 示例可能写成：

```lua
textColorCurve = colorCurve
```

此字段不是 build 12.1.0.68914 当前源码中的结构，AI 不应继续生成。

### 12.2 可供颜色曲线采样的属性

```lua
Enum.DurationTextBindingProperty.RemainingDuration
Enum.DurationTextBindingProperty.RemainingPercent
Enum.DurationTextBindingProperty.ElapsedDuration
Enum.DurationTextBindingProperty.ElapsedPercent
Enum.DurationTextBindingProperty.TotalDuration
Enum.DurationTextBindingProperty.StartTime
Enum.DurationTextBindingProperty.EndTime
```

百分比曲线适合不同总时长共用统一配色；剩余秒数曲线适合固定阈值，例如 5 秒变红、30 秒变蓝。

### 12.3 蓝色平滑过渡到红色

剩余时间不断减少，因此：

- 曲线 x=0 应为红色。
- 曲线 x=30 应为蓝色。
- 线性曲线会在中间平滑插值。

```lua
local remainingColorCurve = C_CurveUtil.CreateColorCurve()
remainingColorCurve:SetType(Enum.LuaCurveType.Linear)
remainingColorCurve:AddPoint(0, CreateColor(1.00, 0.05, 0.05, 1))
remainingColorCurve:AddPoint(30, CreateColor(0.10, 0.35, 1.00, 1))
```

注册：

```lua
button:SetDurationText(durationText, {
    textColor = {
        curve = remainingColorCurve,
        property = Enum.DurationTextBindingProperty.RemainingDuration,
    },
})
```

### 12.4 使用百分比

若希望所有 5 秒、30 秒、120 秒光环都按相同生命周期变色：

```lua
local percentColorCurve = C_CurveUtil.CreateColorCurve()
percentColorCurve:SetType(Enum.LuaCurveType.Linear)
percentColorCurve:AddPoint(0.00, CreateColor(1.00, 0.05, 0.05, 1))
percentColorCurve:AddPoint(1.00, CreateColor(0.10, 0.35, 1.00, 1))
```

```lua
button:SetDurationText(durationText, {
    textColor = {
        curve = percentColorCurve,
        property = Enum.DurationTextBindingProperty.RemainingPercent,
    },
})
```

### 12.5 固定方块字符而不显示数字

`DurationTextBindingFormatOptions` 为：

```lua
{
    formatString = "固定文本或含占位符的格式",
    components = {
        {
            property = Enum.DurationTextBindingProperty.RemainingDuration,
            formatter = numericFormatter,
        },
    },
}
```

纯色字符可使用不含格式组件的固定字符串：

```lua
button:SetDurationText(pixelText, {
    textFormat = {
        formatString = "█",
        components = {},
    },
    textColor = {
        curve = remainingColorCurve,
        property = Enum.DurationTextBindingProperty.RemainingDuration,
    },
})
```

这里文本恒为 `"█"`，但顶点颜色由持续时间绑定自动更新。

注意：方块字符是否存在、边缘是否完整、是否正好铺满 1×2 像素，取决于字体文件、字号、UI 缩放和像素取整。若要求严格像素级结果，应在游戏内逐缩放测试，最好随插件提供包含该字形的字体。

## 13. Icon 或 Texture 能否按剩余时间渐变？

当前结论：

- `SetIcon(texture)` 只负责把光环图标写入纹理。
- `SetDurationBar(statusBar, options)` 负责持续时间数值，不提供持续时间颜色曲线字段。
- `AddDispelTypeTexture(texture, options)` 支持 `customDispelColorCurve`，但其输入是**驱散类型**，不是剩余时间。
- 当前没有公开的“把 Aura 持续时间直接绑定到任意 Texture 的 VertexColor”接口。

所以不能把普通图标或任意 Texture 直接注册成“随剩余时间蓝到红”的安全颜色绑定。

推荐替代：

1. 用固定方块字符的 `FontString` 模拟纯色像素。
2. 用 `StatusBar` 表示持续时间进度，但颜色保持预设值。
3. 同时显示图标和一个很小的持续时间色块 `FontString`。

不要通过插件 `OnUpdate` 读取剩余时间后调用 `texture:SetVertexColor` 来绕过这个限制；这重新引入了 secret 数据读取问题。

## 14. 裁切 FontString

### 14.1 仅设置 Frame 尺寸不会自动裁切

```lua
button:SetSize(1, 2)
```

只改变按钮边界。子 `FontString` 仍可能绘制到边界外。

必须显式启用：

```lua
button:SetClipsChildren(true)
```

### 14.2 1×2 色块按钮

```lua
local function InitializePixelButton(button)
    button:SetSize(1, 2)
    button:SetClipsChildren(true)

    local pixelText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    pixelText:SetPoint("CENTER")
    pixelText:SetText("█")

    button:SetDurationText(pixelText, {
        textFormat = {
            formatString = "█",
            components = {},
        },
        textColor = {
            curve = remainingColorCurve,
            property = Enum.DurationTextBindingProperty.RemainingDuration,
        },
    })
end
```

配合布局覆盖值：

```lua
layout = {
    elementWidth = 1,
    elementHeight = 2,
    elementSpacing = 0,
}
```

### 14.3 裁切整个容器

由于 AuraContainer 会随内容自动改变自身大小，应使用单独的外层 Frame 作为固定视口：

```lua
local viewport = CreateFrame("Frame", nil, parent)
viewport:SetSize(100, 20)
viewport:SetClipsChildren(true)

local container = CreateFrame(
    "AuraContainer",
    nil,
    viewport,
    "CustomAuraContainerTemplate"
)
container:SetPoint("TOPLEFT")
```

此时：

- `container` 继续按内容自动扩展。
- `viewport` 保持 100×20。
- 超出 `viewport` 的子内容被裁切。

## 15. 完整示例：每个 Aura 是一个随剩余时间变色的小色块

```lua
local parent = UIParent

-- 0 秒为红色，30 秒为蓝色，中间线性过渡。
local remainingColorCurve = C_CurveUtil.CreateColorCurve()
remainingColorCurve:SetType(Enum.LuaCurveType.Linear)
remainingColorCurve:AddPoint(0, CreateColor(1.00, 0.05, 0.05, 1))
remainingColorCurve:AddPoint(30, CreateColor(0.10, 0.35, 1.00, 1))

-- 固定裁切视口；AuraContainer 自己仍会根据内容自动改变大小。
local viewport = CreateFrame("Frame", nil, parent)
viewport:SetPoint("CENTER")
viewport:SetSize(100, 20)
viewport:SetClipsChildren(true)

local container = CreateFrame(
    "AuraContainer",
    nil,
    viewport,
    "CustomAuraContainerTemplate"
)
container:SetPoint("TOPLEFT")
container:SetUnit("target")

local function InitializePixelButton(button)
    button:SetSize(2, 8)
    button:SetClipsChildren(true)

    local pixelText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    pixelText:SetPoint("CENTER")

    button:SetDurationText(pixelText, {
        textFormat = {
            formatString = "█",
            components = {},
        },
        textColor = {
            curve = remainingColorCurve,
            property = Enum.DurationTextBindingProperty.RemainingDuration,
        },
    })
end

container:AddAuraGroup("shortTargetDebuffs", "HARMFUL", {
    initializeFrame = InitializePixelButton,

    -- maxDuration 是总持续时间上限；也会排除永久光环。
    candidateFilters = {
        maxDuration = 30,
    },

    sortMethod = AuraContainerSortMethod.Expiration,
    sortDirection = AuraContainerSortDirection.Normal,
    maxFrameCount = 40,

    layout = {
        elementWidth = 2,
        elementHeight = 8,
        elementSpacing = 0,
        lineSpacing = 0,
    },
})
```

如果只想观察指定 SpellID，且当前单位/光环关系允许身份过滤：

```lua
candidateFilters = {
    includeSpellIDs = {
        [12345] = true,
        [67890] = true,
    },
}
```

## 16. AuraSlot 示例

显示候选列表中排序最靠前的一个光环：

```lua
local slotButton = container:AddAuraSlot("priorityAura", "HELPFUL", {
    candidateFilters = {
        includeSpellIDs = {
            [12345] = true,
            [67890] = true,
        },
    },
    sortMethod = AuraContainerSortMethod.Expiration,
    sortDirection = AuraContainerSortDirection.Normal,
    initializeFrame = function(button)
        button:SetSize(32, 32)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        button:SetIcon(icon)

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        button:SetDurationCooldown(cooldown)
    end,
})

slotButton:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
```

AuraSlot 不参加 AuraGroup 的自动流式布局，因此手动 `SetPoint` 是必要的。

## 17. DurationText 选项

当前结构：

```lua
button:SetDurationText(fontString, {
    binding = optionalDurationTextBinding,
    textFormatter = optionalNumericFormatter,
    textFormat = optionalFormatOptions,
    textColor = optionalColorOptions,
})
```

优先级：

1. 若提供 `binding`，按钮复制其配置。
2. 否则按钮建立默认绑定和默认持续时间 formatter。
3. `textFormat` 覆盖 `textFormatter`。
4. `textColor` 向绑定设置颜色曲线。

也可以先建立绑定：

```lua
local binding = C_DurationUtil.CreateDurationTextBinding()
binding:SetToDefaults()
binding:SetTextFormat("█", {})
binding:SetTextColorCurve(
    remainingColorCurve,
    Enum.DurationTextBindingProperty.RemainingDuration
)

button:SetDurationText(pixelText, {
    binding = binding,
})
```

传入的绑定会被复制后再关联到按钮。

## 18. 其他显示选项摘要

### 18.1 DurationBar

```lua
button:SetDurationBar(statusBar, {
    interpolation = optionalStatusBarInterpolation,
    direction = optionalStatusBarTimerDirection,
})
```

### 18.2 ApplicationBar

```lua
button:SetApplicationBar(statusBar, {
    maxApplications = 5, -- 必填
    interpolation = optionalStatusBarInterpolation,
})
```

### 18.3 ApplicationCount

```lua
button:SetApplicationCount(fontString, {
    formatter = optionalNumericFormatter,
})
```

### 18.4 DispelTypeText

```lua
button:SetDispelTypeText(fontString, {
    showWhenHarmful = true,
    showWhenHelpful = false,
    showWithoutDispelType = false,
    customDispelTextMap = {
        Magic = "M",
        Curse = "C",
        Poison = "P",
        Disease = "D",
        [""] = "?",
    },
})
```

### 18.5 DispelTypeTexture

```lua
button:AddDispelTypeTexture(texture, {
    showWhenHarmful = true,
    showWhenHelpful = false,
    showWithoutDispelType = false,
    style = Enum.CustomAuraButtonDispelTypeTextureStyle.BorderWithIcon,
    customDispelAssetMap = nil,
    customDispelColorMap = nil,
    customDispelColorCurve = nil,
})
```

样式：

```lua
Enum.CustomAuraButtonDispelTypeTextureStyle.Border
Enum.CustomAuraButtonDispelTypeTextureStyle.BorderWithIcon
Enum.CustomAuraButtonDispelTypeTextureStyle.Icon
Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset
Enum.CustomAuraButtonDispelTypeTextureStyle.CustomAsset
```

再次强调：`customDispelColorCurve` 根据驱散类型选颜色，不根据剩余时间选颜色。

## 19. 常见错误

| 错误 | 原因 | 正确做法 |
|---|---|---|
| 用 `{12345, 67890}` 过滤 SpellID | 这是数组，键是 1、2 | 用 `{[12345]=true, [67890]=true}` |
| 认为 SpellID 可过滤任何友方 Debuff | 身份过滤受 secrecy 规则限制 | 先判断单位可协助关系和 HELPFUL/HARMFUL |
| 用 `maxDuration` 做“剩余 5 秒显示” | 它检查总持续时间 | 用显示绑定表现剩余时间；不能把它当剩余时间候选过滤器 |
| 使用 `textColorCurve` | 较早 PTR 字段 | 用 `textColor = {curve=..., property=...}` |
| 用 `customDispelColorCurve` 做倒计时颜色 | 曲线输入是驱散类型 | 用 `SetDurationText` 的 `textColor` |
| 给容器 `SetSize` 后期待固定尺寸 | 布局会自动重设容器大小 | 外包一层 `SetClipsChildren(true)` 的视口 |
| 按钮 1×2 就期待字体自动裁切 | 子区域默认可越界绘制 | `button:SetClipsChildren(true)` |
| 在 OnUpdate 中读取剩余时间给图标染色 | 绕开安全绑定，secret 场景不可靠 | 用 DurationTextBinding 驱动 FontString |
| 直接创建 AuraButton | 生命周期和安全限制由容器管理 | 通过 AuraGroup/AuraSlot 创建 |
| 在按钮受限后检查其私有字段 | 可能被禁止访问 | 初始化阶段只注册显示对象 |
| 继续使用 `SetAuraBorder` | 已标为 12.1 后移除 | 使用 `AddDispelTypeTexture` |

## 20. AI 生成代码检查清单

在回答 AuraContainer 编码问题前，AI 应逐项检查：

- [ ] 是否说明目标版本和 PTR 不稳定性？
- [ ] 是否使用 `"AuraContainer"` + `"CustomAuraContainerTemplate"`？
- [ ] 所有显示 Region 是否创建为 AuraButton 子孙？
- [ ] 是否只在 `initializeFrame` 中建立显示结构？
- [ ] SpellID 表是否为 map/set，而非数组？
- [ ] 是否说明 SpellID 身份过滤限制？
- [ ] 是否避免把 `maxDuration` 解释成剩余时间？
- [ ] 持续时间颜色是否使用 `textColor.curve` 和 `textColor.property`？
- [ ] 是否避免声称普通 Icon/Texture 可绑定持续时间颜色？
- [ ] 是否区分 duration curve 与 dispel type curve？
- [ ] 是否说明 AuraGroup 自动布局、AuraSlot 手动锚定？
- [ ] 若需要裁切，是否显式使用 `SetClipsChildren(true)`？
- [ ] 是否避免 `C_UnitAuras` + `OnUpdate` 轮询方案？
- [ ] 是否避免已弃用的 `SetAuraBorder` / `SetAuraSymbol`？

## 21. 机器可读摘要

```yaml
aura_container:
  create:
    frame_type: AuraContainer
    template: CustomAuraContainerTemplate
  owns:
    - aura_enumeration
    - refresh
    - secure_filtering
    - sorting
    - frame_assignment
    - group_layout
  addon_owns:
    - candidate_filter_declaration
    - button_visual_construction
    - display_binding_registration

group:
  api: AddAuraGroup
  cardinality: many
  layout: automatic
  max_count_field: maxFrameCount

slot:
  api: AddAuraSlot
  cardinality: one
  layout: manual

spell_id_filter:
  representation: map_spell_id_to_truthy
  allowed_normally:
    - helpful_on_assistable_unit
    - harmful_on_non_assistable_unit
  exception: spell_aura_secrecy_never_secret

duration_color:
  supported_target: FontString_registered_with_SetDurationText
  current_option:
    textColor:
      curve: LuaColorCurveObject
      property: DurationTextBindingProperty
  obsolete_option: textColorCurve
  unsupported_direct_targets:
    - icon_texture
    - arbitrary_texture

clipping:
  required_call: SetClipsChildren(true)
  fixed_container_viewport: use_separate_parent_frame
```

## 22. 源码依据

核对快照：**PTR 12.1.0.68914，2026-07-24**。

- [Patch 12.1.0 API changes](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes)
- [Blizzard_CustomAuraContainer.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua)
- [Blizzard_CustomAuraButton.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua)
- [Blizzard_AuraContainerShared.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua)
- [Blizzard_AuraContainerUtil.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua)
- [AuraContainerUtilDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuraContainerUtilDocumentation.lua)
- [DurationTextBindingSharedDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/DurationTextBindingSharedDocumentation.lua)
- [CurveUtilDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurveUtilDocumentation.lua)
- [version.txt](https://github.com/Gethe/wow-ui-source/blob/ptr/version.txt)

`Gethe/wow-ui-source` 是客户端界面源码镜像；PTR 分支持续变动。若 build 号变化，应重新核对参数结构和弃用状态。
