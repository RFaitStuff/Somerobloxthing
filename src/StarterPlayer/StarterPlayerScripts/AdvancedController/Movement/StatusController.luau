--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("MovementModes"))
local StatusTypes = require(Shared:WaitForChild("StatusTypes"))
local Util = require(Shared:WaitForChild("Util"))

local StatusController = {}
StatusController.__index = StatusController

function StatusController.new(controller)
    return setmetatable({ Controller = controller, Slows = {}, StaggerTimer = 0, KnockedDownTimer = 0, GetUpTimer = 0, LastStatusName = nil }, StatusController)
end

function StatusController:ApplyServerPayload(payload)
    if typeof(payload) ~= "table" then return end
    local t = payload.Type
    if t == StatusTypes.Slow then
        self:AddSlow(payload.Id or "ServerSlow", tonumber(payload.Multiplier) or 1, tonumber(payload.Duration) or 0)
    elseif t == StatusTypes.Stagger then
        self:Stagger(tonumber(payload.Duration) or Config.Status.StaggerDefaultDuration)
    elseif t == StatusTypes.KnockedDown then
        self:KnockDown(tonumber(payload.Duration) or Config.Status.KnockedDownDefaultDuration)
    elseif t == StatusTypes.Knockback then
        if typeof(payload.Impulse) == "Vector3" then self:Knockback(payload.Impulse) end
        if payload.StaggerDuration then self:Stagger(tonumber(payload.StaggerDuration) or Config.Status.StaggerDefaultDuration) end
    elseif t == StatusTypes.GetUp then
        self:GetUp(tonumber(payload.Duration) or Config.Status.KnockedDownGetUpDuration)
    end
end

function StatusController:AddSlow(id, multiplier, duration)
    multiplier = math.clamp(multiplier, Config.Status.SlowMinMultiplier, 1)
    if duration <= 0 then return end
    self.Slows[id] = { Multiplier = multiplier, EndTime = os.clock() + duration }
    self.LastStatusName = StatusTypes.Slow
end

function StatusController:Stagger(duration)
    self.StaggerTimer = math.max(self.StaggerTimer, duration)
    self.Controller:SetMode(Modes.Staggered)
    self.LastStatusName = StatusTypes.Stagger
    if self.Controller.Animation then self.Controller.Animation:OnStatusChanged(StatusTypes.Stagger) end
end

function StatusController:KnockDown(duration)
    self.KnockedDownTimer = math.max(self.KnockedDownTimer, duration)
    self.StaggerTimer = 0
    self.Controller:SetMode(Modes.KnockedDown)
    self.LastStatusName = StatusTypes.KnockedDown
    if self.Controller.Animation then self.Controller.Animation:OnStatusChanged(StatusTypes.KnockedDown) end
end

function StatusController:GetUp(duration)
    self.KnockedDownTimer = 0
    self.GetUpTimer = math.max(self.GetUpTimer, duration)
    self.Controller:SetMode(Modes.GettingUp)
    self.LastStatusName = StatusTypes.GetUp
    if self.Controller.Animation then self.Controller.Animation:OnStatusChanged(StatusTypes.GetUp) end
end

function StatusController:Knockback(impulse)
    local planar = Util.ClampMagnitude(Vector3.new(impulse.X, 0, impulse.Z), Config.Status.KnockbackMaxImpulse)
    local y = math.clamp(impulse.Y, -Config.Status.KnockbackVerticalMax, Config.Status.KnockbackVerticalMax)
    self.Controller:ApplyImpulse(Vector3.new(planar.X, y, planar.Z))
    self.LastStatusName = StatusTypes.Knockback
    if self.Controller.Animation then self.Controller.Animation:OnStatusChanged(StatusTypes.Knockback) end
end

function StatusController:Update(dt)
    local now = os.clock()
    for id, slow in pairs(self.Slows) do
        if slow.EndTime <= now then self.Slows[id] = nil end
    end
    if self.KnockedDownTimer > 0 then
        self.KnockedDownTimer = math.max(0, self.KnockedDownTimer - dt)
        self.Controller:SetMode(Modes.KnockedDown)
        if self.KnockedDownTimer <= 0 then self:GetUp(Config.Status.KnockedDownGetUpDuration) end
        return
    end
    if self.GetUpTimer > 0 then
        self.GetUpTimer = math.max(0, self.GetUpTimer - dt)
        self.Controller:SetMode(Modes.GettingUp)
        return
    end
    if self.StaggerTimer > 0 then
        self.StaggerTimer = math.max(0, self.StaggerTimer - dt)
        self.Controller:SetMode(Modes.Staggered)
    end
end

function StatusController:GetSpeedMultiplier()
    local multiplier = 1
    for _, slow in pairs(self.Slows) do multiplier = math.min(multiplier, slow.Multiplier) end
    if self.KnockedDownTimer > 0 or self.GetUpTimer > 0 then return 0 end
    if self.StaggerTimer > 0 then return 0.15 * multiplier end
    return multiplier
end

function StatusController:IsMovementLocked()
    return self.KnockedDownTimer > 0 or self.GetUpTimer > 0 or self.StaggerTimer > 0
end

function StatusController:IsKnockedDown()
    return self.KnockedDownTimer > 0
end

function StatusController:IsSlowed()
    return next(self.Slows) ~= nil
end

return StatusController
