local addon, ns = ...

--[[
    auracontainer.lua — 屏幕中央玩家光环（对齐 AuraContainer PTR 7 / 12.1.0.68914）

    CustomAuraContainerTemplate 驱动玩家 HELPFUL 光环：
    图标 + 冷却转圈 + 剩余时间 + 层数。不轮询 C_UnitAuras。

    参考：AuraContainer_AI_Reference_zh-CN.md
]]

local BUTTON_SIZE = 36
local BUTTON_SPACING = 4
local MAX_BUFFS = 32
local ROW_WIDTH = (BUTTON_SIZE + BUTTON_SPACING) * 8

local function EnsureAuraContainerLoaded()
    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end
end

local remainingColorCurve = C_CurveUtil.CreateColorCurve()
remainingColorCurve:SetType(Enum.LuaCurveType.Linear)
remainingColorCurve:AddPoint(0, CreateColor(1.00, 0.20, 0.15, 1))
remainingColorCurve:AddPoint(30, CreateColor(1.00, 1.00, 1.00, 1))

local function InitializePlayerAuraButton(button)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetHideTooltipInCombat(true)
    button:SetTooltipAnchorPoint("ANCHOR_RIGHT", 8, 0)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetIcon(icon)

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)
    button:SetDurationCooldown(cooldown)

    local duration = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    duration:SetPoint("BOTTOM", button, "BOTTOM", 0, 1)
    duration:SetJustifyH("CENTER")
    button:SetDurationText(duration, {
        textColor = {
            curve = remainingColorCurve,
            property = Enum.DurationTextBindingProperty.RemainingDuration,
        },
    })

    local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    count:SetJustifyH("RIGHT")
    button:SetApplicationCount(count)
end

EnsureAuraContainerLoaded()

local host = CreateFrame("Frame", "FuyutsuiCenterPlayerAuras", UIParent)
host:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
host:SetSize(1, 1)
host:SetFrameStrata("MEDIUM")
host:SetFrameLevel(50)

local container = CreateFrame(
    "AuraContainer",
    "FuyutsuiCenterPlayerAuraContainer",
    host,
    "CustomAuraContainerTemplate"
)
container:SetPoint("CENTER", host, "CENTER", 0, 0)
container:SetUnit("player")
container:SetEnabled(true)
container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
container:SetFlowLayoutAnchorPoint("TOPLEFT")
container:SetFlowLayoutGrowthDirection(
    AnchorUtil.FlowDirection.Right,
    AnchorUtil.FlowDirection.Down
)
container:SetFlowLayoutMaximumLineSize(ROW_WIDTH)

container:AddAuraGroup("playerBuffs", "HELPFUL", {
    initializeFrame = InitializePlayerAuraButton,
    sortMethod = AuraContainerSortMethod.Default,
    sortDirection = AuraContainerSortDirection.Normal,
    maxFrameCount = MAX_BUFFS,
    layout = {
        elementWidth = BUTTON_SIZE,
        elementHeight = BUTTON_SIZE,
        elementSpacing = BUTTON_SPACING,
        lineSpacing = BUTTON_SPACING,
    },
})

Fuyutsui.CenterPlayerAuraContainer = container
Fuyutsui.CenterPlayerAuraHost = host
