--!nonstrict
-- Data-driven melee definitions.
-- Keep this public: clients need names, timings, animation ids, and predicted hitbox visuals.
-- Server still owns damage application and validates every swing.

local Melee = {}

local function vec(value, fallback)
    if typeof(value) == "Vector3" then return value end
    return fallback or Vector3.zero
end

local function duration(attack)
    return (attack.Startup or 0) + (attack.Active or 0) + (attack.Recovery or 0)
end

local function makeAttack(data)
    data = table.clone(data or {})
    data.Id = data.Id or data.Animation or "MeleeAttack"
    data.Name = data.Name or data.Id
    data.Variant = data.Variant or data.Branch or "Light"
    data.Branch = data.Branch or data.Variant
    data.Startup = tonumber(data.Startup) or 0.08
    data.Active = tonumber(data.Active) or 0.12
    data.Recovery = tonumber(data.Recovery) or 0.18
    data.Duration = duration(data)
    data.ChainTime = tonumber(data.ChainTime) or math.max(0.1, data.Startup + data.Active + data.Recovery * 0.55)
    data.BufferTime = tonumber(data.BufferTime) or 0.18
    data.Range = tonumber(data.Range) or 8
    data.Width = tonumber(data.Width) or 4.5
    data.Height = tonumber(data.Height) or 5
    data.Radius = tonumber(data.Radius) or math.max(data.Width * 0.5, 2)
    data.Shape = data.Shape or data.Hitbox or "Box"
    data.Hitbox = data.Shape
    data.Offset = vec(data.Offset, Vector3.new(0, 0, -data.Range * 0.5))
    data.StartOffset = vec(data.StartOffset, Vector3.new(0, 0, -2))
    data.EndOffset = vec(data.EndOffset, Vector3.new(0, 0, -data.Range))
    data.Impulse = tonumber(data.Impulse) or 0
    data.LockMovement = data.LockMovement ~= false
    data.MultiHit = data.MultiHit == true
    data.MaxTargets = data.MaxTargets or nil
    data.MinFacingDot = data.MinFacingDot or -0.25
    data.Animation = data.Animation or data.Id
    data.Status = data.Status or nil
    return data
end

local function light(id, damage, startup, active, recovery, range, width, impulse, status)
    return makeAttack({
        Id = id,
        Variant = "Light",
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Range = range,
        Width = width,
        Impulse = impulse,
        Status = status,
        Shape = "Box",
    })
end

local function forward(id, damage, startup, active, recovery, range, width, impulse, status)
    return makeAttack({
        Id = id,
        Variant = "Forward",
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Range = range,
        Width = width,
        Impulse = impulse,
        Status = status,
        Shape = "Capsule",
        Radius = width * 0.45,
        StartOffset = Vector3.new(0, 0, -2.5),
        EndOffset = Vector3.new(0, 0, -range),
    })
end

local function heavy(id, damage, startup, active, recovery, range, width, impulse, status)
    return makeAttack({
        Id = id,
        Variant = "Heavy",
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Range = range,
        Width = width,
        Impulse = impulse,
        Status = status,
        Shape = "Box",
        Height = 6,
        MinFacingDot = -0.35,
    })
end

local function air(id, damage, startup, active, recovery, range, width, impulse, status)
    return makeAttack({
        Id = id,
        Variant = "Air",
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Range = range,
        Width = width,
        Impulse = impulse,
        Status = status,
        Shape = "Capsule",
        Radius = width * 0.45,
        StartOffset = Vector3.new(0, -0.25, -2),
        EndOffset = Vector3.new(0, -0.25, -range),
    })
end

local function slide(id, damage, startup, active, recovery, range, width, impulse, status)
    return makeAttack({
        Id = id,
        Variant = "Slide",
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Range = range,
        Width = width,
        Height = 3.5,
        Impulse = impulse,
        Status = status,
        Shape = "Capsule",
        Radius = width * 0.5,
        StartOffset = Vector3.new(0, -1.0, -1.5),
        EndOffset = Vector3.new(0, -1.0, -range),
        MinFacingDot = -0.45,
    })
end

local function slam(id, damage, startup, active, recovery, radius, status)
    return makeAttack({
        Id = id,
        Variant = "Slam",
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Radius = radius,
        Range = radius,
        Width = radius,
        Height = radius,
        Shape = "Radius",
        Offset = Vector3.new(0, -2.5, -radius * 0.18),
        Impulse = 0,
        Status = status,
        MinFacingDot = -1,
    })
end

Melee.ById = {
    Skana = {
        Id = "Skana",
        Name = "Skana",
        Class = "Sword",
        Description = "Balanced sword stance. Good default combo, mobile slide attack, and reliable slam.",
        LightCombo = {
            light("SwordLight1", 28, 0.07, 0.12, 0.17, 7.5, 4.5, 16),
            light("SwordLight2", 32, 0.07, 0.13, 0.19, 8.0, 4.75, 18),
            light("SwordLight3", 42, 0.10, 0.15, 0.25, 8.75, 5.0, 24, { Stagger = { Duration = 0.22 } }),
        },
        ForwardCombo = {
            forward("SwordForward1", 34, 0.06, 0.13, 0.18, 9.5, 4.7, 30),
            forward("SwordForward2", 40, 0.08, 0.14, 0.22, 10.0, 5.0, 36, { Stagger = { Duration = 0.16 } }),
        },
        Heavy = heavy("SwordHeavy", 86, 0.23, 0.22, 0.42, 11, 6.25, 14, { Knockback = { Force = 44, Up = 8, StaggerDuration = 0.25 } }),
        Air = air("SwordAir", 44, 0.08, 0.14, 0.22, 8.5, 4.8, 14),
        Slide = slide("SwordSlide", 58, 0.04, 0.18, 0.22, 10.75, 6.25, 42),
        Slam = slam("SwordSlam", 72, 0.10, 0.18, 0.34, 10.5, { KnockedDown = { Duration = 0.85 }, Knockback = { Force = 34, Up = 18 } }),
        Block = { DamageMultiplier = 0.35, Angle = 135 },
    },

    HeavyBlade = {
        Id = "HeavyBlade",
        Name = "Heavy Blade",
        Class = "HeavyBlade",
        Description = "Slow, wide sweeps with strong crowd control.",
        LightCombo = {
            light("HeavyBladeLight1", 45, 0.12, 0.17, 0.30, 9.5, 6.4, 12),
            light("HeavyBladeLight2", 54, 0.14, 0.18, 0.34, 10.2, 6.8, 13, { Stagger = { Duration = 0.18 } }),
            light("HeavyBladeLight3", 68, 0.16, 0.20, 0.42, 10.8, 7.2, 14, { Knockback = { Force = 34, Up = 4 } }),
        },
        ForwardCombo = {
            forward("HeavyBladeForward1", 58, 0.13, 0.18, 0.32, 10.5, 6.8, 24),
        },
        Heavy = heavy("HeavyBladeHeavy", 132, 0.34, 0.24, 0.55, 12.5, 8, 8, { KnockedDown = { Duration = 0.75 }, Knockback = { Force = 58, Up = 10 } }),
        Air = air("HeavyBladeAir", 64, 0.14, 0.17, 0.34, 9.8, 6.2, 10),
        Slide = slide("HeavyBladeSlide", 88, 0.07, 0.20, 0.34, 11.5, 7.5, 32),
        Slam = slam("HeavyBladeSlam", 110, 0.15, 0.22, 0.48, 13.5, { KnockedDown = { Duration = 1.1 }, Knockback = { Force = 44, Up = 22 } }),
        Block = { DamageMultiplier = 0.28, Angle = 150 },
    },

    Fists = {
        Id = "Fists",
        Name = "Fists",
        Class = "Fists",
        Description = "Fast short-range strikes. Low recovery and quick combo cycling.",
        LightCombo = {
            light("FistLight1", 16, 0.035, 0.08, 0.11, 4.5, 3.2, 8),
            light("FistLight2", 18, 0.035, 0.08, 0.11, 4.5, 3.2, 10),
            light("FistLight3", 28, 0.05, 0.10, 0.15, 5.25, 3.6, 16, { Stagger = { Duration = 0.16 } }),
        },
        ForwardCombo = {
            forward("FistForward1", 24, 0.04, 0.09, 0.13, 6.2, 3.8, 28),
            forward("FistForward2", 30, 0.05, 0.10, 0.15, 6.8, 4.0, 30),
        },
        Heavy = heavy("FistHeavy", 52, 0.16, 0.13, 0.26, 6.0, 4.2, 12, { Stagger = { Duration = 0.24 } }),
        Air = air("FistAir", 28, 0.05, 0.10, 0.15, 5.2, 3.8, 10),
        Slide = slide("FistSlide", 38, 0.03, 0.12, 0.17, 6.5, 4.3, 34),
        Slam = slam("FistSlam", 46, 0.07, 0.13, 0.22, 7.5, { Stagger = { Duration = 0.2 } }),
        Block = { DamageMultiplier = 0.5, Angle = 105 },
    },
}

local VARIANT_ALIASES = {
    LightMelee = "Light",
    Quick = "Light",
    HeavyMelee = "Heavy",
    GroundSlam = "Slam",
}

function Melee.Get(id)
    return Melee.ById[id] or Melee.ById.Skana
end

function Melee.NormalizeVariant(variant)
    variant = variant or "Light"
    return VARIANT_ALIASES[variant] or variant
end

function Melee.GetCombo(definitionId, variant)
    local def = Melee.Get(definitionId)
    variant = Melee.NormalizeVariant(variant)
    if variant == "Light" then return def.LightCombo or {} end
    if variant == "Forward" then return def.ForwardCombo or def.LightCombo or {} end
    return nil
end

function Melee.GetComboLength(definitionId, variant)
    local combo = Melee.GetCombo(definitionId, variant)
    if combo then return #combo end
    return Melee.GetAttack(definitionId, variant, 1) and 1 or 0
end

function Melee.GetAttack(definitionId, variant, comboIndex)
    local def = Melee.Get(definitionId)
    variant = Melee.NormalizeVariant(variant)
    local combo = Melee.GetCombo(definitionId, variant)
    if combo then
        if #combo <= 0 then return nil end
        local index = ((tonumber(comboIndex) or 1) - 1) % #combo + 1
        local attack = combo[index]
        attack.ComboIndex = index
        return attack
    end
    local attack = def[variant]
    if attack then attack.ComboIndex = 1 end
    return attack
end

function Melee.GetAttackDuration(attack)
    if not attack then return 0 end
    return (attack.Startup or 0) + (attack.Active or 0) + (attack.Recovery or 0)
end

function Melee.IsValidVariant(definitionId, variant)
    return Melee.GetAttack(definitionId, variant, 1) ~= nil
end

function Melee.GetBlock(definitionId)
    local def = Melee.Get(definitionId)
    return def.Block or { DamageMultiplier = 0.45, Angle = 110 }
end

return Melee
