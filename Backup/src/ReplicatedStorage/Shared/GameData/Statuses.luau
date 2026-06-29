--!nonstrict
local Statuses = {}

Statuses.Definitions = {
    Burn = { Id = "Burn", Type = "DamageOverTime", DefaultDuration = 4, TickInterval = 0.5, DamagePerTick = 4, StackPolicy = "StackIntensity", MaxStacks = 4, Element = "Fire" },
    Poison = { Id = "Poison", Type = "DamageOverTime", DefaultDuration = 5, TickInterval = 1, DamagePerTick = 6, StackPolicy = "StackDuration", MaxStacks = 3, Element = "Poison" },
    Bleed = { Id = "Bleed", Type = "DamageOverTime", DefaultDuration = 5, TickInterval = 1, DamagePerTick = 7, StackPolicy = "StackIntensity", MaxStacks = 3, Element = "Kinetic" },
    Slow = { Id = "Slow", Type = "MovementModifier", DefaultDuration = 2.5, DefaultMultiplier = 0.65, MinMultiplier = 0.25, StackPolicy = "Refresh", MaxStacks = 1 },
    Stagger = { Id = "Stagger", Type = "Control", DefaultDuration = 0.45, LocksMovement = true, StackPolicy = "Refresh", MaxStacks = 1 },
    Knockback = { Id = "Knockback", Type = "Impulse", MaxPlanarImpulse = 95, MaxVerticalImpulse = 65, StackPolicy = "StackDuration", MaxStacks = 2 },
    KnockedDown = { Id = "KnockedDown", Type = "Control", DefaultDuration = 1.2, LocksMovement = true, GetUpDuration = 0.45, StackPolicy = "Refresh", MaxStacks = 1 },
    ShieldBreak = { Id = "ShieldBreak", Type = "Debuff", DefaultDuration = 3, ShieldRegenBlock = true, StackPolicy = "Refresh", MaxStacks = 1 },
    SprintBoost = { Id = "SprintBoost", Type = "MovementModifier", DefaultDuration = 4, DefaultMultiplier = 1.25, StackPolicy = "Refresh", MaxStacks = 1 },
    ManaRegen = { Id = "ManaRegen", Type = "ResourceModifier", DefaultDuration = 5, ManaRegenBonus = 8, StackPolicy = "Refresh", MaxStacks = 1 },
}

function Statuses.Get(id)
    return Statuses.Definitions[id]
end

function Statuses.GetDefaultDuration(id, fallback)
    local def = Statuses.Get(id)
    return def and def.DefaultDuration or fallback
end

return Statuses
