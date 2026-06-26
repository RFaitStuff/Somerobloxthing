--!nonstrict
-- ComboBuffer ------------------------------------------------------------
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Config"))

local ComboBuffer = {}
ComboBuffer.__index = ComboBuffer

function ComboBuffer.new()
    return setmetatable({ LastTime = 0, LastVariant = nil, Index = 0 }, ComboBuffer)
end

function ComboBuffer:Next(variant)
    local now = os.clock()
    if variant ~= self.LastVariant or now - self.LastTime > Config.Combat.MeleeComboResetTime then
        self.Index = 1
    else
        self.Index += 1
    end
    self.LastVariant = variant
    self.LastTime = now
    return self.Index
end

-- MeleePredictor ------------------------------------------------------------
local Predictor = {}
Predictor.__index = Predictor

function Predictor.new(clientState, motor, animation)
    return setmetatable({ State = clientState, Motor = motor, Animation = animation }, Predictor)
end

function Predictor:Play(attack)
    self.State.IsMeleeAttacking = true
    if self.Animation then self.Animation:PlayMelee(attack.Animation or attack.Name) end
    if self.Motor then
        local impulse = attack.Impulse or 0
        if impulse > 0 then self.Motor:ApplyImpulse(self.Motor:GetFlatForward() * impulse) end
        self.Motor:SetMeleeLock((attack.Startup or 0) + (attack.Active or 0) + (attack.Recovery or 0))
    end
    task.delay((attack.Startup or 0) + (attack.Active or 0) + (attack.Recovery or 0), function()
        self.State.IsMeleeAttacking = false
    end)
end

-- Main ------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local MeleeDefs = require(Shared:WaitForChild("MeleeDefinitions"))


local MeleeClient = {}
MeleeClient.__index = MeleeClient

function MeleeClient.new(clientState, inputClient, motor, animation)
    local self = setmetatable({}, MeleeClient)
    self.State = clientState
    self.Input = inputClient
    self.Motor = motor
    self.Animation = animation
    self.Buffer = ComboBuffer.new()
    self.Predictor = Predictor.new(clientState, motor, animation)
    self.Remote = nil
    self.LastPredictedAttack = nil
    self.LastPredictedUntil = 0
    return self
end

function MeleeClient:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.MeleeRequest)
    game:GetService("RunService").Heartbeat:Connect(function()
        self:Update()
    end)
end

function MeleeClient:Update()
    local variant = nil
    if self.Input:ConsumePressed("HeavyMelee") then variant = "Heavy" end
    if self.Input:ConsumePressed("Melee") then
        if self.Motor and self.Motor.Mode == "Sliding" then
            variant = "Slide"
        elseif self.Motor and not self.Motor.IsGrounded then
            local fallingFast = self.Motor.Velocity and self.Motor.Velocity.Y < -35
            variant = fallingFast and "Slam" or "Air"
        else
            variant = variant or "Light"
        end
    end
    if not variant then return end

    local comboIndex = self.Buffer:Next(variant)
    local attack = MeleeDefs.GetAttack(self.State.EquippedMeleeId, variant, comboIndex)
    if not attack then return end
    self.LastPredictedAttack = attack
    self.LastPredictedUntil = os.clock() + (attack.Startup or 0) + (attack.Active or 0)
    self.Predictor:Play(attack)
    if self.Remote then
        self.Remote:FireServer({ Variant = variant, ComboIndex = comboIndex, ClientTime = os.clock() })
    end
end

return MeleeClient
