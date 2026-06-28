--!nonstrict
local Modes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MovementModes"))

local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self.Settings = {
        MouseSensitivity = 1,
        GamepadSensitivity = 1,
        InvertY = false,
        ToggleCrouch = true,
    }
    self.Mode = Modes.Idle
    self.ShoulderSign = 1
    self.EquippedWeaponId = "Rifle"
    self.EquippedMeleeId = "Skana"
    self.CanAimGlide = true
    self.IsMeleeAttacking = false
    self.IsBlocking = false
    self.IsSlowed = false
    self.IsStaggered = false
    self.IsKnockedDown = false
    self.SpeedMultiplier = 1
    self.SoftPlayerCollisionStrength = 0
    self.LastServerCorrection = 0
    return self
end

function State:ApplyServerState(payload)
    if typeof(payload) ~= "table" then return end
    if payload.EquippedWeaponId then self.EquippedWeaponId = payload.EquippedWeaponId end
    if payload.EquippedMeleeId then self.EquippedMeleeId = payload.EquippedMeleeId end
    if payload.CanAimGlide ~= nil then self.CanAimGlide = payload.CanAimGlide == true end
end

function State:ApplySettings(settings)
    if typeof(settings) ~= "table" then return end
    for key, value in pairs(settings) do
        self.Settings[key] = value
    end
end

return State
