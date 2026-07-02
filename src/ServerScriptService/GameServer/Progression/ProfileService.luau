--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local XP = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("XP"))
local Mastery = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mastery"))
local Storylines = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Storylines"))
local Rooms = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Rooms"))
local Armor = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Armor"))
local ItemTags = require(Shared:WaitForChild("Data"):WaitForChild("Economy"):WaitForChild("ItemTags"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))

local ProfileService = {}
ProfileService.__index = ProfileService
ProfileService.SchemaVersion = 1

function ProfileService.new(playerState)
    local sessionId = game.JobId
    if sessionId == "" then
        sessionId = "Studio_" .. HttpService:GenerateGUID(false)
    end
    return setmetatable({
        PlayerState = playerState,
        Profiles = {},
        Metadata = {},
        DevBackups = {},
        Remote = nil,
        StoryReplicator = nil,
        Store = nil,
        SessionId = sessionId,
        AutosaveRunning = false,
        Closing = false,
    }, ProfileService)
end

local function makeLevelState()
    return { Level = 1, XP = 0, Mastered = false }
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(item, seen)
    end
    return copy
end

function ProfileService:GetStore()
    if self.Store ~= nil then return self.Store end
    local ok, store = pcall(function()
        return DataStoreService:GetDataStore(Config.Networking.ProfileDataStoreName or "SomerobloxthingProfiles_v1")
    end)
    if ok then
        self.Store = store
    else
        warn("[ProfileService] DataStore unavailable; using local-only profiles: " .. tostring(store))
        self.Store = false
    end
    return self.Store
end

function ProfileService:GetKey(player)
    return "profile_" .. tostring(player.UserId)
end

function ProfileService:GetSessionLock(player)
    return {
        JobId = self.SessionId,
        PlaceId = game.PlaceId,
        UserId = player.UserId,
        LastSeen = os.time(),
    }
end

function ProfileService:ExtractProfile(data)
    if type(data) ~= "table" then return nil end
    if type(data.Profile) == "table" then return data.Profile end
    if data.SelectedFrameId or data.Inventory or data.Wallet then return data end
    return nil
end

function ProfileService:IsForeignLockActive(data)
    if type(data) ~= "table" or type(data.SessionLock) ~= "table" then return false end
    local lock = data.SessionLock
    if lock.JobId == self.SessionId then return false end
    local lastSeen = tonumber(lock.LastSeen or lock.AcquiredAt) or 0
    return os.time() - lastSeen < (Config.Networking.ProfileSessionLockSeconds or 180)
end

function ProfileService:BuildEnvelope(player, profile, release)
    return {
        Version = ProfileService.SchemaVersion,
        SavedAt = os.time(),
        UserId = player.UserId,
        SessionLock = release and nil or self:GetSessionLock(player),
        Profile = deepCopy(profile),
    }
end

function ProfileService:CreateDefaultProfile()
    local frameId = Frames.DefaultFrameId
    return {
        SelectedFrameId = frameId,
        UnlockedFrames = { EmberVanguard = true, AeroMedic = true, VoltStriker = true, Luma = true },
        Frames = {
            EmberVanguard = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "FireBolt", [2] = "FlameDash", [3] = "BurningField", [4] = "MeteorPulse" } },
            AeroMedic = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "WindNeedle", [2] = "GaleStep", [3] = "AeroPulse", [4] = "TempestZone" } },
            VoltStriker = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "ArcLance", [2] = "VoltBlink", [3] = "StormPrison", [4] = "OverchargeField" } },
            Luma = { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "GlimmerBolt", [2] = "HavenMote", [3] = "RadiantWhip", [4] = "SolarBloom" } },
        },
        Equipped = { Primary = "Rifle", Secondary = "MicroRocket", Melee = "Skana", ActiveWeapon = "Rifle" },
        Weapons = { Rifle = makeLevelState(), Pistol = makeLevelState(), Shotgun = makeLevelState(), Launcher = makeLevelState(), MicroRocket = makeLevelState(), BeamTest = makeLevelState(), Skana = makeLevelState(), HeavyBlade = makeLevelState(), Fists = makeLevelState() },
        MasteryXP = 0,
        MasteryRank = 0,
        Wallet = { Coins = 500, Dallions = { Starter = 50, Tradeable = 0, Purchased = 0, Traded = 0 } },
        EquippedArmor = { Helmet = "StarterHelmet", Chest = "StarterChest", Gloves = "StarterGloves", Leggings = "StarterLeggings" },
        Inventory = {
            Materials = { Alloy = 80, Circuit = 35, Spark = 5 },
            Decorations = { BasicCrate = 2 },
            RoomTemplates = { OrbiterPod = true },
            Armor = {
                StarterHelmet = { ArmorId = "FieldHelmet", Rarity = "Common", Upgrade = 0 },
                StarterChest = { ArmorId = "FieldChest", Rarity = "Common", Upgrade = 0 },
                StarterGloves = { ArmorId = "FieldGloves", Rarity = "Common", Upgrade = 0 },
                StarterLeggings = { ArmorId = "FieldLeggings", Rarity = "Common", Upgrade = 0 },
                RaiderChestDrop = { ArmorId = "RaiderChest", Rarity = "Rare", Upgrade = 0 },
            },
            Attachments = {
                StarterRifleCharm = { AttachmentId = "StarterRifleCharm", Slot = "Charm", Rarity = "Common", Upgrade = 0 },
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
        StoryProgress = {
            ActiveStoryId = Storylines.DefaultStoryId,
            CompletedSteps = {},
            CompletedMissions = {},
            CompletedNodes = {},
            UnlockedLocations = { Moon = true },
        },
        MissionProgress = {},
        Clan = nil,
        Room = {
            TemplateId = "OrbiterPod",
            Privacy = "Private",
            Name = "Orbiter Room",
            Placed = {},
            Invites = {},
        },
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
    self:GetStore()
    if not self.AutosaveRunning then
        self.AutosaveRunning = true
        task.spawn(function()
            while self.AutosaveRunning and not self.Closing do
                task.wait(Config.Networking.ProfileAutosaveSeconds or 90)
                if self.Closing then break end
                self:SaveAll(false)
            end
        end)
    end
end

function ProfileService:Load(player)
    local profile = self.Profiles[player]
    if not profile then
        profile = self:LoadFromStore(player) or self:CreateDefaultProfile()
        self.Profiles[player] = profile
    end
    self:BackfillProfile(profile)
    local state = self.PlayerState:Get(player)
    state.Profile = profile
    state.EquippedWeaponId = profile.Equipped.ActiveWeapon
    state.EquippedMeleeId = profile.Equipped.Melee
    state.CanAimGlide = Weapons.CanAimGlide(state.EquippedWeaponId)
    self:Replicate(player)
    return profile
end

function ProfileService:LoadFromStore(player)
    local store = self:GetStore()
    if not store then
        self.Metadata[player] = { LocalOnly = true, LoadStatus = "NoStore" }
        return nil
    end

    local key = self:GetKey(player)
    local loadedProfile = nil
    local locked = false
    local ok, dataOrErr = pcall(function()
        return store:UpdateAsync(key, function(existing)
            if self:IsForeignLockActive(existing) then
                loadedProfile = self:ExtractProfile(existing)
                locked = true
                return nil
            end
            loadedProfile = self:ExtractProfile(existing) or self:CreateDefaultProfile()
            return self:BuildEnvelope(player, loadedProfile, false)
        end)
    end)

    if not ok then
        warn("[ProfileService] Load failed for " .. player.Name .. "; using local-only profile: " .. tostring(dataOrErr))
        self.Metadata[player] = { LocalOnly = true, LoadStatus = "LoadFailed", Error = tostring(dataOrErr) }
        return nil
    end

    if locked then
        warn("[ProfileService] Profile is session-locked for " .. player.Name .. "; using read-only copy")
        self.Metadata[player] = { ReadOnly = true, LoadStatus = "Locked" }
        return loadedProfile
    end

    local profile = self:ExtractProfile(dataOrErr) or loadedProfile
    self.Metadata[player] = { LocalOnly = false, ReadOnly = false, LoadStatus = "Loaded", LastLoadedAt = os.time() }
    return profile
end

function ProfileService:Save(player, release)
    local profile = self.Profiles[player]
    if not profile then return true end
    local metadata = self.Metadata[player] or {}
    if metadata.LocalOnly or metadata.ReadOnly then
        if release then
            self.Profiles[player] = nil
            self.Metadata[player] = nil
            self.DevBackups[player] = nil
        end
        return true
    end
    local store = self:GetStore()
    if not store then return false end

    local profileToSave = self.DevBackups[player] or profile
    self:BackfillProfile(profileToSave)
    local key = self:GetKey(player)
    local saved = false
    local ok, err = pcall(function()
        store:UpdateAsync(key, function(existing)
            if self:IsForeignLockActive(existing) then
                warn("[ProfileService] Refusing to save " .. player.Name .. " because another session owns the profile")
                return existing
            end
            saved = true
            return self:BuildEnvelope(player, profileToSave, release == true)
        end)
    end)
    if not ok then
        warn("[ProfileService] Save failed for " .. player.Name .. ": " .. tostring(err))
        return false
    end
    metadata.LastSavedAt = os.time()
    metadata.LastSaveReleased = release == true
    self.Metadata[player] = metadata
    if release then
        self.Profiles[player] = nil
        self.Metadata[player] = nil
        self.DevBackups[player] = nil
    end
    return saved
end

function ProfileService:SaveAll(release)
    local ok = true
    for player in pairs(self.Profiles) do
        if player and player.Parent then
            ok = self:Save(player, release) and ok
        elseif release then
            self.Profiles[player] = nil
            self.Metadata[player] = nil
            self.DevBackups[player] = nil
        end
    end
    return ok
end

function ProfileService:Shutdown()
    self.Closing = true
    self.AutosaveRunning = false
    return self:SaveAll(true)
end

function ProfileService:Get(player)
    local profile = self.Profiles[player] or self:Load(player)
    self:BackfillProfile(profile)
    return profile
end

function ProfileService:BackfillProfile(profile)
    if not profile then return end
    profile.SelectedFrameId = profile.SelectedFrameId or Frames.DefaultFrameId
    profile.UnlockedFrames = profile.UnlockedFrames or { EmberVanguard = true, AeroMedic = true, VoltStriker = true, Luma = true }
    profile.Frames = profile.Frames or {}
    profile.Frames.EmberVanguard = profile.Frames.EmberVanguard or { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "FireBolt", [2] = "FlameDash", [3] = "BurningField", [4] = "MeteorPulse" } }
    profile.Frames.AeroMedic = profile.Frames.AeroMedic or { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "WindNeedle", [2] = "GaleStep", [3] = "AeroPulse", [4] = "TempestZone" } }
    profile.Frames.VoltStriker = profile.Frames.VoltStriker or { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "ArcLance", [2] = "VoltBlink", [3] = "StormPrison", [4] = "OverchargeField" } }
    profile.UnlockedFrames.Luma = profile.UnlockedFrames.Luma ~= false and true or profile.UnlockedFrames.Luma
    profile.Frames.Luma = profile.Frames.Luma or { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = { [1] = "GlimmerBolt", [2] = "HavenMote", [3] = "RadiantWhip", [4] = "SolarBloom" } }
    profile.Frames.Luma.SelectedVariants = profile.Frames.Luma.SelectedVariants or { [1] = "GlimmerBolt", [2] = "HavenMote", [3] = "RadiantWhip", [4] = "SolarBloom" }
    profile.Equipped = profile.Equipped or { Primary = "Rifle", Secondary = "MicroRocket", Melee = "Skana", ActiveWeapon = "Rifle" }
    profile.Equipped.Primary = profile.Equipped.Primary or "Rifle"
    profile.Equipped.Secondary = profile.Equipped.Secondary or "MicroRocket"
    profile.Equipped.Melee = profile.Equipped.Melee or "Skana"
    profile.Equipped.ActiveWeapon = profile.Equipped.ActiveWeapon or profile.Equipped.Primary
    profile.Weapons = profile.Weapons or {}
    for _, weaponId in ipairs({ "Rifle", "Pistol", "Shotgun", "Launcher", "MicroRocket", "BeamTest", "Skana", "HeavyBlade", "Fists" }) do
        profile.Weapons[weaponId] = profile.Weapons[weaponId] or makeLevelState()
    end
    profile.Inventory = profile.Inventory or {}
    profile.Inventory.Materials = profile.Inventory.Materials or {}
    profile.Inventory.Armor = profile.Inventory.Armor or {}
    profile.Inventory.Attachments = profile.Inventory.Attachments or {}
    profile.Inventory.Mods = profile.Inventory.Mods or {}
    profile.Inventory.Decorations = profile.Inventory.Decorations or { BasicCrate = 2 }
    profile.Inventory.RoomTemplates = profile.Inventory.RoomTemplates or { OrbiterPod = true }
    profile.Wallet = profile.Wallet or { Coins = 0, Dallions = { Starter = 50, Tradeable = 0, Purchased = 0, Traded = 0 } }
    profile.Wallet.Coins = profile.Wallet.Coins or profile.Wallet.Credits or 0
    profile.Wallet.Credits = nil
    if type(profile.Wallet.Dallions) ~= "table" then
        local legacy = tonumber(profile.Wallet.Dallions or profile.Wallet.Premium) or 0
        profile.Wallet.Dallions = { Starter = math.min(legacy, 50), Tradeable = math.max(0, legacy - 50), Purchased = 0, Traded = 0 }
    end
    profile.Wallet.Premium = nil
    profile.Wallet.Dallions.Starter = profile.Wallet.Dallions.Starter or 50
    profile.Wallet.Dallions.Tradeable = profile.Wallet.Dallions.Tradeable or 0
    profile.Wallet.Dallions.Purchased = profile.Wallet.Dallions.Purchased or 0
    profile.Wallet.Dallions.Traded = profile.Wallet.Dallions.Traded or 0
    profile.MarketplacePurchases = profile.MarketplacePurchases or {}
    if profile.Clan ~= nil and typeof(profile.Clan) ~= "table" then
        profile.Clan = nil
    end
    profile.Room = profile.Room or { TemplateId = "OrbiterPod", Privacy = "Private", Name = "Orbiter Room", Placed = {}, Invites = {} }
    profile.Room.Placed = profile.Room.Placed or {}
    profile.Room.Invites = profile.Room.Invites or {}
    profile.Crafting = profile.Crafting or { Jobs = {}, Completed = {} }
    profile.Crafting.Jobs = profile.Crafting.Jobs or {}
    profile.Crafting.Completed = profile.Crafting.Completed or {}
    profile.EquippedMods = profile.EquippedMods or { Frame = { "Vitality", "Redirection" }, Weapon = { "Serration" }, Melee = { "PressurePoint" } }
    profile.EquippedArmor = profile.EquippedArmor or { Helmet = "StarterHelmet", Chest = "StarterChest", Gloves = "StarterGloves", Leggings = "StarterLeggings" }
    profile.MasteryXP = profile.MasteryXP or 0
    profile.MasteryRank = profile.MasteryRank or XP.GetMasteryRank(profile.MasteryXP)
end

function ProfileService:GetInventorySnapshot(player)
    local profile = self:Get(player)
    return {
        Materials = profile.Inventory.Materials,
        Armor = profile.Inventory.Armor,
        Attachments = profile.Inventory.Attachments,
        Mods = profile.Inventory.Mods,
        Weapons = profile.Weapons,
        Decorations = profile.Inventory.Decorations,
        RoomTemplates = profile.Inventory.RoomTemplates,
        Equipped = profile.Equipped,
        EquippedMods = profile.EquippedMods,
        EquippedArmor = profile.EquippedArmor,
        Wallet = profile.Wallet,
        Mastery = Mastery.GetSummary(profile),
    }
end

function ProfileService:CanSpendCurrency(player, costs)
    local profile = self:Get(player)
    profile.Wallet = profile.Wallet or {}
    for id, amount in pairs(costs or {}) do
        if id == "Credits" then id = "Coins" end
        if id == "Dallions" then
            local wallet = profile.Wallet.Dallions or {}
            if ((wallet.Starter or 0) + (wallet.Tradeable or 0)) < amount then
                return false, id
            end
        elseif (profile.Wallet[id] or 0) < amount then
            return false, id
        end
    end
    return true
end

function ProfileService:SpendCurrency(player, costs)
    local ok, missing = self:CanSpendCurrency(player, costs)
    if not ok then return false, missing end
    local profile = self:Get(player)
    for id, amount in pairs(costs or {}) do
        if id == "Credits" then id = "Coins" end
        if id == "Dallions" then
            local wallet = profile.Wallet.Dallions
            local remaining = amount
            local fromStarter = math.min(wallet.Starter or 0, remaining)
            wallet.Starter -= fromStarter
            remaining -= fromStarter
            if remaining > 0 then
                wallet.Tradeable = math.max(0, (wallet.Tradeable or 0) - remaining)
            end
        else
            profile.Wallet[id] = math.max(0, (profile.Wallet[id] or 0) - amount)
        end
    end
    self:Replicate(player)
    return true
end

function ProfileService:GrantCurrency(player, currencyId, amount)
    local profile = self:Get(player)
    amount = math.max(0, tonumber(amount) or 0)
    if currencyId == "Credits" then currencyId = "Coins" end
    if currencyId == "Dallions" then
        profile.Wallet.Dallions.Tradeable += amount
        profile.Wallet.Dallions.Purchased += amount
    else
        profile.Wallet[currencyId] = (profile.Wallet[currencyId] or 0) + amount
    end
    self:Replicate(player)
    return true
end

function ProfileService:GetDallionsTotal(player)
    local wallet = self:Get(player).Wallet.Dallions
    return (wallet.Starter or 0) + (wallet.Tradeable or 0)
end

function ProfileService:CanTradeDallions(player, amount)
    local profile = self:Get(player)
    if (profile.MasteryRank or 0) < 4 then return false, "MasteryTooLow" end
    amount = math.max(1, tonumber(amount) or 1)
    if (profile.Wallet.Dallions.Tradeable or 0) < amount then return false, "StarterDallionsNotTradeable" end
    return true
end

function ProfileService:RemoveTradeableDallions(player, amount)
    local ok = self:CanTradeDallions(player, amount)
    if not ok then return false end
    local profile = self:Get(player)
    amount = math.max(1, tonumber(amount) or 1)
    profile.Wallet.Dallions.Tradeable = math.max(0, (profile.Wallet.Dallions.Tradeable or 0) - amount)
    self:Replicate(player)
    return true
end

function ProfileService:GrantTradedDallions(player, amount)
    local profile = self:Get(player)
    amount = math.max(1, tonumber(amount) or 1)
    profile.Wallet.Dallions.Tradeable += amount
    profile.Wallet.Dallions.Traded += amount
    self:Replicate(player)
    return true
end

function ProfileService:GrantMaterial(player, materialId, amount)
    return self:GrantCraftedOutput(player, "Material", materialId, amount)
end

function ProfileService:CanSpendMaterials(player, costs)
    local profile = self:Get(player)
    for id, amount in pairs(costs or {}) do
        if (profile.Inventory.Materials[id] or 0) < amount then
            return false, id
        end
    end
    return true
end

function ProfileService:SpendMaterials(player, costs)
    local ok, missing = self:CanSpendMaterials(player, costs)
    if not ok then return false, missing end
    local profile = self:Get(player)
    for id, amount in pairs(costs or {}) do
        profile.Inventory.Materials[id] = math.max(0, (profile.Inventory.Materials[id] or 0) - amount)
    end
    self:Replicate(player)
    return true
end

function ProfileService:GrantCraftedOutput(player, outputType, outputId, amount)
    local profile = self:Get(player)
    amount = math.max(1, tonumber(amount) or 1)
    if outputType == "Weapon" then
        if not Weapons.Get(outputId) then return false end
        profile.Weapons[outputId] = profile.Weapons[outputId] or makeLevelState()
    elseif outputType == "Material" then
        profile.Inventory.Materials[outputId] = (profile.Inventory.Materials[outputId] or 0) + amount
    elseif outputType == "Decoration" then
        profile.Inventory.Decorations[outputId] = (profile.Inventory.Decorations[outputId] or 0) + amount
    elseif outputType == "RoomTemplate" then
        if not Rooms.GetTemplate(outputId) then return false end
        profile.Inventory.RoomTemplates[outputId] = true
    elseif outputType == "Mod" then
        profile.Inventory.Mods[outputId] = profile.Inventory.Mods[outputId] or { Rank = 0 }
    elseif outputType == "Attachment" then
        profile.Inventory.Attachments = profile.Inventory.Attachments or {}
        for _ = 1, amount do
            profile.Inventory.Attachments[HttpService:GenerateGUID(false)] = {
                AttachmentId = outputId,
                Rarity = "Common",
                Upgrade = 0,
            }
        end
    elseif outputType == "Currency" then
        return self:GrantCurrency(player, outputId, amount)
    elseif outputType == "Bundle" then
        profile.Inventory.Bundles = profile.Inventory.Bundles or {}
        profile.Inventory.Bundles[outputId] = (profile.Inventory.Bundles[outputId] or 0) + amount
    else
        return false
    end
    self:Replicate(player)
    return true
end

function ProfileService:CanRemoveTradable(player, itemType, itemId, amount)
    local profile = self:Get(player)
    amount = math.max(1, tonumber(amount) or 1)
    local tagId = itemId
    if itemType == "Armor" and profile.Inventory.Armor[itemId] then
        tagId = profile.Inventory.Armor[itemId].ArmorId
    elseif itemType == "Attachment" and profile.Inventory.Attachments and profile.Inventory.Attachments[itemId] then
        tagId = profile.Inventory.Attachments[itemId].AttachmentId
    end
    if not ItemTags.IsTradable(itemType, tagId) then return false end
    if itemType == "Material" then
        return (profile.Inventory.Materials[itemId] or 0) >= amount
    elseif itemType == "Decoration" then
        return (profile.Inventory.Decorations[itemId] or 0) >= amount
    elseif itemType == "Mod" then
        for _, group in pairs(profile.EquippedMods or {}) do
            for _, equippedModId in ipairs(group) do
                if equippedModId == itemId then return false end
            end
        end
        return profile.Inventory.Mods[itemId] ~= nil and amount == 1
    elseif itemType == "Armor" then
        for _, equippedUid in pairs(profile.EquippedArmor or {}) do
            if equippedUid == itemId then return false end
        end
        return profile.Inventory.Armor[itemId] ~= nil and amount == 1
    elseif itemType == "Attachment" then
        return profile.Inventory.Attachments ~= nil and profile.Inventory.Attachments[itemId] ~= nil and amount == 1
    elseif itemType == "Dallions" then
        local ok = self:CanTradeDallions(player, amount)
        return ok == true
    end
    return false
end

function ProfileService:RemoveTradable(player, itemType, itemId, amount)
    if not self:CanRemoveTradable(player, itemType, itemId, amount) then return false end
    local profile = self:Get(player)
    amount = math.max(1, tonumber(amount) or 1)
    local payload = nil
    if itemType == "Material" then
        profile.Inventory.Materials[itemId] = math.max(0, (profile.Inventory.Materials[itemId] or 0) - amount)
    elseif itemType == "Decoration" then
        profile.Inventory.Decorations[itemId] = math.max(0, (profile.Inventory.Decorations[itemId] or 0) - amount)
    elseif itemType == "Mod" then
        payload = { ModId = itemId, State = profile.Inventory.Mods[itemId] }
        profile.Inventory.Mods[itemId] = nil
    elseif itemType == "Armor" then
        payload = { ItemUid = itemId, State = profile.Inventory.Armor[itemId] }
        profile.Inventory.Armor[itemId] = nil
    elseif itemType == "Attachment" then
        payload = { ItemUid = itemId, State = profile.Inventory.Attachments[itemId] }
        profile.Inventory.Attachments[itemId] = nil
    elseif itemType == "Dallions" then
        return self:RemoveTradeableDallions(player, amount)
    else
        return false
    end
    self:Replicate(player)
    return true, payload
end

function ProfileService:GrantTradable(player, itemType, itemId, amount, payload)
    if itemType == "Material" then
        return self:GrantCraftedOutput(player, "Material", itemId, amount)
    elseif itemType == "Decoration" then
        return self:GrantCraftedOutput(player, "Decoration", itemId, amount)
    elseif itemType == "Mod" then
        local profile = self:Get(player)
        profile.Inventory.Mods[itemId] = payload and payload.State or { Rank = 0 }
        self:Replicate(player)
        return true
    elseif itemType == "Armor" then
        local profile = self:Get(player)
        local state = payload and payload.State
        if state and state.ArmorId then
            local uid = payload.ItemUid or HttpService:GenerateGUID(false)
            profile.Inventory.Armor[uid] = state
            self:Replicate(player)
            return true
        end
        local def = Armor.Get(itemId)
        if not def then return false end
        profile.Inventory.Armor[HttpService:GenerateGUID(false)] = { ArmorId = itemId, Rarity = def.MinRarity or "Common", Upgrade = 0 }
        self:Replicate(player)
        return true
    elseif itemType == "Attachment" then
        local profile = self:Get(player)
        profile.Inventory.Attachments = profile.Inventory.Attachments or {}
        local state = payload and payload.State
        if state and state.AttachmentId then
            local uid = payload.ItemUid or HttpService:GenerateGUID(false)
            profile.Inventory.Attachments[uid] = state
            self:Replicate(player)
            return true
        end
        profile.Inventory.Attachments[HttpService:GenerateGUID(false)] = { AttachmentId = itemId, Rarity = "Common", Upgrade = 0 }
        self:Replicate(player)
        return true
    elseif itemType == "Dallions" then
        return self:GrantTradedDallions(player, amount)
    end
    return false
end

function ProfileService:GetRoom(player)
    return self:Get(player).Room
end

function ProfileService:GetClan(player)
    return self:Get(player).Clan
end

function ProfileService:SetClan(player, clanData)
    local profile = self:Get(player)
    profile.Clan = clanData
    self:Replicate(player)
    return true
end

function ProfileService:CanUseMasteryGate(player, gateId)
    return Mastery.CanUse(self:Get(player), gateId)
end

function ProfileService:GetStoryProgress(player)
    local profile = self:Get(player)
    profile.StoryProgress = profile.StoryProgress or {
        ActiveStoryId = Storylines.DefaultStoryId,
        CompletedSteps = {},
        CompletedMissions = {},
        CompletedNodes = {},
        UnlockedLocations = { Moon = true },
    }
    profile.StoryProgress.CompletedSteps = profile.StoryProgress.CompletedSteps or {}
    profile.StoryProgress.CompletedMissions = profile.StoryProgress.CompletedMissions or {}
    profile.StoryProgress.CompletedNodes = profile.StoryProgress.CompletedNodes or {}
    profile.StoryProgress.UnlockedLocations = profile.StoryProgress.UnlockedLocations or { Moon = true }
    profile.StoryProgress.ActiveStoryId = profile.StoryProgress.ActiveStoryId or Storylines.DefaultStoryId
    return profile.StoryProgress
end

function ProfileService:MarkMissionComplete(player, missionId, nodeId)
    local progress = self:GetStoryProgress(player)
    local unlockedGates = {}
    if missionId then
        progress.CompletedMissions[missionId] = true
    end
    if nodeId then
        progress.CompletedNodes[nodeId] = true
    end

    local story = Storylines.Get(progress.ActiveStoryId)
    for _, step in ipairs(story and story.Steps or {}) do
        local matchesMission = missionId and step.MissionId == missionId
        local matchesNode = nodeId and step.NodeId == nodeId
        if step.Kind == "CompleteNode" and (matchesMission or matchesNode) then
            progress.CompletedSteps[step.Id] = true
            if step.Id == "OpenEarthGate" then
                progress.UnlockedLocations.Earth = true
                table.insert(unlockedGates, "EarthGate")
            elseif step.Id == "CompleteMarsGate" then
                progress.UnlockedLocations.Hub = true
                progress.UnlockedLocations.Mars = true
                table.insert(unlockedGates, "MarsGate")
                table.insert(unlockedGates, "AtlasShardGate")
            elseif step.Id == "DefeatDeadeye" then
                progress.UnlockedLocations.Mars = true
            end
        end
    end
    self:Replicate(player)
    if self.StoryReplicator then
        self.StoryReplicator(player)
    end
    return unlockedGates
end

function ProfileService:MarkStoryStepComplete(player, stepId)
    local progress = self:GetStoryProgress(player)
    local step = Storylines.GetStep(progress.ActiveStoryId, stepId)
    if not step then return false end
    progress.CompletedSteps[step.Id] = true
    self:Replicate(player)
    if self.StoryReplicator then
        self.StoryReplicator(player)
    end
    return true
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

function ProfileService:ReplicateEquipmentState(player)
    local state = self.PlayerState:Get(player)
    Net.GetRemoteEvent(Net.RemoteEvents.StateUpdate):FireClient(player, {
        EquippedWeaponId = state.EquippedWeaponId,
        EquippedMeleeId = state.EquippedMeleeId,
        CanAimGlide = state.CanAimGlide,
        DevMode = state.DevMode,
        LocationId = state.LocationId,
        SafeZone = state.SafeZone,
        TrainingRange = state.TrainingRange,
    })
end

function ProfileService:EquipWeapon(player, slot, weaponId)
    local profile = self:Get(player)
    local def = Weapons.Get(weaponId)
    if not def then return false end
    if not profile.Weapons[weaponId] then return false end

    profile.Equipped = profile.Equipped or { Primary = "Rifle", Secondary = "MicroRocket", Melee = "Skana", ActiveWeapon = "Rifle" }
    local state = self.PlayerState:Get(player)
    slot = slot or (def.Kind == "Melee" and "Melee" or "Primary")

    if slot == "Melee" then
        if def.Kind ~= "Melee" then return false end
        profile.Equipped.Melee = weaponId
        state.EquippedMeleeId = weaponId
    elseif slot == "Primary" or slot == "Secondary" then
        if def.Kind ~= "Ranged" then return false end
        profile.Equipped[slot] = weaponId
        profile.Equipped.ActiveWeapon = weaponId
        state.EquippedWeaponId = weaponId
        state.CanAimGlide = Weapons.CanAimGlide(weaponId)
    elseif slot == "Active" then
        if def.Kind ~= "Ranged" then return false end
        profile.Equipped.ActiveWeapon = weaponId
        if profile.Equipped.Primary ~= weaponId and profile.Equipped.Secondary ~= weaponId then
            profile.Equipped.Primary = weaponId
        end
        state.EquippedWeaponId = weaponId
        state.CanAimGlide = Weapons.CanAimGlide(weaponId)
    else
        return false
    end

    self:Replicate(player)
    self:ReplicateEquipmentState(player)
    return true
end

function ProfileService:ResetProgress(player)
    local profile = self:CreateDefaultProfile()
    self:BackfillProfile(profile)
    self.Profiles[player] = profile
    self.DevBackups[player] = nil
    local state = self.PlayerState:Get(player)
    state.Profile = profile
    state.EquippedWeaponId = profile.Equipped.ActiveWeapon
    state.EquippedMeleeId = profile.Equipped.Melee
    state.CanAimGlide = Weapons.CanAimGlide(state.EquippedWeaponId)
    state.DevMode = "ResetProgress"
    state.LocationId = "Moon"
    state.SafeZone = true
    state.TrainingRange = false
    state.WeaponRuntime = {}
    state.AbilityCooldowns = {}
    self:Replicate(player)
    self:ReplicateEquipmentState(player)
    return true
end

local function teleportCharacter(player, cf)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        root.CFrame = cf
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

function ProfileService:EnsureDevBackup(player)
    if self.DevBackups[player] then return end
    local profile = self.Profiles[player]
    if profile then
        self.DevBackups[player] = deepCopy(profile)
    end
end

function ProfileService:RestoreDevBackup(player)
    local backup = self.DevBackups[player]
    if not backup then return false end
    local restored = deepCopy(backup)
    self:BackfillProfile(restored)
    self.Profiles[player] = restored
    self.DevBackups[player] = nil

    local state = self.PlayerState:Get(player)
    state.Profile = restored
    state.EquippedWeaponId = restored.Equipped.ActiveWeapon
    state.EquippedMeleeId = restored.Equipped.Melee
    state.CanAimGlide = Weapons.CanAimGlide(state.EquippedWeaponId)
    state.WeaponRuntime = {}
    state.AbilityCooldowns = {}
    return true
end

function ProfileService:ApplyDevelopmentMode(player, mode, startId)
    mode = tostring(mode or "NormalPlay")
    if mode == "ResetProgress" then
        return self:ResetProgress(player)
    end

    if mode == "NormalPlay" then
        self:RestoreDevBackup(player)
    else
        self:EnsureDevBackup(player)
    end

    local profile = self:Get(player)
    local progress = self:GetStoryProgress(player)
    local state = self.PlayerState:Get(player)
    state.DevMode = mode

    if mode == "DevSpace" then
        for frameId in pairs(Frames.ById or {}) do
            profile.UnlockedFrames[frameId] = true
            profile.Frames[frameId] = profile.Frames[frameId] or { Level = 1, XP = 0, CE = {}, EnemyCECounts = {}, SelectedVariants = {} }
        end
        for weaponId in pairs(Weapons.ById or {}) do
            profile.Weapons[weaponId] = profile.Weapons[weaponId] or makeLevelState()
        end
        progress.UnlockedLocations.Moon = true
        progress.UnlockedLocations.Earth = true
        progress.UnlockedLocations.Hub = true
        progress.UnlockedLocations.Mars = true
        progress.UnlockedLocations.AtlasShard = true
        state.LocationId = "DevSpace"
        state.SafeZone = false
        state.TrainingRange = true
        teleportCharacter(player, CFrame.new(0, 10, 0))
    elseif mode == "NormalPlay" then
        state.DevMode = "NormalPlay"
        state.LocationId = state.LocationId == "DevSpace" and "Moon" or (state.LocationId or "Moon")
        state.SafeZone = state.LocationId == "Hub" or state.LocationId == "Moon"
        state.TrainingRange = false
    elseif mode == "StartAt" then
        startId = tostring(startId or "MoonStart")
        state.DevMode = "StartAt:" .. startId
        progress.UnlockedLocations.Moon = true
        if startId == "EarthStart" or startId == "HubStart" or startId == "MarsStart" then
            progress.UnlockedLocations.Earth = true
            progress.CompletedSteps.OpenEarthGate = true
            progress.CompletedNodes.Moon_CraterGate = true
        end
        if startId == "HubStart" or startId == "MarsStart" then
            progress.UnlockedLocations.Hub = true
            progress.CompletedSteps.CompleteMarsGate = true
        end
        if startId == "MarsStart" then
            progress.UnlockedLocations.Mars = true
            progress.CompletedSteps.DefeatDeadeye = true
        end
        local locationByStart = {
            MoonStart = "Moon",
            EarthStart = "Earth",
            HubStart = "Hub",
            MarsStart = "Mars",
        }
        state.LocationId = locationByStart[startId] or "Moon"
        state.SafeZone = state.LocationId == "Hub" or state.LocationId == "Moon"
        state.TrainingRange = state.LocationId ~= "Hub"
        teleportCharacter(player, CFrame.new(0, 10, 0))
    else
        return false
    end

    state.EquippedWeaponId = profile.Equipped.ActiveWeapon
    state.EquippedMeleeId = profile.Equipped.Melee
    state.CanAimGlide = Weapons.CanAimGlide(state.EquippedWeaponId)
    self:Replicate(player)
    self:ReplicateEquipmentState(player)
    if self.StoryReplicator then
        self.StoryReplicator(player)
    end
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
