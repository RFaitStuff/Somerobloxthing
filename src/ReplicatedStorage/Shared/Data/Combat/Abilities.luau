--!nonstrict
local Blocks = require(script.Parent:WaitForChild("AbilityBlocks"))

local Abilities = {}

Abilities.ById = {
    FireBolt = { Id = "FireBolt", Name = "Fire Bolt", Slot = 1, Block = Blocks.Projectile, Element = "Fire", Damage = 55, ManaCost = 22, Cooldown = 2.5, Speed = 165, Radius = 2, Status = { Burn = { Chance = 0.45, Duration = 4 } } },
    CinderFan = { Id = "CinderFan", Name = "Cinder Fan", Slot = 1, Block = Blocks.Projectile, Element = "Fire", Count = 5, Damage = 22, ManaCost = 28, Cooldown = 4, Speed = 135, Spread = 12, Status = { Burn = { Chance = 0.25, Duration = 3 } } },
    FlameDash = { Id = "FlameDash", Name = "Flame Dash", Slot = 2, Block = Blocks.Dash, Element = "Fire", Damage = 45, ManaCost = 35, Cooldown = 7, Range = 28, Status = { Burn = { Chance = 0.35, Duration = 3 } } },
    SolarGuard = { Id = "SolarGuard", Name = "Solar Guard", Slot = 2, Block = Blocks.Buff, Element = "Light", ManaCost = 38, Cooldown = 10, Duration = 6, Buff = { Shield = 50 } },
    BurningField = { Id = "BurningField", Name = "Burning Field", Slot = 3, Block = Blocks.Area, Element = "Fire", Damage = 70, ManaCost = 48, Cooldown = 10, Radius = 14, Status = { Burn = { Chance = 0.8, Duration = 5 } } },
    AshSnare = { Id = "AshSnare", Name = "Ash Snare", Slot = 3, Block = Blocks.Debuff, Element = "Dark", Damage = 35, ManaCost = 42, Cooldown = 9, Radius = 12, Status = { Slow = { Multiplier = 0.45, Duration = 3.5 } } },
    MeteorPulse = { Id = "MeteorPulse", Name = "Meteor Pulse", Slot = 4, Block = Blocks.Area, Element = "Fire", Damage = 145, ManaCost = 80, Radius = 18, Cooldown = 22, Status = { KnockedDown = { Duration = 0.8 } } },
    PhoenixSurge = { Id = "PhoenixSurge", Name = "Phoenix Surge", Slot = 4, Block = Blocks.Heal, Element = "Light", Heal = 75, ManaCost = 75, Cooldown = 24, Radius = 16, Status = { SprintBoost = { Duration = 4 } } },

    WindNeedle = { Id = "WindNeedle", Name = "Wind Needle", Slot = 1, Block = Blocks.Projectile, Element = "Air", Damage = 42, ManaCost = 18, Cooldown = 2, Speed = 190, Radius = 1.5 },
    LightNeedle = { Id = "LightNeedle", Name = "Light Needle", Slot = 1, Block = Blocks.Projectile, Element = "Light", Damage = 34, Heal = 14, ManaCost = 22, Cooldown = 2.5, Speed = 180, Radius = 1.5 },
    GaleStep = { Id = "GaleStep", Name = "Gale Step", Slot = 2, Block = Blocks.Dash, Element = "Air", Damage = 30, ManaCost = 30, Cooldown = 6, Range = 34, Status = { Slow = { Multiplier = 0.7, Duration = 2 } } },
    CleanseStep = { Id = "CleanseStep", Name = "Cleanse Step", Slot = 2, Block = Blocks.Buff, Element = "Light", ManaCost = 36, Cooldown = 9, Duration = 5, Buff = { Mana = 30 } },
    AeroPulse = { Id = "AeroPulse", Name = "Aero Pulse", Slot = 3, Block = Blocks.Area, Element = "Air", Damage = 58, ManaCost = 42, Cooldown = 9, Radius = 15, Status = { Knockback = { Force = 38, Up = 12 } } },
    MenderPulse = { Id = "MenderPulse", Name = "Mender Pulse", Slot = 3, Block = Blocks.Heal, Element = "Light", Heal = 55, ManaCost = 45, Cooldown = 10, Radius = 14, Status = { ManaRegen = { Duration = 5 } } },
    TempestZone = { Id = "TempestZone", Name = "Tempest Zone", Slot = 4, Block = Blocks.Area, Element = "Lightning", Damage = 112, ManaCost = 80, Cooldown = 20, Radius = 20, Status = { Stagger = { Duration = 0.35 } } },
    SanctuaryZone = { Id = "SanctuaryZone", Name = "Sanctuary Zone", Slot = 4, Block = Blocks.Heal, Element = "Light", Heal = 95, ManaCost = 85, Cooldown = 24, Radius = 18, Buff = { Shield = 80 } },

    ArcLance = { Id = "ArcLance", Name = "Arc Lance", Slot = 1, Block = Blocks.Projectile, Element = "Lightning", Damage = 48, ManaCost = 20, Cooldown = 2.1, Speed = 210, Radius = 2, Status = { Stagger = { Chance = 0.25, Duration = 0.25 } } },
    ChainSpark = { Id = "ChainSpark", Name = "Chain Spark", Slot = 1, Block = Blocks.Area, Element = "Lightning", Damage = 32, ManaCost = 30, Cooldown = 4.5, Radius = 12, Status = { Slow = { Chance = 0.35, Multiplier = 0.7, Duration = 2 } } },
    VoltBlink = { Id = "VoltBlink", Name = "Volt Blink", Slot = 2, Block = Blocks.Dash, Element = "Lightning", Damage = 40, ManaCost = 32, Cooldown = 6.5, Range = 40, Status = { Stagger = { Chance = 0.4, Duration = 0.3 } } },
    StaticGuard = { Id = "StaticGuard", Name = "Static Guard", Slot = 2, Block = Blocks.Buff, Element = "Lightning", ManaCost = 36, Cooldown = 10, Duration = 6, Buff = { Shield = 65 } },
    StormPrison = { Id = "StormPrison", Name = "Storm Prison", Slot = 3, Block = Blocks.Debuff, Element = "Lightning", Damage = 44, ManaCost = 45, Cooldown = 10, Radius = 15, Status = { Slow = { Multiplier = 0.35, Duration = 3.2 }, Stagger = { Chance = 0.5, Duration = 0.25 } } },
    RailSurge = { Id = "RailSurge", Name = "Rail Surge", Slot = 3, Block = Blocks.Projectile, Element = "Lightning", Damage = 92, ManaCost = 52, Cooldown = 11, Speed = 260, Radius = 3, Status = { Knockback = { Force = 34, Up = 8 } } },
    OverchargeField = { Id = "OverchargeField", Name = "Overcharge Field", Slot = 4, Block = Blocks.Area, Element = "Lightning", Damage = 128, ManaCost = 82, Cooldown = 22, Radius = 19, Status = { Stagger = { Duration = 0.45 }, Burn = { Chance = 0.2, Duration = 3 } } },
    CapacitorPulse = { Id = "CapacitorPulse", Name = "Capacitor Pulse", Slot = 4, Block = Blocks.Heal, Element = "Lightning", Heal = 45, ManaCost = 78, Cooldown = 24, Radius = 18, Buff = { Shield = 115 } },
}

function Abilities.Get(id)
    return Abilities.ById[id]
end

return Abilities
