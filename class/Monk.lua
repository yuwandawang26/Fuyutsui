if UnitClassBase("player") ~= "MONK" then return end
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
                "能量值",
                "队伍人数",
                "首领战",
                "难度",
                "酒池",
                "敌人人数",
            },
            ["目标"] = {
                "类型",
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
        -- TODO spellId: 疗伤珠
        -- TODO spellId: 活力苏醒
        -- TODO spellId: 清空地窖
        spells = {
            { spellId = 121253, name = "醉酿投" },
            { spellId = 121253, name = "醉酿投", charge = true },
            { spellId = 119582, name = "活血酒" },
            { spellId = 119582, name = "活血酒", charge = true },
            { spellId = 322507, name = "天神酒" },
            { spellId = 322507, name = "天神酒", charge = true },
            { spellId = 1241059, name = "天神灌注" },
            { spellId = 1241059, name = "天神灌注", charge = true },
            { spellId = 322109, name = "轮回之触" },
            { spellId = 119381, name = "扫堂腿" },
            { spellId = 322101, name = "移花接木", castCount = 10 },
            { spellId = 101643, name = "魂体双分" },
            { spellId = 119996, name = "魂体双分：转移" },
            { spellId = 116705, name = "切喉手" },
            { spellId = 115181, name = "火焰之息" },
            { spellId = 123986, name = "真气爆裂" },
            { spellId = 325153, name = "爆炸酒桶" },
            { spellId = 198898, name = "赤精之歌" },
            { spellId = 115399, name = "玄牛酒" },
            { spellId = 116844, name = "平心之环" },
            { spellId = 115078, name = "分筋错骨" },
            { spellId = 132578, name = "玄牛下凡" },
            { spellId = 205523, name = "幻灭踢" },
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
                "敌人人数",
                "施法技能",
                "施法目标",
                "爆发开关",
            },
            ["目标"] = {
                "类型",
                "距离",
                "施法",
                "施法可打断",
            },
        },
        -- TODO spellId: 生生不息1
        -- TODO spellId: 生生不息2
        -- TODO spellId: 灵泉
        -- TODO spellId: 玄牛之力
        -- TODO spellId: 青龙之心
        -- TODO spellId: 活力苏醒
        spells = {
            { spellId = 116680, name = "雷光聚神茶" },
            { spellId = 116680, name = "雷光聚神茶", charge = true },
            { spellId = 115151, name = "复苏之雾" },
            { spellId = 115151, name = "复苏之雾", charge = true },
            { spellId = 115310, name = "还魂术" },
            { spellId = 116849, name = "作茧缚命" },
            { spellId = 115450, name = "清创生血" },
            { spellId = 443028, name = "天神御身" },
            { spellId = 322109, name = "轮回之触" },
            { spellId = 119381, name = "扫堂腿" },
            { spellId = 1270621, name = "宁神茶" },
            { spellId = 101643, name = "魂体双分" },
            { spellId = 119996, name = "魂体双分：转移" },
            { spellId = 107428, name = "旭日东升踢" },
            { spellId = 100784, name = "幻灭踢" },
            { spellId = 116844, name = "平心之环" },
            { spellId = 115078, name = "分筋错骨" },
            { spellId = 115294, name = "法力茶", castCount = 20 },
            { spellId = 399491, name = "神龙之赐", castCount = 10 },
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
                "能量值",
                "队伍人数",
                "首领战",
                "难度",
                "敌人人数",
                "真气",
            },
            ["目标"] = {
                "类型",
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
            { spellId = 122470, name = "业报之触" },
            { spellId = 107428, name = "旭日东升踢" },
            { spellId = 1249625, name = "乾元之巅" },
            { spellId = 1249625, name = "乾元之巅", charge = true, maxCharge = 2 },
            { spellId = 218164, name = "清创生血" },
            { spellId = 152175, name = "升龙霸" },
            { spellId = 101545, name = "翔龙在天" },
            { spellId = 113656, name = "怒雷破" },
            { spellId = 322109, name = "轮回之触" },
            { spellId = 119381, name = "扫堂腿" },
            { spellId = 322101, name = "移花接木" },
            { spellId = 101643, name = "魂体双分" },
            { spellId = 119996, name = "魂体双分：转移" },
            { spellId = 116705, name = "切喉手" },
            { spellId = 198898, name = "赤精之歌" },
            { spellId = 116844, name = "平心之环" },
            { spellId = 115078, name = "分筋错骨" },
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
    -- 武僧
    [322109]  = { index = 1, failed = true },  -- 轮回之触
    [119381]  = { index = 2, failed = true },  -- 扫堂腿
    [101643]  = { index = 3, failed = true },  -- 魂体双分
    [119996]  = { index = 4, failed = true },  -- 转移
    [115310]  = { index = 5, failed = true },  -- 还魂术
    [116844]  = { index = 6, failed = true },  -- 平心之环
    [115078]  = { index = 7, failed = true },  -- 分筋错骨
    [132578]  = { index = 8, failed = true },  -- 玄牛下凡
    [100780]  = { index = 9, },                -- 猛虎掌
    [322729]  = { index = 10, },               -- 神鹤引项踢
    [205523]  = { index = 11, },               -- 幻灭踢
    [325153]  = { index = 12, },               -- 爆炸酒桶
    [123986]  = { index = 13, },               -- 真气爆裂
    [121253]  = { index = 14, },               -- 醉酿投
    [115181]  = { index = 15, },               -- 火焰之息
    [116847]  = { index = 16, },               -- 碧玉疾风
    [117952]  = { index = 17, },               -- 碎玉闪电
    [101546]  = { index = 18, },               -- 神鹤引项踢
    [100784]  = { index = 19, },               -- 幻灭踢
    [113656]  = { index = 20, },               -- 怒雷破
    [107428]  = { index = 21, },               -- 旭日东升踢
    [392983]  = { index = 22, },               -- 风领主之击
    [467307]  = { index = 23, },               -- 疾风呼啸踢
    [152175]  = { index = 24, },               -- 升龙霸
    [399491]  = { index = 25, },               -- 神龙之赐
    [116670]  = { index = 26, },               -- 活血术
    [115175]  = { index = 27, },               -- 抚慰之雾
    [443028]  = { index = 28, },               -- 天神御身
    [124682]  = { index = 29, },               -- 氤氲之雾
    [115294]  = { index = 30, },               -- 法力茶
}
