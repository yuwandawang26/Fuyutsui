local addon, ns = ...
local className, classFilename, classId = UnitClass("player")

Fuyutsui = Fuyutsui or {}

local eventFrame = CreateFrame("Frame", "FuyutsuiEventFrame")

--- 与 AceEvent 一致：回调为 addon[event](addon, event, ...)
function Fuyutsui:RegisterEvent(event)
    eventFrame:RegisterEvent(event)
end

function Fuyutsui:UnregisterEvent(event)
    eventFrame:UnregisterEvent(event)
end

function Fuyutsui:UnregisterAllEvents()
    eventFrame:UnregisterAllEvents()
end

local function CopyDefaults(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function GetCharKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Unknown"
    return name .. " - " .. realm
end

--- 兼容原 AceDB-3.0 的 FuyutsuiADB 布局（char / profiles / profileKeys）
local function InitDB()
    if type(FuyutsuiADB) ~= "table" then
        FuyutsuiADB = {}
    end
    local sv = FuyutsuiADB
    sv.char = sv.char or {}
    sv.profiles = sv.profiles or {}
    sv.profileKeys = sv.profileKeys or {}

    local charKey = GetCharKey()
    if type(sv.char[charKey]) ~= "table" then
        sv.char[charKey] = {}
    end
    local char = sv.char[charKey]
    CopyDefaults(char, Fuyutsui.defaults.char)

    local profileName = sv.profileKeys[charKey] or "Default"
    sv.profileKeys[charKey] = profileName
    if type(sv.profiles[profileName]) ~= "table" then
        sv.profiles[profileName] = {}
    end
    local profile = sv.profiles[profileName]
    CopyDefaults(profile, Fuyutsui.defaults.profile)

    Fuyutsui.db = {
        char = char,
        profile = profile,
    }
end

function Fuyutsui:OnInitialize()
    InitDB()

    SLASH_FUYUTSUI1 = "/fu"
    SLASH_FUYUTSUI2 = "/fuyutsui"
    SlashCmdList["FUYUTSUI"] = function(msg, editbox)
        Fuyutsui:SlashCommand(msg, editbox)
    end

    self:GetCharacterInfo()
end

function Fuyutsui:OnEnable()
    self:GetCharacterSpecInfo()
    self:updateSpellKnown()
    self:updatePlayerBlocks()
    self:readKeybindings()
    self:hookChatFrameEditBox()

    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("PLAYER_DEAD")
    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterEvent("PLAYER_UNGHOST")
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_STARTED_MOVING")
    self:RegisterEvent("PLAYER_STOPPED_MOVING")
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
    self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH")
    self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
    self:RegisterEvent("UNIT_HEAL_PREDICTION")
    self:RegisterEvent("SPELL_UPDATE_USES")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_DIED")
    self:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
    self:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    self:RegisterEvent("UI_ERROR_MESSAGE")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    self:RegisterEvent("ENCOUNTER_START")
    self:RegisterEvent("ENCOUNTER_END")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self:RegisterEvent("SPELL_UPDATE_ICON")
    self:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_SHOW")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_HIDE")
    self:RegisterEvent("UPDATE_BINDINGS")
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("SPELL_UPDATE_CHARGES")
    self:RegisterEvent("ITEM_COUNT_CHANGED")
    self:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    self:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
    self:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED")
    self:RegisterEvent("UNIT_AURA")
    if self.StartFrameUpdates then
        self:StartFrameUpdates()
    end
    if self.InitQuickToggleButton then
        self:InitQuickToggleButton()
    end
    self.Initialize = true
end

local function CharCfg()
    return Fuyutsui.db and Fuyutsui.db.char
end

local fuDelayEndTimer = nil

local function SaveConfig()
    local c = CharCfg()
    if not c then return end
    c.aoeMode = c.aoeMode or 0
    c.cooldowns = c.cooldowns or 0
    c.dpsMode = c.dpsMode or 0
    c.delay = c.delay or 0
    c.potion = c.potion or 0
end

--- 与斜杠一致：print、同步顶部像素、规范化 db.char
function Fuyutsui:SwitchCooldown()
    local c = self.db and self.db.char
    if not c then return end
    if c.cooldowns == 0 then
        print("|cff00ff00[Fuyutsui]|r 爆发已|cffff0000关闭|r")
    else
        print("|cff00ff00[Fuyutsui]|r 爆发已|cff00ff00开启|r")
    end
    local st = self.blocks and self.blocks.state
    if st and st["爆发开关"] then
        self:CreatTexture(st["爆发开关"], c.cooldowns / 255 or 0)
    end
    SaveConfig()
    if self.RefreshQuickToggleAppearance then
        self:RefreshQuickToggleAppearance()
    end
end

function Fuyutsui:SwitchAoeMode()
    local c = self.db and self.db.char
    if not c then return end
    if c.aoeMode == 0 then
        print("|cff00ff00[Fuyutsui]|r 已切换|cff00ff00自动|r模式！")
    else
        print("|cff00ff00[Fuyutsui]|r 已切换|cff00ff00单体|r模式！")
    end
    local st = self.blocks and self.blocks.state
    if st and st["AOE开关"] then
        self:CreatTexture(st["AOE开关"], c.aoeMode / 255 or 0)
    end
    SaveConfig()
    if self.RefreshQuickToggleAppearance then
        self:RefreshQuickToggleAppearance()
    end
end

function Fuyutsui:SwitchDpsMode()
    local c = self.db and self.db.char
    if not c then return end
    if c.dpsMode == 0 then
        print("|cff00ff00[Fuyutsui]|r 输出模式已修改为|cff00ff00官方一键辅助|r")
    else
        print("|cff00ff00[Fuyutsui]|r 输出模式已修改为|cff00ff00手动编写逻辑|r")
    end
    local st = self.blocks and self.blocks.state
    if st and st["输出模式"] then
        self:CreatTexture(st["输出模式"], c.dpsMode / 255 or 0)
    end
    SaveConfig()
    if self.RefreshQuickToggleAppearance then
        self:RefreshQuickToggleAppearance()
    end
end

function Fuyutsui:SwitchDelay()
    local c = self.db and self.db.char
    if not c then return end
    local st = self.blocks and self.blocks.state
    if st and st["延迟"] then
        self:CreatTexture(st["延迟"], c.delay / 255 or 0)
    end
    SaveConfig()
end

function Fuyutsui:SwitchPotion()
    local c = self.db and self.db.char
    if not c then return end
    if c.potion == 0 then
        print("|cff00ff00[Fuyutsui]|r 药水已|cffff0000关闭|r")
    else
        print("|cff00ff00[Fuyutsui]|r 药水已|cff00ff00开启|r")
    end
    local st = self.blocks and self.blocks.state
    if st and st["爆发药水开关"] then
        self:CreatTexture(st["爆发药水开关"], c.potion / 255 or 0)
    end
    SaveConfig()
    if self.RefreshQuickToggleAppearance then
        self:RefreshQuickToggleAppearance()
    end
end

function Fuyutsui:SlashCommand(input, editbox)
    input = strtrim(input or "")
    local command = string.lower(input)

    local c = self.db and self.db.char
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
            local cc = Fuyutsui.db and Fuyutsui.db.char
            if cc then
                cc.delay = 0
                self:Print("延迟已恢复。")
                self:SwitchDelay()
            end
        end)
        if not delayAlreadyActive then
            self:Print("延迟已生效，" .. sec .. " 秒后恢复。")
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
        self:Print("输入 /fu help 查看命令。")
    end
end

function Fuyutsui:IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
    local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
    return function()
        local ret
        if i == 0 and unit == 'party' then
            ret = 'player'
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end
        i = i + (reversed and -1 or 1)
        return ret
    end
end

function Fuyutsui:creatColorCurve(point, b)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:AddPoint(0, CreateColor(0, 0, 0, 1))
    curve:AddPoint(point, CreateColor(0, 0, b / 255, 1))
    return curve
end

Fuyutsui.state = {
    classId = classId,
    className = className,
    classFilename = classFilename,
}
Fuyutsui.blocks = {}
Fuyutsui.target = {}
Fuyutsui.focus = {}
Fuyutsui.nameplate = {}
Fuyutsui.group = {}
Fuyutsui.groupList = {}
Fuyutsui.defaults = {
    profile = {
        someInput = "",
    },
    char = {
        level = 0,
        aoeMode = 0,
        cooldowns = 0,
        dpsMode = 0,
        delay = 0,
        potion = 0,
        quickButtonCX = 180,
        quickButtonCY = -100,
        quickButtonShow = true,
    },
}

local initialized = false
local enabled = false

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addon then
            return
        end
        eventFrame:UnregisterEvent("ADDON_LOADED")
        if not initialized then
            initialized = true
            Fuyutsui:OnInitialize()
        end
        if IsLoggedIn() and not enabled then
            enabled = true
            Fuyutsui:OnEnable()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        if not enabled then
            enabled = true
            Fuyutsui:OnEnable()
        end
        return
    end

    local handler = Fuyutsui[event]
    if handler then
        handler(Fuyutsui, event, ...)
    end
end)
