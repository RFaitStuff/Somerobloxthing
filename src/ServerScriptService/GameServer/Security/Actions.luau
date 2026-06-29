--!nonstrict
-- RateLimiter ------------------------------------------------------------
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Config"))

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new()
    return setmetatable({ Buckets = {} }, RateLimiter)
end

function RateLimiter:Allow(player)
    local now = os.clock()
    local bucket = self.Buckets[player]
    if not bucket or now - bucket.Start > 1 then
        bucket = { Start = now, Count = 0 }
        self.Buckets[player] = bucket
    end
    bucket.Count += 1
    return bucket.Count <= Config.Security.ActionRateLimitPerSecond
end

-- CooldownGate ------------------------------------------------------------
local COOLDOWNS = {
    BulletJump = 0.10,
    AirDodge = 0.15,
    Roll = 0.10,
    WallHop = 0.10,
    Jump = 0.04,
    DoubleJump = 0.04,
    Slide = 0.04,
}

local CooldownGate = {}
CooldownGate.__index = CooldownGate

function CooldownGate.new()
    return setmetatable({ Last = {} }, CooldownGate)
end

function CooldownGate:Allow(player, actionName)
    local now = os.clock()
    self.Last[player] = self.Last[player] or {}
    local last = self.Last[player][actionName] or 0
    local cooldown = COOLDOWNS[actionName] or 0.02
    if now - last < cooldown then return false end
    self.Last[player][actionName] = now
    return true
end

-- SanityChecks ------------------------------------------------------------
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Config"))

local Sanity = {}
Sanity.__index = Sanity

function Sanity.new(playerState)
    return setmetatable({ PlayerState = playerState }, Sanity)
end

function Sanity:Check(player, actionName, data)
    if typeof(actionName) ~= "string" then return false end
    if data ~= nil and typeof(data) ~= "table" then return false end
    if data and data.Position then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - data.Position).Magnitude > Config.Security.PositionReportMaxDistance then
            return false
        end
    end
    if actionName == "AimGlide" then
        local state = self.PlayerState:Get(player)
        if not state.CanAimGlide then return false end
    end
    return true
end

-- Main ------------------------------------------------------------

local Validator = {}
Validator.__index = Validator

function Validator.new(playerState)
    return setmetatable({ PlayerState = playerState, RateLimiter = RateLimiter.new(), Cooldowns = CooldownGate.new(), Sanity = Sanity.new(playerState) }, Validator)
end

function Validator:Validate(player, actionName, data)
    if not self.RateLimiter:Allow(player) then return false end
    if not self.Sanity:Check(player, actionName, data) then return false end
    if not self.Cooldowns:Allow(player, actionName) then return false end
    return true
end

return Validator
