--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local StatusTypes = require(Shared:WaitForChild("StatusTypes"))
local Util = require(Shared:WaitForChild("Util"))
local StatusData = require(ServerStorage:WaitForChild("GameData"):WaitForChild("Statuses"))

local Statuses = {}
Statuses.__index = Statuses

function Statuses.new(playerState)
    return setmetatable({ PlayerState = playerState, Remote = nil }, Statuses)
end

function Statuses:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.StatusUpdate)
end

function Statuses:Send(player, payload)
    if not self.Remote then return end
    self.Remote:FireClient(player, payload)
end

function Statuses:ApplySlow(player, id, multiplier, duration)
    local definition = StatusData.Get(StatusTypes.Slow) or {}
    multiplier = math.clamp(tonumber(multiplier) or definition.DefaultMultiplier or 1, definition.MinMultiplier or Config.Status.SlowMinMultiplier, 1)
    duration = tonumber(duration) or StatusData.GetDefaultDuration(StatusTypes.Slow, 0)
    if duration <= 0 then return end
    local state = self.PlayerState:Get(player)
    state.StatusEffects[id or "Slow"] = { Type = StatusTypes.Slow, EndTime = os.clock() + duration, Multiplier = multiplier }
    self:Send(player, { Type = StatusTypes.Slow, Id = id or "Slow", Multiplier = multiplier, Duration = duration })
end

function Statuses:ApplyStagger(player, duration)
    duration = tonumber(duration) or StatusData.GetDefaultDuration(StatusTypes.Stagger, Config.Status.StaggerDefaultDuration)
    local state = self.PlayerState:Get(player)
    state.StatusTrustUntil = math.max(state.StatusTrustUntil or 0, os.clock() + duration + 0.25)
    self:Send(player, { Type = StatusTypes.Stagger, Duration = duration })
end

function Statuses:ApplyKnockDown(player, duration)
    local knockedDown = StatusData.Get(StatusTypes.KnockedDown) or {}
    local getUpDuration = knockedDown.GetUpDuration or Config.Status.KnockedDownGetUpDuration
    duration = tonumber(duration) or StatusData.GetDefaultDuration(StatusTypes.KnockedDown, Config.Status.KnockedDownDefaultDuration)
    local state = self.PlayerState:Get(player)
    state.StatusTrustUntil = math.max(state.StatusTrustUntil or 0, os.clock() + duration + getUpDuration + 0.35)
    self:Send(player, { Type = StatusTypes.KnockedDown, Duration = duration })
end

function Statuses:ApplyKnockback(player, impulse, staggerDuration)
    if typeof(impulse) ~= "Vector3" then return end
    local definition = StatusData.Get(StatusTypes.Knockback) or {}
    local planarMax = definition.MaxPlanarImpulse or Config.Status.KnockbackMaxImpulse
    local verticalMax = definition.MaxVerticalImpulse or Config.Status.KnockbackVerticalMax
    local planar = Util.ClampMagnitude(Vector3.new(impulse.X, 0, impulse.Z), planarMax)
    local y = math.clamp(impulse.Y, -verticalMax, verticalMax)
    local safeImpulse = Vector3.new(planar.X, y, planar.Z)
    local state = self.PlayerState:Get(player)
    state.StatusTrustUntil = math.max(state.StatusTrustUntil or 0, os.clock() + 0.8)
    self:Send(player, { Type = StatusTypes.Knockback, Impulse = safeImpulse, StaggerDuration = staggerDuration })
end

return Statuses
