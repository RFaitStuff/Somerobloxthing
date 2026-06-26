--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local StatusTypes = require(Shared:WaitForChild("StatusTypes"))
local Util = require(Shared:WaitForChild("Util"))

local StatusService = {}
StatusService.__index = StatusService

function StatusService.new(playerState)
    return setmetatable({ PlayerState = playerState, Remote = nil }, StatusService)
end

function StatusService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.StatusUpdate)
end

function StatusService:Send(player, payload)
    if not self.Remote then return end
    self.Remote:FireClient(player, payload)
end

function StatusService:ApplySlow(player, id, multiplier, duration)
    multiplier = math.clamp(tonumber(multiplier) or 1, Config.Status.SlowMinMultiplier, 1)
    duration = tonumber(duration) or 0
    if duration <= 0 then return end
    local state = self.PlayerState:Get(player)
    state.StatusEffects[id or "Slow"] = { Type = StatusTypes.Slow, EndTime = os.clock() + duration, Multiplier = multiplier }
    self:Send(player, { Type = StatusTypes.Slow, Id = id or "Slow", Multiplier = multiplier, Duration = duration })
end

function StatusService:ApplyStagger(player, duration)
    duration = tonumber(duration) or Config.Status.StaggerDefaultDuration
    local state = self.PlayerState:Get(player)
    state.StatusTrustUntil = math.max(state.StatusTrustUntil or 0, os.clock() + duration + 0.25)
    self:Send(player, { Type = StatusTypes.Stagger, Duration = duration })
end

function StatusService:ApplyKnockDown(player, duration)
    duration = tonumber(duration) or Config.Status.KnockedDownDefaultDuration
    local state = self.PlayerState:Get(player)
    state.StatusTrustUntil = math.max(state.StatusTrustUntil or 0, os.clock() + duration + Config.Status.KnockedDownGetUpDuration + 0.35)
    self:Send(player, { Type = StatusTypes.KnockedDown, Duration = duration })
end

function StatusService:ApplyKnockback(player, impulse, staggerDuration)
    if typeof(impulse) ~= "Vector3" then return end
    local planar = Util.ClampMagnitude(Vector3.new(impulse.X, 0, impulse.Z), Config.Status.KnockbackMaxImpulse)
    local y = math.clamp(impulse.Y, -Config.Status.KnockbackVerticalMax, Config.Status.KnockbackVerticalMax)
    local safeImpulse = Vector3.new(planar.X, y, planar.Z)
    local state = self.PlayerState:Get(player)
    state.StatusTrustUntil = math.max(state.StatusTrustUntil or 0, os.clock() + 0.8)
    self:Send(player, { Type = StatusTypes.Knockback, Impulse = safeImpulse, StaggerDuration = staggerDuration })
end

return StatusService
