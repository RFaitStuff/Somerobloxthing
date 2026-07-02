--!nonstrict
local XP = require(script.Parent:WaitForChild("XP"))

local Mastery = {}

Mastery.Gates = {
    Mars = 2,
    Launcher = 3,
    RelaySuite = 3,
    AdapterSlot = 5,
    MythicArmor = 7,
    Subsuming = 8,
    ClanResearch = 2,
    Trading = 1,
}

function Mastery.GetRank(totalXp)
    return XP.GetMasteryRank(totalXp or 0)
end

function Mastery.CanUse(profile, gateId)
    local needed = Mastery.Gates[gateId] or 0
    return (profile and profile.MasteryRank or 0) >= needed, needed
end

function Mastery.GetSummary(profile)
    local rank = profile and profile.MasteryRank or 0
    local xp = profile and profile.MasteryXP or 0
    local nextThreshold = XP.MasteryThresholds[rank + 2]
    return {
        Rank = rank,
        XP = xp,
        NextXP = nextThreshold,
        Gates = Mastery.Gates,
    }
end

return Mastery
