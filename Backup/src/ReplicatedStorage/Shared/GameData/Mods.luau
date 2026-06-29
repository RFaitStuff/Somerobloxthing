--!nonstrict
local Mods = {}

Mods.ById = {
    Vitality = { Id = "Vitality", Name = "Vitality", Slot = "Frame", Stat = "Health", PerRank = 20, MaxRank = 5 },
    Redirection = { Id = "Redirection", Name = "Redirection", Slot = "Frame", Stat = "Shield", PerRank = 18, MaxRank = 5 },
    Flow = { Id = "Flow", Name = "Flow", Slot = "Frame", Stat = "Mana", PerRank = 16, MaxRank = 5 },
    Serration = { Id = "Serration", Name = "Serration", Slot = "Weapon", Stat = "DamageMultiplier", PerRank = 0.08, MaxRank = 5 },
    SplitChamber = { Id = "SplitChamber", Name = "Split Chamber", Slot = "Weapon", Stat = "PelletBonusChance", PerRank = 0.08, MaxRank = 5 },
    PressurePoint = { Id = "PressurePoint", Name = "Pressure Point", Slot = "Melee", Stat = "DamageMultiplier", PerRank = 0.1, MaxRank = 5 },
}

function Mods.Get(id)
    return Mods.ById[id]
end

return Mods
