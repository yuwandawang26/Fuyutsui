if UnitClassBase("player") ~= "PALADIN" then return end
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
                "神圣能量",
                "施法技能",
                "施法目标",
                "爆发开关",
                "大红冷却",
                "延迟",
            },
            ["目标"] = {
                "类型",
                "距离",
                "施法",
                "施法可打断",
            },
        },
        -- TODO spellId: 神圣意志
        -- TODO spellId: 圣光灌注
        -- TODO spellId: 灌注层数
        -- TODO spellId: 神性层数
        -- TODO spellId: 美德道标
        spells = {
            { spellId = 115750, name = "盲目之光" },
            { spellId = 853, name = "制裁之锤" },
            { spellId = 642, name = "圣盾术" },
            { spellId = 6940, name = "牺牲祝福" },
            { spellId = 1044, name = "自由祝福" },
            { spellId = 1022, name = "保护祝福" },
            { spellId = 633, name = "圣疗术" },
            { spellId = 20473, name = "神圣震击" },
            { spellId = 20473, name = "神圣震击", charge = true },
            { spellId = 4987, name = "清洁术" },
            { spellId = 275773, name = "审判" },
            { spellId = 375576, name = "圣洁鸣钟" },
            { spellId = 114165, name = "神圣棱镜" },
            { spellId = 31821, name = "光环掌握" },
            { spellId = 200025, name = "美德道标" },
        },
        group = {
            num = 6,
            healthPercent = 1,
            role = 2,
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
                "神圣能量",
                "大红冷却",
                "延迟",
            },
            ["目标"] = {
                "类型",
                "距离",
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
        -- TODO spellId: 神圣意志
        -- TODO spellId: 神圣壁垒
        -- TODO spellId: 圣洁武器
        -- TODO spellId: 闪耀之光
        -- TODO spellId: 闪光层数
        -- TODO spellId: 神圣军备
        -- TODO spellId: 奉献
        -- TODO spellId: 复仇之怒
        -- TODO spellId: 圣光之锤
        spells = {
            { spellId = 115750, name = "盲目之光" },
            { spellId = 853, name = "制裁之锤" },
            { spellId = 642, name = "圣盾术" },
            { spellId = 6940, name = "牺牲祝福" },
            { spellId = 1044, name = "自由祝福" },
            { spellId = 1022, name = "保护祝福" },
            { spellId = 633, name = "圣疗术" },
            { spellId = 432459, name = "神圣壁垒" },
            { spellId = 432459, name = "神圣壁垒", charge = true },
            { spellId = 213644, name = "清毒术" },
            { spellId = 275779, name = "审判" },
            { spellId = 375576, name = "圣洁鸣钟" },
            { spellId = 31935, name = "复仇者之盾" },
            { spellId = 26573, name = "奉献" },
            { spellId = 53600, name = "正义盾击" },
            { spellId = 204019, name = "祝福之锤" },
            { spellId = 24275, name = "正义之锤" },
        },
        group = {
            num = 3,
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
                "神圣能量",
                "爆发开关",
                "AOE开关",
                "输出模式",
                "敌人人数",
                "大红冷却",
                "延迟",
            },
            ["目标"] = {
                "类型",
                "距离",
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
        -- TODO spellId: 神圣意志
        -- TODO spellId: 复仇之怒
        -- TODO spellId: 处决宣判
        -- TODO spellId: 圣光之锤
        spells = {
            { spellId = 115750, name = "盲目之光" },
            { spellId = 853, name = "制裁之锤" },
            { spellId = 642, name = "圣盾术" },
            { spellId = 6940, name = "牺牲祝福" },
            { spellId = 1044, name = "自由祝福" },
            { spellId = 1022, name = "保护祝福" },
            { spellId = 633, name = "圣疗术" },
            { spellId = 213644, name = "清毒术" },
            { spellId = 20271, name = "审判" },
            { spellId = 20271, name = "审判", charge = true },
            { spellId = 375576, name = "圣洁鸣钟" },
            { spellId = 184575, name = "公正之剑" },
            { spellId = 343527, name = "处决宣判" },
            { spellId = 255937, name = "灰烬觉醒" },
            { spellId = 31884, name = "复仇之怒" },
        },
        group = {
            num = 3,
            healthPercent = 1,
            role = 2,
        },
    },
} -- 创建圣骑士宏{

Fuyutsui.spellsList = {

    [384255]  = { index = 151, },              -- 切换天赋
    [200749]  = { index = 152, },              -- 切换专精
    -- 种族
    [59547]   = { index = 122, },              -- 纳鲁的赐福
    [28730]   = { index = 101, },              -- 奥术洪流(法师)
    [232633]  = { index = 101, },              -- 奥术洪流(牧师)
    [129597]  = { index = 101, },              -- 奥术洪流(武僧)
    -- 圣骑士
    [115750]  = { index = 1, failed = true },  -- 盲目之光
    [31821]   = { index = 2, failed = true },  -- 光环掌握
    [1044]    = { index = 3, failed = true },  -- 自由祝福
    [853]     = { index = 4, failed = true },  -- 制裁之锤
    [1022]    = { index = 5, failed = true },  -- 保护祝福
    [642]     = { index = 6, failed = true },  -- 圣盾术
    [375576]  = { index = 7, failed = true },  -- 圣洁鸣钟
    [31935]   = { index = 8, },                -- 复仇者之盾
    [26573]   = { index = 9, },                -- 奉献
    [275779]  = { index = 10, },               -- 审判
    [53600]   = { index = 11, },               -- 正义盾击
    [204019]  = { index = 12, },               -- 祝福之锤
    [184575]  = { index = 13, },               -- 公正之剑
    [20271]   = { index = 14, },               -- 审判
    [383328]  = { index = 15, },               -- 最终审判
    [255937]  = { index = 16, failed = true }, -- 灰烬觉醒
    [53385]   = { index = 17, },               -- 神圣风暴
    [427453]  = { index = 18, },               -- 圣光之锤(灰烬觉醒, 圣洁鸣钟)
    [24275]   = { index = 19, },               -- 愤怒之锤(审判)
    [343527]  = { index = 20, },               -- 处决宣判
    [1241413] = { index = 21, },               -- 愤怒之锤(审判)
    [82326]   = { index = 22, },               -- 圣光术
    [19750]   = { index = 23, },               -- 圣光闪现
    [200025]  = { index = 24, failed = true }, -- 美德道标
    [114165]  = { index = 25, },               -- 神圣棱镜
    [53595]   = { index = 26, },               -- 正义之锤
}
