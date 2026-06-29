--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Net"))

local ResourceService = {}
ResourceService.__index = ResourceService

function ResourceService.new(playerState, frameService)
    return setmetatable({ PlayerState = playerState, FrameService = frameService, Remote = nil, Connection = nil, ReplicateAccumulator = 0 }, ResourceService)
end

function ResourceService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.ProfileUpdate)
    self.Connection = RunService.Heartbeat:Connect(function(dt) self:Update(dt) end)
end

function ResourceService:Ensure(player)
    local state = self.PlayerState:Get(player)
    local stats = state.Stats or self.FrameService:Refresh(player)
    if not state.Resources then
        state.Resources = { Health = stats.Health, Shield = stats.Shield, Mana = stats.Mana, LastDamage = 0 }
    end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.MaxHealth = math.max(humanoid.MaxHealth, 100)
        if state.Resources.Health > 0 and humanoid.Health <= 0 then
            humanoid.Health = humanoid.MaxHealth
        end
    end
    state.Resources.Health = math.clamp(state.Resources.Health, 0, stats.Health)
    state.Resources.Shield = math.clamp(state.Resources.Shield, 0, stats.Shield)
    state.Resources.Mana = math.clamp(state.Resources.Mana, 0, stats.Mana)
    return state.Resources, stats
end

function ResourceService:SpendMana(player, amount)
    local res = self:Ensure(player)
    if res.Mana < amount then return false end
    res.Mana -= amount
    self:Replicate(player)
    return true
end

function ResourceService:Heal(player, amount)
    local res, stats = self:Ensure(player)
    res.Health = math.min(stats.Health, res.Health + amount)
    self:Replicate(player)
end

function ResourceService:AddShield(player, amount)
    local res, stats = self:Ensure(player)
    res.Shield = math.min(stats.Shield, res.Shield + amount)
    self:Replicate(player)
end

function ResourceService:AddMana(player, amount)
    local res, stats = self:Ensure(player)
    res.Mana = math.min(stats.Mana, res.Mana + amount)
    self:Replicate(player)
end

function ResourceService:DamagePlayer(player, amount)
    local res = self:Ensure(player)
    res.LastDamage = os.clock()
    local shieldDamage = math.min(res.Shield, amount)
    res.Shield -= shieldDamage
    res.Health = math.max(0, res.Health - (amount - shieldDamage))
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:SetAttribute("ResourceHealth", res.Health)
        humanoid:SetAttribute("ResourceMaxHealth", (self.PlayerState:Get(player).Stats or {}).Health or 0)
        humanoid:SetAttribute("ResourceShield", res.Shield)
        if res.Health <= 0 then
            humanoid.Health = 0
        else
            humanoid.Health = humanoid.MaxHealth
        end
    end
    self:Replicate(player)
end

function ResourceService:Update(dt)
    self.ReplicateAccumulator += dt
    local shouldReplicate = self.ReplicateAccumulator >= 0.25
    if shouldReplicate then self.ReplicateAccumulator = 0 end
    for player, state in pairs(self.PlayerState.States) do
        if state.Profile and state.Stats and state.Resources then
            local res = state.Resources
            local stats = state.Stats
            res.Mana = math.min(stats.Mana, res.Mana + (stats.ManaRegen or 0) * dt)
            if os.clock() - (res.LastDamage or 0) > 2.5 then
                res.Shield = math.min(stats.Shield, res.Shield + (stats.ShieldRegen or 0) * dt)
            end
            if shouldReplicate then self:Replicate(player) end
        end
    end
end

function ResourceService:Replicate(player)
    if not self.Remote then return end
    local state = self.PlayerState:Get(player)
    self.Remote:FireClient(player, { Stats = state.Stats, Resources = state.Resources })
end

return ResourceService
