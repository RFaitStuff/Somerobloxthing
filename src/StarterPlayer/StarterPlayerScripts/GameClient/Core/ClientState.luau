--!nonstrict
local Modes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("MovementModes"))

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
    self.IsMeleeBlocking = false
    self.IsBlocking = false
    self.IsSlowed = false
    self.IsStaggered = false
    self.IsKnockedDown = false
    self.SpeedMultiplier = 1
    self.SoftPlayerCollisionStrength = 0
    self.LastServerCorrection = 0
    self.Profile = nil
    self.Stats = nil
    self.Resources = nil
    self.LastReward = nil
    self.Mission = nil
    self.WeaponRuntime = {}
    self.AbilityRuntime = {}
    self.Validation = nil
    return self
end

function State:ApplyProfilePayload(payload)
    if typeof(payload) ~= "table" then return end
    if payload.Profile then self.Profile = payload.Profile end
    if payload.Stats then self.Stats = payload.Stats end
    if payload.Resources then self.Resources = payload.Resources end
    if self.Profile and self.Profile.Equipped then
        self.EquippedWeaponId = self.Profile.Equipped.ActiveWeapon or self.EquippedWeaponId
        self.EquippedMeleeId = self.Profile.Equipped.Melee or self.EquippedMeleeId
    end
end

function State:ApplyReward(payload)
    if typeof(payload) ~= "table" then return end
    self.LastReward = payload
end

function State:ApplyMission(payload)
    if typeof(payload) ~= "table" then return end
    self.Mission = payload.Mission
end

function State:ApplyWeaponRuntime(payload)
    if typeof(payload) ~= "table" then return end
    if payload.WeaponId then
        self.WeaponRuntime[payload.WeaponId] = payload
    end
end

function State:ApplyAbilityRuntime(payload)
    if typeof(payload) ~= "table" then return end
    if payload.AbilityId then
        self.AbilityRuntime[payload.AbilityId] = payload
    end
end

function State:ApplyValidation(payload)
    if typeof(payload) ~= "table" then return end
    self.Validation = payload
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
