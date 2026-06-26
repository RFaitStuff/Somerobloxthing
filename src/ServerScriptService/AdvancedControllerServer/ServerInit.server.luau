--!nonstrict
local Players = game:GetService("Players")

local RemoteFactory = require(script.Parent:WaitForChild("RemoteFactory"))
RemoteFactory.Ensure()

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local CollisionService = require(script.Parent:WaitForChild("CollisionService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local ActionValidator = require(script.Parent:WaitForChild("ActionValidator"))
local MeleeServer = require(script.Parent:WaitForChild("MeleeService"))
local StatusService = require(script.Parent:WaitForChild("StatusService"))
local AntiCheat = require(script.Parent:WaitForChild("AntiCheatService"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Net"))
local Debug = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Debug"))

local states = PlayerStateService.new()
local collision = CollisionService.new()
local inventory = InventoryService.new(states)
local validator = ActionValidator.new(states)
local melee = MeleeServer.new(states)
local status = StatusService.new(states)
local antiCheat = AntiCheat.new(states)
local data = DataService.new()

Debug.Try(Debug.Channels.Startup, "CollisionService:Start", function() collision:Start() end)
Debug.Try(Debug.Channels.Startup, "InventoryService:Start", function() inventory:Start() end)
Debug.Try(Debug.Channels.Startup, "StatusService:Start", function() status:Start() end)
Debug.Try(Debug.Channels.Startup, "MeleeService:Start", function() melee:Start(status) end)
Debug.Try(Debug.Channels.Startup, "AntiCheatService:Start", function() antiCheat:Start() end)
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
