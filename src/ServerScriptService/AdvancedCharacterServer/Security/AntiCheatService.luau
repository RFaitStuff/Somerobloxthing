--!nonstrict
-- MovementEnvelope ------------------------------------------------------------
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Config"))

local Envelope = {}
Envelope.__index = Envelope

function Envelope.new(playerState)
    return setmetatable({ PlayerState = playerState }, Envelope)
end

function Envelope:Check(player)
    local state = self.PlayerState:Get(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local now = os.clock()
    local pos = root.Position
    local lastPos = state.LastPosition
    local lastTime = state.LastPositionTime or now
    state.LastPosition = pos
    state.LastPositionTime = now

    if not lastPos then return nil end
    if (state.StatusTrustUntil or 0) > now then return nil end

    local dt = math.max(now - lastTime, 1 / 60)
    local delta = pos - lastPos
    local horizontalSpeed = Vector3.new(delta.X, 0, delta.Z).Magnitude / dt
    local verticalSpeed = math.abs(delta.Y) / dt

    if (pos - lastPos).Magnitude > Config.Security.TeleportDistanceHard or horizontalSpeed > Config.Security.MaxHorizontalSpeedHard or verticalSpeed > Config.Security.MaxVerticalSpeedHard then
        if now - (state.LastCorrection or 0) >= Config.Security.CorrectionCooldown then
            state.LastCorrection = now
            return { Position = lastPos, Velocity = Vector3.zero }
        end
    end
    return nil
end

-- Main ------------------------------------------------------------
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Net"))

local AntiCheat = {}
AntiCheat.__index = AntiCheat

function AntiCheat.new(playerState)
    return setmetatable({ PlayerState = playerState, Envelope = Envelope.new(playerState), CorrectionRemote = nil }, AntiCheat)
end

function AntiCheat:Start()
    self.CorrectionRemote = Net.GetRemoteEvent(Net.RemoteEvents.Correction)
    RunService.Heartbeat:Connect(function()
        self:Update()
    end)
end

function AntiCheat:Update()
    for player in pairs(self.PlayerState.States) do
        local correction = self.Envelope:Check(player)
        if correction and self.CorrectionRemote then
            self.CorrectionRemote:FireClient(player, correction)
        end
    end
end

return AntiCheat
