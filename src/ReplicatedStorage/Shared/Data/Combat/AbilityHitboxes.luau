--!nonstrict
local AbilityHitboxes = {}

AbilityHitboxes.Shapes = {
    Raycast = "Raycast",
    Projectile = "Projectile",
    Sphere = "Sphere",
    Box = "Box",
    Cone = "Cone",
    Capsule = "Capsule",
    Beam = "Beam",
    Field = "Field",
    WhipTrace = "WhipTrace",
}

AbilityHitboxes.Presets = {
    Fireball = { Shape = AbilityHitboxes.Shapes.Projectile, Radius = 5, Range = 120, Speed = 155, ImpactRadius = 8, MaxTargets = 8, DebugColor = Color3.fromRGB(255, 112, 58) },
    LightBolt = { Shape = AbilityHitboxes.Shapes.Projectile, Radius = 2, Range = 135, Speed = 190, ImpactRadius = 5, MaxTargets = 5, DebugColor = Color3.fromRGB(255, 244, 172) },
    SupportField = { Shape = AbilityHitboxes.Shapes.Field, Radius = 16, Range = 10, Duration = 6, Ticks = 3, MaxTargets = 12, DebugColor = Color3.fromRGB(124, 221, 255) },
    BlinkCapsule = { Shape = AbilityHitboxes.Shapes.Capsule, Radius = 4, Range = 34, MaxTargets = 8, DebugColor = Color3.fromRGB(182, 160, 255) },
    WhipTrace = { Shape = AbilityHitboxes.Shapes.WhipTrace, Radius = 3, Range = 24, Segments = 6, ArcDegrees = 82, MaxTargets = 10, DebugColor = Color3.fromRGB(255, 206, 93) },
    Beam = { Shape = AbilityHitboxes.Shapes.Beam, Radius = 3, Range = 95, MaxTargets = 8, DebugColor = Color3.fromRGB(94, 210, 255) },
}

function AbilityHitboxes.Get(idOrConfig)
    if type(idOrConfig) == "table" then return idOrConfig end
    return AbilityHitboxes.Presets[idOrConfig]
end

function AbilityHitboxes.Merge(baseId, overrides)
    local base = AbilityHitboxes.Get(baseId) or {}
    local merged = {}
    for key, value in pairs(base) do merged[key] = value end
    for key, value in pairs(overrides or {}) do merged[key] = value end
    return merged
end

return AbilityHitboxes
