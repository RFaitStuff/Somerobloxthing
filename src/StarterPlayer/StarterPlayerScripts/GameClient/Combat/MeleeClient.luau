--!nonstrict
-- Client melee prediction: input selection, combo buffering, animation and movement feel.
-- Server owns damage and final hitboxes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Debug = require(Shared:WaitForChild("Core"):WaitForChild("Debug"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local MeleeDefs = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Melee"))

-- ComboBuffer ------------------------------------------------------------
local ComboBuffer = {}
ComboBuffer.__index = ComboBuffer

function ComboBuffer.new()
    return setmetatable({ LastTime = 0, LastVariant = nil, Index = 0 }, ComboBuffer)
end

function ComboBuffer:Next(definitionId, variant, attack)
    local now = os.clock()
    local chainWindow = attack and (attack.ChainTime or attack.Duration or Config.Combat.MeleeComboResetTime) or Config.Combat.MeleeComboResetTime
    local comboLength = math.max(MeleeDefs.GetComboLength(definitionId, variant), 1)
    if variant ~= self.LastVariant or now - self.LastTime > math.max(chainWindow + 0.2, Config.Combat.MeleeComboResetTime) then
        self.Index = 1
    else
        self.Index = (self.Index % comboLength) + 1
    end
    self.LastVariant = variant
    self.LastTime = now
    return self.Index
end

-- Predictor ------------------------------------------------------------
local Predictor = {}
Predictor.__index = Predictor

function Predictor.new(clientState, motor, animation)
    return setmetatable({ State = clientState, Motor = motor, Animation = animation }, Predictor)
end

function Predictor:Play(attack)
    local total = MeleeDefs.GetAttackDuration(attack)
    self.State.IsMeleeAttacking = true
    self.State.MeleeVariant = attack.Variant
    self.State.MeleePhase = "Startup"

    if self.Animation then
        self.Animation:PlayMelee(attack.Animation or attack.Id or attack.Name)
    end

    if self.Motor then
        local impulse = attack.Impulse or 0
        if impulse > 0 and self.Motor.GetFlatForward and self.Motor.ApplyImpulse then
            self.Motor:ApplyImpulse(self.Motor:GetFlatForward() * impulse)
        end
        if attack.LockMovement ~= false and self.Motor.SetMeleeLock then
            self.Motor:SetMeleeLock(total)
        end
    end

    task.delay(attack.Startup or 0, function()
        if self.State then self.State.MeleePhase = "Active" end
    end)
    task.delay((attack.Startup or 0) + (attack.Active or 0), function()
        if self.State then self.State.MeleePhase = "Recovery" end
    end)
    task.delay(total, function()
        if self.State then
            self.State.IsMeleeAttacking = false
            self.State.MeleePhase = nil
            self.State.MeleeVariant = nil
        end
    end)
end

-- Main ------------------------------------------------------------
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
    self.LastRequestTime = 0
    self.Blocking = false
    self.LastSentBlock = nil
    return self
end

function MeleeClient:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.MeleeRequest)
    RunService.Heartbeat:Connect(function()
        Debug.Try(Debug.Channels.Combat, "MeleeClient:Update", function()
            self:Update()
        end)
    end)
end

function MeleeClient:GetDefinitionId()
    return self.State.EquippedMeleeId or "Skana"
end

function MeleeClient:ResolveVariant()
    local wantsBlock = self.Input:IsHeld("MeleeBlock")
    if wantsBlock ~= self.Blocking then
        self.Blocking = wantsBlock
        self.State.IsMeleeBlocking = wantsBlock
        self.State.IsBlocking = wantsBlock
        if self.Remote and self.LastSentBlock ~= wantsBlock then
            self.LastSentBlock = wantsBlock
            self.Remote:FireServer({ Action = "Block", IsBlocking = wantsBlock, ClientTime = os.clock() })
        end
    end

    if self.Input:ConsumePressed("HeavyMelee") then
        return "Heavy"
    end

    if not self.Input:ConsumePressed("Melee") then
        return nil
    end

    if self.Motor and self.Motor.Mode == "Sliding" then
        return "Slide"
    end

    if self.Motor and not self.Motor.IsGrounded then
        local velocity = self.Motor.Velocity or Vector3.zero
        if velocity.Y < -35 then
            return "Slam"
        end
        return "Air"
    end

    local move = self.Input.GetMoveVector and self.Input:GetMoveVector() or Vector2.zero
    if move.Y > 0.55 then
        return "Forward"
    end

    return "Light"
end

function MeleeClient:Update()
    local variant = self:ResolveVariant()
    if not variant then return end

    local definitionId = self:GetDefinitionId()
    local previewAttack = MeleeDefs.GetAttack(definitionId, variant, self.Buffer.Index + 1)
    if not previewAttack then return end

    local comboIndex = self.Buffer:Next(definitionId, variant, previewAttack)
    local attack = MeleeDefs.GetAttack(definitionId, variant, comboIndex)
    if not attack then return end

    local now = os.clock()
    if now - self.LastRequestTime < 0.035 then return end
    self.LastRequestTime = now

    self.LastPredictedAttack = attack
    self.LastPredictedUntil = now + (attack.Startup or 0) + (attack.Active or 0)
    self.Predictor:Play(attack)

    if self.Remote then
        self.Remote:FireServer({
            Variant = variant,
            ComboIndex = comboIndex,
            ClientTime = now,
        })
    end
end

return MeleeClient
