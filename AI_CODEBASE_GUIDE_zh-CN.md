---
title: "Fuyutsui 代码库 AI 阅读指南"
language: "zh-CN"
repository_type: "World of Warcraft Retail Lua AddOn"
wow_interface: "120000 / 120001 / 120005 / 120007 / 120010"
entrypoint: "Fuyutsui.toc"
primary_global: "Fuyutsui"
saved_variables: "FuyutsuiADB"
generated_from: "2026-07-25 当前工作区源码"
---

# Fuyutsui 代码库 AI 阅读指南

本文档用于让 AI 在修改代码前快速建立正确的整体模型。它描述的是当前工作区中的实际实现，不是设计愿景。

如果文档与源码冲突，按以下优先级判断：

1. `Fuyutsui.toc` 的实际加载顺序。
2. `core/block.lua` 的实际像素协议与 AuraContainer 实现。
3. `main.lua` 的实际状态写入与 `LoadPlayerBlocks` 解析逻辑。
4. 当前职业文件的实际表结构。
5. 本文档、`AGENTS.md`、`README.md` 和其他说明文件。

## 1. 一句话模型

Fuyutsui 在 WoW 客户端内采集玩家、目标、队伍、光环、冷却和配置状态，将数据编码到屏幕顶部的极窄色块中；外部程序通过读取像素颜色还原状态。插件还会创建安全宏按钮、扫描动作条键位，并提供游戏内快速开关。

核心数据流：

```text
WoW API / WoW 事件
        │
        ├─ core/events.lua + player/spells/target/group 状态缓存
        │       │
        │       ├─ 每帧 / 0.2 秒 / 1 秒刷新
        │       │
        │       ▼
        │   Fuyutsui:CreateTexture(index, normalizedValue)
        │
        └─ core/block.lua AuraContainer（玩家 / 队伍光环）
                │
                ▼ 事件驱动，不走 OnUpdate
            主色条光环格 + 横向层数条
                │
                ▼
屏幕顶部 RGB 像素协议
                │
                ▼
外部读取程序
```

## 2. 当前目录职责

| 路径 | 职责 | 修改注意 |
| --- | --- | --- |
| `Fuyutsui.toc` | AddOn 元数据与唯一加载顺序 | 新增或删除运行时文件必须同步 |
| `embeds.xml` | 加载 `LibStub` | 当前只加载一个 vendored stub |
| `libs/LibStub/` | 库版本注册器 | 第三方代码，不做业务修改 |
| `libs/LibRangeCheck-3.0/` | 目标和姓名板距离估算 | 第三方代码；业务只调用 `GetRange(unit)` |
| `core/core.lua` | 全局对象、事件总线、SavedVariables、生命周期 | 必须先于其他业务模块 |
| `core/config.lua` | 法术编码、事件名、英雄天赋、Boss、能量、动作条、键码等静态表 | 大型纯数据文件 |
| `core/curves.lua` | 颜色/能量曲线工厂 | 依赖 `config.lua` 的能量枚举 |
| `core/block.lua` | 510 格主色条、横向计数/层数条、玩家与队伍 AuraContainer | 像素协议与光环输出的最终事实来源 |
| `core/stateblocks.lua` | `UpdateStateBlock` 与状态 getter | 新增状态名时同步这里 |
| `core/commands.lua` | `/fu` 斜杠命令与 `Switch*` | 与 quickbutton 共用 `GetCharConfig` |
| `core/macro.lua` | 安全宏按钮和覆盖键位 | 受 `InCombatLockdown()` 限制 |
| `core/classmacros.lua` | 全职业 `ClassMacros` 数据 | 改宏改这里，不改 class 文件 |
| `core/keybinds.lua` | 扫描动作条，建立 spellId 到按键资料的映射 | 扫描延迟 0.5 秒 |
| `core/quickbutton.lua` | 爆发、AOE、输出模式、药水快速按钮 | 位置保存在角色级 DB |
| `core/player.lua` | 玩家状态、专精、有效性、姿态等 | 领域逻辑 |
| `core/spells.lua` | 已知法术、冷却、物品 | 领域逻辑 |
| `core/target.lua` | 目标/焦点/姓名版/敌人 | 领域逻辑 |
| `core/group.lua` | 队伍重建与轮询 | 领域逻辑 |
| `core/events.lua` | 事件处理与 `OnUpdate` | 分频刷新入口 |
| `class/*.lua` | 当前职业的专精色块声明 | 非当前职业文件在首行立即返回 |
| `main.lua` | `LoadPlayerBlocks` / `LoadPlayerMacros` / `UpdatePlayerBlocks` | 薄编排层 |
| `auracontainer.lua` | 中央玩家 buff 演示 UI | **与顶部像素协议无关** |
| `AuraContainer_AI_Reference_zh-CN.md` | AuraContainer 专项 API 参考 | 改光环像素前先读 |
| `Keymap.md` | `core/macro.lua` 的宏序号到组合键对照 | 修改宏键池时同步 |
| `README.md` | 面向使用者的项目说明 | 不是实现细节的最终来源 |
| `AGENTS.md` | 仓库协作和修改约束 | 执行任务时同时遵守 |
| `core/Spell_Misc_EmotionHappy.blp` | AddOn 图标纹理 | 非 Lua 代码 |
| `Fuyutsui.sln` | 编辑器/IDE 解决方案文件 | 不参与 WoW 加载 |
| `LICENSE` | MIT 许可证 | 不参与运行时 |

### 2.1 已下线但仍可能残留的文件

| 路径 | 状态 |
| --- | --- |
| `core/auras.lua` | **不再被 `Fuyutsui.toc` 加载**。旧事件推导逻辑光环状态机已移除；磁盘上若仍存在，只作历史参考，不是运行时。 |
| `core/macros.lua` | **已重命名为 `core/classmacros.lua`**。 |

不要再按旧文档假设存在 `Fuyutsui.Auras`、`updateAura()`、`updateAuraBlocks()`，或 `auraName` / `showKey` 驱动的像素写入。

## 3. 精确加载顺序

`Fuyutsui.toc` 当前按以下顺序执行：

```text
embeds.xml
Libs/LibRangeCheck-3.0/LibRangeCheck-3.0.lua

core/core.lua
core/config.lua
core/curves.lua
core/block.lua
core/stateblocks.lua
core/commands.lua
core/quickbutton.lua
core/macro.lua
core/classmacros.lua
core/keybinds.lua
auracontainer.lua

class/Warrior.lua
class/Paladin.lua
class/Rogue.lua
class/Hunter.lua
class/Priest.lua
class/DeathKnight.lua
class/Shaman.lua
class/Mage.lua
class/Warlock.lua
class/Monk.lua
class/Druid.lua
class/DemonHunter.lua
class/Evoker.lua

core/player.lua
core/spells.lua
core/target.lua
core/group.lua
core/events.lua
main.lua
```

重要推论：

- `core/core.lua` 创建 `_G.Fuyutsui`，后续文件都向它挂表或方法。
- `core/config.lua` 必须早于 `core/curves.lua` / `core/keybinds.lua`。
- 光环像素逻辑在 `core/block.lua`，由 `LoadPlayerBlocks` / `UpdatePlayerBarInfo` / `UpdateGroup` 触发刷新。
- 所有职业文件都会被解释；只有匹配 `UnitClassBase("player")` 的文件越过首行卫语句。
- `main.lua` 只做色块/宏编排；事件与 OnUpdate 在 `core/events.lua`。

## 4. 启动与事件分派

### 4.1 自建事件框架

项目已不依赖 AceAddon/AceEvent。`core/core.lua` 创建 `FuyutsuiEventFrame`，并提供：

```lua
Fuyutsui:RegisterEvent(event)
Fuyutsui:UnregisterEvent(event)
Fuyutsui:UnregisterAllEvents()
```

统一事件回调约定是：

```lua
Fuyutsui[event](Fuyutsui, event, ...)
```

因此事件方法通常写成：

```lua
function Fuyutsui:UNIT_HEALTH(_, unit)
    -- `_` 接收事件名
end
```

### 4.2 生命周期

```text
ADDON_LOADED
  └─ OnInitialize()
       ├─ InitDB()
       ├─ 注册 /fu 和 /fuyutsui
       └─ GetCharacterInfo()

PLAYER_LOGIN 或已登录状态
  └─ OnEnable()
       ├─ GetCharacterSpecInfo()
       ├─ UpdateSpellKnown()
       ├─ UpdatePlayerBlocks()
       ├─ ReadKeybindings()
       ├─ HookChatFrameEditBox()
       ├─ 注册运行时事件
       ├─ StartFrameUpdates()
       └─ InitQuickToggleButton()
```

`initialized` 和 `enabled` 是 `core/core.lua` 内部局部标志，防止重复启动。

## 5. 全局对象与状态所有权

### 5.1 `Fuyutsui.state`

玩家和全局运行时状态。主要字段由 `main.lua` 动态增加：

- 身份：`classId`、`className`、`classFilename`、`name`、`GUID`。
- 专精：`specIndex`、`specID`、`specName`、`specRole`、`specRange`。
- 有效性：`isDead`、`mounted`、`isChatOpen`、`drinkStatus`、`valid`。
- 战斗：`combat`、`combatStartTime`、`combatTime`、`moving`。
- 施法：`casting`、`channeling`、`empowering`、持续时间、技能和目标。
- 资源：`healthPercent`、`power[powerType]`、`runeCount`、`staggerPercent`。
- 环境：`mapID`、`encounterID`、`bossID`、`difficultyID`、`enemyCount`。
- 物品：各种药水和治疗石数量。

### 5.2 其他共享缓存

| 表 | 内容 |
| --- | --- |
| `Fuyutsui.blocks` | 当前专精解析后的输出映射 |
| `Fuyutsui.target` | 当前目标的攻击性、距离、血量和施法状态 |
| `Fuyutsui.focus` | 预留的焦点缓存；焦点施法主要直接查 WoW API |
| `Fuyutsui.nameplate` | `nameplateN` 单位的距离与战斗状态 |
| `Fuyutsui.group` | unit token 到成员状态对象 |
| `Fuyutsui.groupList` | 队伍成员 unit token 的稳定轮询顺序 |
| `Fuyutsui.keybindings` | spellId 到动作条按键信息 |
| `Fuyutsui.includeDispelTypes` | 玩家当前会的防御驱散类型，供队伍 AuraContainer 使用 |
| `Fuyutsui.PlayerAuraContainer` | 玩家光环持续时间槽 |
| `Fuyutsui.PlayerAuraBarContainer` | 玩家光环层数条槽 |

旧的 `Fuyutsui.Auras` 逻辑光环表已不再由运行时维护。

### 5.3 局部别名陷阱

`main.lua` 顶部把多个全局表保存为局部变量：

```lua
local state = Fuyutsui.state
local blocks = Fuyutsui.blocks
local group = Fuyutsui.group
local groupList = Fuyutsui.groupList
```

`LoadPlayerBlocks()` 和 `UpdateGroup()` 会同时重建局部变量与 `self` 上的表。新增“整体替换表”的逻辑时，也必须同步相应局部别名，否则后续函数可能继续读旧表。

## 6. SavedVariables

SavedVariables 名称是 `FuyutsuiADB`。`core/core.lua` 保留兼容 AceDB 的外形：

```lua
FuyutsuiADB = {
    char = {
        ["角色名 - 服务器"] = { ... },
    },
    profiles = {
        ["Default"] = { ... },
    },
    profileKeys = {
        ["角色名 - 服务器"] = "Default",
    },
}
```

运行时访问入口：

```lua
Fuyutsui.db.char
Fuyutsui.db.profile
```

角色默认项：

| 字段 | 默认值 | 含义 |
| --- | ---: | --- |
| `level` | `0` | 角色等级缓存 |
| `aoeMode` | `0` | 0 自动，1 单体 |
| `cooldowns` | `0` | 爆发开关 |
| `dpsMode` | `0` | 0 官方一键辅助，1 手写逻辑 |
| `delay` | `0` | 临时延迟标志 |
| `potion` | `0` | 爆发药水开关 |
| `quickButtonCX/CY` | `180/-100` | 快捷按钮默认偏移 |
| `quickButtonShow` | `true` | 是否显示快捷按钮 |

`CopyDefaults()` 只补缺失值，不覆盖已有用户配置。

## 7. 顶部像素协议

### 7.1 主色条是 510 格

当前 `core/block.lua` 的真实常量：

```lua
BLOCK_FIX_COUNT = 510
BLOCK_FIRST_SCHEME_MAX = 255
BLOCK_HEIGHT = 5
blockWidth = GetScreenWidth() / 510
```

不要继续假设只有 255 格，也不要假设高度永远是 1 像素；以 `core/block.lua` 置顶配置为准。部分旧说明（含 `AGENTS.md`）仍可能写“255 个静态色块”。

### 7.2 `CreateTexture(i, b)` 编码

索引 `1..255`：

```text
R = 0
G = i / 255
B = b
A = 1
```

索引 `256..510`：

```text
R = 1 / 255
G = (i - 255) / 255
B = b
A = 1
```

解码器应先用红通道选择索引方案，再用绿通道还原索引。蓝通道是业务值。

调用方负责传入合适的 `b`。常见编码：

- 布尔值：`0` 或 `1/255`。
- 小整数：`value / 255`。
- 百分比或持续时间：通过颜色曲线得到 `0..1`。
- 秒数：常用 `min(1, remaining / 255)`。
- 冷却不可用或未知：部分路径写 `1`，即蓝通道 255。

`CreateTexture()` 不主动 clamp `b`，也不检查 secret value；调用方必须保证安全。

### 7.3 初始化与清空

- 文件加载时立即创建并清零 510 个纹理。
- `ClearAllTextures()` 再次把 1..510 全部写零。
- 专精切换会清空主色条，然后重建当前专精映射。
- `ClearAllFuyutsuiBars()` 会清理横向条，并释放玩家/队伍 AuraContainer。

### 7.4 第二行横向条

横向条容器 `FuyutsuiCountBars`：

```lua
BAR_UNIT_COUNT = 500
BAR_HEIGHT = 5
BAR_FRAME_HEIGHT = 20
BAR_START_INDEX = 2
```

排布顺序：

```text
计数条（CreateAutoLayoutBar） → 光环层数条（LayoutAuraApplicationBars） → BAR_END_COLOR 终点色块
```

`CreateAutoLayoutBar(valueType, minValue, maxValue, spellId)` 支持：

- `castCount` → `C_Spell.GetSpellCastCount(spellId)`。
- `charge` → `C_Spell.GetSpellCharges(spellId).currentCharges`。

布局规则：

- 第一个 bar 从逻辑索引 2 开始。
- 单条占用：背景单元 `[-1..max]` + 预留终点位 + 间隔 → 步进 `max + 3`。
- 相同 `spellId` 只创建一次。
- 超过 `BAR_UNIT_COUNT` 会打印空间不足警告。
- 终点色块始终移动到全部已分配内容之后。
- 切换专精或天赋时应先调用 `ClearAllFuyutsuiBars()`。

背景编码：`(r=1/255, g=相对索引/255, b=0)`，供外部定位条段。

## 8. 当前专精块解析

### 8.1 固定 1..8 格

`main.lua` 强制为每个有效专精建立：

| 索引 | 名称 |
| ---: | --- |
| 1 | 锚点 |
| 2 | 职业 |
| 3 | 专精 |
| 4 | 队伍类型 |
| 5 | 英雄天赋 |
| 6 | 有效性 |
| 7 | 一键辅助 |
| 8 | 法术失败 |

职业文件一般从索引 9 开始。

### 8.2 `ClassBlocks` 条目格式

普通状态：

```lua
[9] = {
    type = "block",
    name = "战斗时间",
}
```

玩家光环（AuraContainer）：

```lua
[24] = {
    type = "aura",
    name = "虚空之盾",
    spellIds = { 17, 1253593 }, -- 或单值 spellId = 17
    maxApps = 10,               -- 可选；有则额外创建横向层数条
}
```

法术冷却：

```lua
[38] = {
    type = "spell",
    spellId = 20473,
    name = "神圣震击",
}
```

法术充能冷却可使用同一 spellId 的第二格：

```lua
[39] = {
    type = "spell",
    spellId = 20473,
    name = "神圣震击",
    charge = true,
}
```

可选法术字段：

- `forcedKnown = true`：跳过已学会检查。
- `inSpellBook = true`：用 `IsSpellInSpellBook()` 代替 `IsSpellKnown()`。

队伍布局：

```lua
[70] = {
    type = "group",
    num = 5,
    healthPercent = 1,
    role = 2,
    dispel = 3, -- 可选：可驱散减益偏移
    aura = {    -- 可选：成员有益光环偏移
        [4] = { name = "救赎", spellId = 194384 },
        [5] = { name = "真言术：盾", spellIds = { 17, 1253593 } },
    },
}
```

计数条：

```lua
["countBars"] = {
    {
        valueType = "charge",
        minValue = 0,
        maxValue = 2,
        spellId = 47540,
    },
}
```

### 8.3 解析结果

`LoadPlayerBlocks(specIndex)` 生成：

```lua
blocks = {
    state = {
        ["状态名"] = pixelIndex,
    },
    auras = {
        [pixelIndex] = classEntry, -- 仅含 spellId/spellIds 的 aura
    },
    spells = {
        [spellId] = {
            index = pixelIndex,
            charge = optionalChargePixelIndex,
            forcedKnown = optionalBoolean,
            inSpellBook = optionalBoolean,
        },
    },
    countBars = { ... },
    groups = {
        start = firstPixelIndex,
        num = stride,
        healthPercent = offset,
        role = offset,
        dispel = optionalOffset,
        aura = optionalOffsetTable,
    },
}
```

解析规则要点：

- 没有 `type` 的专精字段会被跳过；目前解析器只特殊处理 `countBars`。
- `type = "aura"` **必须**带 `spellId` 或 `spellIds`，才会进入 `blocks.auras`。
- 仅含旧字段 `auraName` / `showKey` 的条目会被静默忽略。
- `groups.dispel` 与 `groups.aura` 现已复制进解析结果，由 `RefreshGroupAuraContainers()` 消费。

### 8.4 队伍格公式

成员 `obj.index` 从 1 开始：

```text
memberBase = blocks.groups.start + (obj.index - 1) * blocks.groups.num
healthPixel = memberBase + blocks.groups.healthPercent
rolePixel   = memberBase + blocks.groups.role
auraPixel   = memberBase + auraOffset
dispelPixel = memberBase + blocks.groups.dispel
```

角色/范围格的蓝值：

- 无效、死亡、不可协助、短暂判定不在视野：0。
- 有效但不在范围：0。
- 有效且在范围：Tank=`1/255`、Healer=`2/255`、Damage=`3/255`。

生命格通过颜色曲线合并当前血量、预计治疗和治疗吸收的近似修正。

血量/角色仍由 `main.lua` 的 `CreateTexture` 写入；成员光环与可驱散减益由 AuraContainer 直接画在对应像素位上。

## 9. 法术冷却输出

`UpdateCooldownSpellKnown()` 在延迟 1 秒后筛选当前专精已知法术，结果保存在 `main.lua` 局部 `spells`。

`UpdateSpellCooldown()` 每 0.2 秒刷新：

1. `GetSpellCooldownDuration(spellID)` 取得持续时间对象。
2. 用 `curve255` 计算剩余时间颜色。
3. `cdInfo.isEnabled` 为假时选择特殊颜色。
4. 如果 `cdInfo.isOnGCD`，强制写 0，避免把公共 GCD 当作技能冷却。
5. 若配置了 `charge` 格，再用 `GetSpellChargeDuration()` 写充能恢复时间。

职业文件中的 `name` 主要供人阅读；运行时按 `spellId` 工作。

## 10. 光环像素：AuraContainer

### 10.1 当前模型

玩家与队伍光环**不再**使用事件推导的逻辑光环状态机。当前路径：

1. 职业表声明 `type = "aura"` + `spellId`/`spellIds`（可选 `maxApps`）。
2. `LoadPlayerBlocks()` 写入 `blocks.auras[index]`。
3. `UpdatePlayerBarInfo()` 调用：
   - `RefreshPlayerAuraContainers()`：主色条上的持续时间槽；
   - `CreateAutoLayoutBar(...)`：专精计数条；
   - `LayoutAuraApplicationBars()`：带 `maxApps` 的层数条。
4. `UpdateGroup()` 调用 `RefreshGroupAuraContainers()`。
5. Blizzard `CustomAuraContainerTemplate` 在光环变化时刷新像素；**不在 `OnUpdate` 中轮询**。

依赖：运行时会 `LoadAddOn("Blizzard_AuraContainer")`。细节见 `AuraContainer_AI_Reference_zh-CN.md`。

### 10.2 玩家光环槽

`CollectAuraSpellSlots()` 从 `blocks.auras` 收集条目，要求 `spellId` 或 `spellIds` 能建成非空 `includeSpellIDs` 集合。

每个槽：

- 单位：`player`
- 过滤器：`HELPFUL`
- `includeSpellIDs`：任一命中即显示；`AuraSlot` 取排序最前的一个
- 排序：`Expiration` / `Normal`
- 位置：与主色条同索引的屏幕坐标
- 视觉：底色 `(r, g, 1)` + 裁剪后的 `█` 文本；蓝通道随剩余秒数 `0..255` 从 0→1
- **不要**给 candidateFilters 设非 nil 的 `maxDuration`，否则会排除永久光环（持续时间为 0）

可选 `maxApps`：

- 在横向条区域追加 StatusBar 层数条；
- 与计数条共用 `ReserveHorizontalBarUnits` / 背景编码；
- 由 `button:SetApplicationBar(bar, { maxApplications = maxApps })` 驱动。

### 10.3 队伍光环槽

每个 `groupList` 成员一个 `AuraContainer`：

| 配置 | 过滤器 | 含义 |
| --- | --- | --- |
| `groups.aura[offset]` | `HELPFUL\|PLAYER` | 成员身上、来自玩家的有益光环 |
| `groups.dispel` | `HARMFUL` + `includeDispelTypes` | 玩家当前会驱散的减益类型 |

`Fuyutsui.includeDispelTypes` 由 `UpdateSpellKnown()` 根据已学会的防御驱散技能生成，例如 `{ Magic = true, Disease = true }`。

成员离开 `groupList` 后，对应容器会被禁用并隐藏；专精切换时 `LoadPlayerBlocks()` 会 `ReleaseGroupAuraContainers()`。

### 10.4 迁移状态（重要）

运行时只认新格式。当前工作区中：

- **已迁移示例**：`class/Priest.lua` 戒律专精（`spellId` / `spellIds` / `maxApps`，以及 `group.dispel` + `group.aura`）。
- **大量未迁移**：多数职业/专精仍写着旧的 `auraName` + `showKey`。这些条目会被 `LoadPlayerBlocks()` 忽略，**不会输出任何光环像素**。

迁移一个光环时：

1. 查真实 SpellID（可用游戏内工具或日志）。
2. 把 `{ type = "aura", name = "...", auraName = "...", showKey = "remaining" }` 改成带 `spellId`/`spellIds` 的新格式。
3. 若以前用单独格子表示层数（`showKey = "count"`），改为同一光环上的 `maxApps`，或接受层数改走横向条。
4. 旧的“逻辑光环 / 图标高亮 / 发光”语义（例如战士斩杀高亮）不能原样映射到真实单位光环时，需要另找真实 SpellID 或改设计。
5. `/reload` 后验证主色条索引与横向层数条。

不要重新启用 `core/auras.lua`，除非任务明确要求恢复旧状态机。

## 11. 玩家、目标与队伍状态刷新

### 11.1 玩家

| 输出类别 | 主要写入函数 |
| --- | --- |
| 有效性 | `UpdatePlayerValid()` |
| 战斗时间 | `UpdatePlayerCombatTime()` |
| 移动 | `UpdatePlayerMoving()` |
| 施法/引导/蓄力 | `UpdatePlayerCastingInfo()` 等 |
| 生命 | `UpdatePlayerHealth()` |
| 资源 | `UpdatePlayerPower()`、`UpdateRune()` |
| 一键辅助 | `UpdatePlayerAssistant()` |
| 法术失败 | `UpdateSpellFailed()` |
| 队伍类型/人数 | `UpdateGroupType()`、`UpdateGroupCount()` |
| Boss/难度 | `UpdateEncounterID()` |
| 英雄天赋 | `UpdateHeroTalent()` |
| 配置开关 | `UpdatePlayerConfig()` 与各 `Switch*()` |
| 物品冷却 | `UpdateItemCooldown()` |
| 光环像素 | `RefreshPlayerAuraContainers()` / `LayoutAuraApplicationBars()` |

玩家“有效”要求同时满足：

```text
未死亡
且未坐骑/旅行形态
且聊天输入框未聚焦
且未处于喝水状态
```

### 11.2 目标和焦点

- 目标类型当前只区分：无目标/无效=0、敌方=`1/255`、友方=`11/255`。
- 目标距离来自 `LibRangeCheck-3.0:GetRange("target")`。
- 敌方范围阈值取当前专精 `rangeSpecID`；友方阈值固定 40 码。
- 目标和焦点的施法/引导剩余时间与可打断状态由动态名称拼接写入：

```text
目标施法、目标施法可打断、目标引导、目标引导可打断
焦点施法、焦点施法可打断、焦点引导、焦点引导可打断
```

这些名称虽然不一定以字面量 `blocks.state["..."]` 出现在静态搜索结果中，仍然有真实写入者。

### 11.3 姓名板敌人数

`NAME_PLATE_UNIT_ADDED/REMOVED` 维护 `nameplate` 缓存。每 0.2 秒重新估算距离，只统计：

- 可攻击；
- `maxRange <= 当前专精范围`；
- 正在战斗，或位于测试地图/测试首领环境。

## 12. 宏系统

### 12.1 键池

`core/macro.lua` 生成 7 组修饰键：

```text
CTRL
ALT
SHIFT
ALT-CTRL
ALT-SHIFT
CTRL-SHIFT
ALT-CTRL-SHIFT
```

每组结合数字键盘、F 键和标点/数字键，共形成顺序化的 `macroKind`。按钮名为 `s1`、`s2`……，使用 `SecureActionButtonTemplate` 和 `SetOverrideBindingClick()`。

### 12.2 `ClassMacros` / `MacrosList`

宏数据源在 `core/classmacros.lua`：

```lua
Fuyutsui.ClassMacros = {
    WARRIOR = {
        dynamicSpells = { ... },
        staticSpells = { ... },
        specialSpells = { ... },
    },
    -- 其他职业 ...
}
```

`LoadPlayerMacros()` 按 `UnitClassBase("player")` 取出当前职业表，赋给运行时 `self.MacrosList`，再调用 `CreateMacro`。

分配规则：

1. 每个 `dynamicSpells` 占 30 个连续键。
2. 动态键按 raid1..raid30 展开；前 5 个键兼容玩家/小队。
3. 动态区之后，使用 `specialSpells[index]`。
4. 若该位置没有 special，则回退到 `staticSpells[index]` 并自动加 `/cast `。
5. 同一位置的 special 优先于 static。

安全按钮不能在战斗中创建或修改。`CreateMacro()` 遇到 `InCombatLockdown()` 会直接返回。

## 13. 动作条键位扫描

`core/keybinds.lua` 在 `ReadKeybindings()` 后延迟 0.5 秒扫描槽位 1..180：

```lua
Fuyutsui.keybindings[spellId] = {
    key = "CTRL-1",
    slot = 1,
    keycode = Fuyutsui.keymap[key],
    icon = spellinfo.iconID,
    name = spellinfo.name,
}
```

扫描触发：

- 启用插件。
- `UPDATE_BINDINGS`。
- `SPELLS_CHANGED`。
- `ACTIONBAR_SHOWGRID`。
- `ACTIONBAR_HIDEGRID`。

动作条槽位范围和绑定前缀在 `Fuyutsui.actionBars`；Windows 风格虚拟键码在 `Fuyutsui.keymap`。宏生成顺序的完整对照在 `Keymap.md`，两套“键位”概念不要混淆：

- `macroKind`：插件创建安全宏时占用的组合键序列。
- `keymap`：扫描用户动作条后把 WoW 按键名转成整数编码。

## 14. 分频刷新

`StartFrameUpdates()` 创建一个 Frame，把 `OnUpdate` 转发到 `Fuyutsui:OnUpdate(elapsed)`。

### 每帧

- 玩家施法。
- 玩家引导。
- 玩家蓄力与层数。
- 目标施法/引导。
- 焦点施法/引导。
- 每次轮询一个队伍成员的范围、角色和血量。

### 每 0.2 秒

- 法术冷却与充能。
- 官方一键辅助建议。
- 符文。
- 目标距离。
- 范围内敌人数。
- 物品冷却。

### 每 1 秒

- 战斗时间。
- 死亡骑士天启骑士数量。

### 不在 OnUpdate 中

- 玩家/队伍光环像素：AuraContainer 事件驱动。

新增逻辑时优先放到最低可接受频率。只有读条、引导、蓄力或平滑倒计时才应每帧运行。

## 15. 职业覆盖概览

`specIndex` 是职业内的 1-based 专精序号，不是全局 specID。

| 职业文件 | 专精 1 | 专精 2 | 专精 3 | 专精 4 | 结构特点 |
| --- | --- | --- | --- | --- | --- |
| `Warrior.lua` | 武器 | 狂怒 | 防护 | — | 仍有大量旧 `auraName` 高亮条目（当前不生效） |
| `Paladin.lua` | 神圣 | 防护 | 惩戒 | — | 三专精都有队伍区；光环待迁到 spellId |
| `Hunter.lua` | 野兽控制 | 射击 | 生存 | — | 野兽专精有旧光环和多个充能格 |
| `Rogue.lua` | 奇袭 | 狂徒 | 敏锐 | — | 以法术冷却和通用战斗状态为主 |
| `Priest.lua` | 戒律 | 神圣 | 暗影 | — | 戒律已迁 AuraContainer；神圣等仍有旧格式 |
| `DeathKnight.lua` | 鲜血 | 冰霜 | 邪恶 | — | 符文、天启骑士、邪恶多计数条 |
| `Shaman.lua` | 元素 | 增强 | 恢复 | — | 恢复队伍区从索引 256 开始 |
| `Mage.lua` | 奥术 | 火焰 | 冰霜 | — | 奥术/火焰目前只有基础状态；冰霜有旧光环 |
| `Warlock.lua` | 痛苦 | 恶魔学识 | 毁灭 | — | 恶魔专精有施法计数条 |
| `Monk.lua` | 酒仙 | 织雾 | 踏风 | — | 酒池、治疗队伍区、多种计数条 |
| `Druid.lua` | 平衡 | 野性 | 守护 | 恢复 | 姿态、守护/恢复旧光环、恢复队伍区 |
| `DemonHunter.lua` | 浩劫 | 复仇 | 噬灭 | — | 复仇 5 条计数条，噬灭残片计数 |
| `Evoker.lua` | 湮灭 | 恩护 | 增辉 | — | 恩护当前为空表；增辉有队伍区 |

任何“支持情况”都应结合：专精表是否为空、是否只有基础状态、光环是否已迁到 `spellId`/`spellIds`、是否具备手写逻辑所需输出。不能只看文件是否存在。

## 16. 配置开关入口

斜杠命令：

| 命令 | 行为 |
| --- | --- |
| `/fu cd [on\|off]` | 修改 `cooldowns` |
| `/fu aoemode [auto\|aoe]` | 修改 `aoeMode` |
| `/fu dpsmode [manual\|assistant]` | 修改 `dpsMode` |
| `/fu potion [on\|off]` | 修改 `potion` |
| `/fu delay [秒]` | 把 `delay` 置 1，到期归零 |
| `/fu help` | 打印帮助 |

快速按钮：

- 左键：爆发。
- 右键：AOE。
- 中键：输出模式。
- 鼠标按键 4：药水。
- 按住左键拖动：保存位置。

修改开关时应通过对应 `SwitchCooldown/SwitchAoeMode/SwitchDpsMode/SwitchDelay/SwitchPotion` 完成聊天提示、DB 规范化、像素和按钮外观同步。

## 17. 添加功能的正确路径

### 17.1 添加普通状态格

1. 在目标职业和专精的 `ClassBlocks` 中选一个不冲突的索引。
2. 添加 `{ type = "block", name = "中文名称" }`。
3. 在 `main.lua` 增加状态采集与 `CreateTexture()` 写入。
4. 选择事件驱动或合适的分频刷新。
5. 搜索同名字符串，确认声明和写入完全一致。
6. 在游戏内 `/reload`，再由读取端核对索引和蓝值。

只声明 block 不会自动产生值。

### 17.2 添加法术冷却格

1. 在职业表添加 `type = "spell"` 与数值 `spellId`。
2. 如需充能恢复时间，增加同 spellId、`charge = true` 的第二格。
3. 临时/未正常出现在已知法术 API 的技能按需使用 `forcedKnown` 或 `inSpellBook`。
4. 如果官方一键辅助或施法技能编码也要识别它，在 `Fuyutsui.spellsList` 添加正确索引。

### 17.3 添加玩家光环格（AuraContainer）

1. 在对应 `class/*.lua` 专精中加入：

```lua
[index] = {
    type = "aura",
    name = "中文名称",
    spellId = 12345,          -- 或 spellIds = { 12345, 67890 }
    maxApps = 5,              -- 可选
}
```

2. 确认索引不与同专精其他格冲突。
3. 若需要层数条，设 `maxApps`，并确认横向条总宽不超过 `BAR_UNIT_COUNT`。
4. 不要再写 `auraName` / `showKey`，也不要改已下线的 `core/auras.lua`。
5. `/reload` 后验证：有光环时该索引出现 `█`/底色，过期后消失；层数条随层数变化。

### 17.4 添加队伍光环 / 驱散格

1. 在 `type = "group"` 中设置 `num`、`healthPercent`、`role`。
2. 成员有益光环：

```lua
aura = {
    [offset] = { name = "...", spellId = 12345 },
}
```

3. 可驱散减益：`dispel = offset`。
4. 确认 `start + (maxMembers - 1) * num + maxOffset <= 510`。
5. 队伍变化后依赖 `UpdateGroup()` → `RefreshGroupAuraContainers()`。

### 17.5 添加宏

1. 判断是 30 人动态目标技能、普通 `/cast`，还是完整特殊宏。
2. 动态技能放 `dynamicSpells`。
3. 普通技能放 `staticSpells`。
4. 完整文本放 `specialSpells`；同序号会覆盖 static。
5. 检查动态区占用的 `#dynamicSpells * 30` 偏移。
6. 不要尝试在战斗中重建安全按钮。
7. 如果改变键池顺序，同步 `Keymap.md` 和外部读取端。

### 17.6 添加新 Lua 模块

1. 明确它依赖哪些 `Fuyutsui` 表或方法。
2. 在依赖之后、消费者之前插入 `Fuyutsui.toc`。
3. 使用 WoW Lua 5.1 兼容语法。
4. 不引入普通 Lua 运行时才有、WoW 中没有的模块。

## 18. 已知实现边界与可疑点

以下是阅读当前源码时必须知道的事实。除非任务明确要求修复，否则先保留行为并向用户说明。

1. `core/block.lua` 已支持 510 个主色块、高度 5、横向条 500 单元；部分旧说明仍写 255/高度 1。
2. `ClearGroupBlocks()` 只清到索引 255；若用于索引 256 之后的队伍区，清理范围不足。
3. 多数职业光环仍是旧 `auraName`/`showKey` 写法，运行时被忽略；目前只有戒律牧师等少量条目完成迁移。
4. `core/auras.lua` 若仍在磁盘上，也不是运行时；不要把它当生效模块去改。
5. 萨满增强声明了“漩涡武器层数”，当前主逻辑没有明确写入者。
6. `UpdateItemCooldown()` 支持“大蓝冷却”和“圣光潜力冷却”，当前职业表没有声明对应格，属于休眠能力。
7. `UpdatePlayerConfig()` 写爆发、AOE、输出模式和药水，但不写 `delay`；delay 主要由 `SwitchDelay()` 更新。
8. `UNIT_SPELLCAST_EMPOWER_STOP` 条件可疑：`unitTarget ~= "player"` 时清理的是玩家蓄力状态，与其他施法停止处理不一致，修改前应在游戏内复现。
9. `UpdateShapeshiftForm()` 把 `state.shapeshiftFormID` 除以 255 保存，而 `UpdatePlayerMounted()` 又拿它和原始 ID `27/3/29` 比较，形态坐骑判定值得实测。
10. 目标类型注释/曲线曾为驱散细分预留空间，但当前 `getTargetDispelType()` 实际只输出敌方 1、友方 11 或 0。
11. `core/keybinds.lua` 对动作类型 `macro` 与 `spell` 使用相同的第二返回值作为 spellId；复杂宏的识别结果需要游戏内验证。
12. AuraContainer 受 secret aura / 安全模板限制；战斗中首次创建失败时的行为需按 `AuraContainer_AI_Reference_zh-CN.md` 验证。

## 19. 静态检查建议

修改后至少执行：

```text
1. 检查 Fuyutsui.toc 加载顺序。
2. 搜索新增 block 名称的声明和写入。
3. 搜索新增光环是否使用 spellId/spellIds，而不是旧 auraName/showKey。
4. 搜索 spellId 是否在职业表、spellsList、队伍 aura 和宏中承担不同含义。
5. 检查同一专精是否出现重复像素索引。
6. 检查主色块索引是否在 1..510。
7. 检查横向条（计数条 + maxApps）总宽是否超过 BAR_UNIT_COUNT。
8. 检查 group 起点、步长、dispel/aura 偏移和最大队伍人数是否会越过 510。
9. 检查 Lua 5.1 兼容性和表尾逗号。
10. 避免格式化整个仓库或修改 vendored libs。
```

可用的只读搜索思路：

```powershell
rg -n 'type = "block"|type = "aura"|type = "spell"|type = "group"' class
rg -n 'spellId = |spellIds = |maxApps = |auraName = ' class
rg -n 'blocks\.state|CreateTexture|RefreshPlayerAura|RefreshGroupAura|LayoutAura' main.lua core
rg -n '^function Fuyutsui:|^local function' main.lua core
```

普通 shell 无法验证 WoW API、secret value、安全模板、战斗锁定、实际动作条或像素取整。

## 20. 游戏内验证清单

1. `/reload` 后确认无 Lua 错误。
2. 确认顶部主色条横向无缝，高度与 `BLOCK_HEIGHT` 一致。
3. 分别验证 1..255 与 256..510 的索引解码。
4. 切换天赋与专精，确认旧色块、计数条和 AuraContainer 被清理重建。
5. 进入和离开战斗，确认战斗时间与安全宏没有 taint/lockdown 错误。
6. 聚焦聊天框，确认“有效性”归零。
7. 更换目标和焦点，验证读条、可打断、距离和血量。
8. 组队后验证成员顺序、血量、角色、范围，以及 `group.aura` / `group.dispel` 像素。
9. 触发新增光环的获得、叠层、消费、隐藏和自然过期路径。
10. 修改动作条或键位后确认 `Fuyutsui.keybindings` 重建。
11. 若修改 AuraContainer，分别在脱战创建、战斗延迟创建和 secret aura 环境验证。

## 21. 给后续 AI 的最短工作流程

接到代码修改任务时：

1. 先读 `Fuyutsui.toc` 和相关模块，不凭文件名猜加载关系。
2. 检查 `git status --short`，保护用户已有改动。
3. 若涉及输出协议或光环像素，先读 `core/block.lua`，必要时再读 `AuraContainer_AI_Reference_zh-CN.md`。
4. 若涉及职业格，连读对应 `class/*.lua` 与 `main.lua` 写入/`LoadPlayerBlocks`；光环只认 `spellId`/`spellIds`。
5. 若涉及宏，连读 `core/macro.lua`、`core/classmacros.lua` 和 `Keymap.md`。
6. 若涉及配置，检查 DB、斜杠命令、快速按钮和像素四处是否同步。
7. 做最小范围修改；公开 API 保持 PascalCase，改名后全局替换调用点与文档。
8. 完成静态检查，并明确哪些部分只能在 WoW 内验证。
