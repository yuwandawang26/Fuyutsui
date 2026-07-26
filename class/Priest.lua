if UnitClassBase("player") ~= "PRIEST" then return end
local addon, ns = ...
Fuyutsui.ClassBlocks = {
    [1] = {
        states = {
            ["状态"] = {
                "锚点",
                "职业",
                "专精",
                "队伍类型",
                "英雄天赋",
                "有效性",
                "一键辅助",
                "法术失败",
                "战斗时间",
                "移动",
                "施法",
                "引导",
                "蓄力",
                "蓄力层数",
                "生命值",
                "法力值",
                "队伍人数",
                "首领战",
                "难度",
                "施法技能",
                "施法目标",
                "延迟",
                "大红冷却",
                "敌人人数",
            },
            ["目标"] = {
                "类型",
                "生命值",
                "施法",
                "施法可打断",
            },
        },
        auras = {
            { name = "虚空之盾", spellIds = 1253590 },
            { name = "圣光涌动", spellId = 114255, maxApps = 2 },
            { name = "熵能裂隙", spellId = 447444 },
            { name = "福音", spellId = 472433, maxApps = 2 },
            { name = "祸福相依", spellId = 390787, maxApps = 10 },
        },
        spells = {
            { spellId = 8122, name = "心灵尖啸" },
            { spellId = 32375, name = "群体驱散" },
            { spellId = 527, name = "纯净术" },
            { spellId = 19236, name = "绝望祷言" },
            { spellId = 232633, name = "奥术洪流" },
            { spellId = 47540, name = "苦修" },
            { spellId = 47540, name = "苦修", charge = true, maxCharge = 2 },
            { spellId = 194509, name = "真言术：耀" },
            { spellId = 194509, name = "真言术：耀", charge = true, maxCharge = 2 },
            { spellId = 17, name = "真言术：盾" },
            { spellId = 62618, name = "真言术：障" },
            { spellId = 421453, name = "终极苦修" },
            { spellId = 472433, name = "福音" },
            { spellId = 8092, name = "心灵震爆" },
            { spellId = 32379, name = "暗言术：灭" },
            { spellId = 34433, name = "暗影魔" },
            { spellId = 1235211, name = "暗影分流" },
            { spellId = 586, name = "渐隐术" },
        },
        group = {
            num = 5,
            healthPercent = 1,
            role = 2,
            dispel = 3,
            aura = {
                [4] = { name = "救赎", spellId = 194384 },
                [5] = { name = "真言术：盾", spellIds = { 17, 1253593 } }
            },
        },
    },
    [2] = {
        states = {
            ["状态"] = {
                "锚点",
                "职业",
                "专精",
                "队伍类型",
                "英雄天赋",
                "有效性",
                "一键辅助",
                "法术失败",
                "战斗时间",
                "移动",
                "施法",
                "引导",
                "蓄力",
                "蓄力层数",
                "生命值",
                "法力值",
                "队伍人数",
                "首领战",
                "难度",
                "施法技能",
                "施法目标",
            },
            ["目标"] = {
                "类型",
                "施法",
                "施法可打断",
            },
        },
        -- TODO spellId: 织光者
        -- TODO spellId: 织光者层数
        -- TODO spellId: 圣光涌动
        -- TODO spellId: 祈福
        spells = {
            { spellId = 8122, name = "心灵尖啸" },
            { spellId = 32375, name = "群体驱散" },
            { spellId = 527, name = "纯净术" },
            { spellId = 19236, name = "绝望祷言" },
            { spellId = 232633, name = "奥术洪流" },
            { spellId = 33076, name = "愈合祷言" },
            { spellId = 33076, name = "愈合祷言", charge = true, maxCharge = 2 },
            { spellId = 2050, name = "圣言术：静" },
            { spellId = 2050, name = "圣言术：静", charge = true, maxCharge = 2 },
            { spellId = 88625, name = "圣言术：罚" },
            { spellId = 200183, name = "神圣化身" },
            { spellId = 14914, name = "神圣之火" },
            { spellId = 120517, name = "光晕" },
            { spellId = 64843, name = "神圣赞美诗" },
        },
        group = {
            num = 5,
            healthPercent = 1,
            role = 2,
        },
    },
    [3] = {
        states = {
            ["状态"] = {
                "锚点",
                "职业",
                "专精",
                "队伍类型",
                "英雄天赋",
                "有效性",
                "一键辅助",
                "法术失败",
                "战斗时间",
                "移动",
                "施法",
                "引导",
                "蓄力",
                "蓄力层数",
                "生命值",
                "法力值",
                "队伍人数",
                "首领战",
                "难度",
                "爆发开关",
                "输出模式",
                "AOE开关",
                "敌人人数",
                "施法技能",
            },
            ["目标"] = {
                "类型",
                "距离",
                "生命值",
                "施法",
                "施法可打断",
                "引导",
                "引导可打断",
            },
            ["焦点"] = {
                "施法",
                "施法可打断",
                "引导",
                "引导可打断",
            },
        },
        spells = {
            { spellId = 8122, name = "心灵尖啸" },
            { spellId = 32375, name = "群体驱散" },
            { spellId = 527, name = "纯净术" },
            { spellId = 19236, name = "绝望祷言" },
            { spellId = 232633, name = "奥术洪流" },
            { spellId = 8092, name = "心灵震爆" },
            { spellId = 32379, name = "暗言术：灭" },
            { spellId = 263165, name = "虚空洪流" },
            { spellId = 228260, name = "虚空形态" },
            { spellId = 1227280, name = "触须猛击" },
            { spellId = 15286, name = "吸血鬼的拥抱" },
            { spellId = 120644, name = "光晕" },
            { spellId = 1242173, name = "虚空齐射", forcedKnown = true },
        },
    },
}

Fuyutsui.spellsList = {

    [384255]  = { index = 151, },              -- 切换天赋
    [200749]  = { index = 152, },              -- 切换专精
    -- 种族
    [59547]   = { index = 122, },              -- 纳鲁的赐福
    [28730]   = { index = 101, },              -- 奥术洪流(法师)
    [232633]  = { index = 101, },              -- 奥术洪流(牧师)
    [129597]  = { index = 101, },              -- 奥术洪流(武僧)
    -- 牧师
    [8122]    = { index = 1, failed = true },  -- 心灵尖啸
    [32375]   = { index = 2, failed = true },  -- 群体驱散
    [62618]   = { index = 3, failed = true },  -- 真言术：障
    [421453]  = { index = 4, failed = true },  -- 终极苦修
    [200183]  = { index = 5, failed = true },  -- 神圣化身
    [120517]  = { index = 6, failed = true },  -- 光晕
    [64843]   = { index = 7, failed = true },  -- 神圣赞美诗
    [228260]  = { index = 8, failed = true },  -- 虚空形态
    [15286]   = { index = 9, failed = true },  -- 吸血鬼的拥抱
    [21562]   = { index = 10, },               -- 真言术：韧
    [8092]    = { index = 11, },               -- 心灵震爆
    [585]     = { index = 12, },               -- 惩击
    [32379]   = { index = 13, },               -- 暗言术：灭
    [589]     = { index = 14, },               -- 暗言术：痛
    [47540]   = { index = 15, },               -- 苦修
    [47757]   = { index = 15, },               -- 苦修
    [47758]   = { index = 15, },               -- 苦修
    [88625]   = { index = 16, },               -- 圣言术：罚
    [14914]   = { index = 17, },               -- 神圣之火
    [132157]  = { index = 18, },               -- 神圣新星
    [34914]   = { index = 19, },               -- 吸血鬼之触
    [232698]  = { index = 20, },               -- 暗影形态
    [335467]  = { index = 21, },               -- 暗言术：癫
    [15407]   = { index = 22, },               -- 精神鞭笞
    [263165]  = { index = 23, },               -- 虚空洪流
    [1227280] = { index = 24, },               -- 触须猛击
    [450983]  = { index = 25, },               -- 虚空冲击
    [1242173] = { index = 26, },               -- 虚空齐射
    [391403]  = { index = 27, },               -- 精神鞭笞：狂
    [120644]  = { index = 28, },               -- 光晕
    [2061]    = { index = 29, },               -- 快速治疗
    [194509]  = { index = 30, failed = true }, -- 真言术：耀
    [64863]   = { index = 31, },               -- 神圣赞美诗
    [596]     = { index = 32, },               -- 治疗祷言
    [1262763] = { index = 33, },               -- 祈福
    [186263]  = { index = 34, },               -- 暗影愈合
    [472433]  = { index = 35, failed = true }, -- 福音
}
