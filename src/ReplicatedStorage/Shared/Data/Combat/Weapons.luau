--!nonstrict
local Weapons = {}

Weapons.ById = {
    Rifle = { Id = "Rifle", Name = "MK1 Rifle", Kind = "Ranged", FireMode = "Auto", Simulation = "Hitscan", Damage = 18, FireRate = 8, Magazine = 30, ReloadTime = 1.4, Range = 500, Spread = 1.5, Recoil = 0.7, Element = "Kinetic", CanAimGlide = true, MuzzleOffset = Vector3.new(0.25, 1.25, -1.15), MeleeDefinition = "Skana" },
    Pistol = { Id = "Pistol", Name = "Sidearm", Kind = "Ranged", FireMode = "Semi", Simulation = "Hitscan", Damage = 28, FireRate = 4, Magazine = 12, ReloadTime = 1.1, Range = 350, Spread = 1, Element = "Kinetic", CanAimGlide = true, MeleeDefinition = "Skana" },
    Shotgun = { Id = "Shotgun", Name = "Scattergun", Kind = "Ranged", FireMode = "Semi", Simulation = "Hitscan", Damage = 9, Pellets = 8, FireRate = 1.4, Magazine = 6, ReloadTime = 1.8, Range = 180, Spread = 8, Element = "Kinetic", CanAimGlide = true, MeleeDefinition = "Skana" },
    Launcher = { Id = "Launcher", Name = "Arc Launcher", Kind = "Ranged", FireMode = "Projectile", Simulation = "ProjectileRay", Damage = 85, FireRate = 0.8, Magazine = 4, ReloadTime = 2.2, Range = 260, Radius = 12, ProjectileSpeed = 120, Recoil = 3.5, Element = "Lightning", ProjectileColor = Color3.fromRGB(80, 170, 255), CanAimGlide = true, MuzzleOffset = Vector3.new(0.25, 1.25, -1.15), MeleeDefinition = "Skana" },
    MicroRocket = { Id = "MicroRocket", Name = "Micro Rocket", Kind = "Ranged", FireMode = "Auto", Simulation = "ArmedImpactRay", Damage = 36, FireRate = 5, Magazine = 24, ReloadTime = 1.8, Range = 320, Radius = 13, ArmDistance = 18, ProjectileSpeed = 185, Spread = 1.2, Recoil = 1.6, Element = "Blast", ProjectileColor = Color3.fromRGB(255, 185, 80), CanAimGlide = true, MuzzleOffset = Vector3.new(0.25, 1.25, -1.15), MeleeDefinition = "Skana" },
    BeamTest = { Id = "BeamTest", Name = "Beam Test", Kind = "Ranged", FireMode = "Beam", Simulation = "Hitscan", Damage = 10, FireRate = 12, Magazine = 80, ReloadTime = 1.6, Range = 220, Recoil = 0.15, Element = "Light", BeamWidth = 0.35, CanAimGlide = true, MuzzleOffset = Vector3.new(0.25, 1.25, -1.15), MeleeDefinition = "Skana" },
    Skana = { Id = "Skana", Name = "Skana", Kind = "Melee", CanAimGlide = false, MeleeDefinition = "Skana" },
    HeavyBlade = { Id = "HeavyBlade", Name = "Heavy Blade", Kind = "Melee", CanAimGlide = false, MeleeDefinition = "HeavyBlade" },
    Fists = { Id = "Fists", Name = "Fists", Kind = "Melee", CanAimGlide = false, MeleeDefinition = "Fists" },
}

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
