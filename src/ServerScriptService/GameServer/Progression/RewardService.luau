--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rewards = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Rewards"):WaitForChild("RewardTables"))
local MissionNodes = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Missions"):WaitForChild("MissionNodes"))
local EnemyDropTables = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Rewards"):WaitForChild("EnemyDropTables"))
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

local function awardCurrencies(profiles, player, reward)
    for _, currencyId in ipairs({ "Coins", "Credits", "Dallions" }) do
        local amount = reward and reward[currencyId]
        if amount then
            profiles:GrantCurrency(player, currencyId, amount)
        end
    end
end

local function rollAmount(amount)
    if typeof(amount) == "table" then
        return math.random(tonumber(amount[1]) or 1, tonumber(amount[2]) or tonumber(amount[1]) or 1)
    end
    return math.max(1, tonumber(amount) or 1)
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

function RewardService:AwardEnemyKill(player, enemyRole, enemyId, sourceType, faction, enemyLevel)
    local profile = self.Profiles:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    local weaponState = profile.Weapons[profile.Equipped.ActiveWeapon]
    local reward = Rewards.Enemy[enemyRole] or Rewards.Enemy.Gunner
    local levelScale = 1 + math.max(0, (tonumber(enemyLevel) or 1) - 1) * 0.015
    self:AwardXP(profile, frameState, weaponState, math.floor((reward.XP or 0) * levelScale), sourceType)
    self:AddCE(profile, frameState, enemyId or enemyRole, enemyRole, faction)
    addMaterials(profile, reward.Materials)
    local state = self.PlayerState:Get(player)
    local activeMission = state.ActiveMission
    local missionSetup = activeMission and MissionNodes.GetMissionSetup(activeMission.Id, activeMission.NodeId)
    local drops = missionSetup and missionSetup.Drops
    local tableId = drops and drops.EnemyDropTable
    local rolledDrops = {}
    for _, entry in ipairs((tableId and EnemyDropTables[tableId]) or {}) do
        local chance = math.clamp(tonumber(entry.Chance) or 0, 0, 1)
        if math.random() <= chance then
            local amount = rollAmount(entry.Amount)
            if entry.Type == "Material" then
                profile.Inventory.Materials[entry.Id] = (profile.Inventory.Materials[entry.Id] or 0) + amount
            end
            table.insert(rolledDrops, { Type = entry.Type, Id = entry.Id, Amount = amount })
        end
    end
    self.FrameService:Refresh(player)
    self.Profiles:Replicate(player)
    self:AwardSharedXP(player, math.floor((reward.XP or 0) * levelScale))
    if self.Remote then self.Remote:FireClient(player, { Type = "EnemyKill", Role = enemyRole, Level = enemyLevel, Reward = reward, Drops = rolledDrops }) end
end

function RewardService:AwardMission(player, missionId)
    local profile = self.Profiles:Get(player)
    local state = self.PlayerState:Get(player)
    local activeMission = state.ActiveMission
    local reward = MissionNodes.GetReward(missionId, activeMission and activeMission.NodeId) or Rewards.Mission[missionId]
    if not reward then return end
    local frameState = profile.Frames[profile.SelectedFrameId]
    local weaponState = profile.Weapons[profile.Equipped.ActiveWeapon]
    self:AwardXP(profile, frameState, weaponState, reward.XP, "Mission")
    addMaterials(profile, reward.Materials)
    awardCurrencies(self.Profiles, player, reward)
    self.FrameService:Refresh(player)
    self.Profiles:Replicate(player)
    if self.Remote then self.Remote:FireClient(player, { Type = "Mission", MissionId = missionId, Reward = reward }) end
end

return RewardService
