--!nonstrict
local Players = game:GetService("Players")

local Core = script.Parent:WaitForChild("Core")
local Combat = script.Parent:WaitForChild("Combat")
local Security = script.Parent:WaitForChild("Security")
local Systems = script.Parent:WaitForChild("Systems")

local Remotes = require(Core:WaitForChild("Remotes"))
Remotes.Ensure()

local PlayerStates = require(Core:WaitForChild("PlayerStates"))
local Collision = require(Core:WaitForChild("Collision"))
local Loadout = require(Core:WaitForChild("Loadout"))
local SettingsData = require(Core:WaitForChild("SettingsData"))
local ValidationAudit = require(Core:WaitForChild("ValidationAudit"))
local Melee = require(Combat:WaitForChild("Melee"))
local Statuses = require(Combat:WaitForChild("Statuses"))
local Actions = require(Security:WaitForChild("Actions"))
local MovementChecks = require(Security:WaitForChild("MovementChecks"))
local ProfileService = require(Systems:WaitForChild("ProfileService"))
local FrameService = require(Systems:WaitForChild("FrameService"))
local ResourceService = require(Systems:WaitForChild("ResourceService"))
local RewardService = require(Systems:WaitForChild("RewardService"))
local CombatService = require(Systems:WaitForChild("CombatService"))
local EnemyService = require(Systems:WaitForChild("EnemyService"))
local AbilityService = require(Systems:WaitForChild("AbilityService"))
local WeaponService = require(Systems:WaitForChild("WeaponService"))
local MissionService = require(Systems:WaitForChild("MissionService"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Debug = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Debug"))
local AnimationRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimationRegistry"))
local FramesData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("Frames"))
local WeaponsData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("Weapons"))
local MeleeData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("Melee"))
local EnemiesData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("Enemies"))

local states = PlayerStates.new()
local collision = Collision.new()
local inventory = Loadout.new(states)
local validator = Actions.new(states)
local melee = Melee.new(states)
local status = Statuses.new(states)
local antiCheat = MovementChecks.new(states)
local data = SettingsData.new()
local profiles = ProfileService.new(states)
local frames = FrameService.new(states, profiles)
local resources = ResourceService.new(states, frames)
local rewards = RewardService.new(states, profiles, frames)
local combatPipeline = CombatService.new(states, status, resources, rewards)
local enemies = EnemyService.new(states, combatPipeline, rewards)
local abilities = AbilityService.new(states, profiles, resources, combatPipeline)
local weapons = WeaponService.new(states, profiles, combatPipeline)
local missions = MissionService.new(states, enemies, rewards)

ValidationAudit.Init()
status:SetCombat(combatPipeline)
enemies:SetMissionService(missions)

AnimationRegistry.Ensure()
Debug.Try(Debug.Channels.Startup, "Collision:Start", function() collision:Start() end)
Debug.Try(Debug.Channels.Startup, "Loadout:Start", function() inventory:Start() end)
Debug.Try(Debug.Channels.Startup, "Statuses:Start", function() status:Start() end)
Debug.Try(Debug.Channels.Startup, "Melee:Start", function() melee:Start(status, combatPipeline) end)
if Config.Security.AntiCheatEnabled then
    Debug.Try(Debug.Channels.Startup, "MovementChecks:Start", function() antiCheat:Start() end)
else
    Debug.Warn(Debug.Channels.Startup, "MovementChecks disabled while movement is being tuned")
end
Debug.Try(Debug.Channels.Startup, "SettingsData:Start", function() data:Start() end)
Debug.Try(Debug.Channels.Startup, "ProfileService:Start", function() profiles:Start() end)
Debug.Try(Debug.Channels.Startup, "ResourceService:Start", function() resources:Start() end)
Debug.Try(Debug.Channels.Startup, "RewardService:Start", function() rewards:Start() end)
Debug.Try(Debug.Channels.Startup, "EnemyService:Start", function() enemies:Start() end)
Debug.Try(Debug.Channels.Startup, "AbilityService:Start", function() abilities:Start() end)
Debug.Try(Debug.Channels.Startup, "WeaponService:Start", function() weapons:Start() end)
Debug.Try(Debug.Channels.Startup, "MissionService:Start", function() missions:Start() end)

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
        elseif payload.Action == "GrantFrameXP" then
            if profiles:AddDebugFrameXP(player, tonumber(payload.Amount) or 0) then
                frames:Refresh(player)
                resources:Ensure(player)
                resources:Replicate(player)
            else
                ValidationAudit.Reject(player, "Profile", "InvalidXPGrant")
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
            enemies:Spawn(player, payload.Role or "Gunner")
        elseif payload.Action == "Wave" then
            enemies:SpawnWave(player, payload.Role or "Gunner", math.clamp(tonumber(payload.Count) or 5, 1, 20))
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
