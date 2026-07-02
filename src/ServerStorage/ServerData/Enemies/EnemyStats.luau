--!nonstrict
local Enemies = {
    Raider = { Id = "Raider", Name = "Dust Raider", Role = "Melee", AIType = "Melee", Faction = "EarthBandits", Health = 125, Shield = 0, Armor = 12, Damage = 15, Range = 5.5, AggroRange = 120, FireRate = 1.15, MoveSpeed = 16, Element = "Kinetic" },
    Gunner = { Id = "Gunner", Name = "Scrap Gunner", Role = "Gunner", AIType = "Ranged", Faction = "EarthBandits", WeaponVisual = "Grakata", Accuracy = 0.68, HitRadius = 2.4, BurstCount = 3, BurstInterval = 0.08, Health = 110, Shield = 45, Armor = 8, Damage = 10, Range = 92, PreferredRange = 52, RetreatRange = 16, AggroRange = 150, FireRate = 1.2, MoveSpeed = 12, Element = "Kinetic" },
    Bulwark = { Id = "Bulwark", Name = "Bandit Bulwark", Role = "Heavy", AIType = "Melee", Faction = "EarthBandits", Health = 330, Shield = 95, Armor = 48, Damage = 24, Range = 8, AggroRange = 110, FireRate = 0.75, MoveSpeed = 8, Element = "Earth", StatusId = "Knockback", StatusChance = 0.25 },
    Shield = { Id = "Shield", Name = "Remnant Shieldguard", Role = "Shield", AIType = "Melee", Faction = "MarsRemnant", Health = 260, Shield = 180, Armor = 42, Damage = 19, Range = 7, AggroRange = 120, FireRate = 0.9, MoveSpeed = 9, Element = "Kinetic", StatusId = "Slow", StatusChance = 0.16, StatusDuration = 1.4 },

    Acolyte = { Id = "Acolyte", Name = "Void Acolyte", Role = "Melee", AIType = "Melee", Faction = "VoidCult", Health = 145, Shield = 65, Armor = 14, Damage = 17, Range = 6, AggroRange = 125, FireRate = 1.05, MoveSpeed = 14, Element = "Dark", StatusId = "Slow", StatusChance = 0.2, StatusDuration = 2 },
    Caster = { Id = "Caster", Name = "Void Caster", Role = "Caster", AIType = "Ranged", Faction = "VoidCult", WeaponVisual = "VoidStaff", Accuracy = 0.78, HitRadius = 2.6, Health = 100, Shield = 125, Armor = 5, Damage = 18, Range = 112, PreferredRange = 64, RetreatRange = 20, AggroRange = 165, FireRate = 0.85, MoveSpeed = 11, Element = "Dark", StatusId = "Slow", StatusChance = 0.35, StatusDuration = 2.5 },
    Deadeye = { Id = "Deadeye", Name = "Void Deadeye", Role = "Sniper", AIType = "Ranged", Faction = "VoidCult", WeaponVisual = "LongRifle", Accuracy = 0.9, HitRadius = 1.5, Health = 85, Shield = 70, Armor = 4, Damage = 36, Range = 175, PreferredRange = 95, RetreatRange = 30, AggroRange = 220, FireRate = 0.48, MoveSpeed = 10, Element = "Dark", StatusId = "Stagger", StatusChance = 0.18, StatusDuration = 0.25 },

    RyatoSkirmisher = { Id = "RyatoSkirmisher", Name = "Ryato Skirmisher", Role = "Melee", AIType = "Melee", Faction = "Ryato", Health = 155, Shield = 30, Armor = 18, Damage = 18, Range = 6, AggroRange = 130, FireRate = 1.2, MoveSpeed = 18, Element = "Kinetic", StatusId = "Stagger", StatusChance = 0.12, StatusDuration = 0.2 },
    RyatoGunner = { Id = "RyatoGunner", Name = "Ryato Suppressor", Role = "Gunner", AIType = "Ranged", Faction = "Ryato", WeaponVisual = "Grakata", Accuracy = 0.72, HitRadius = 2.2, BurstCount = 4, BurstInterval = 0.07, Health = 135, Shield = 70, Armor = 14, Damage = 12, Range = 105, PreferredRange = 58, RetreatRange = 18, AggroRange = 165, FireRate = 1.1, MoveSpeed = 13, Element = "Kinetic" },
    RyatoBulwark = { Id = "RyatoBulwark", Name = "Ryato Gate Bulwark", Role = "Heavy", AIType = "Melee", Faction = "Ryato", Health = 420, Shield = 130, Armor = 58, Damage = 28, Range = 8, AggroRange = 120, FireRate = 0.7, MoveSpeed = 8, Element = "Dark", StatusId = "Knockback", StatusChance = 0.25 },
    MoonveilRemnant = { Id = "MoonveilRemnant", Name = "Moonveil Remnant", Role = "Caster", AIType = "Ranged", Faction = "MoonveilRemnants", WeaponVisual = "VoidStaff", Accuracy = 0.74, HitRadius = 2.4, Health = 120, Shield = 120, Armor = 6, Damage = 15, Range = 90, PreferredRange = 52, RetreatRange = 18, AggroRange = 140, FireRate = 0.9, MoveSpeed = 10, Element = "Light", StatusId = "Slow", StatusChance = 0.22, StatusDuration = 1.6 },
}

function Enemies.Get(id)
    return Enemies[id]
end

function Enemies.GetByFaction(factionId)
    local out = {}
    for id, def in pairs(Enemies) do
        if type(def) == "table" and def.Faction == factionId then
            table.insert(out, id)
        end
    end
    table.sort(out)
    return out
end

function Enemies.GetByRole(role)
    local out = {}
    for id, def in pairs(Enemies) do
        if type(def) == "table" and def.Role == role then
            table.insert(out, id)
        end
    end
    table.sort(out)
    return out
end

function Enemies.ListIds()
    local out = {}
    for id, def in pairs(Enemies) do
        if type(def) == "table" and type(id) == "string" then
            table.insert(out, id)
        end
    end
    table.sort(out)
    return out
end

return Enemies
