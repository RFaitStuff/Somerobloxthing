--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local XP = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("XP"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))

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
        Weapons = { Rifle = makeLevelState(), Pistol = makeLevelState(), Shotgun = makeLevelState(), Launcher = makeLevelState(), MicroRocket = makeLevelState(), BeamTest = makeLevelState(), Skana = makeLevelState(), HeavyBlade = makeLevelState(), Fists = makeLevelState() },
        MasteryXP = 0,
        MasteryRank = 0,
        EquippedArmor = { Helmet = "StarterHelmet", Chest = "StarterChest", Gloves = "StarterGloves", Leggings = "StarterLeggings" },
        Inventory = {
            Materials = {},
            Armor = {
                StarterHelmet = { ArmorId = "FieldHelmet", Rarity = "Common", Upgrade = 0 },
                StarterChest = { ArmorId = "FieldChest", Rarity = "Common", Upgrade = 0 },
                StarterGloves = { ArmorId = "FieldGloves", Rarity = "Common", Upgrade = 0 },
                StarterLeggings = { ArmorId = "FieldLeggings", Rarity = "Common", Upgrade = 0 },
                RaiderChestDrop = { ArmorId = "RaiderChest", Rarity = "Rare", Upgrade = 0 },
            },
            Mods = {
                Vitality = { Rank = 1 },
                Redirection = { Rank = 1 },
                Flow = { Rank = 0 },
                Serration = { Rank = 1 },
                SplitChamber = { Rank = 0 },
                PressurePoint = { Rank = 1 },
            },
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
    local def = Weapons.Get(weaponId)
    if not def then return false end
    if not profile.Weapons[weaponId] then return false end

    local state = self.PlayerState:Get(player)
    slot = slot or (def.Kind == "Melee" and "Melee" or "Primary")

    if slot == "Melee" then
        if def.Kind ~= "Melee" then return false end
        profile.Equipped.Melee = weaponId
        state.EquippedMeleeId = weaponId
        -- Melee is a separate equipment slot. Do not replace the active gun.
    elseif slot == "Primary" or slot == "Secondary" then
        if def.Kind ~= "Ranged" then return false end
        profile.Equipped[slot] = weaponId
        profile.Equipped.ActiveWeapon = weaponId
        state.EquippedWeaponId = weaponId
        state.CanAimGlide = Weapons.CanAimGlide(weaponId)
    else
        return false
    end

    self:Replicate(player)
    return true
end



local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
    return false
end

function ProfileService:EquipMod(player, group, modId)
    local profile = self:Get(player)
    local Mods = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mods"))
    local mod = Mods.Get(modId)
    if not mod or not profile.Inventory.Mods[modId] then return false end
    group = group or mod.Slot or "Frame"
    if mod.Slot ~= group then return false end
    profile.EquippedMods[group] = profile.EquippedMods[group] or {}
    if contains(profile.EquippedMods[group], modId) then return true end
    if #profile.EquippedMods[group] >= 4 then return false end
    table.insert(profile.EquippedMods[group], modId)
    self:Replicate(player)
    return true
end

function ProfileService:UnequipMod(player, group, modId)
    local profile = self:Get(player)
    local list = profile.EquippedMods and profile.EquippedMods[group]
    if not list then return false end
    for index, item in ipairs(list) do
        if item == modId then
            table.remove(list, index)
            self:Replicate(player)
            return true
        end
    end
    return false
end

function ProfileService:EquipArmor(player, itemUid)
    local profile = self:Get(player)
    local item = profile.Inventory and profile.Inventory.Armor and profile.Inventory.Armor[itemUid]
    if not item then return false end
    local Armor = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Armor"))
    local def = Armor.Get(item.ArmorId)
    if not def or not def.Slot then return false end
    profile.EquippedArmor = profile.EquippedArmor or {}
    profile.EquippedArmor[def.Slot] = itemUid
    self:Replicate(player)
    return true
end

function ProfileService:DebugUpgradeArmor(player, itemUid)
    local profile = self:Get(player)
    local item = profile.Inventory and profile.Inventory.Armor and profile.Inventory.Armor[itemUid]
    if not item then return false end
    local Armor = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Armor"))
    if not Armor.CanUpgrade(item.ArmorId, item) then return false end
    item.Upgrade = (tonumber(item.Upgrade) or 0) + 1
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


function ProfileService:AddDebugWeaponXP(player, weaponId, amount)
    local profile = self:Get(player)
    weaponId = weaponId or profile.Equipped.ActiveWeapon
    local weaponState = profile.Weapons[weaponId]
    if not weaponState then return false end
    self:AddXPToLevelState(weaponState, amount or 0, XP.WeaponMaxLevel)
    profile.MasteryXP += math.floor((amount or 0) * 0.2)
    profile.MasteryRank = XP.GetMasteryRank(profile.MasteryXP)
    self:Replicate(player)
    return true
end


function ProfileService:SetDebugWeaponLevel(player, weaponId, level)
    local profile = self:Get(player)
    weaponId = weaponId or profile.Equipped.ActiveWeapon
    local weaponState = profile.Weapons[weaponId]
    if not weaponState then return false end
    weaponState.Level = math.clamp(math.floor(tonumber(level) or 1), 1, XP.WeaponMaxLevel)
    weaponState.XP = 0
    self:Replicate(player)
    return true
end

function ProfileService:AddDebugMasteryXP(player, amount)
    local profile = self:Get(player)
    amount = math.max(0, tonumber(amount) or 0)
    profile.MasteryXP += amount
    profile.MasteryRank = XP.GetMasteryRank(profile.MasteryXP)
    self:Replicate(player)
    return true
end

function ProfileService:SetDebugFrameLevel(player, level)
    local profile = self:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    if not frameState then return false end
    frameState.Level = math.clamp(math.floor(tonumber(level) or 1), 1, XP.FrameMaxLevel)
    frameState.XP = 0
    self:Replicate(player)
    return true
end

function ProfileService:Replicate(player)
    if self.Remote then
        self.Remote:FireClient(player, { Profile = self:Get(player) })
    end
end

return ProfileService
