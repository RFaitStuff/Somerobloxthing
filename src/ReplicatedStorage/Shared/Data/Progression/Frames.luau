--!nonstrict
local Frames = {}

Frames.ById = {
    EmberVanguard = {
        Id = "EmberVanguard",
        DisplayName = "Ember Vanguard",
        Theme = "Fire",
        Role = "Aggressive caster / burn damage",
        Passive = "After casting an ability, weapon and melee hits have bonus burn chance for a short time.",
        BaseStats = { Health = 150, Shield = 90, Armor = 65, Mana = 130, ManaRegen = 7, ShieldRegen = 18, Speed = 1 },
        LevelGrowth = { Health = 8, Shield = 4, Mana = 5 },
        AbilitySlots = {
            [1] = { UnlockLevel = 1, Variants = { "FireBolt", "CinderFan" } },
            [2] = { UnlockLevel = 3, Variants = { "FlameDash", "SolarGuard" } },
            [3] = { UnlockLevel = 5, Variants = { "BurningField", "AshSnare" } },
            [4] = { UnlockLevel = 7, Variants = { "MeteorPulse", "PhoenixSurge" } },
        },
    },
    AeroMedic = {
        Id = "AeroMedic",
        DisplayName = "Aero Medic",
        Theme = "Air",
        Role = "Mobile support / sustain",
        Passive = "Aim glide lasts longer and healing abilities grant a short haste buff.",
        BaseStats = { Health = 120, Shield = 130, Armor = 35, Mana = 155, ManaRegen = 9, ShieldRegen = 24, Speed = 1.06 },
        LevelGrowth = { Health = 5, Shield = 7, Mana = 6 },
        AbilitySlots = {
            [1] = { UnlockLevel = 1, Variants = { "WindNeedle", "LightNeedle" } },
            [2] = { UnlockLevel = 3, Variants = { "GaleStep", "CleanseStep" } },
            [3] = { UnlockLevel = 5, Variants = { "AeroPulse", "MenderPulse" } },
            [4] = { UnlockLevel = 7, Variants = { "TempestZone", "SanctuaryZone" } },
        },
    },
    VoltStriker = {
        Id = "VoltStriker",
        DisplayName = "Volt Striker",
        Theme = "Lightning",
        Role = "Speed control / stagger chaining",
        Passive = "Weapon hits after movement abilities have a small stagger chance.",
        BaseStats = { Health = 132, Shield = 125, Armor = 42, Mana = 148, ManaRegen = 8, ShieldRegen = 22, Speed = 1.1 },
        LevelGrowth = { Health = 6, Shield = 6, Mana = 5 },
        AbilitySlots = {
            [1] = { UnlockLevel = 1, Variants = { "ArcLance", "ChainSpark" } },
            [2] = { UnlockLevel = 3, Variants = { "VoltBlink", "StaticGuard" } },
            [3] = { UnlockLevel = 5, Variants = { "StormPrison", "RailSurge" } },
            [4] = { UnlockLevel = 7, Variants = { "OverchargeField", "CapacitorPulse" } },
        },
    },
}

Frames.DefaultFrameId = "EmberVanguard"

function Frames.Get(id)
    return Frames.ById[id or Frames.DefaultFrameId]
end

return Frames
