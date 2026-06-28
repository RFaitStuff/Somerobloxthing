--!nonstrict
local Statuses = {}

Statuses.Definitions = {
    Slow = {
        Type = "MovementModifier",
        DefaultDuration = 1.25,
        MinMultiplier = 0.25,
        DefaultMultiplier = 0.65,
        Stackable = false,
    },
    Stagger = {
        Type = "Control",
        DefaultDuration = 0.45,
        LocksMovement = true,
        Stackable = false,
    },
    KnockedDown = {
        Type = "Control",
        DefaultDuration = 1.2,
        LocksMovement = true,
        GetUpDuration = 0.45,
        Stackable = false,
    },
    Knockback = {
        Type = "Impulse",
        MaxPlanarImpulse = 95,
        MaxVerticalImpulse = 65,
        Stackable = true,
    },
    Burn = {
        Type = "DamageOverTime",
        DefaultDuration = 4,
        TickInterval = 0.5,
        DamagePerTick = 3,
        Stackable = true,
        MaxStacks = 3,
    },
    Bleed = {
        Type = "DamageOverTime",
        DefaultDuration = 5,
        TickInterval = 1,
        DamagePerTick = 5,
        Stackable = true,
        MaxStacks = 3,
    },
    SprintBoost = {
        Type = "MovementModifier",
        DefaultDuration = 3,
        DefaultMultiplier = 1.35,
        Stackable = false,
    },
}

function Statuses.Get(id)
    return Statuses.Definitions[id]
end

function Statuses.GetDefaultDuration(id, fallback)
    local definition = Statuses.Get(id)
    return definition and definition.DefaultDuration or fallback
end

return Statuses
