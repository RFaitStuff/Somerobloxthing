--!nonstrict
local defaults = {
    Unarmed = { Id = "Unarmed", Kind = "Unarmed", CanAimGlide = false, MeleeDefinition = "Fists" },
    Rifle = { Id = "Rifle", Kind = "Ranged", CanAimGlide = true, MeleeDefinition = "Skana" },
    Pistol = { Id = "Pistol", Kind = "Ranged", CanAimGlide = true, MeleeDefinition = "Skana" },
    HeavyGun = { Id = "HeavyGun", Kind = "Ranged", CanAimGlide = true, MeleeDefinition = "HeavyBlade" },
    Skana = { Id = "Skana", Kind = "Melee", CanAimGlide = false, MeleeDefinition = "Skana" },
    HeavyBlade = { Id = "HeavyBlade", Kind = "Melee", CanAimGlide = false, MeleeDefinition = "HeavyBlade" },
    Fists = { Id = "Fists", Kind = "Melee", CanAimGlide = false, MeleeDefinition = "Fists" },
}

local Weapons = {}
Weapons.ById = defaults

function Weapons.Get(id)
    return Weapons.ById[id]
end

function Weapons.CanAimGlide(id)
    local def = Weapons.Get(id)
    return def ~= nil and def.CanAimGlide == true
end

function Weapons.IsMelee(id)
    local def = Weapons.Get(id)
    return def ~= nil and def.Kind == "Melee"
end

return Weapons
