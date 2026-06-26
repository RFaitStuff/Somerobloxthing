--!nonstrict
local Players = game:GetService("Players")

local Core = script.Parent:WaitForChild("Core")
local Combat = script.Parent:WaitForChild("Combat")
local Security = script.Parent:WaitForChild("Security")

local RemoteFactory = require(Core:WaitForChild("RemoteFactory"))
RemoteFactory.Ensure()

local PlayerStateService = require(Core:WaitForChild("PlayerStateService"))
local CollisionService = require(Core:WaitForChild("CollisionService"))
local InventoryService = require(Core:WaitForChild("InventoryService"))
local DataService = require(Core:WaitForChild("DataService"))
local MeleeServer = require(Combat:WaitForChild("MeleeService"))
local StatusService = require(Combat:WaitForChild("StatusService"))
local ActionValidator = require(Security:WaitForChild("ActionValidator"))
local AntiCheat = require(Security:WaitForChild("AntiCheatService"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Net"))
local Debug = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Debug"))
local AnimationRegistry = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("AnimationRegistry"))

local states = PlayerStateService.new()
local collision = CollisionService.new()
local inventory = InventoryService.new(states)
local validator = ActionValidator.new(states)
local melee = MeleeServer.new(states)
local status = StatusService.new(states)
local antiCheat = AntiCheat.new(states)
local data = DataService.new()

AnimationRegistry.Ensure()
Debug.Try(Debug.Channels.Startup, "CollisionService:Start", function() collision:Start() end)
Debug.Try(Debug.Channels.Startup, "InventoryService:Start", function() inventory:Start() end)
Debug.Try(Debug.Channels.Startup, "StatusService:Start", function() status:Start() end)
Debug.Try(Debug.Channels.Startup, "MeleeService:Start", function() melee:Start(status) end)
if Config.Security.AntiCheatEnabled then
    Debug.Try(Debug.Channels.Startup, "AntiCheatService:Start", function() antiCheat:Start() end)
else
    Debug.Warn(Debug.Channels.Startup, "AntiCheatService disabled while movement is being tuned")
end
Debug.Try(Debug.Channels.Startup, "DataService:Start", function() data:Start() end)

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
