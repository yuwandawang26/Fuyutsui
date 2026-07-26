local addon, ns = ...

local IsSpellKnown = C_SpellBook.IsSpellKnown
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook

local state = Fuyutsui.state
local EnumPowerType = Fuyutsui.EnumPowerType
local spellsList = Fuyutsui.spellsList

local diseaseJudgeTimer = nil
local drinkStatusTimer = nil

function Fuyutsui:GetCharacterInfo()
    self.db.char.level = UnitLevel("player")
    self.state.name = UnitName("player")
    self.state.GUID = UnitGUID("player")
    self.state.classColor = RAID_CLASS_COLORS[self.state.classFilename].colorStr
end

function Fuyutsui:GetCharacterSpecInfo()
    self.state.specIndex = C_SpecializationInfo.GetSpecialization()
    local specID, specName, _, _, role = C_SpecializationInfo.GetSpecializationInfo(self.state.specIndex)
    self.state.specID = specID
    self.state.specName = specName
    self.state.specRole = role
    self.state.specRange = self.rangeSpecID[specID]
    self.state.isDead = UnitIsDeadOrGhost("player")
    self.state.isChatOpen = false
    self.state.casting = false
    self.state.channeling = false
    self:LoadPlayerBlocks(self.state.specIndex)
    self:UpdateSpellKnown()
    self:UpdatePlayerMounted()
    self:UpdateGroup()
    self:LoadPlayerMacros()
    self:GetItemCount()
    self:UpdateStateBlock("状态", "职业")
    self:UpdateStateBlock("状态", "专精")
end

function Fuyutsui:UpdatePlayerSpecInfo()
    self:ClearAllTextures()
    self.state.specIndex = C_SpecializationInfo.GetSpecialization()
    local specID, specName, _, _, role = C_SpecializationInfo.GetSpecializationInfo(self.state.specIndex)
    self.state.specID = specID
    self.state.specName = specName
    self.state.specRole = role
    self.state.specRange = self.rangeSpecID[specID]
    self:LoadPlayerBlocks(self.state.specIndex)
    self:UpdateSpellKnown()
    self:UpdatePlayerBlocks()
    self:UpdateStateBlock("状态", "职业")
    self:UpdateStateBlock("状态", "专精")
end

function Fuyutsui:UpdatePlayerValid()
    local valid = not state.isDead and not state.mounted and not state.isChatOpen and not state.drinkStatus
    state.valid = valid and 1 / 255 or 0
    self:UpdateStateBlock("状态", "有效性")
end

function Fuyutsui:UpdatePlayerCombat()
    state.combat = UnitAffectingCombat("player")
end

function Fuyutsui:UpdatePlayerCombatTime()
    if state.combat then
        local combatTime = GetTime() - state.combatStartTime
        state.combatTime = math.min(1, combatTime / 255)
    else
        state.combatTime = 0
    end
    self:UpdateStateBlock("状态", "战斗时间")
end

function Fuyutsui:UpdatePlayerMoving(boolean)
    state.drinkStatus = false
    self:UpdatePlayerValid()
    state.moving = boolean and 1 / 255 or 0
    self:UpdateStateBlock("状态", "移动")
end

function Fuyutsui:UpdatePlayerCastBlocks()
    self:UpdateStateBlock("状态", "施法")
    self:UpdateStateBlock("状态", "引导")
    self:UpdateStateBlock("状态", "蓄力")
    self:UpdateStateBlock("状态", "蓄力层数")
end

function Fuyutsui:UpdatePlayerCastingInfo()
    self:UpdateStateBlock("状态", "施法")
end

function Fuyutsui:UpdatePlayerChannelingInfo()
    self:UpdateStateBlock("状态", "引导")
end

function Fuyutsui:UpdatePlayerEmpowerInfo()
    self:UpdateStateBlock("状态", "蓄力")
    self:UpdateStateBlock("状态", "蓄力层数")
end

function Fuyutsui:UpdatePlayerHealth()
    local healthPercent = UnitHealthPercent("player", false, self.curve100)
    ---@diagnostic disable-next-line: param-type-mismatch
    local _, _, b = healthPercent:GetRGB()
    state.healthPercent = b
    self:UpdateStateBlock("状态", "生命值")
end

function Fuyutsui:UpdatePlayerPower(powerType)
    local blocks = self.blocks
    if not blocks then return end
    local powerName = self.powerNameMap[powerType]
    if not powerName then return end
    if not self.powerCurves[powerType] then self:CreatePowerCurve(powerType) end
    local powerPercent = UnitPowerPercent("player", EnumPowerType[powerType], nil, self.powerCurves[powerType])
    ---@diagnostic disable-next-line: param-type-mismatch
    local _, _, b = powerPercent:GetRGB()
    state.power[powerType] = b
    self:UpdateStateBlock("状态", powerName)
end

function Fuyutsui:UpdatePlayerPowerType()
    state.power = {}
    for powerType in pairs(EnumPowerType) do
        self:CreatePowerCurve(powerType)
        self:UpdatePlayerPower(powerType)
    end
end

function Fuyutsui:UpdatePlayerAssistant()
    local spellId = C_AssistedCombat.GetNextCastSpell()
    local spellIndex = spellsList[spellId] and spellsList[spellId].index or 0
    state.assistantSpell = spellIndex / 255 or 0
    self:UpdateStateBlock("状态", "一键辅助")
end

function Fuyutsui:UpdateGroupType()
    local index = 0
    if UnitInRaid("player") then
        index = UnitInRaid("player") or 0
    elseif UnitInParty("player") then
        index = 46
    end
    state.groupType = index / 255 or 0
    self:UpdateStateBlock("状态", "队伍类型")
end

function Fuyutsui:UpdateGroupCount()
    local count = GetNumGroupMembers()
    state.groupCount = count / 255 or 0
    self:UpdateStateBlock("状态", "队伍人数")
end

function Fuyutsui:UpdateEncounterID(encounterID, difficultyID)
    state.encounterID = encounterID
    local id = self.bossID and self.bossID[encounterID] or 0
    if id then
        state.bossID = id / 255 or 0
    else
        state.bossID = 0
    end
    self:UpdateStateBlock("状态", "首领战")
    state.difficultyID = difficultyID
    self:UpdateStateBlock("状态", "难度")
end

function Fuyutsui:UpdateHeroTalent()
    if self.heroTalents then
        C_Timer.After(1, function()
            self.state.heroTalent = 0
            for spellID, index in pairs(self.heroTalents) do
                if IsSpellKnown(spellID) or IsSpellInSpellBook(spellID) then
                    self.state.heroTalent = index
                    break
                end
            end
            self:UpdateStateBlock("状态", "英雄天赋")
        end)
    end
end

function Fuyutsui:UpdatePlayerBarInfo()
    local blocks = self.blocks
    if self.RefreshPlayerAuraContainers then
        self:RefreshPlayerAuraContainers()
    end
    if blocks and blocks.bars then
        for _, v in ipairs(blocks.bars) do
            self:CreateAutoLayoutBar(v.valueType, v.minValue, v.maxValue, v.spellId)
        end
    end
    if self.LayoutAuraApplicationBars then
        self:LayoutAuraApplicationBars()
    end
end

function Fuyutsui:UpdatePlayerMounted()
    state.mounted = IsMounted() or state.shapeshiftFormID == 27 or state.shapeshiftFormID == 3 or
        state.shapeshiftFormID == 29
    self:UpdatePlayerValid()
end

function Fuyutsui:UpdatePlayerCasting(spellId)
    local castingSpell = spellsList[spellId] and spellsList[spellId].index or 0
    state.castingSpell = castingSpell / 255 or 0
    self:UpdateStateBlock("状态", "施法目标")
    self:UpdateStateBlock("状态", "施法技能")
end

function Fuyutsui:UpdatePlayerConfig()
    if not (self.db and self.db.char) then return end
    self:UpdateStateBlock("状态", "爆发开关")
    self:UpdateStateBlock("状态", "AOE开关")
    self:UpdateStateBlock("状态", "输出模式")
    self:UpdateStateBlock("状态", "爆发药水开关")
end

function Fuyutsui:UpdatePlayerStagger()
    local unit = "player"
    local damage = UnitStagger(unit)
    local maxHealth = UnitHealthMax(unit)
    local staggerPercent = damage / maxHealth * 100
    state.staggerPercent = staggerPercent / 255 or 0
    self:UpdateStateBlock("状态", "酒池")
end

function Fuyutsui:UpdateRune()
    local total = 0
    for i = 1, 6 do
        local runeCount = GetRuneCount(i)
        if runeCount then
            total = total + runeCount
        end
    end
    state.runeCount = total / 255 or 0
    self:UpdateStateBlock("状态", "符文")
end

function Fuyutsui:UpdateShapeshiftForm()
    local shapeshiftFormID = GetShapeshiftFormID() or 0
    state.shapeshiftFormID = shapeshiftFormID / 255
    self:UpdateStateBlock("状态", "姿态")
end

function Fuyutsui:UpdateDiseaseJudge()
    local b = self.blocks
    if not (b and b.state and b.state["疾病判断"]) then return end
    state.diseaseJudge = 1 / 255 or 0
    self:UpdateStateBlock("状态", "疾病判断")
    if diseaseJudgeTimer then
        diseaseJudgeTimer:Cancel()
        diseaseJudgeTimer = nil
    end
    diseaseJudgeTimer = C_Timer.NewTimer(1, function()
        state.diseaseJudge = 0
        self:UpdateStateBlock("状态", "疾病判断")
        diseaseJudgeTimer = nil
    end)
end

function Fuyutsui:UpdateDrinkStatus(spellID)
    local name = C_Spell.GetSpellName(spellID)
    if name == "饮水" or name == "进食饮水" then
        state.drinkStatus = true
        self:UpdatePlayerValid()
        if drinkStatusTimer then
            drinkStatusTimer:Cancel()
            drinkStatusTimer = nil
        end
        drinkStatusTimer = C_Timer.NewTimer(20, function()
            state.drinkStatus = false
            self:UpdatePlayerValid()
            drinkStatusTimer = nil
        end)
    else
        if drinkStatusTimer then
            drinkStatusTimer:Cancel()
            drinkStatusTimer = nil
        end
        state.drinkStatus = false
        self:UpdatePlayerValid()
    end
end

-- 死亡骑士天启骑士检测
local ActiveKnightSpells = {
    [454393] = 1,
    [454389] = 2,
    [454392] = 3,
    [454390] = 4,
}
local InactiveKnightSpells = {
    [444248] = 1,
    [444251] = 2,
    [444252] = 3,
    [444254] = 4,
}
local ActiveKnights = { false, false, false, false }

function Fuyutsui:UpdateKnightStatus(spellID)
    if ActiveKnightSpells[spellID] then
        ActiveKnights[ActiveKnightSpells[spellID]] = true
    end
    if InactiveKnightSpells[spellID] then
        ActiveKnights[InactiveKnightSpells[spellID]] = false
    end
end

local function GetActiveKnightsCount()
    local count = 0
    for i = 1, 4 do
        if ActiveKnights[i] then
            count = count + 1
        end
    end
    return count
end

function Fuyutsui:UpdateKnightStatusCount()
    state.knightCount = GetActiveKnightsCount() / 255
    self:UpdateStateBlock("状态", "天启骑士数量")
end

function Fuyutsui:HookChatFrameEditBox()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:HookScript("OnEditFocusGained", function()
                state.isChatOpen = true
                self:UpdatePlayerValid()
            end)
            editBox:HookScript("OnEditFocusLost", function()
                state.isChatOpen = false
                self:UpdatePlayerValid()
            end)
        end
    end
end
