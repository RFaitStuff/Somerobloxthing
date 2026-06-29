--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = script.Parent
local Core = Root:WaitForChild("Core")
local Combat = Root:WaitForChild("Combat")
local Security = Root:WaitForChild("Security")
local Progression = Root:WaitForChild("Progression")
local EnemiesFolder = Root:WaitForChild("Enemies")
local MissionsFolder = Root:WaitForChild("Missions")
local WorldFolder = Root:WaitForChild("World")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Debug = require(Shared:WaitForChild("Core"):WaitForChild("Debug"))
local AnimationRegistry = require(Shared:WaitForChild("Core"):WaitForChild("AnimationRegistry"))
local FramesData = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local WeaponsData = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local MeleeData = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Melee"))
local EnemiesData = require(Shared:WaitForChild("Data"):WaitForChild("Enemies"):WaitForChild("Enemies"))

local Remotes = require(Core:WaitForChild("Remotes"))
local PlayerStates = require(Core:WaitForChild("PlayerStates"))
local Collision = require(Core:WaitForChild("Collision"))
local Loadout = require(Core:WaitForChild("Loadout"))
local SettingsData = require(Core:WaitForChild("SettingsData"))
local ValidationAudit = require(Core:WaitForChild("ValidationAudit"))

local Melee = require(Combat:WaitForChild("Melee"))
local Statuses = require(Combat:WaitForChild("Statuses"))
local CombatService = require(Combat:WaitForChild("CombatService"))
local AbilityService = require(Combat:WaitForChild("AbilityService"))
local WeaponService = require(Combat:WaitForChild("WeaponService"))

local Actions = require(Security:WaitForChild("Actions"))
local MovementChecks = require(Security:WaitForChild("MovementChecks"))

local ProfileService = require(Progression:WaitForChild("ProfileService"))
local FrameService = require(Progression:WaitForChild("FrameService"))
local ResourceService = require(Progression:WaitForChild("ResourceService"))
local RewardService = require(Progression:WaitForChild("RewardService"))

local EnemyService = require(EnemiesFolder:WaitForChild("EnemyService"))
local MissionService = require(MissionsFolder:WaitForChild("MissionService"))
local WorldService = require(WorldFolder:WaitForChild("WorldService"))

Remotes.Ensure()
ValidationAudit.Init()
AnimationRegistry.Ensure()

local states = PlayerStates.new()
local collision = Collision.new()
local inventory = Loadout.new(states)
local validator = Actions.new(states)
local melee = Melee.new(states)
local status = Statuses.new(states)
local antiCheat = MovementChecks.new(states)
local settingsData = SettingsData.new()
local profiles = ProfileService.new(states)
local frames = FrameService.new(states, profiles)
local resources = ResourceService.new(states, frames)
local rewards = RewardService.new(states, profiles, frames)
local combatPipeline = CombatService.new(states, status, resources, rewards)
local enemies = EnemyService.new(states, combatPipeline, rewards)
local abilities = AbilityService.new(states, profiles, resources, combatPipeline)
local weapons = WeaponService.new(states, profiles, combatPipeline)
local missions = MissionService.new(states, enemies, rewards)
local world = WorldService.new(states, missions)

status:SetCombat(combatPipeline)
enemies:SetMissionService(missions)

local function startService(label, callback)
    Debug.Try(Debug.Channels.Startup, label, callback)
end

startService("Collision:Start", function() collision:Start() end)
startService("Loadout:Start", function() inventory:Start() end)
startService("Statuses:Start", function() status:Start() end)
startService("Melee:Start", function() melee:Start(status, combatPipeline) end)
if Config.Security.AntiCheatEnabled then
    startService("MovementChecks:Start", function() antiCheat:Start() end)
else
    Debug.Warn(Debug.Channels.Startup, "MovementChecks disabled while movement is being tuned")
end
startService("SettingsData:Start", function() settingsData:Start() end)
startService("ProfileService:Start", function() profiles:Start() end)
startService("ResourceService:Start", function() resources:Start() end)
startService("RewardService:Start", function() rewards:Start() end)
startService("EnemyService:Start", function() enemies:Start() end)
startService("AbilityService:Start", function() abilities:Start() end)
startService("WeaponService:Start", function() weapons:Start() end)
startService("MissionService:Start", function() missions:Start() end)
startService("WorldService:Start", function() world:Start() end)

Net.GetRemoteEvent(Net.RemoteEvents.ActionRequest).OnServerEvent:Connect(function(player, actionName, payload)
    Debug.Try(Debug.Channels.Validation, "ActionRequest", function()
        if validator:Validate(player, actionName, payload) then
            local state = states:Get(player)
            state.LastActions[actionName] = os.clock()
        end
    end)
end)

local function setupPlayer(player)
    states:Get(player)
    profiles:Load(player)
    frames:Refresh(player)
    resources:Ensure(player)
    profiles:Replicate(player)

    local function setupCharacter(character)
        Debug.Try(Debug.Channels.Startup, "CharacterAdded", function()
            local state = states:Get(player)
            state.IsMeleeBlocking = false
            state.MeleeRuntime = {}
            collision:ApplyCharacter(character)
            task.wait(0.25)
            inventory:Replicate(player)
            frames:Refresh(player)
            resources:Ensure(player)
            resources:Replicate(player)
            weapons:ReplicateEquipped(player)
        end)
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        task.spawn(setupCharacter, player.Character)
    end
end

Net.GetRemoteEvent(Net.RemoteEvents.ProfileRequest).OnServerEvent:Connect(function(player, payload)
    Debug.Try(Debug.Channels.Validation, "ProfileUpdateRequest", function()
        if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Profile", "BadPayload") return end
        if payload.Action == "SelectFrame" then
            if profiles:SelectFrame(player, payload.FrameId) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidFrame")
            end
        elseif payload.Action == "SelectAbility" then
            if not profiles:SelectAbilityVariant(player, tonumber(payload.Slot), payload.AbilityId) then
                ValidationAudit.Reject(player, "Profile", "InvalidAbilityVariant")
            end
        elseif payload.Action == "UnlockFrame" then
            if not profiles:UnlockFrame(player, payload.FrameId) then
                ValidationAudit.Reject(player, "Profile", "InvalidUnlock")
            end
        elseif payload.Action == "EquipMod" then
            if profiles:EquipMod(player, payload.Group, payload.ModId) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidModEquip")
            end
        elseif payload.Action == "UnequipMod" then
            if profiles:UnequipMod(player, payload.Group, payload.ModId) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidModUnequip")
            end
        elseif payload.Action == "EquipArmor" then
            if profiles:EquipArmor(player, payload.ItemUid) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidArmorEquip")
            end
        elseif payload.Action == "UpgradeArmor" then
            if profiles:DebugUpgradeArmor(player, payload.ItemUid) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidArmorUpgrade")
            end
        elseif payload.Action == "GrantFrameXP" then
            if profiles:AddDebugFrameXP(player, tonumber(payload.Amount) or 0) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidXPGrant")
            end
        elseif payload.Action == "GrantWeaponXP" then
            if not profiles:AddDebugWeaponXP(player, payload.WeaponId, tonumber(payload.Amount) or 0) then
                ValidationAudit.Reject(player, "Profile", "InvalidWeaponXPGrant")
            end
        elseif payload.Action == "SetWeaponLevel" then
            if not profiles:SetDebugWeaponLevel(player, payload.WeaponId, tonumber(payload.Level) or 1) then
                ValidationAudit.Reject(player, "Profile", "InvalidWeaponLevel")
            end
        elseif payload.Action == "GrantMasteryXP" then
            if not profiles:AddDebugMasteryXP(player, tonumber(payload.Amount) or 0) then
                ValidationAudit.Reject(player, "Profile", "InvalidMasteryXPGrant")
            end
        elseif payload.Action == "SetFrameLevel" then
            if profiles:SetDebugFrameLevel(player, tonumber(payload.Level) or 1) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidFrameLevel")
            end
        elseif payload.Action == "RequestSnapshot" then
            frames:Refresh(player)
            resources:Ensure(player)
            profiles:Replicate(player)
            resources:Replicate(player)
        else
            ValidationAudit.Reject(player, "Profile", "UnknownAction")
        end
    end)
end)

Net.GetRemoteEvent(Net.RemoteEvents.EnemyRequest).OnServerEvent:Connect(function(player, payload)
    Debug.Try(Debug.Channels.Validation, "EnemyRequest", function()
        if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Enemy", "BadPayload") return end
        if payload.Action == "Spawn" then
            enemies:Spawn(player, payload.EnemyId or payload.Role or "Gunner")
        elseif payload.Action == "Wave" then
            enemies:SpawnWave(player, payload.EnemyId or payload.Role or "Gunner", math.clamp(tonumber(payload.Count) or 5, 1, 20))
        elseif payload.Action == "Clear" then
            enemies:Clear()
        elseif payload.Action == "SetAIPaused" then
            enemies:SetAIPaused(payload.Paused == true)
        else
            ValidationAudit.Reject(player, "Enemy", "UnknownAction")
        end
    end)
end)

local function applyNumber(target, key, value)
    value = tonumber(value)
    if not target or type(key) ~= "string" or not value then return false end
    target[key] = value
    return true
end

Net.GetRemoteEvent(Net.RemoteEvents.TuningRequest).OnServerEvent:Connect(function(player, payload)
    Debug.Try(Debug.Channels.Validation, "TuningRequest", function()
        if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Tuning", "BadPayload") return end
        local ok = false
        if payload.TargetType == "FrameStat" then
            local frame = FramesData.Get(payload.Id)
            ok = applyNumber(frame and frame.BaseStats, payload.Key, payload.Value)
        elseif payload.TargetType == "Weapon" then
            local weapon = WeaponsData.Get(payload.Id)
            ok = applyNumber(weapon, payload.Key, payload.Value)
        elseif payload.TargetType == "Enemy" then
            local enemy = EnemiesData[payload.Id]
            ok = applyNumber(enemy, payload.Key, payload.Value)
        elseif payload.TargetType == "MeleeAttack" then
            local attack = MeleeData.GetAttack(payload.Id, payload.Variant, tonumber(payload.ComboIndex) or 1)
            ok = applyNumber(attack, payload.Key, payload.Value)
        end
        if ok then
            Net.GetRemoteEvent(Net.RemoteEvents.TuningUpdate):FireAllClients(payload)
        else
            ValidationAudit.Reject(player, "Tuning", "InvalidTarget")
        end
    end)
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
    profiles:Save(player)
end)
