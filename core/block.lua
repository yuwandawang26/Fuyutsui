local addon, ns = ...
local screenWidth = GetScreenWidth()

--[[============================================================================
    可修改配置（置顶）
============================================================================]]

-- 主色条（FuyutsuiColorBars / CreatTexture）
local BLOCK_FIX_COUNT = 510        -- 总色块数量
local BLOCK_FIRST_SCHEME_MAX = 255 -- 第一套索引方案上限（其后用 r=1/255）
local BLOCK_HEIGHT = 1             -- 色块高度
local BLOCK_SPACING = 0            -- 色块间距
local COLOR_BARS_STRATA = "BACKGROUND"
local COLOR_BARS_LEVEL = 5001

-- 计数条（FuyutsuiCountBars / CreateAutoLayoutBar）
local BAR_UNIT_COUNT = 255  -- 计数条横向单元数
local BAR_HEIGHT = 1        -- 计数条高度
local BAR_FRAME_HEIGHT = 20 -- 计数条容器高度
local BAR_START_INDEX = 2   -- 首条占用起始单元
local BAR_STRATA = "BACKGROUND"
local BAR_LEVEL = 1
local BAR_STATUS_LEVEL = 5002 -- StatusBar 层级
local BAR_END_COLOR = { 200 / 255, 200 / 255, 200 / 255, 1 }

-- AuraContainer 计时色块（█）
local AURA_BLOCK_HEIGHT = 10     -- 高单独设置；宽与主色块一致
local AURA_DURATION_CHAR = "█"
local AURA_ENABLE_MOUSE = false -- false = 关闭悬停提示
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

local function creatTextureByIndex(i)
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
function Fuyutsui:CreatTexture(i, b)
    local tex = creatTextureByIndex(i)
    if tex then
        if i > BLOCK_FIRST_SCHEME_MAX then
            tex:SetColorTexture(1 / 255, (i - BLOCK_FIRST_SCHEME_MAX) / 255, b, 1)
        else
            tex:SetColorTexture(0, i / 255, b, 1)
        end
    end
end

function Fuyutsui:clearAllTextures()
    for i = 1, BLOCK_FIX_CONFIG.blockCount do
        self:CreatTexture(i, 0)
    end
end

for i = 1, BLOCK_FIX_CONFIG.blockCount do
    Fuyutsui:CreatTexture(i, 0)
end

--[[============================================================================
    计数条
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
local auraBarSlotButtons = {}

local BAR_EVENTS = { "SPELL_UPDATE_USES", "PLAYER_ENTERING_WORLD", "SPELL_UPDATE_CHARGES" }

---@param minValue number
---@param maxValue number
---@param spellId number
function Fuyutsui:CreateAutoLayoutBar(valueType, minValue, maxValue, spellId)
    maxValue = maxValue or 0
    minValue = minValue or 0
    if spellIdToBar[spellId] then
        return spellIdToBar[spellId]
    end

    local startIndex = nextAvailableIndex
    local barWidth = maxValue * BAR_CONFIG.width
    -- +1 终点色块，+2 与下一条间隔
    nextAvailableIndex = startIndex + maxValue + 3

    if nextAvailableIndex > BAR_CONFIG.count then
        print("警告: Fuyutsui_CountBars 空间不足!")
        return nil
    end

    local bar = CreateFrame("StatusBar", nil, countBars)
    bar:SetSize(barWidth + 1, BAR_CONFIG.height)
    bar:SetPoint("TOPLEFT", countBars, "TOPLEFT", (startIndex - 1) * BAR_CONFIG.width, 0)
    bar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar:GetStatusBarTexture():SetDrawLayer("ARTWORK")
    bar:SetStatusBarColor(1, 1, 1, 1)
    bar:SetFrameLevel(BAR_STATUS_LEVEL)

    for i = -1, maxValue do
        local currentRelativeIndex = i + 1
        local absolutePos = startIndex + i
        local tex = countBars:CreateTexture(nil, "BACKGROUND")
        tex:SetSize(BAR_CONFIG.width, BAR_CONFIG.height)
        tex:SetPoint("TOPLEFT", countBars, "TOPLEFT", (absolutePos - 1) * BAR_CONFIG.width, 0)
        tex:SetColorTexture(1 / 255, currentRelativeIndex / 255, 0, 1)
    end

    local endPos = startIndex + maxValue + 1
    if not countBarEndTexture then
        countBarEndTexture = countBars:CreateTexture(nil, "BACKGROUND")
        countBarEndTexture:SetSize(BAR_CONFIG.width, BAR_CONFIG.height)
    end
    countBarEndTexture:ClearAllPoints()
    countBarEndTexture:SetPoint("TOPLEFT", countBars, "TOPLEFT", (endPos - 1) * BAR_CONFIG.width, 0)
    countBarEndTexture:SetColorTexture(BAR_END_COLOR[1], BAR_END_COLOR[2], BAR_END_COLOR[3], BAR_END_COLOR[4])
    countBarEndTexture:Show()

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
    auraBarLaidOut = false
    if Fuyutsui.ReleasePlayerAuraContainers then
        Fuyutsui:ReleasePlayerAuraContainers()
    end
end

--[[============================================================================
    AuraContainer（列表来自 ClassBlocks type="aura" + spellId）
    参考：AuraContainer_AI_Reference_zh-CN.md
============================================================================]]

local function CollectAuraSpellSlots()
    local slots = {}
    local auras = Fuyutsui.blocks and Fuyutsui.blocks.auras
    if not auras then
        return slots
    end
    local indices = {}
    for index, info in pairs(auras) do
        if type(info) == "table" and info.spellId then
            tinsert(indices, index)
        end
    end
    table.sort(indices)
    for _, index in ipairs(indices) do
        local info = auras[index]
        tinsert(slots, {
            index = index,
            spellId = info.spellId,
            maxApps = info.maxApps,
            name = info.name,
        })
    end
    return slots
end

local function AuraSlotFilters(spellId)
    -- 不要设 maxDuration：任何非 nil 的 maxDuration 都会排除永久光环（持续时间为 0）
    return {
        includeSpellIDs = { [spellId] = true },
    }
end

local function AuraBarWidth(maxApps)
    return maxApps * BAR_CONFIG.width
end

local function AuraBlockXOffset(index)
    return (index - 1) * BLOCK_FIX_CONFIG.blockWidth
end

--- 对齐 CreatTexture(i, b)：绿通道编码索引，蓝通道随剩余秒数 0..255 从 0→1
local function MakeDurationColorCurve(index)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    local i = index / 255
    if index > BLOCK_FIRST_SCHEME_MAX then
        i = (index - BLOCK_FIRST_SCHEME_MAX) / 255
        curve:AddPoint(0, CreateColor(1 / 255, i, 0, 1))
        curve:AddPoint(255, CreateColor(1 / 255, i, 1, 1))
    else
        curve:AddPoint(0, CreateColor(1, i, 0, 1))
        curve:AddPoint(255, CreateColor(1, i, 1, 1))
    end
    return curve
end

local function SetupClippedDuration(button, index)
    button:SetSize(AURA_BLOCK_W, AURA_BLOCK_H)
    button:SetClipsChildren(true)
    button:SetMouseMotionEnabled(AURA_ENABLE_MOUSE)

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

local function SetupApplicationBarOnly(button, maxApps)
    button:SetSize(AuraBarWidth(maxApps), BAR_CONFIG.height)
    button:SetMouseMotionEnabled(AURA_ENABLE_MOUSE)

    local bar = CreateFrame("StatusBar", nil, button)
    bar:SetAllPoints(button)
    bar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar:GetStatusBarTexture():SetDrawLayer("ARTWORK")
    bar:SetStatusBarColor(1, 1, 1, 1)
    bar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)

    button:SetApplicationBar(bar, {
        maxApplications = maxApps,
    })
end

local function MakeBarSlotInitializer(maxApps)
    return function(button)
        SetupApplicationBarOnly(button, maxApps)
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

function Fuyutsui:ReleasePlayerAuraContainers()
    ReleaseFrame(Fuyutsui.PlayerAuraContainer)
    ReleaseFrame(Fuyutsui.PlayerAuraBarContainer)
    Fuyutsui.PlayerAuraContainer = nil
    Fuyutsui.PlayerAuraBarContainer = nil
    wipe(auraBarSlotButtons)
    auraBarLaidOut = false
end

---@return boolean
local function CreatePlayerAuraDurationSlots(spellSlots)
    if InCombatLockdown() then
        return false
    end
    if not spellSlots or #spellSlots == 0 then
        return true
    end

    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end

    local durationSlots = CreateFrame("AuraContainer", "FuyutsuiPlayerAuraDurationSlots", UIParent,
        "CustomAuraContainerTemplate")
    durationSlots:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    durationSlots:SetUnit("player")
    durationSlots:SetEnabled(true)
    durationSlots:SetFrameStrata(AURA_DURATION_STRATA)
    durationSlots:SetFrameLevel(AURA_DURATION_LEVEL)

    for _, info in ipairs(spellSlots) do
        local index = info.index
        local btn = durationSlots:AddAuraSlot("duration_spell_" .. info.spellId, "HELPFUL", {
            candidateFilters = AuraSlotFilters(info.spellId),
            initializeFrame = MakeDurationSlotInitializer(index),
        })
        btn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", AuraBlockXOffset(index), 0)
    end

    Fuyutsui.PlayerAuraContainer = durationSlots
    return true
end

function Fuyutsui:RefreshPlayerAuraContainers()
    if Fuyutsui.PlayerAuraContainer then
        return
    end

    local spellSlots = CollectAuraSpellSlots()
    if #spellSlots == 0 then
        return
    end

    if not CreatePlayerAuraDurationSlots(spellSlots) then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(frame)
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
            Fuyutsui:RefreshPlayerAuraContainers()
        end)
    end
end

function Fuyutsui:LayoutAuraApplicationBars()
    if auraBarLaidOut then
        return
    end
    if InCombatLockdown() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            self:SetScript("OnEvent", nil)
            Fuyutsui:LayoutAuraApplicationBars()
        end)
        return
    end

    local spellSlots = CollectAuraSpellSlots()
    local hasApps = false
    for _, info in ipairs(spellSlots) do
        if info.maxApps then
            hasApps = true
            break
        end
    end
    if not hasApps then
        auraBarLaidOut = true
        return
    end

    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end

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
        wipe(auraBarSlotButtons)

        for _, info in ipairs(spellSlots) do
            if info.maxApps then
                local btn = barSlots:AddAuraSlot("bar_spell_" .. info.spellId, "HELPFUL", {
                    candidateFilters = AuraSlotFilters(info.spellId),
                    initializeFrame = MakeBarSlotInitializer(info.maxApps),
                })
                tinsert(auraBarSlotButtons, { button = btn, maxApps = info.maxApps })
            end
        end
    end

    for _, entry in ipairs(auraBarSlotButtons) do
        local startIndex = nextAvailableIndex
        nextAvailableIndex = startIndex + entry.maxApps + 3
        if nextAvailableIndex > BAR_CONFIG.count then
            print("警告: Fuyutsui_CountBars 光环层数条空间不足!")
            break
        end
        entry.button:ClearAllPoints()
        entry.button:SetPoint("TOPLEFT", countBars, "TOPLEFT", (startIndex - 1) * BAR_CONFIG.width, 0)
    end

    auraBarLaidOut = true
end
