--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(playerState, statuses, resources, rewards)
    return setmetatable({ PlayerState = playerState, Statuses = statuses, Resources = resources, Rewards = rewards, Feedback = nil }, CombatService)
end

local function playerFromHumanoid(humanoid)
    local model = humanoid and humanoid.Parent
    return model and Players:GetPlayerFromCharacter(model)
end

function CombatService:ApplyStatus(attacker, targetPlayer, targetHumanoid, statusPayload)
    if not statusPayload or not self.Statuses then return end
    for statusId, data in pairs(statusPayload) do
        if math.random() <= (data.Chance or 1) then
            self.Statuses:ApplyStatus(targetPlayer, statusId, data, attacker, targetHumanoid)
        end
    end
end

function CombatService:Damage(attacker, targetHumanoid, packet)
    if not targetHumanoid or targetHumanoid.Health <= 0 then return false end
    packet = packet or {}
    local amount = math.max(0, packet.Damage or 0)
    local targetPlayer = playerFromHumanoid(targetHumanoid)
    local applied = 0
    if targetPlayer and self.Resources then
        local before = self.PlayerState:Get(targetPlayer).Resources and self.PlayerState:Get(targetPlayer).Resources.Health or 0
        self.Resources:DamagePlayer(targetPlayer, amount)
        local state = self.PlayerState:Get(targetPlayer)
        applied = math.max(0, before - (state.Resources and state.Resources.Health or 0))
        if state.Resources and state.Resources.Health <= 0 then
            targetHumanoid.Health = 0
        end
    else
        local model = targetHumanoid.Parent
        local armor = tonumber(targetHumanoid:GetAttribute("Armor")) or 0
        local mitigated = amount * (100 / (100 + armor))
        local health = tonumber(model and model:GetAttribute("Health")) or targetHumanoid.Health
        local maxHealth = tonumber(model and model:GetAttribute("MaxHealth")) or targetHumanoid.MaxHealth
        local shield = tonumber(model and model:GetAttribute("Shield")) or tonumber(targetHumanoid:GetAttribute("Shield")) or 0
        if shield > 0 then
            local absorbed = math.min(shield, mitigated)
            shield -= absorbed
            mitigated -= absorbed
        end
        if mitigated > 0 then
            health = math.max(0, health - mitigated)
            applied = mitigated
        end
        if model then
            model:SetAttribute("Health", health)
            model:SetAttribute("MaxHealth", maxHealth)
            model:SetAttribute("Shield", shield)
            targetHumanoid:SetAttribute("Shield", shield)
        end
        targetHumanoid.Health = health <= 0 and 0 or targetHumanoid.MaxHealth
        if health <= 0 and model then
            targetHumanoid.Health = 0
        end
    end

    local attackerPlayer = typeof(attacker) == "Instance" and attacker:IsA("Player") and attacker or nil
    self:ApplyStatus(attackerPlayer, targetPlayer, targetHumanoid, packet.Status)

    if attackerPlayer then
        targetHumanoid:SetAttribute("LastDamagedBy", attackerPlayer.UserId)
        targetHumanoid:SetAttribute("LastDamageSource", packet.SourceType or "Unknown")
    end
    local model = targetHumanoid.Parent
    local feedback = self.Feedback or Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback)
    self.Feedback = feedback
    feedback:FireAllClients({
        Type = "Damage",
        Target = model,
        Amount = math.floor((applied > 0 and applied or amount) + 0.5),
        Health = targetPlayer and (self.PlayerState:Get(targetPlayer).Resources or {}).Health or (model and model:GetAttribute("Health")),
        MaxHealth = targetPlayer and (self.PlayerState:Get(targetPlayer).Stats or {}).Health or (model and model:GetAttribute("MaxHealth")),
        Shield = targetPlayer and (self.PlayerState:Get(targetPlayer).Resources or {}).Shield or (model and model:GetAttribute("Shield")),
        MaxShield = targetPlayer and (self.PlayerState:Get(targetPlayer).Stats or {}).Shield or (model and model:GetAttribute("MaxShield")),
        SourceType = packet.SourceType or "Unknown",
    })
    return true
end

function CombatService:Heal(player, amount)
    if self.Resources then self.Resources:Heal(player, amount) end
end

function CombatService:AddShield(player, amount)
    if self.Resources then self.Resources:AddShield(player, amount) end
end

function CombatService:AddMana(player, amount)
    if self.Resources then self.Resources:AddMana(player, amount) end
end

return CombatService
