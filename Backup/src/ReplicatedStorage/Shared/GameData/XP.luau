--!nonstrict
local XP = {}

XP.FrameMaxLevel = 30
XP.WeaponMaxLevel = 30
XP.LevelCurve = {}
XP.MasteryThresholds = { 0, 1000, 3000, 6500, 11000, 17000, 24500, 33500, 44000, 56000 }

for level = 1, 30 do
    XP.LevelCurve[level] = math.floor(90 + (level - 1) * 45 + (level - 1) ^ 2 * 8)
end

function XP.GetRequired(level)
    return XP.LevelCurve[math.clamp(level, 1, 30)] or XP.LevelCurve[30]
end

function XP.GetMasteryRank(totalXp)
    local rank = 0
    for index, threshold in ipairs(XP.MasteryThresholds) do
        if totalXp >= threshold then rank = index - 1 end
    end
    return rank
end

return XP
