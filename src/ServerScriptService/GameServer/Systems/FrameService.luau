--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Frames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("Frames"))
local Mods = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("Mods"))

local FrameService = {}
FrameService.__index = FrameService

function FrameService.new(playerState, profiles)
    return setmetatable({ PlayerState = playerState, Profiles = profiles }, FrameService)
end

function FrameService:ComputeStats(profile)
    local frame = Frames.Get(profile.SelectedFrameId)
    local frameState = profile.Frames[profile.SelectedFrameId]
    local level = frameState and frameState.Level or 1
    local stats = table.clone(frame.BaseStats)
    for stat, gain in pairs(frame.LevelGrowth or {}) do
        stats[stat] = (stats[stat] or 0) + gain * (level - 1)
    end
    for stat, value in pairs(frameState and frameState.CE or {}) do
        if stat == "Vitality" then stats.Health += math.floor(value * 0.55) end
        if stat == "Guard" then stats.Shield += math.floor(value * 0.35); stats.Armor += math.floor(value * 0.12) end
        if stat == "Flow" then stats.Mana += math.floor(value * 0.45) end
        if stat == "Haste" then stats.Speed += value * 0.0008 end
        if stat == "Focus" then stats.ManaRegen += value * 0.015 end
        if stat == "Might" then stats.Power = (stats.Power or 1) + value * 0.001 end
    end
    for _, modId in ipairs(profile.EquippedMods and profile.EquippedMods.Frame or {}) do
        local mod = Mods.Get(modId)
        local owned = profile.Inventory and profile.Inventory.Mods and profile.Inventory.Mods[modId]
        local rank = owned and owned.Rank or 0
        if mod and rank > 0 and mod.Stat and stats[mod.Stat] then
            stats[mod.Stat] += mod.PerRank * rank
        end
    end
    stats.Level = level
    stats.FrameId = frame.Id
    stats.FrameName = frame.DisplayName
    return stats
end

function FrameService:Refresh(player)
    local profile = self.Profiles:Get(player)
    local state = self.PlayerState:Get(player)
    state.Stats = self:ComputeStats(profile)
    return state.Stats
end

return FrameService
