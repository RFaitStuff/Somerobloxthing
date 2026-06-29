--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rewards = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Rewards"):WaitForChild("RewardTables"))
local CE = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Enemies"):WaitForChild("CERewards"))
local XP = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("XP"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))

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

local function addCePool(frameState, pool, total)
    for stat, amount in pairs(pool or {}) do
        local current = frameState.CE[stat] or 0
        local add = math.min(amount, CE.StatCap - current, CE.TotalCap - total)
        if add > 0 then
            frameState.CE[stat] = current + add
            total += add
        end
        if total >= CE.TotalCap then break end
    end
    return total
end

function RewardService:AddCE(profile, frameState, enemyId, role, faction)
    frameState.CE = frameState.CE or {}
    frameState.EnemyCECounts = frameState.EnemyCECounts or {}
    local counts = frameState.EnemyCECounts
    counts[enemyId] = (counts[enemyId] or 0) + 1
    if counts[enemyId] > CE.RepeatEnemyLimit then return end
    local total = 0
    for _, value in pairs(frameState.CE) do total += value end
    if total >= CE.TotalCap then return end
    total = addCePool(frameState, CE.RoleRewards[role], total)
    if total < CE.TotalCap then
        addCePool(frameState, CE.FactionRewards and CE.FactionRewards[faction], total)
    end
end

local function getEquippedWeaponIds(profile)
    local equipped = profile.Equipped or {}
    local ids = {}
    local seen = {}
    for _, key in ipairs({ "Primary", "Secondary", "Melee" }) do
        local id = equipped[key]
        if id and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end
    return ids
end

function RewardService:AwardXP(profile, frameState, activeWeaponState, amount, sourceType)
    amount = math.max(0, amount or 0)
    local frameShare = 0.45
    local activeShare = sourceType == "Weapon" and 0.55 or 0.25
    local passiveShare = 0.20
    if sourceType == "Mission" then
        frameShare = 0.45
        activeShare = 0.20
        passiveShare = 0.30
    elseif sourceType == "Melee" then
        activeShare = 0.50
    elseif sourceType == "Shared" then
        frameShare = 0.35
        activeShare = 0.0
        passiveShare = 0.55
    end

    self.Profiles:AddXPToLevelState(frameState, math.floor(amount * frameShare), XP.FrameMaxLevel)
    if activeWeaponState and activeShare > 0 then
        self.Profiles:AddXPToLevelState(activeWeaponState, math.floor(amount * activeShare), XP.WeaponMaxLevel)
    end

    local equippedIds = getEquippedWeaponIds(profile)
    local passiveEach = #equippedIds > 0 and math.floor((amount * passiveShare) / #equippedIds) or 0
    for _, weaponId in ipairs(equippedIds) do
        local weaponState = profile.Weapons[weaponId]
        if weaponState and weaponState ~= activeWeaponState and passiveEach > 0 then
            self.Profiles:AddXPToLevelState(weaponState, passiveEach, XP.WeaponMaxLevel)
        end
    end

    profile.MasteryXP += math.floor(amount * 0.15)
    profile.MasteryRank = XP.GetMasteryRank(profile.MasteryXP)
end


function RewardService:AwardSharedXP(sourcePlayer, amount)
    local sourceRoot = sourcePlayer.Character and sourcePlayer.Character:FindFirstChild("HumanoidRootPart")
    if not sourceRoot then return end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= sourcePlayer then
            local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - sourceRoot.Position).Magnitude <= 120 then
                local profile = self.Profiles:Get(other)
                local frameState = profile.Frames[profile.SelectedFrameId]
                local weaponState = profile.Weapons[profile.Equipped.ActiveWeapon]
                self:AwardXP(profile, frameState, weaponState, math.floor(amount * 0.25), "Shared")
                self.FrameService:Refresh(other)
                self.Profiles:Replicate(other)
                if self.Remote then self.Remote:FireClient(other, { Type = "SharedXP", XP = math.floor(amount * 0.25) }) end
            end
        end
    end
end

function RewardService:AwardEnemyKill(player, enemyRole, enemyId, sourceType, faction)
    local profile = self.Profiles:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    local weaponState = profile.Weapons[profile.Equipped.ActiveWeapon]
    local reward = Rewards.Enemy[enemyRole] or Rewards.Enemy.Gunner
    self:AwardXP(profile, frameState, weaponState, reward.XP, sourceType)
    self:AddCE(profile, frameState, enemyId or enemyRole, enemyRole, faction)
    addMaterials(profile, reward.Materials)
    self.FrameService:Refresh(player)
    self.Profiles:Replicate(player)
    self:AwardSharedXP(player, reward.XP or 0)
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
