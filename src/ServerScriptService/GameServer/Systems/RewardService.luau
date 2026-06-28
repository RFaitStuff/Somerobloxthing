--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rewards = require(Shared:WaitForChild("GameData"):WaitForChild("Rewards"))
local CE = require(Shared:WaitForChild("GameData"):WaitForChild("CE"))
local XP = require(Shared:WaitForChild("GameData"):WaitForChild("XP"))
local Net = require(Shared:WaitForChild("Net"))

local RewardService = {}
RewardService.__index = RewardService

function RewardService.new(playerState, profiles, frameService)
    return setmetatable({ PlayerState = playerState, Profiles = profiles, FrameService = frameService, Remote = nil }, RewardService)
end

function RewardService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.RewardUpdate)
end

local function addMaterials(profile, materials)
    for id, amount in pairs(materials or {}) do
        profile.Inventory.Materials[id] = (profile.Inventory.Materials[id] or 0) + amount
    end
end

function RewardService:AddCE(profile, frameState, enemyId, role)
    local counts = frameState.EnemyCECounts
    counts[enemyId] = (counts[enemyId] or 0) + 1
    if counts[enemyId] > CE.RepeatEnemyLimit then return end
    local total = 0
    for _, value in pairs(frameState.CE) do total += value end
    if total >= CE.TotalCap then return end
    for stat, amount in pairs(CE.RoleRewards[role] or {}) do
        local current = frameState.CE[stat] or 0
        local add = math.min(amount, CE.StatCap - current, CE.TotalCap - total)
        if add > 0 then
            frameState.CE[stat] = current + add
            total += add
        end
    end
end

function RewardService:AwardXP(profile, frameState, activeWeaponState, amount, sourceType)
    amount = math.max(0, amount or 0)
    self.Profiles:AddXPToLevelState(frameState, math.floor(amount * 0.65), XP.FrameMaxLevel)
    if activeWeaponState then
        self.Profiles:AddXPToLevelState(activeWeaponState, sourceType == "Weapon" and amount or math.floor(amount * 0.35), XP.WeaponMaxLevel)
    end
    profile.MasteryXP += math.floor(amount * 0.15)
    profile.MasteryRank = XP.GetMasteryRank(profile.MasteryXP)
end

function RewardService:AwardEnemyKill(player, enemyRole, enemyId, sourceType)
    local profile = self.Profiles:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    local weaponState = profile.Weapons[profile.Equipped.ActiveWeapon]
    local reward = Rewards.Enemy[enemyRole] or Rewards.Enemy.Gunner
    self:AwardXP(profile, frameState, weaponState, reward.XP, sourceType)
    self:AddCE(profile, frameState, enemyId or enemyRole, enemyRole)
    addMaterials(profile, reward.Materials)
    self.FrameService:Refresh(player)
    self.Profiles:Replicate(player)
    if self.Remote then self.Remote:FireClient(player, { Type = "EnemyKill", Role = enemyRole, Reward = reward }) end
end

function RewardService:AwardMission(player, missionId)
    local profile = self.Profiles:Get(player)
    local reward = Rewards.Mission[missionId]
    if not reward then return end
    local frameState = profile.Frames[profile.SelectedFrameId]
    local weaponState = profile.Weapons[profile.Equipped.ActiveWeapon]
    self:AwardXP(profile, frameState, weaponState, reward.XP, "Mission")
    addMaterials(profile, reward.Materials)
    self.FrameService:Refresh(player)
    self.Profiles:Replicate(player)
    if self.Remote then self.Remote:FireClient(player, { Type = "Mission", MissionId = missionId, Reward = reward }) end
end

return RewardService
