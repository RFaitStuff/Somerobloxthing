--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
    return setmetatable({ PlayerState = playerState, Remote = nil, Combat = nil, Connection = nil, HumanoidEffects = {} }, Statuses)
end

function Statuses:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.StatusUpdate)
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function Statuses:SetCombat(combat)
    self.Combat = combat
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

function Statuses:ApplyStatus(player, statusId, data, attacker, targetHumanoid)
    local definition = StatusData.Get(statusId)
    if not definition then return end
    data = data or {}
    if not player and targetHumanoid then
        self:ApplyHumanoidStatus(targetHumanoid, statusId, data, attacker)
        return
    end
    if not player then return end
    if definition.Type == "MovementModifier" then
        self:ApplySlow(player, statusId, data.Multiplier or definition.DefaultMultiplier, data.Duration or definition.DefaultDuration)
        return
    end
    if statusId == StatusTypes.Stagger or statusId == "Stagger" then
        self:ApplyStagger(player, data.Duration or definition.DefaultDuration)
        return
    end
    if statusId == StatusTypes.KnockedDown or statusId == "KnockedDown" or statusId == "KnockDown" then
        self:ApplyKnockDown(player, data.Duration or definition.DefaultDuration)
        return
    end
    if statusId == StatusTypes.Knockback or statusId == "Knockback" then
        local impulse = Vector3.zero
        if targetHumanoid and attacker and attacker.Character then
            local root = targetHumanoid.Parent and targetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
            local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
            if root and attackerRoot then
                local delta = root.Position - attackerRoot.Position
                local dir = Vector3.new(delta.X, 0, delta.Z)
                dir = dir.Magnitude > 0.001 and dir.Unit or attackerRoot.CFrame.LookVector
                impulse = dir * (data.Force or 35) + Vector3.yAxis * (data.Up or 0)
            end
        end
        self:ApplyKnockback(player, impulse, data.StaggerDuration)
        return
    end

    local state = self.PlayerState:Get(player)
    local key = statusId
    local now = os.clock()
    local duration = data.Duration or definition.DefaultDuration or 1
    local current = state.StatusEffects[key]
    local stacks = current and current.Stacks or 0
    stacks = math.min((definition.MaxStacks or 1), stacks + 1)
    state.StatusEffects[key] = {
        Type = statusId,
        EndTime = now + duration,
        NextTick = now + (definition.TickInterval or duration),
        Stacks = stacks,
        Data = data,
    }
    self:Send(player, { Type = statusId, Duration = duration, Stacks = stacks })
end

function Statuses:GetHumanoidBucket(humanoid)
    local bucket = self.HumanoidEffects[humanoid]
    if not bucket then
        bucket = { Effects = {}, BaseWalkSpeed = humanoid.WalkSpeed }
        self.HumanoidEffects[humanoid] = bucket
        humanoid.Destroying:Connect(function()
            self.HumanoidEffects[humanoid] = nil
        end)
    end
    return bucket
end

function Statuses:ApplyHumanoidMovement(humanoid, bucket)
    local multiplier = 1
    for _, effect in pairs(bucket.Effects) do
        local definition = StatusData.Get(effect.Type)
        if definition and definition.Type == "MovementModifier" then
            multiplier *= effect.Multiplier or definition.DefaultMultiplier or 1
        elseif effect.Type == StatusTypes.Stagger or effect.Type == StatusTypes.KnockedDown or effect.Type == "KnockDown" then
            multiplier = 0
        end
    end
    humanoid.WalkSpeed = math.max(0, bucket.BaseWalkSpeed * multiplier)
end

function Statuses:ApplyHumanoidStatus(humanoid, statusId, data, attacker)
    if not humanoid or humanoid.Health <= 0 then return end
    local definition = StatusData.Get(statusId)
    if not definition then return end
    local now = os.clock()
    local bucket = self:GetHumanoidBucket(humanoid)
    local key = statusId
    local current = bucket.Effects[key]
    local stacks = current and current.Stacks or 0
    stacks = math.min(definition.MaxStacks or 1, stacks + 1)
    bucket.Effects[key] = {
        Type = statusId,
        EndTime = now + (data.Duration or definition.DefaultDuration or 1),
        NextTick = now + (definition.TickInterval or data.TickInterval or 1),
        Stacks = stacks,
        Multiplier = data.Multiplier or definition.DefaultMultiplier,
        Attacker = attacker,
    }
    humanoid.Parent:SetAttribute("LastStatus", statusId)
    self:ApplyHumanoidMovement(humanoid, bucket)

    if statusId == StatusTypes.Knockback or statusId == "Knockback" then
        local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
        local attackerRoot = attacker and attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
        if root and attackerRoot then
            local delta = root.Position - attackerRoot.Position
            local dir = Vector3.new(delta.X, 0, delta.Z)
            dir = dir.Magnitude > 0.001 and dir.Unit or attackerRoot.CFrame.LookVector
            root.AssemblyLinearVelocity += dir * (data.Force or 35) + Vector3.yAxis * (data.Up or 0)
        end
    end
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

function Statuses:Update(dt)
    local now = os.clock()
    for player, state in pairs(self.PlayerState.States) do
        for id, effect in pairs(state.StatusEffects) do
            local definition = StatusData.Get(effect.Type)
            if not definition or now >= (effect.EndTime or 0) then
                state.StatusEffects[id] = nil
                self:Send(player, { Type = effect.Type, Expired = true })
            elseif definition.Type == "DamageOverTime" and now >= (effect.NextTick or 0) then
                effect.NextTick = now + (definition.TickInterval or 1)
                if self.Combat then
                    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        self.Combat:Damage(nil, humanoid, { Damage = (definition.DamagePerTick or 1) * (effect.Stacks or 1), SourceType = effect.Type })
                    end
                end
            elseif definition.Type == "ResourceModifier" and definition.ManaRegenBonus then
                if state.Resources and state.Stats then
                    state.Resources.Mana = math.min(state.Stats.Mana, state.Resources.Mana + definition.ManaRegenBonus * (dt or 0))
                end
            end
        end
    end
    for humanoid, bucket in pairs(self.HumanoidEffects) do
        if not humanoid.Parent or humanoid.Health <= 0 then
            self.HumanoidEffects[humanoid] = nil
        else
            local changedMovement = false
            for id, effect in pairs(bucket.Effects) do
                local definition = StatusData.Get(effect.Type)
                if not definition or now >= (effect.EndTime or 0) then
                    bucket.Effects[id] = nil
                    changedMovement = true
                elseif definition.Type == "DamageOverTime" and now >= (effect.NextTick or 0) then
                    effect.NextTick = now + (definition.TickInterval or 1)
                    if self.Combat then
                        self.Combat:Damage(effect.Attacker, humanoid, { Damage = (definition.DamagePerTick or 1) * (effect.Stacks or 1), SourceType = effect.Type })
                    else
                        humanoid:TakeDamage((definition.DamagePerTick or 1) * (effect.Stacks or 1))
                    end
                end
            end
            if changedMovement then
                self:ApplyHumanoidMovement(humanoid, bucket)
            end
        end
    end
end

return Statuses
