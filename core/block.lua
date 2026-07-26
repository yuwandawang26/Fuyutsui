local addon, ns = ...
local screenWidth = GetScreenWidth()

--[[============================================================================
    可修改配置（置顶）
============================================================================]]

-- 主色条（FuyutsuiColorBars / CreateTexture）
local BLOCK_FIX_COUNT = 510        -- 总色块数量
local BLOCK_FIRST_SCHEME_MAX = 255 -- 第一套索引方案上限（其后用 r=1/255）
local BLOCK_HEIGHT = 1             -- 色块高度
local BLOCK_SPACING = 0            -- 色块间距
local COLOR_BARS_STRATA = "BACKGROUND"
local COLOR_BARS_LEVEL = 5001

-- 横向条（FuyutsuiCountBars：计数条 + 光环层数条，BAR_END_COLOR 收尾）
local BAR_UNIT_COUNT = 500  -- 横向单元数
local BAR_HEIGHT = 1        -- 条高度
local BAR_FRAME_HEIGHT = 20 -- 容器高度
local BAR_START_INDEX = 2   -- 首条占用起始单元
local BAR_STRATA = "BACKGROUND"
local BAR_LEVEL = 1
local BAR_STATUS_LEVEL = 4999                                -- StatusBar 层级
local BAR_END_COLOR = { 200 / 255, 200 / 255, 200 / 255, 1 } -- 全部条之后的终点色块

-- AuraContainer 计时色块（█）
local AURA_BLOCK_HEIGHT = BLOCK_HEIGHT -- 高单独设置；宽与主色块一致
local AURA_DURATION_CHAR = "█"
local AURA_ENABLE_MOUSE = false        -- false = 关闭悬停提示
local AURA_DURATION_STRATA = "TOOLTIP"
local AURA_DURATION_LEVEL = 5003

-- AuraContainer 层数条
local AURA_BAR_STRATA = "TOOLTIP"
local AURA_BAR_LEVEL = 5004

--[[============================================================================
    派生尺寸（一般不用改）
============================================================================]]

local BLOCK_FIX_CONFIG = {
    blockCount = BLOCK_FIX_COUNT,
    blockWidth = screenWidth / BLOCK_FIX_COUNT,
    blockHeight = BLOCK_HEIGHT,
    blockSpacing = BLOCK_SPACING,
}

local BAR_CONFIG = {
    count = BAR_UNIT_COUNT,
    heightOffset = -BLOCK_HEIGHT,
    width = screenWidth / BAR_UNIT_COUNT,
    height = BAR_HEIGHT,
    point = "TOPLEFT",
}

local AURA_BLOCK_W = BLOCK_FIX_CONFIG.blockWidth
local AURA_BLOCK_H = AURA_BLOCK_HEIGHT

--- 索引 1..255 → r=0, g=i/255；256..510 → r=1/255, g=(i-255)/255
local function EncodeBlockChannels(index)
    if index > BLOCK_FIRST_SCHEME_MAX then
        return 1 / 255, (index - BLOCK_FIRST_SCHEME_MAX) / 255
    end
    return 0, index / 255
end

local function EnsureAuraContainerLoaded()
    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end
end

--[[============================================================================
    主色条
============================================================================]]

local function GetXOffset(index, Width, spacing)
    return index * (Width + spacing)
end

local colorBars = CreateFrame("Frame", "FuyutsuiColorBars", UIParent)
colorBars:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
colorBars:SetSize(screenWidth, BLOCK_FIX_CONFIG.blockHeight)
colorBars:SetFrameStrata(COLOR_BARS_STRATA)
colorBars:SetFrameLevel(COLOR_BARS_LEVEL)

local pixelTextures = {}

local function createTextureByIndex(i)
    if i <= 0 or i > BLOCK_FIX_CONFIG.blockCount then return nil end
    if pixelTextures[i] == nil then
        local tex = colorBars:CreateTexture(nil, "OVERLAY")
        tex:SetSize(BLOCK_FIX_CONFIG.blockWidth, BLOCK_FIX_CONFIG.blockHeight)
        tex:SetPoint("TOPLEFT", colorBars, "TOPLEFT",
            GetXOffset(i - 1, BLOCK_FIX_CONFIG.blockWidth, BLOCK_FIX_CONFIG.blockSpacing), 0)
        pixelTextures[i] = tex
    end
    return pixelTextures[i]
end

-- 索引 1..255: (0, i/255, b, 1)；索引 256..510: (1/255, (i-255)/255, b, 1)
function Fuyutsui:CreateTexture(i, b)
    local tex = createTextureByIndex(i)
    if tex then
        local r, g = EncodeBlockChannels(i)
        tex:SetColorTexture(r, g, b, 1)
    end
end

function Fuyutsui:ClearAllTextures()
    for i = 1, BLOCK_FIX_CONFIG.blockCount do
        self:CreateTexture(i, 0)
    end
end

for i = 1, BLOCK_FIX_CONFIG.blockCount do
    Fuyutsui:CreateTexture(i, 0)
end

--[[============================================================================
    横向计数条布局（计数条 + AuraContainer 层数条共用）
    排布：计数条 → 光环层数条 → BAR_END_COLOR（终点色块始终在最后）
    单条占用：背景单元 [-1..max] + 预留终点位 + 间隔 → 步进 max+3
============================================================================]]

local countBars = CreateFrame("Frame", "FuyutsuiCountBars", UIParent)
countBars:SetSize(screenWidth, BAR_FRAME_HEIGHT)
countBars:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, BAR_CONFIG.heightOffset)
countBars:SetFrameStrata(BAR_STRATA)
countBars:SetFrameLevel(BAR_LEVEL)

local createdBars = {}
local spellIdToBar = {}
local nextAvailableIndex = BAR_START_INDEX
local countBarEndTexture = nil
local auraBarLaidOut = false
local anyHorizontalBarLaidOut = false

local BAR_EVENTS = { "SPELL_UPDATE_USES", "PLAYER_ENTERING_WORLD", "SPELL_UPDATE_CHARGES" }

--- 预留一条横向条的单元；成功返回 startIndex，空间不足返回 nil
local function ReserveHorizontalBarUnits(maxValue, warnMsg)
    local startIndex = nextAvailableIndex
    -- +1 终点色块预留，+2 与下一条间隔（终点色块最终只画在全部条之后）
    local newIndex = startIndex + maxValue + 3
    if newIndex > BAR_CONFIG.count then
        if warnMsg then
            print(warnMsg)
        end
        return nil
    end
    nextAvailableIndex = newIndex
    anyHorizontalBarLaidOut = true
    return startIndex
end

--- 背景索引色块：(r=1/255, g=相对索引/255, b=0)，供外部定位条段
local function CreateHorizontalBarBackgrounds(startIndex, maxValue)
    for i = -1, maxValue do
        local currentRelativeIndex = i + 1
        local absolutePos = startIndex + i
        local tex = countBars:CreateTexture(nil, "BACKGROUND")
        tex:SetSize(BAR_CONFIG.width, BAR_CONFIG.height)
        tex:SetPoint("TOPLEFT", countBars, "TOPLEFT", (absolutePos - 1) * BAR_CONFIG.width, 0)
        tex:SetColorTexture(1 / 255, currentRelativeIndex / 255, 0, 1)
    end
end

local function StyleHorizontalStatusBar(bar)
    bar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar:GetStatusBarTexture():SetDrawLayer("ARTWORK")
    bar:SetStatusBarColor(1, 1, 1, 1)
end

--- 将终点色块放到当前已分配内容之后（nextAvailableIndex - 2）
local function UpdateHorizontalBarEndMarker()
    if not anyHorizontalBarLaidOut then
        if countBarEndTexture then
            countBarEndTexture:Hide()
        end
        return
    end
    local endPos = nextAvailableIndex - 2
    if not countBarEndTexture then
        countBarEndTexture = countBars:CreateTexture(nil, "BACKGROUND")
        countBarEndTexture:SetSize(BAR_CONFIG.width, BAR_CONFIG.height)
    end
    countBarEndTexture:ClearAllPoints()
    countBarEndTexture:SetPoint("TOPLEFT", countBars, "TOPLEFT", (endPos - 1) * BAR_CONFIG.width, 0)
    countBarEndTexture:SetColorTexture(BAR_END_COLOR[1], BAR_END_COLOR[2], BAR_END_COLOR[3], BAR_END_COLOR[4])
    countBarEndTexture:Show()
end

---@param minValue number
---@param maxValue number
---@param spellId number
function Fuyutsui:CreateAutoLayoutBar(valueType, minValue, maxValue, spellId)
    maxValue = maxValue or 0
    minValue = minValue or 0
    if spellIdToBar[spellId] then
        return spellIdToBar[spellId]
    end

    local startIndex = ReserveHorizontalBarUnits(maxValue, "警告: Fuyutsui_CountBars 空间不足!")
    if not startIndex then
        return nil
    end

    CreateHorizontalBarBackgrounds(startIndex, maxValue)

    local bar = CreateFrame("StatusBar", nil, countBars)
    bar:SetSize(maxValue * BAR_CONFIG.width + 1, BAR_CONFIG.height)
    bar:SetPoint("TOPLEFT", countBars, "TOPLEFT", (startIndex - 1) * BAR_CONFIG.width, 0)
    StyleHorizontalStatusBar(bar)
    bar:SetFrameLevel(BAR_STATUS_LEVEL)

    local function Refresh()
        local val = 0
        if valueType == "castCount" then
            val = C_Spell.GetSpellCastCount(spellId) or 0
        elseif valueType == "charge" then
            local charges = C_Spell.GetSpellCharges(spellId)
            if not charges then return end
            val = charges.currentCharges or 0
        end
        bar:SetMinMaxValues(minValue, maxValue)
        bar:SetValue(val)
    end

    for _, event in ipairs(BAR_EVENTS) do
        bar:RegisterEvent(event)
    end
    bar:SetScript("OnEvent", Refresh)
    Refresh()

    tinsert(createdBars, bar)
    spellIdToBar[spellId] = bar
    return bar
end

function Fuyutsui:ClearAllFuyutsuiBars()
    for _, bar in ipairs(createdBars) do
        bar:UnregisterAllEvents()
        bar:SetScript("OnEvent", nil)
        bar:Hide()
        bar:SetParent(nil)
    end

    local regions = { countBars:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") then
            ---@diagnostic disable-next-line: undefined-field
            region:SetColorTexture(0, 0, 0, 0)
            region:Hide()
        end
    end

    wipe(createdBars)
    wipe(spellIdToBar)
    nextAvailableIndex = BAR_START_INDEX
    anyHorizontalBarLaidOut = false
    auraBarLaidOut = false
    if Fuyutsui.ReleasePlayerAuraContainers then
        Fuyutsui:ReleasePlayerAuraContainers()
    end
    if Fuyutsui.ReleaseGroupAuraContainers then
        Fuyutsui:ReleaseGroupAuraContainers()
    end
end

--[[============================================================================
    AuraContainer（列表来自 ClassBlocks auras + spellId/spellIds）
    单位：player / target / focus；filter：HELPFUL / HARMFUL
    includeSpellIDs 可绑多个 ID：任一存在即显示（AuraSlot 取排序最前的一个）
    参考：AuraContainer_AI_Reference_zh-CN.md（PTR 7）
============================================================================]]

--- 归一化为 includeSpellIDs 集合；支持 spellId、spellIds=number 或 spellIds={ id1, id2 }
local function BuildIncludeSpellIDs(info)
    local set = {}
    if type(info.spellIds) == "table" then
        for _, id in ipairs(info.spellIds) do
            if type(id) == "number" then
                set[id] = true
            end
        end
    elseif type(info.spellIds) == "number" then
        set[info.spellIds] = true
    end
    if type(info.spellId) == "number" then
        set[info.spellId] = true
    end
    return set
end

local function CollectAuraSpellSlots(unitFilter)
    local slots = {}
    local auras = Fuyutsui.blocks and Fuyutsui.blocks.auras
    if not auras then
        return slots
    end
    for index, info in pairs(auras) do
        if type(info) == "table" then
            local unit = info.unit or "player"
            if not unitFilter or unit == unitFilter then
                local includeSpellIDs = BuildIncludeSpellIDs(info)
                if next(includeSpellIDs) then
                    tinsert(slots, {
                        index = index,
                        includeSpellIDs = includeSpellIDs,
                        maxApps = info.maxApps,
                        name = info.name,
                        unit = unit,
                        filter = info.filter or "HELPFUL",
                    })
                end
            end
        end
    end
    table.sort(slots, function(a, b)
        return a.index < b.index
    end)
    return slots
end

local function AuraSlotFilters(includeSpellIDs)
    -- 不要设 maxDuration：任何非 nil 的 maxDuration 都会排除永久光环（持续时间为 0）
    return {
        includeSpellIDs = includeSpellIDs,
    }
end

local function AuraBlockXOffset(index)
    return (index - 1) * BLOCK_FIX_CONFIG.blockWidth
end

local function ConfigureAuraButtonMouse(button)
    button:SetMouseMotionEnabled(AURA_ENABLE_MOUSE)
    if AURA_ENABLE_MOUSE then
        button:SetHideTooltipInCombat(true)
    end
end

--- 对齐 CreateTexture(i, b)：绿通道编码索引，蓝通道随剩余秒数 0..255 从 0→1
local function MakeDurationColorCurve(index)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    local r, g = EncodeBlockChannels(index)
    curve:AddPoint(0, CreateColor(r, g, 0, 1))
    curve:AddPoint(255, CreateColor(r, g, 1, 1))
    return curve
end

local function SetupClippedDuration(button, index)
    button:SetSize(AURA_BLOCK_W, AURA_BLOCK_H)
    button:SetClipsChildren(true)
    ConfigureAuraButtonMouse(button)
    button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", AuraBlockXOffset(index), 0)

    -- 纯色底：固定 (r, g, 1, 1)，层级低于 █
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    local r, g = EncodeBlockChannels(index)
    bg:SetColorTexture(r, g, 1, 1)

    local duration = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    duration:SetPoint("CENTER", button, "CENTER", 0, 0)
    duration:SetJustifyH("CENTER")
    duration:SetJustifyV("MIDDLE")
    button:SetDurationText(duration, {
        textFormat = {
            formatString = AURA_DURATION_CHAR,
            components = {},
        },
        textColor = {
            curve = MakeDurationColorCurve(index),
            property = Enum.DurationTextBindingProperty.RemainingDuration,
        },
    })
end

local function MakeDurationSlotInitializer(index)
    return function(button)
        SetupClippedDuration(button, index)
    end
end

-- 防御驱散类型 -> 蓝通道编码（与 main.lua DEFENSIVE_DISPEL_TYPE_NAMES / dispelCapabilities 一致）
local DISPEL_TYPE_COLOR_IDS = {
    Magic = 1,
    Curse = 2,
    Disease = 3,
    Poison = 4,
    Bleed = 11,
}

--- 驱散像素：固定纹理 + 按驱散类型写死颜色（非剩余时间）
local function MakeDispelColorMap(index)
    local r, g = EncodeBlockChannels(index)
    local map = {}
    for name, id in pairs(DISPEL_TYPE_COLOR_IDS) do
        map[name] = CreateColor(r, g, id / 255, 1)
    end
    return map
end

local function SetupDispelTypePixel(button, index)
    button:SetSize(AURA_BLOCK_W, AURA_BLOCK_H)
    button:SetClipsChildren(true)
    ConfigureAuraButtonMouse(button)
    button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", AuraBlockXOffset(index), 0)

    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(button)
    tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    tex:SetVertexColor(1, 1, 1, 1)

    button:AddDispelTypeTexture(tex, {
        showWhenHarmful = true,
        showWhenHelpful = false,
        showWithoutDispelType = false,
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
        customDispelColorMap = MakeDispelColorMap(index),
    })
end

local function MakeDispelSlotInitializer(index)
    return function(button)
        SetupDispelTypePixel(button, index)
    end
end

--- 层数条：与计数条同一套坐标/背景编码，StatusBar 由 AuraContainer 驱动
local function SetupApplicationBarOnly(button, maxApps, startIndex)
    button:SetSize(maxApps * BAR_CONFIG.width, BAR_CONFIG.height)
    ConfigureAuraButtonMouse(button)
    button:SetPoint("TOPLEFT", countBars, "TOPLEFT", (startIndex - 1) * BAR_CONFIG.width, 0)

    local bar = CreateFrame("StatusBar", nil, button)
    bar:SetAllPoints(button)
    StyleHorizontalStatusBar(bar)
    bar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)

    button:SetApplicationBar(bar, {
        maxApplications = maxApps,
    })
end

local function MakeBarSlotInitializer(maxApps, startIndex)
    return function(button)
        SetupApplicationBarOnly(button, maxApps, startIndex)
    end
end

local function ReleaseFrame(frame)
    if not frame then
        return
    end
    frame:SetEnabled(false)
    frame:Hide()
    frame:SetParent(nil)
end

local UNIT_AURA_CONTAINER_KEYS = {
    player = "PlayerAuraContainer",
    target = "TargetAuraContainer",
    focus = "FocusAuraContainer",
}

function Fuyutsui:ReleaseUnitAuraContainers()
    for _, key in pairs(UNIT_AURA_CONTAINER_KEYS) do
        ReleaseFrame(Fuyutsui[key])
        Fuyutsui[key] = nil
    end
    ReleaseFrame(Fuyutsui.PlayerAuraBarContainer)
    Fuyutsui.PlayerAuraBarContainer = nil
    auraBarLaidOut = false
end

-- 兼容旧名
function Fuyutsui:ReleasePlayerAuraContainers()
    self:ReleaseUnitAuraContainers()
end

local function CreateUnitAuraDurationSlots(unit, spellSlots)
    if not spellSlots or #spellSlots == 0 then
        return
    end

    local key = UNIT_AURA_CONTAINER_KEYS[unit]
    if not key then
        return
    end

    EnsureAuraContainerLoaded()

    local frameName = "Fuyutsui" .. unit:gsub("^%l", string.upper) .. "AuraDurationSlots"
    local durationSlots = CreateFrame("AuraContainer", frameName, UIParent, "CustomAuraContainerTemplate")
    durationSlots:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    durationSlots:SetUnit(unit)
    durationSlots:SetEnabled(true)
    durationSlots:SetFrameStrata(AURA_DURATION_STRATA)
    durationSlots:SetFrameLevel(AURA_DURATION_LEVEL)

    for _, info in ipairs(spellSlots) do
        local filter = info.filter or "HELPFUL"
        durationSlots:AddAuraSlot("duration_index_" .. info.index, filter, {
            candidateFilters = AuraSlotFilters(info.includeSpellIDs),
            sortMethod = AuraContainerSortMethod.Expiration,
            sortDirection = AuraContainerSortDirection.Normal,
            initializeFrame = MakeDurationSlotInitializer(info.index),
        })
    end

    Fuyutsui[key] = durationSlots
end

function Fuyutsui:RefreshUnitAuraContainers()
    for unit, key in pairs(UNIT_AURA_CONTAINER_KEYS) do
        if not Fuyutsui[key] then
            local spellSlots = CollectAuraSpellSlots(unit)
            if #spellSlots > 0 then
                CreateUnitAuraDurationSlots(unit, spellSlots)
            end
        end
    end
end

-- 兼容旧名
function Fuyutsui:RefreshPlayerAuraContainers()
    self:RefreshUnitAuraContainers()
end

--- 在计数条之后排布层数条，最后放置 BAR_END_COLOR（仅玩家光环 maxApps）
function Fuyutsui:LayoutAuraApplicationBars()
    if auraBarLaidOut then
        return
    end

    local spellSlots = CollectAuraSpellSlots("player")
    local appSlots = {}
    for _, info in ipairs(spellSlots) do
        if info.maxApps then
            tinsert(appSlots, info)
        end
    end

    if #appSlots > 0 then
        EnsureAuraContainerLoaded()

        local barSlots = Fuyutsui.PlayerAuraBarContainer
        if not barSlots then
            barSlots = CreateFrame("AuraContainer", "FuyutsuiPlayerAuraBarSlots", countBars,
                "CustomAuraContainerTemplate")
            barSlots:SetPoint("TOPLEFT", countBars, "TOPLEFT", 0, 0)
            barSlots:SetUnit("player")
            barSlots:SetEnabled(true)
            barSlots:SetFrameStrata(AURA_BAR_STRATA)
            barSlots:SetFrameLevel(AURA_BAR_LEVEL)
            Fuyutsui.PlayerAuraBarContainer = barSlots

            for _, info in ipairs(appSlots) do
                local startIndex = ReserveHorizontalBarUnits(
                    info.maxApps,
                    "警告: Fuyutsui_CountBars 光环层数条空间不足!"
                )
                if not startIndex then
                    break
                end
                CreateHorizontalBarBackgrounds(startIndex, info.maxApps)
                barSlots:AddAuraSlot("bar_index_" .. info.index, info.filter or "HELPFUL", {
                    candidateFilters = AuraSlotFilters(info.includeSpellIDs),
                    sortMethod = AuraContainerSortMethod.Expiration,
                    sortDirection = AuraContainerSortDirection.Normal,
                    initializeFrame = MakeBarSlotInitializer(info.maxApps, startIndex),
                })
            end
        end
    end

    UpdateHorizontalBarEndMarker()
    auraBarLaidOut = true
end

--[[============================================================================
    队伍成员 AuraContainer
    配置：
      groups.aura[offset] = { name, spellId/spellIds }  -- HELPFUL|PLAYER，剩余时间色块
      groups.dispel = offset                            -- HARMFUL，按可驱散类型过滤；固定纹理按类型着色
    像素：start + (memberIndex-1)*num + offset
    驱散蓝通道：Magic=1 Curse=2 Disease=3 Poison=4 Bleed=11（/255）
============================================================================]]

local groupAuraContainers = {} -- [memberIndex] = AuraContainer

local function CollectGroupAuraDefs(auraTable)
    local defs = {}
    if type(auraTable) ~= "table" then
        return defs
    end
    for offset, info in pairs(auraTable) do
        if type(offset) == "number" and type(info) == "table" then
            local includeSpellIDs = BuildIncludeSpellIDs(info)
            if next(includeSpellIDs) then
                tinsert(defs, {
                    offset = offset,
                    includeSpellIDs = includeSpellIDs,
                    name = info.name,
                })
            end
        end
    end
    table.sort(defs, function(a, b)
        return a.offset < b.offset
    end)
    return defs
end

local function GroupAuraPixelIndex(groups, memberIndex, offset)
    return groups.start + (memberIndex - 1) * groups.num + offset
end

local function CopyIncludeDispelTypes()
    local src = Fuyutsui.includeDispelTypes
    if type(src) ~= "table" then
        return nil
    end
    local dst = {}
    local any = false
    for name, enabled in pairs(src) do
        if enabled then
            dst[name] = true
            any = true
        end
    end
    if not any then
        return nil
    end
    return dst
end

function Fuyutsui:ReleaseGroupAuraContainers()
    for memberIndex, container in pairs(groupAuraContainers) do
        ReleaseFrame(container)
        groupAuraContainers[memberIndex] = nil
    end
end

local function CreateGroupMemberAuraContainer(memberIndex, groups, auraDefs, includeDispelTypes)
    EnsureAuraContainerLoaded()

    local container = CreateFrame("AuraContainer", "FuyutsuiGroupAuraSlots_" .. memberIndex, UIParent,
        "CustomAuraContainerTemplate")
    container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    container:SetEnabled(true)
    container:SetFrameStrata(AURA_DURATION_STRATA)
    container:SetFrameLevel(AURA_DURATION_LEVEL)

    for _, def in ipairs(auraDefs) do
        local pixelIndex = GroupAuraPixelIndex(groups, memberIndex, def.offset)
        if pixelIndex > 0 and pixelIndex <= BLOCK_FIX_COUNT then
            container:AddAuraSlot(
                "group_" .. memberIndex .. "_aura_" .. def.offset,
                "HELPFUL|PLAYER",
                {
                    candidateFilters = AuraSlotFilters(def.includeSpellIDs),
                    sortMethod = AuraContainerSortMethod.Expiration,
                    sortDirection = AuraContainerSortDirection.Normal,
                    initializeFrame = MakeDurationSlotInitializer(pixelIndex),
                }
            )
        end
    end

    -- 可驱散减益：仅包含玩家当前会的驱散类型；像素显示类型固定色，非剩余时间
    if groups.dispel and includeDispelTypes then
        local pixelIndex = GroupAuraPixelIndex(groups, memberIndex, groups.dispel)
        if pixelIndex > 0 and pixelIndex <= BLOCK_FIX_COUNT then
            container:AddAuraSlot(
                "group_" .. memberIndex .. "_dispel",
                "HARMFUL",
                {
                    candidateFilters = {
                        includeDispelTypes = includeDispelTypes,
                    },
                    sortMethod = AuraContainerSortMethod.Expiration,
                    sortDirection = AuraContainerSortDirection.Normal,
                    initializeFrame = MakeDispelSlotInitializer(pixelIndex),
                }
            )
        end
    end

    return container
end

--- 按当前 groupList 为每个成员创建/绑定单位光环槽
function Fuyutsui:RefreshGroupAuraContainers()
    local groups = Fuyutsui.blocks and Fuyutsui.blocks.groups
    if not groups or not groups.start or not groups.num then
        self:ReleaseGroupAuraContainers()
        return
    end

    local auraDefs = CollectGroupAuraDefs(groups.aura)
    local includeDispelTypes = groups.dispel and CopyIncludeDispelTypes() or nil
    if #auraDefs == 0 and not includeDispelTypes then
        self:ReleaseGroupAuraContainers()
        return
    end

    local groupList = Fuyutsui.groupList or {}
    local group = Fuyutsui.group or {}
    local used = {}

    for _, unit in ipairs(groupList) do
        local obj = group[unit]
        if obj and obj.index then
            local memberIndex = obj.index
            used[memberIndex] = true
            local container = groupAuraContainers[memberIndex]
            if not container then
                container = CreateGroupMemberAuraContainer(memberIndex, groups, auraDefs, includeDispelTypes)
                groupAuraContainers[memberIndex] = container
            end
            container:SetUnit(unit)
            container:SetEnabled(true)
            container:Show()
        end
    end

    for memberIndex, container in pairs(groupAuraContainers) do
        if not used[memberIndex] then
            container:SetEnabled(false)
            container:Hide()
        end
    end
end
