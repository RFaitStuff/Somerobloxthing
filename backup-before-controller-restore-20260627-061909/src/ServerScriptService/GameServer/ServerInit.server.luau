--!nonstrict
local Players = game:GetService("Players")

local Core = script.Parent:WaitForChild("Core")
local Combat = script.Parent:WaitForChild("Combat")
local Security = script.Parent:WaitForChild("Security")

local Remotes = require(Core:WaitForChild("Remotes"))
Remotes.Ensure()

local PlayerStates = require(Core:WaitForChild("PlayerStates"))
local Collision = require(Core:WaitForChild("Collision"))
local Loadout = require(Core:WaitForChild("Loadout"))
local SettingsData = require(Core:WaitForChild("SettingsData"))
local Melee = require(Combat:WaitForChild("Melee"))
local Statuses = require(Combat:WaitForChild("Statuses"))
local Actions = require(Security:WaitForChild("Actions"))
local MovementChecks = require(Security:WaitForChild("MovementChecks"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Debug = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Debug"))
local AnimationRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimationRegistry"))

local states = PlayerStates.new()
local collision = Collision.new()
local inventory = Loadout.new(states)
local validator = Actions.new(states)
local melee = Melee.new(states)
local status = Statuses.new(states)
local antiCheat = MovementChecks.new(states)
local data = SettingsData.new()

AnimationRegistry.Ensure()
Debug.Try(Debug.Channels.Startup, "Collision:Start", function() collision:Start() end)
Debug.Try(Debug.Channels.Startup, "Loadout:Start", function() inventory:Start() end)
Debug.Try(Debug.Channels.Startup, "Statuses:Start", function() status:Start() end)
Debug.Try(Debug.Channels.Startup, "Melee:Start", function() melee:Start(status) end)
if Config.Security.AntiCheatEnabled then
    Debug.Try(Debug.Channels.Startup, "MovementChecks:Start", function() antiCheat:Start() end)
else
    Debug.Warn(Debug.Channels.Startup, "MovementChecks disabled while movement is being tuned")
end
Debug.Try(Debug.Channels.Startup, "SettingsData:Start", function() data:Start() end)

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
    local function setupCharacter(character)
        Debug.Try(Debug.Channels.Startup, "CharacterAdded", function()
            collision:ApplyCharacter(character)
            task.wait(0.25)
            inventory:Replicate(player)
        end)
    end
    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        task.spawn(setupCharacter, player.Character)
    end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end
