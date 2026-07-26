local addon, ns = ...

function Fuyutsui:UpdatePlayerBlocks()
    self.isInitialized = false
    self.state.isDead = UnitIsDeadOrGhost("player")
    self.state.isChatOpen = false
    self.state.drinkStatus = false
    self:UpdatePlayerMounted()
    self:UpdatePlayerCombat()
    self:UpdatePlayerMoving(IsPlayerMoving())
    self:UpdatePlayerCastBlocks()
    self:UpdatePlayerHealth()
    self:UpdatePlayerPowerType()
    self:UpdatePlayerAssistant()
    self:UpdateTargetType()
    self:UpdateGroupType()
    self:UpdateGroupCount()
    self:UpdateHeroTalent()
    self:UpdatePlayerBarInfo()
    self:UpdateShapeshiftForm()
    self:UpdatePlayerStagger()
    self:UpdateRune()
    self:UpdateTargetRangeBlock()
    self:UpdateTargetHealth()
    self:UpdateEnemyCount()
    self:UpdateGroup()
    self:GetItemCount()
    C_Timer.After(1, function()
        self:UpdatePlayerConfig()
        self.isInitialized = true
    end)
end

-- 载入玩家 blocks 配置
function Fuyutsui:LoadPlayerBlocks(specIndex)
    if not specIndex or not self.ClassBlocks then
        return
    end
    local t = self.ClassBlocks[specIndex]
    if not t then return end
    local blocks = {
        state = {},
        auras = {},
        spells = {},
        bars = {},
    }

    local index = 1

    -- states 支持分类表：{ ["状态"]={...}, ["目标"]={...}, ["焦点"]={...} }
    -- blocks.state 键：状态用名称本身；目标/焦点用 分类..名称（如 目标+生命值 -> 目标生命值）
    if type(t.states) == "table" then
        local stateCategoryOrder = { "状态", "目标", "焦点" }
        local nested = t.states["状态"] or t.states["目标"] or t.states["焦点"]
        if nested then
            for _, category in ipairs(stateCategoryOrder) do
                local list = t.states[category]
                if type(list) == "table" then
                    for _, name in ipairs(list) do
                        if name then
                            local key = (category == "状态") and name or (category .. name)
                            blocks.state[key] = index
                            index = index + 1
                        end
                    end
                end
            end
        else
            for _, name in ipairs(t.states) do
                if name then
                    blocks.state[name] = index
                    index = index + 1
                end
            end
        end
    end

    -- auras 支持：
    --   旧：{ { spellId=... }, ... }  → 视为 player / HELPFUL
    --   新：{ player={...}, target={ harmful={...}, helpful={...} }, focus={...} }
    if type(t.auras) == "table" then
        local function AppendAuraList(list, unit, filter)
            if type(list) ~= "table" then return end
            for _, aura in ipairs(list) do
                if type(aura) == "table" and (aura.spellId or aura.spellIds) then
                    blocks.auras[index] = {
                        name = aura.name,
                        spellId = aura.spellId,
                        spellIds = aura.spellIds,
                        maxApps = aura.maxApps,
                        unit = unit,
                        filter = filter,
                    }
                    index = index + 1
                else
                    print("LoadPlayerBlocks: aura 缺少 spellId/spellIds，已跳过")
                end
            end
        end

        local nested = t.auras.player or t.auras.target or t.auras.focus
        if nested then
            AppendAuraList(t.auras.player, "player", "HELPFUL")
            if type(t.auras.target) == "table" then
                AppendAuraList(t.auras.target.harmful, "target", "HARMFUL")
                AppendAuraList(t.auras.target.helpful, "target", "HELPFUL")
            end
            if type(t.auras.focus) == "table" then
                AppendAuraList(t.auras.focus.harmful, "focus", "HARMFUL")
                AppendAuraList(t.auras.focus.helpful, "focus", "HELPFUL")
            end
        else
            AppendAuraList(t.auras, "player", "HELPFUL")
        end
    end

    if type(t.spells) == "table" then
        for _, spell in ipairs(t.spells) do
            if type(spell) ~= "table" or not spell.spellId then
                print("LoadPlayerBlocks: spell 缺少 spellId，已跳过")
            else
                local spellId = spell.spellId
                if not blocks.spells[spellId] then
                    blocks.spells[spellId] = {}
                end
                if spell.charge then
                    blocks.spells[spellId].charge = index
                else
                    blocks.spells[spellId].index = index
                end
                if spell.forcedKnown then
                    blocks.spells[spellId].forcedKnown = spell.forcedKnown
                end
                if spell.inSpellBook then
                    blocks.spells[spellId].inSpellBook = spell.inSpellBook
                end
                if spell.charge and type(spell.maxCharge) == "number" then
                    tinsert(blocks.bars, {
                        valueType = "charge",
                        minValue = 0,
                        maxValue = spell.maxCharge,
                        spellId = spellId,
                    })
                end
                if type(spell.castCount) == "number" and spell.castCount > 0 then
                    tinsert(blocks.bars, {
                        valueType = "castCount",
                        minValue = 0,
                        maxValue = spell.castCount,
                        spellId = spellId,
                    })
                end
                index = index + 1
            end
        end
    end

    if type(t.group) == "table" then
        blocks.groups = {
            start = index,
            num = t.group.num,
            healthPercent = t.group.healthPercent,
            role = t.group.role,
            dispel = t.group.dispel,
            -- 成员光环偏移：pixel = start + (memberIndex-1)*num + offset
            aura = t.group.aura,
        }
    end

    self.blocks = blocks
    if self.ReleaseUnitAuraContainers then
        self:ReleaseUnitAuraContainers()
    elseif self.ReleasePlayerAuraContainers then
        self:ReleasePlayerAuraContainers()
    end
    if self.ReleaseGroupAuraContainers then
        self:ReleaseGroupAuraContainers()
    end
end

-- 载入玩家宏（按当前职业从 ClassMacros 选取）
function Fuyutsui:LoadPlayerMacros()
    local classFile = UnitClassBase("player")
    local m = self.ClassMacros and self.ClassMacros[classFile]
    if not m then
        return
    end
    self.MacrosList = m
    self:CreateMacro(m.dynamicSpells, m.staticSpells, m.specialSpells)
end
