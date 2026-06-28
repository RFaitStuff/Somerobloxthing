--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Frames = require(Shared:WaitForChild("GameData"):WaitForChild("Frames"))
local Weapons = require(Shared:WaitForChild("GameData"):WaitForChild("Weapons"))
local XP = require(Shared:WaitForChild("GameData"):WaitForChild("XP"))
local Net = require(Shared:WaitForChild("Net"))

local ProfileService = {}
ProfileService.__index = ProfileService

function ProfileService.new(playerState)
    return setmetatable({ PlayerState = playerState, Profiles = {}, Remote = nil }, ProfileService)
end

local function makeLevelState()
    return { Level = 1, XP = 0, Mastered = false }
end

function ProfileService:CreateDefaultProfile()
    local frameId = Frames.DefaultFrameId
    return {
        SelectedFrameId = frameId,
        UnlockedFrames = { EmberVanguard = true, AeroMedic = true, VoltStriker = true },
        Frames = {
            EmberVanguard = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "FireBolt", [2] = "FlameDash", [3] = "BurningField", [4] = "MeteorPulse" } },
            AeroMedic = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "WindNeedle", [2] = "GaleStep", [3] = "AeroPulse", [4] = "TempestZone" } },
            VoltStriker = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "ArcLance", [2] = "VoltBlink", [3] = "StormPrison", [4] = "OverchargeField" } },
        },
        Equipped = { Primary = "Rifle", Secondary = "MicroRocket", Melee = "Skana", ActiveWeapon = "Rifle" },
        Weapons = { Rifle = makeLevelState(), Pistol = makeLevelState(), Shotgun = makeLevelState(), Launcher = makeLevelState(), MicroRocket = makeLevelState(), BeamTest = makeLevelState(), Skana = makeLevelState() },
        MasteryXP = 0,
        MasteryRank = 0,
        Inventory = {
            Materials = {},
            Mods = {
                Vitality = { Rank = 1 },
                Redirection = { Rank = 1 },
                Flow = { Rank = 0 },
                Serration = { Rank = 1 },
                SplitChamber = { Rank = 0 },
                PressurePoint = { Rank = 1 },
            },
            Armor = {},
            Rewards = {},
        },
        EquippedMods = {
            Frame = { "Vitality", "Redirection" },
            Weapon = { "Serration" },
            Melee = { "PressurePoint" },
        },
        MissionProgress = {},
    }
end

function ProfileService:UnlockFrame(player, frameId)
    local profile = self:Get(player)
    if not Frames.Get(frameId) then return false end
    profile.UnlockedFrames[frameId] = true
    if not profile.Frames[frameId] then
        profile.Frames[frameId] = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = {} }
    end
    self:Replicate(player)
    return true
end

function ProfileService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.ProfileUpdate)
end

function ProfileService:Load(player)
    local profile = self.Profiles[player]
    if not profile then
        profile = self:CreateDefaultProfile()
        self.Profiles[player] = profile
    end
    local state = self.PlayerState:Get(player)
    state.Profile = profile
    state.EquippedWeaponId = profile.Equipped.ActiveWeapon
    state.EquippedMeleeId = profile.Equipped.Melee
    state.CanAimGlide = Weapons.CanAimGlide(state.EquippedWeaponId)
    self:Replicate(player)
    return profile
end

function ProfileService:Save(_player)
    return true
end

function ProfileService:Get(player)
    return self.Profiles[player] or self:Load(player)
end

function ProfileService:SelectFrame(player, frameId)
    local profile = self:Get(player)
    if not profile.UnlockedFrames[frameId] or not Frames.Get(frameId) then return false end
    profile.SelectedFrameId = frameId
    self:Replicate(player)
    return true
end

function ProfileService:SelectAbilityVariant(player, slot, abilityId)
    local profile = self:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    local frame = Frames.Get(profile.SelectedFrameId)
    local slotData = frame and frame.AbilitySlots[slot]
    if not frameState or not slotData then return false end
    if frameState.Level < slotData.UnlockLevel then return false end
    local allowed = false
    for _, id in ipairs(slotData.Variants) do
        if id == abilityId then allowed = true break end
    end
    if not allowed then return false end
    frameState.SelectedVariants[slot] = abilityId
    self:Replicate(player)
    return true
end

function ProfileService:EquipWeapon(player, slot, weaponId)
    local profile = self:Get(player)
    if not Weapons.Get(weaponId) then return false end
    if slot == "Primary" or slot == "Secondary" or slot == "Melee" then
        profile.Equipped[slot] = weaponId
        if slot == "Melee" then profile.Equipped.Melee = weaponId end
    end
    profile.Equipped.ActiveWeapon = weaponId
    local state = self.PlayerState:Get(player)
    state.EquippedWeaponId = weaponId
    state.EquippedMeleeId = profile.Equipped.Melee
    state.CanAimGlide = Weapons.CanAimGlide(weaponId)
    self:Replicate(player)
    return true
end

function ProfileService:AddXPToLevelState(levelState, amount, maxLevel)
    levelState.XP += math.max(0, amount)
    while levelState.Level < maxLevel do
        local needed = XP.GetRequired(levelState.Level)
        if levelState.XP < needed then break end
        levelState.XP -= needed
        levelState.Level += 1
    end
end

function ProfileService:AddDebugFrameXP(player, amount)
    local profile = self:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    if not frameState then return false end
    self:AddXPToLevelState(frameState, amount or 0, XP.FrameMaxLevel)
    profile.MasteryXP += math.floor((amount or 0) * 0.15)
    profile.MasteryRank = XP.GetMasteryRank(profile.MasteryXP)
    self:Replicate(player)
    return true
end

function ProfileService:Replicate(player)
    if self.Remote then
        self.Remote:FireClient(player, { Profile = self:Get(player) })
    end
end

return ProfileService
