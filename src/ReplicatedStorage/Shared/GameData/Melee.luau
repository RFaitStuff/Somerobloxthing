--!nonstrict
local function attack(id, branch, damage, startup, active, recovery, range, width, impulse, animation, status)
    return {
        Id = id,
        Name = id,
        Branch = branch,
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        ChainTime = math.max(0.05, startup + active + recovery * 0.45),
        Range = range,
        Width = width,
        Height = 5,
        Offset = Vector3.new(0, 0, -range * 0.5),
        Impulse = impulse or 0,
        Animation = animation or id,
        Hitbox = "Box",
        MultiHit = false,
        Status = status,
    }
end

local Melee = {}

Melee.ById = {
    Skana = {
        Id = "Skana",
        Class = "Sword",
        LightCombo = {
            attack("MeleeLight1", "Light", 28, 0.08, 0.12, 0.18, 7.5, 4.5, 18),
            attack("MeleeLight2", "Light", 32, 0.07, 0.13, 0.2, 8.0, 4.75, 20),
            attack("MeleeLight3", "Light", 42, 0.10, 0.15, 0.26, 8.5, 5.0, 26, nil, { Stagger = { Duration = 0.22 } }),
        },
        ForwardCombo = {
            attack("MeleeForward1", "Forward", 34, 0.07, 0.12, 0.18, 9.0, 4.5, 34),
            attack("MeleeForward2", "Forward", 38, 0.08, 0.13, 0.22, 9.5, 5.0, 38),
        },
        Heavy = attack("MeleeHeavy", "Heavy", 85, 0.25, 0.2, 0.42, 10.5, 6.0, 18, nil, { Knockback = { Force = 48, Up = 8, StaggerDuration = 0.28 } }),
        Air = attack("MeleeAir", "Air", 42, 0.10, 0.14, 0.24, 8.5, 5.0, 16),
        Slide = attack("MeleeSlide", "Slide", 60, 0.05, 0.18, 0.24, 10.5, 6.5, 48),
        Slam = { Id = "MeleeSlam", Name = "MeleeSlam", Branch = "Slam", Damage = 70, Startup = 0.12, Active = 0.18, Recovery = 0.38, Range = 10, Width = 8, Height = 8, Radius = 10, Impulse = 0, Animation = "MeleeSlam", Hitbox = "Radius", MultiHit = false, Status = { KnockedDown = { Duration = 0.85 }, Knockback = { Force = 36, Up = 18 } } },
    },
    HeavyBlade = {
        Id = "HeavyBlade",
        Class = "HeavyBlade",
        LightCombo = {
            attack("HeavyBladeLight1", "Light", 45, 0.13, 0.16, 0.28, 9.0, 6.0, 15),
            attack("HeavyBladeLight2", "Light", 52, 0.15, 0.16, 0.32, 9.5, 6.0, 16),
        },
        Heavy = attack("HeavyBladeHeavy", "Heavy", 130, 0.36, 0.22, 0.55, 12.0, 7.5, 10, nil, { KnockedDown = { Duration = 0.75 }, Knockback = { Force = 58, Up = 10 } }),
        Air = attack("HeavyBladeAir", "Air", 60, 0.16, 0.16, 0.34, 9.5, 6.0, 12),
        Slide = attack("HeavyBladeSlide", "Slide", 86, 0.08, 0.18, 0.34, 11.0, 7.0, 36),
        Slam = { Id = "HeavyBladeSlam", Branch = "Slam", Damage = 105, Startup = 0.16, Active = 0.22, Recovery = 0.48, Radius = 13, Impulse = 0, Animation = "HeavyBladeSlam", Hitbox = "Radius", Status = { KnockedDown = { Duration = 1.1 }, Knockback = { Force = 44, Up = 22 } } },
    },
    Fists = {
        Id = "Fists",
        Class = "Fists",
        LightCombo = {
            attack("FistLight1", "Light", 16, 0.04, 0.08, 0.12, 4.2, 3.2, 10),
            attack("FistLight2", "Light", 18, 0.04, 0.08, 0.12, 4.2, 3.2, 12),
            attack("FistLight3", "Light", 28, 0.06, 0.10, 0.16, 5.0, 3.5, 18, nil, { Stagger = { Duration = 0.16 } }),
        },
        Heavy = attack("FistHeavy", "Heavy", 50, 0.18, 0.12, 0.28, 5.5, 4.0, 14),
        Air = attack("FistAir", "Air", 26, 0.06, 0.10, 0.16, 4.8, 3.6, 12),
        Slide = attack("FistSlide", "Slide", 36, 0.03, 0.12, 0.18, 5.8, 4.0, 38),
        Slam = { Id = "FistSlam", Branch = "Slam", Damage = 44, Startup = 0.08, Active = 0.12, Recovery = 0.22, Radius = 7, Impulse = 0, Animation = "FistSlam", Hitbox = "Radius" },
    },
}

function Melee.Get(id)
    return Melee.ById[id] or Melee.ById.Skana
end

function Melee.GetAttack(definitionId, variant, comboIndex)
    local def = Melee.Get(definitionId)
    variant = variant or "Light"
    if variant == "Light" then
        local combo = def.LightCombo or {}
        return combo[((comboIndex or 1) - 1) % math.max(#combo, 1) + 1]
    end
    if variant == "Forward" then
        local combo = def.ForwardCombo or def.LightCombo or {}
        return combo[((comboIndex or 1) - 1) % math.max(#combo, 1) + 1]
    end
    return def[variant]
end

return Melee
