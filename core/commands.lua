local addon, ns = ...

local fuDelayEndTimer = nil

function Fuyutsui:GetCharConfig()
    return self.db and self.db.char
end

function Fuyutsui:NormalizeCharConfig()
    local c = self:GetCharConfig()
    if not c then return end
    c.aoeMode = c.aoeMode or 0
    c.cooldowns = c.cooldowns or 0
    c.dpsMode = c.dpsMode or 0
    c.delay = c.delay or 0
    c.potion = c.potion or 0
end

--- 通用角色开关：规范化、同步像素、刷新快捷按钮
function Fuyutsui:SwitchCharFlag(key, offMsg, onMsg, blockName)
    local c = self:GetCharConfig()
    if not c then return end
    if c[key] == 0 then
        print(offMsg)
    else
        print(onMsg)
    end
    if blockName and self.UpdateStateBlock then
        self:UpdateStateBlock("状态", blockName)
    end
    self:NormalizeCharConfig()
    if self.RefreshQuickToggleAppearance then
        self:RefreshQuickToggleAppearance()
    end
end

function Fuyutsui:SwitchCooldown()
    self:SwitchCharFlag(
        "cooldowns",
        "|cff00ff00[Fuyutsui]|r 爆发已|cffff0000关闭|r",
        "|cff00ff00[Fuyutsui]|r 爆发已|cff00ff00开启|r",
        "爆发开关"
    )
end

function Fuyutsui:SwitchAoeMode()
    self:SwitchCharFlag(
        "aoeMode",
        "|cff00ff00[Fuyutsui]|r 已切换|cff00ff00自动|r模式！",
        "|cff00ff00[Fuyutsui]|r 已切换|cff00ff00单体|r模式！",
        "AOE开关"
    )
end

function Fuyutsui:SwitchDpsMode()
    self:SwitchCharFlag(
        "dpsMode",
        "|cff00ff00[Fuyutsui]|r 输出模式已修改为|cff00ff00官方一键辅助|r",
        "|cff00ff00[Fuyutsui]|r 输出模式已修改为|cff00ff00手动编写逻辑|r",
        "输出模式"
    )
end

function Fuyutsui:SwitchPotion()
    self:SwitchCharFlag(
        "potion",
        "|cff00ff00[Fuyutsui]|r 药水已|cffff0000关闭|r",
        "|cff00ff00[Fuyutsui]|r 药水已|cff00ff00开启|r",
        "爆发药水开关"
    )
end

function Fuyutsui:SwitchDelay()
    local c = self:GetCharConfig()
    if not c then return end
    if self.UpdateStateBlock then
        self:UpdateStateBlock("状态", "延迟")
    end
    self:NormalizeCharConfig()
end

function Fuyutsui:SlashCommand(input, editbox)
    input = strtrim(input or "")
    local command = string.lower(input)

    local c = self:GetCharConfig()
    if command == "cd" then
        if not c then return end
        c.cooldowns = (c.cooldowns == 0) and 1 or 0
        self:SwitchCooldown()
    elseif command == "cd on" then
        if not c then return end
        c.cooldowns = 1
        self:SwitchCooldown()
    elseif command == "cd off" then
        if not c then return end
        c.cooldowns = 0
        self:SwitchCooldown()
    elseif command == "aoemode" then
        if not c then return end
        c.aoeMode = (c.aoeMode == 0) and 1 or 0
        self:SwitchAoeMode()
    elseif command == "aoemode auto" then
        if not c then return end
        c.aoeMode = 0
        self:SwitchAoeMode()
    elseif command == "aoemode aoe" then
        if not c then return end
        c.aoeMode = 1
        self:SwitchAoeMode()
    elseif command == "dpsmode" then
        if not c then return end
        c.dpsMode = (c.dpsMode == 0) and 1 or 0
        self:SwitchDpsMode()
    elseif command == "dpsmode manual" then
        if not c then return end
        c.dpsMode = 1
        self:SwitchDpsMode()
    elseif command == "dpsmode assistant" then
        if not c then return end
        c.dpsMode = 0
        self:SwitchDpsMode()
    elseif command == "potion" then
        if not c then return end
        c.potion = (c.potion == 0) and 1 or 0
        self:SwitchPotion()
    elseif command == "potion on" then
        if not c then return end
        c.potion = 1
        self:SwitchPotion()
    elseif command == "potion off" then
        if not c then return end
        c.potion = 0
        self:SwitchPotion()
    elseif command:match("^delay") then
        if not c then return end
        local secStr = command:match("^delay%s+(.+)$")
        local sec = 1
        if secStr then
            local trimmed = strtrim(secStr)
            if trimmed ~= "" then
                local parsed = tonumber(trimmed)
                if parsed and parsed > 0 then
                    sec = parsed
                else
                    print("|cff00ff00[Fuyutsui]|r 无效秒数；请输入正数（例如 /fu delay 5），或不写秒数使用默认 1 秒。")
                    return
                end
            end
        end
        local delayAlreadyActive = fuDelayEndTimer ~= nil
        if fuDelayEndTimer then
            fuDelayEndTimer:Cancel()
            fuDelayEndTimer = nil
        end
        c.delay = 1
        self:SwitchDelay()
        fuDelayEndTimer = C_Timer.NewTimer(sec, function()
            fuDelayEndTimer = nil
            local cc = Fuyutsui:GetCharConfig()
            if cc then
                cc.delay = 0
                print("延迟已恢复。")
                Fuyutsui:SwitchDelay()
            end
        end)
        if not delayAlreadyActive then
            print("延迟已生效，" .. sec .. " 秒后恢复。")
        end
    elseif command == "help" or command == "" then
        print("|cff00ff00Fuyutsui|r 命令列表:")
        print("爆发开关: /fu cd")
        print("|cff00ff00开启|r爆发: /fu cd on")
        print("|cffff0000关闭|r爆发: /fu cd off")
        print("切换AOE模式: /fu aoemode")
        print("切换AOE为|cff00ff00自动|r: /fu aoemode auto")
        print("切换AOE为|cff00ff00单体|r: /fu aoemode aoe")
        print("切换输出模式: /fu dpsmode")
        print("切换输出模式为|cff00ff00手写逻辑|r: /fu dpsmode manual")
        print("切换输出模式为|cff00ff00一键辅助|r: /fu dpsmode assistant")
        print("爆发药水开关: /fu potion")
        print("|cff00ff00开启|r药水: /fu potion on")
        print("|cffff0000关闭|r药水: /fu potion off")
        print("临时 delay 标志（db.char.delay 置 1 持续 x 秒后归零）: /fu delay [秒]，省略秒数则为 1 秒")
        print("帮助: /fu help")
    else
        print("输入 /fu help 查看命令。")
    end
end
