local addon, ns = ...

local rc = LibStub("LibRangeCheck-3.0")

local state = Fuyutsui.state
local target = Fuyutsui.target
local nameplate = Fuyutsui.nameplate

function Fuyutsui:GetUnitRange(unit)
    local minRange, maxRange = rc:GetRange(unit)
    return minRange, maxRange
end

local function GetTargetDispelType()
    if not UnitExists("target") then return 0 end
    if target.canAttack then
        return 1 / 255
    elseif target.canAssist then
        return 11 / 255
    end
    return 0
end

function Fuyutsui:UpdateTargetType()
    local targetType = 0
    if not target.isDead then
        targetType = GetTargetDispelType()
    end
    target.type = targetType
    self:UpdateStateBlock("目标", "类型")
end

function Fuyutsui:UpdateTargetCanAttack()
    target.canAttack = UnitCanAttack("player", "target")
    target.canAssist = UnitCanAssist("player", "target")
    self:UpdateTargetType()
end

function Fuyutsui:UpdateTargetRangeBlock()
    local minRange, maxRange = self:GetUnitRange("target")
    target.minRange = minRange
    target.maxRange = maxRange
    if target.canAttack then
        if target.maxRange and self.state.specRange then
            target.inRange = target.maxRange <= self.state.specRange
            self:UpdateTargetType()
        end
    elseif target.canAssist then
        if target.maxRange then
            target.inRange = target.maxRange <= 40
            self:UpdateTargetType()
        end
    end
    self:UpdateStateBlock("目标", "距离")
end

local unitZHMap = {
    ["target"] = "目标",
    ["focus"] = "焦点",
    ["boss1"] = "首领1",
    ["boss2"] = "首领2",
    ["boss3"] = "首领3",
    ["boss4"] = "首领4",
    ["boss5"] = "首领5",
}

function Fuyutsui:UpdateUnitCastingOrChannelingInfo(unit)
    if not UnitExists(unit) then return end
    local obj = unitZHMap[unit]
    if not obj then return end

    self:UpdateStateBlock(obj, "施法")
    self:UpdateStateBlock(obj, "施法可打断")
    self:UpdateStateBlock(obj, "引导")
    self:UpdateStateBlock(obj, "引导可打断")
end

function Fuyutsui:UpdateTargetDeath()
    target.isDead = UnitIsDeadOrGhost("target")
    self:UpdateTargetType()
end

function Fuyutsui:UpdateTargetHealth()
    local healthPercent = UnitHealthPercent("target", false, self.curve100)
    ---@diagnostic disable-next-line: param-type-mismatch
    local _, _, b = healthPercent:GetRGB()
    target.healthPercent = b or 0
    self:UpdateStateBlock("目标", "生命值")
end

function Fuyutsui:UpdateTargetFullInfo()
    self:UpdateTargetCanAttack()
    self:UpdateTargetDeath()
    self:UpdateTargetHealth()
end

function Fuyutsui:AddNameplate(unit)
    local minRange, maxRange = self:GetUnitRange(unit)
    nameplate[unit] = {
        name = GetUnitName(unit, true),
        GUID = UnitGUID(unit),
        canAttack = UnitCanAttack("player", unit),
        canAssist = UnitCanAssist("player", unit),
        minRange = minRange,
        maxRange = maxRange,
        affectingCombat = UnitAffectingCombat(unit),
    }
end

local testMap = {
    [2393] = true,
}
local testEncounter = {
    [2563] = true,
}

function Fuyutsui:UpdateEnemyCount()
    local count = 0
    local inTestMap = state.mapID and testMap[state.mapID]
    local inTestEncounter = state.encounterID and testEncounter[state.encounterID]
    for unit, data in pairs(nameplate) do
        local minRange, maxRange = self:GetUnitRange(unit)
        data.minRange = minRange
        data.maxRange = maxRange
        data.affectingCombat = UnitAffectingCombat(unit)
        if data.canAttack and data.maxRange and data.maxRange <= self.state.specRange
            and (data.affectingCombat or inTestMap or inTestEncounter) then
            count = count + 1
        end
    end
    state.enemyCount = count / 255 or 0
    self:UpdateStateBlock("状态", "敌人人数")
end
