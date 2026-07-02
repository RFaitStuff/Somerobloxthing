--!nonstrict
local Visuals = {}

local function cframeFromOffsets(position, rotationDegrees)
    position = position or Vector3.zero
    rotationDegrees = rotationDegrees or Vector3.zero
    return CFrame.new(position) * CFrame.Angles(math.rad(rotationDegrees.X), math.rad(rotationDegrees.Y), math.rad(rotationDegrees.Z))
end

Visuals.ById = {
    Rifle = {
        WeaponName = "Rifle",
        ModelPath = { "ServerStorage", "ServerAssets", "Weapons", "Rifle" },
        MainHandle = "HandleRight",
        LeftHandle = "HandleLeft",
        Muzzle = "Muzzle",
        AimPart = "AimPart",
        GripPositionOffset = Vector3.new(0, 0, 0),
        GripRotationOffset = Vector3.new(0, 0, 0),
        BackHolsterPositionOffset = Vector3.new(0.2, 0.15, 0.55),
        BackHolsterRotationOffset = Vector3.new(25, 180, -35),
        AnimationProfile = "Rifle",
    },
}

Visuals.DefaultWeaponId = "Rifle"

for _, id in ipairs({ "Pistol", "Shotgun", "Launcher", "MicroRocket", "BeamTest" }) do
    Visuals.ById[id] = table.clone(Visuals.ById.Rifle)
    Visuals.ById[id].WeaponName = id
    Visuals.ById[id].UsesFallbackModel = true
end

function Visuals.Get(id)
    return Visuals.ById[id] or Visuals.ById[Visuals.DefaultWeaponId]
end

function Visuals.HasConfig(id)
    return Visuals.ById[id] ~= nil
end

function Visuals.GetGripCFrame(config)
    return cframeFromOffsets(config.GripPositionOffset, config.GripRotationOffset)
end

function Visuals.GetBackHolsterCFrame(config)
    return cframeFromOffsets(config.BackHolsterPositionOffset, config.BackHolsterRotationOffset)
end

function Visuals.CopyOffsets(config)
    return {
        GripPositionOffset = config.GripPositionOffset,
        GripRotationOffset = config.GripRotationOffset,
        BackHolsterPositionOffset = config.BackHolsterPositionOffset,
        BackHolsterRotationOffset = config.BackHolsterRotationOffset,
    }
end

return Visuals
