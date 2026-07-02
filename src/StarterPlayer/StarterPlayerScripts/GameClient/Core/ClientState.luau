--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modes = require(Shared:WaitForChild("Core"):WaitForChild("MovementModes"))
local SettingsSchema = require(Shared:WaitForChild("Data"):WaitForChild("Settings"):WaitForChild("SettingsSchema"))

local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self.Settings = SettingsSchema.GetDefaults()
    self.Mode = Modes.Idle
    self.ShoulderSign = 1
    self.EquippedWeaponId = "Rifle"
    self.EquippedMeleeId = "Skana"
    self.CanAimGlide = true
    self.IsMeleeAttacking = false
    self.IsMeleeBlocking = false
    self.IsBlocking = false
    self.IsSlowed = false
    self.IsStaggered = false
    self.IsKnockedDown = false
    self.SpeedMultiplier = 1
    self.SoftPlayerCollisionStrength = 0
    self.LastServerCorrection = 0
    self.Profile = nil
    self.Stats = nil
    self.Resources = nil
    self.LastReward = nil
    self.Mission = nil
    self.World = nil
    self.Story = nil
    self.Quest = nil
    self.Matchmaking = nil
    self.Power = 0
    self.Hub = nil
    self.Inventory = nil
    self.Crafting = nil
    self.Mastery = nil
    self.Room = nil
    self.Marketplace = nil
    self.Npc = nil
    self.Clan = nil
    self.Trade = nil
    self.ResourceNodes = nil
    self.Training = nil
    self.Chat = { Channels = {}, Order = {}, Messages = {}, Seen = {} }
    self.WeaponRuntime = {}
    self.AbilityRuntime = { Cooldowns = {}, Events = {}, LatestByAbility = {} }
    self.Validation = nil
    return self
end

function State:ApplyProfilePayload(payload)
    if typeof(payload) ~= "table" then return end
    if payload.Profile then self.Profile = payload.Profile end
    if payload.Stats then self.Stats = payload.Stats end
    if payload.Resources then self.Resources = payload.Resources end
    if self.Profile and self.Profile.Equipped then
        self.EquippedWeaponId = self.Profile.Equipped.ActiveWeapon or self.EquippedWeaponId
        self.EquippedMeleeId = self.Profile.Equipped.Melee or self.EquippedMeleeId
    end
end

function State:ApplyReward(payload)
    if typeof(payload) ~= "table" then return end
    self.LastReward = payload
end

function State:ApplyMission(payload)
    if typeof(payload) ~= "table" then return end
    self.Mission = payload.Mission
end

function State:ApplyWorld(payload)
    if typeof(payload) ~= "table" then return end
    self.World = payload
    if payload.Matchmaking ~= nil then self.Matchmaking = payload.Matchmaking end
    if payload.Power ~= nil then self.Power = payload.Power end
end

function State:ApplyStory(payload)
    if typeof(payload) ~= "table" then return end
    self.Story = payload
end

function State:ApplyQuest(payload)
    if typeof(payload) ~= "table" then return end
    self.Quest = payload
end

function State:ApplyHub(payload)
    if typeof(payload) ~= "table" then return end
    self.Hub = payload
end

function State:ApplyInventory(payload)
    if typeof(payload) ~= "table" then return end
    self.Inventory = payload
end

function State:ApplyCrafting(payload)
    if typeof(payload) ~= "table" then return end
    self.Crafting = payload
end

function State:ApplyMastery(payload)
    if typeof(payload) ~= "table" then return end
    self.Mastery = payload
end

function State:ApplyRoom(payload)
    if typeof(payload) ~= "table" then return end
    self.Room = payload
end

function State:ApplyMarketplace(payload)
    if typeof(payload) ~= "table" then return end
    self.Marketplace = payload
end

function State:ApplyNpc(payload)
    if typeof(payload) ~= "table" then return end
    self.Npc = payload
end

function State:ApplyClan(payload)
    if typeof(payload) ~= "table" then return end
    self.Clan = payload
end

function State:ApplyTrade(payload)
    if typeof(payload) ~= "table" then return end
    self.Trade = payload
end

function State:ApplyResourceNode(payload)
    if typeof(payload) ~= "table" then return end
    self.ResourceNodes = payload
end

function State:ApplyTraining(payload)
    if typeof(payload) ~= "table" then return end
    self.Training = payload
end

function State:ApplyChat(payload)
    if typeof(payload) ~= "table" then return end
    self.Chat = self.Chat or { Channels = {}, Order = {}, Messages = {}, Seen = {} }
    self.Chat.Seen = self.Chat.Seen or {}
    if payload.Type == "Channels" then
        self.Chat.Channels = payload.Channels or {}
        self.Chat.Order = payload.Order or {}
    elseif payload.Type == "Message" then
        local messageId = payload.MessageId
        if messageId and self.Chat.Seen[messageId] then return end
        if messageId then self.Chat.Seen[messageId] = true end
        table.insert(self.Chat.Messages, payload)
        while #self.Chat.Messages > 60 do
            table.remove(self.Chat.Messages, 1)
        end
    end
end

function State:ApplyWeaponRuntime(payload)
    if typeof(payload) ~= "table" then return end
    if payload.WeaponId then
        self.WeaponRuntime[payload.WeaponId] = payload
    end
end

function State:ApplyAbilityRuntime(payload)
    if typeof(payload) ~= "table" then return end
    if payload.AbilityId then
        self.AbilityRuntime = self.AbilityRuntime or { Cooldowns = {}, Events = {}, LatestByAbility = {} }
        self.AbilityRuntime.Cooldowns = self.AbilityRuntime.Cooldowns or {}
        self.AbilityRuntime.Events = self.AbilityRuntime.Events or {}
        self.AbilityRuntime.LatestByAbility = self.AbilityRuntime.LatestByAbility or {}
        if payload.Type == "Cooldown" or payload.CooldownEnds then
            self.AbilityRuntime.Cooldowns[payload.AbilityId] = payload
        else
            self.AbilityRuntime.LatestByAbility[payload.AbilityId] = payload
            table.insert(self.AbilityRuntime.Events, payload)
            while #self.AbilityRuntime.Events > 24 do
                table.remove(self.AbilityRuntime.Events, 1)
            end
        end
    end
end

function State:ApplyValidation(payload)
    if typeof(payload) ~= "table" then return end
    self.Validation = payload
end

function State:ApplyServerState(payload)
    if typeof(payload) ~= "table" then return end
    if payload.EquippedWeaponId then self.EquippedWeaponId = payload.EquippedWeaponId end
    if payload.EquippedMeleeId then self.EquippedMeleeId = payload.EquippedMeleeId end
    if payload.CanAimGlide ~= nil then self.CanAimGlide = payload.CanAimGlide == true end
end

function State:ApplySettings(settings)
    if typeof(settings) ~= "table" then return end
    local clean = SettingsSchema.SanitizeSettings(settings)
    for key, value in pairs(clean) do
        self.Settings[key] = value
    end
end

return State
