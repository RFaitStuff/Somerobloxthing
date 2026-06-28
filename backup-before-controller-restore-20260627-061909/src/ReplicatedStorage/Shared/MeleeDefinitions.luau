--!nonstrict
local function attack(name, damage, startup, active, recovery, range, width, impulse, animation, status)
    return {
        Name = name,
        Damage = damage,
        Startup = startup,
        Active = active,
        Recovery = recovery,
        Range = range,
        Width = width,
        Height = 5,
        Impulse = impulse or 0,
        Animation = animation or name,
        Hitbox = "Box",
        Status = status,
    }
end

local stances = {
    Skana = {
        Id = "Skana",
        Class = "Sword",
        LightCombo = {
            attack("MeleeLight1", 28, 0.08, 0.12, 0.18, 7.5, 4.5, 18),
            attack("MeleeLight2", 32, 0.07, 0.13, 0.2, 8.0, 4.75, 20),
            attack("MeleeLight3", 42, 0.10, 0.15, 0.26, 8.5, 5.0, 26, nil, { Stagger = { Duration = 0.22 } }),
        },
        ForwardCombo = {
            attack("MeleeForward1", 34, 0.07, 0.12, 0.18, 9.0, 4.5, 34),
            attack("MeleeForward2", 38, 0.08, 0.13, 0.22, 9.5, 5.0, 38),
        },
        Heavy = attack("MeleeHeavy", 85, 0.25, 0.2, 0.42, 10.5, 6.0, 18, nil, { Knockback = { Force = 48, Up = 8, StaggerDuration = 0.28 } }),
        Air = attack("MeleeAir", 42, 0.10, 0.14, 0.24, 8.5, 5.0, 16),
        Slide = attack("MeleeSlide", 60, 0.05, 0.18, 0.24, 10.5, 6.5, 48),
        Slam = { Name = "MeleeSlam", Damage = 70, Startup = 0.12, Active = 0.18, Recovery = 0.38, Range = 10, Width = 8, Height = 8, Radius = 10, Impulse = 0, Animation = "MeleeSlam", Hitbox = "Radius", Status = { KnockDown = { Duration = 0.85 }, Knockback = { Force = 36, Up = 18 } } },
    },

    HeavyBlade = {
        Id = "HeavyBlade",
        Class = "HeavyBlade",
        LightCombo = {
            attack("HeavyBladeLight1", 45, 0.13, 0.16, 0.28, 9.0, 6.0, 15),
            attack("HeavyBladeLight2", 52, 0.15, 0.16, 0.32, 9.5, 6.0, 16),
        },
        Heavy = attack("HeavyBladeHeavy", 130, 0.36, 0.22, 0.55, 12.0, 7.5, 10, nil, { KnockDown = { Duration = 0.75 }, Knockback = { Force = 58, Up = 10 } }),
        Air = attack("HeavyBladeAir", 60, 0.16, 0.16, 0.34, 9.5, 6.0, 12),
        Slide = attack("HeavyBladeSlide", 86, 0.08, 0.18, 0.34, 11.0, 7.0, 36),
        Slam = { Name = "HeavyBladeSlam", Damage = 105, Startup = 0.16, Active = 0.22, Recovery = 0.48, Radius = 13, Impulse = 0, Animation = "HeavyBladeSlam", Hitbox = "Radius", Status = { KnockDown = { Duration = 1.1 }, Knockback = { Force = 44, Up = 22 } } },
    },

    Fists = {
        Id = "Fists",
        Class = "Fists",
        LightCombo = {
            attack("FistLight1", 16, 0.04, 0.08, 0.12, 4.2, 3.2, 10),
            attack("FistLight2", 18, 0.04, 0.08, 0.12, 4.2, 3.2, 12),
            attack("FistLight3", 28, 0.06, 0.10, 0.16, 5.0, 3.5, 18, nil, { Stagger = { Duration = 0.16 } }),
        },
        Heavy = attack("FistHeavy", 50, 0.18, 0.12, 0.28, 5.5, 4.0, 14),
        Air = attack("FistAir", 26, 0.06, 0.10, 0.16, 4.8, 3.6, 12),
        Slide = attack("FistSlide", 36, 0.03, 0.12, 0.18, 5.8, 4.0, 38),
        Slam = { Name = "FistSlam", Damage = 44, Startup = 0.08, Active = 0.12, Recovery = 0.22, Radius = 7, Impulse = 0, Animation = "FistSlam", Hitbox = "Radius" },
    },
}

local Melee = {}
Melee.ById = stances

function Melee.Get(id)
    return Melee.ById[id] or Melee.ById.Skana
end

function Melee.GetAttack(definitionId, variant, comboIndex)
    local def = Melee.Get(definitionId)
    if not def then return nil end
    variant = variant or "Light"
    if variant == "Light" then
        local combo = def.LightCombo or {}
        return combo[((comboIndex - 1) % math.max(#combo, 1)) + 1]
    end
    if variant == "Forward" then
        local combo = def.ForwardCombo or def.LightCombo or {}
        return combo[((comboIndex - 1) % math.max(#combo, 1)) + 1]
    end
    return def[variant]
end

return Melee
