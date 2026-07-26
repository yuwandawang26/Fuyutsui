local addon, ns = ...

local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean

local state = Fuyutsui.state
local target = Fuyutsui.target

local ColorValue0 = CreateColor(0, 0, 0, 1)
local ColorValue1 = CreateColor(0, 0, 1 / 255, 1)

Fuyutsui.powerNameMap = {
    ["MANA"] = "法力值",
    ["RAGE"] = "怒气值",
    ["FOCUS"] = "集中值",
    ["ENERGY"] = "能量值",
    ["RUNES"] = "符文",
    ["RUNIC_POWER"] = "符文能量",
    ["LUNAR_POWER"] = "星界能量",
    ["MAELSTROM"] = "漩涡值",
    ["INSANITY"] = "狂乱值",
    ["ARCANE_CHARGES"] = "奥术充能",
    ["FURY"] = "恶魔之怒",
    ["PAIN"] = "痛苦值",
    ["COMBO_POINTS"] = "连击点",
    ["HOLY_POWER"] = "神圣能量",
    ["ESSENCE"] = "精华能量",
    ["SOUL_SHARDS"] = "灵魂碎片",
    ["CHI"] = "真气",
}

local function GetItemCooldownPixel(self, countKey, itemID)
    if not self.state[countKey] then
        self:GetItemCount()
    end
    local remainingTime = self:GetItemRemainingTime(itemID)
    if remainingTime and self.state[countKey] > 0 then
        return math.min(1, remainingTime / 255)
    end
    return 1
end

--- mode: "cast" | "channel"
function Fuyutsui:GetUnitCastPixel(unit, mode)
    local castCurve = self.castCurve
    if mode == "channel" then
        local channel = UnitChannelDuration(unit)
        if not channel then return 0 end
        local _, _, _, _, _, _, _, _, _, _, castBarID = UnitChannelInfo(unit)
        if not castBarID then return nil end
        local channelDurationColor = channel:EvaluateRemainingDuration(castCurve)
        ---@diagnostic disable-next-line: param-type-mismatch
        local _, _, b = channelDurationColor:GetRGB()
        return b
    end

    local cast = UnitCastingDuration(unit)
    if not cast then return 0 end
    local castingDurationColor = cast:EvaluateRemainingDuration(castCurve)
    ---@diagnostic disable-next-line: param-type-mismatch
    local _, _, b = castingDurationColor:GetRGB()
    return b
end

--- mode: "cast" | "channel"
function Fuyutsui:GetUnitInterruptiblePixel(unit, mode)
    if mode == "channel" then
        local channel = UnitChannelDuration(unit)
        if not channel then return 0 end
        local _, _, _, _, _, _, notInterruptible, _, _, _, castBarID = UnitChannelInfo(unit)
        if not castBarID then return nil end
        local interruptibleColor = EvaluateColorFromBoolean(notInterruptible, ColorValue0, ColorValue1)
        local _, _, interruptible = interruptibleColor:GetRGB()
        return interruptible
    end

    if not UnitCastingDuration(unit) then return 0 end
    local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    local interruptibleColor = EvaluateColorFromBoolean(notInterruptible, ColorValue0, ColorValue1)
    local _, _, interruptible = interruptibleColor:GetRGB()
    return interruptible
end

-- stateBlockGetters[分类][名称]
-- blocks.state 键：分类为"状态"时用名称本身；否则用 分类..名称（如 目标+生命值 -> 目标生命值）
local stateBlockGetters = {
    ["状态"] = {
        ["职业"] = function(self) return self.state.classId / 255 end,
        ["专精"] = function(self) return self.state.specIndex / 255 end,
        ["有效性"] = function() return state.valid or 0 end,
        ["战斗时间"] = function() return state.combatTime or 0 end,
        ["移动"] = function() return state.moving or 0 end,
        ["生命值"] = function() return state.healthPercent or 0 end,
        ["一键辅助"] = function() return state.assistantSpell or 0 end,
        ["法术失败"] = function() return state.failedSpell or 0 end,
        ["队伍类型"] = function() return state.groupType or 0 end,
        ["队伍人数"] = function() return state.groupCount or 0 end,
        ["首领战"] = function() return state.bossID or 0 end,
        ["难度"] = function() return (state.difficultyID or 0) / 255 end,
        ["英雄天赋"] = function(self) return (self.state.heroTalent or 0) / 255 end,
        ["施法目标"] = function() return state.castTargetIndex or 0 end,
        ["施法技能"] = function() return state.castingSpell or 0 end,
        ["敌人人数"] = function() return state.enemyCount or 0 end,
        ["酒池"] = function() return state.staggerPercent or 0 end,
        ["符文"] = function()
            if state.runeCount ~= nil then return state.runeCount end
            return (state.power and state.power["RUNES"]) or 0
        end,
        ["姿态"] = function() return state.shapeshiftFormID or 0 end,
        ["疾病判断"] = function() return state.diseaseJudge or 0 end,
        ["天启骑士数量"] = function() return state.knightCount or 0 end,

        ["爆发开关"] = function(self)
            local c = self.db and self.db.char
            return c and (c.cooldowns / 255) or 0
        end,
        ["AOE开关"] = function(self)
            local c = self.db and self.db.char
            return c and (c.aoeMode / 255) or 0
        end,
        ["输出模式"] = function(self)
            local c = self.db and self.db.char
            return c and (c.dpsMode / 255) or 0
        end,
        ["爆发药水开关"] = function(self)
            local c = self.db and self.db.char
            return c and (c.potion / 255) or 0
        end,
        ["延迟"] = function(self)
            local c = self.db and self.db.char
            return c and (c.delay / 255) or 0
        end,

        ["大红冷却"] = function(self) return GetItemCooldownPixel(self, "HealthPotionCount", 241304) end,
        ["大蓝冷却"] = function(self) return GetItemCooldownPixel(self, "ManaPotionCount", 241301) end,
        ["治疗石冷却"] = function(self) return GetItemCooldownPixel(self, "HealthstoneCount", 5512) end,
        ["鲁莽药水冷却"] = function(self) return GetItemCooldownPixel(self, "RecklessnessCount", 241288) end,
        ["圣光潜力冷却"] = function(self) return GetItemCooldownPixel(self, "LightsPotentialCount", 241308) end,

        ["施法"] = function(self)
            if not state.casting then
                state.castingDuration = 0
                return 0
            end
            local cast = UnitCastingDuration("player")
            if cast then
                local castingDurationColor = cast:EvaluateElapsedDuration(self.castCurve)
                ---@diagnostic disable-next-line: param-type-mismatch
                local _, _, b = castingDurationColor:GetRGB()
                state.castingDuration = b
                return b
            end
            state.castingDuration = 0
            return 0
        end,
        ["引导"] = function(self)
            if not state.channeling then
                state.channelingDuration = 0
                return 0
            end
            local channel = UnitChannelDuration("player")
            if channel then
                local channelDurationColor = channel:EvaluateRemainingDuration(self.castCurve)
                ---@diagnostic disable-next-line: param-type-mismatch
                local _, _, b = channelDurationColor:GetRGB()
                state.channelingDuration = b
                return b
            end
            state.channelingDuration = 0
            return 0
        end,
        ["蓄力"] = function(self)
            if not state.empowering then
                state.empowerDuration = 0
                return 0
            end
            local empowerDuration = UnitEmpoweredChannelDuration("player")
            if empowerDuration then
                local empowerDurationColor = empowerDuration:EvaluateRemainingDuration(self.castCurve)
                ---@diagnostic disable-next-line: param-type-mismatch
                local _, _, b = empowerDurationColor:GetRGB()
                state.empowerDuration = b
                return b
            end
            return state.empowerDuration or 0
        end,
        ["蓄力层数"] = function(self)
            if not state.empowering then
                state.empowerStage = 0
                return 0
            end
            local empowerStages = UnitEmpoweredStageDurations("player")
            if empowerStages then
                for k, v in pairs(empowerStages) do
                    local empower = v:EvaluateRemainingDuration(self.castCurve)
                    ---@diagnostic disable-next-line: param-type-mismatch
                    local _, _, b = empower:GetRGB()
                    state.empowerStage = (k - 1) / 255
                    if b > 0 then
                        break
                    end
                end
                return state.empowerStage or 0
            end
            return state.empowerStage or 0
        end,
    },
    ["目标"] = {
        ["类型"] = function() return target.type or 0 end,
        ["生命值"] = function() return target.healthPercent or 0 end,
        ["距离"] = function()
            if not target.maxRange then return nil end
            return target.maxRange / 255
        end,
        ["施法"] = function(self) return self:GetUnitCastPixel("target", "cast") end,
        ["施法可打断"] = function(self) return self:GetUnitInterruptiblePixel("target", "cast") end,
        ["引导"] = function(self) return self:GetUnitCastPixel("target", "channel") end,
        ["引导可打断"] = function(self) return self:GetUnitInterruptiblePixel("target", "channel") end,
    },
    ["焦点"] = {
        ["施法"] = function(self) return self:GetUnitCastPixel("focus", "cast") end,
        ["施法可打断"] = function(self) return self:GetUnitInterruptiblePixel("focus", "cast") end,
        ["引导"] = function(self) return self:GetUnitCastPixel("focus", "channel") end,
        ["引导可打断"] = function(self) return self:GetUnitInterruptiblePixel("focus", "channel") end,
    },
}

for powerType, powerName in pairs(Fuyutsui.powerNameMap) do
    if powerName ~= "符文" and not stateBlockGetters["状态"][powerName] then
        local pt = powerType
        stateBlockGetters["状态"][powerName] = function()
            return (state.power and state.power[pt]) or 0
        end
    end
end

-- UpdateStateBlock("状态", "职业") / UpdateStateBlock("目标", "生命值")
function Fuyutsui:UpdateStateBlock(category, name)
    local cat = stateBlockGetters[category]
    if not cat then return end
    local getter = cat[name]
    if not getter then return end
    local key = (category == "状态") and name or (category .. name)
    local b = self.blocks
    local index = b and b.state and b.state[key]
    if not index then return end
    local value = getter(self)
    if value ~= nil then
        self:CreateTexture(index, value)
    end
end
