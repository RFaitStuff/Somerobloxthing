--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Net"))
local Debug = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Debug"))

local Root = script.Parent
local ClientState = require(Root:WaitForChild("Core"):WaitForChild("ClientState"))
local InputClient = require(Root:WaitForChild("Core"):WaitForChild("InputClient"))
local CameraClient = require(Root:WaitForChild("Camera"):WaitForChild("CameraClient"))
local KinematicClient = require(Root:WaitForChild("Movement"):WaitForChild("MovementClient"))
local AnimationClient = require(Root:WaitForChild("Animation"):WaitForChild("AnimationClient"))
local MeleeClient = require(Root:WaitForChild("Combat"):WaitForChild("MeleeClient"))
local GameplayCombatClient = require(Root:WaitForChild("Combat"):WaitForChild("GameplayCombatClient"))
local CombatFeedbackClient = require(Root:WaitForChild("Combat"):WaitForChild("CombatFeedbackClient"))
local SettingsClient = require(Root:WaitForChild("Settings"):WaitForChild("SettingsClient"))
local DebugVisualizer = require(Root:WaitForChild("DevTools"):WaitForChild("DebugVisualizer"))
local TuningMenuClient = require(Root:WaitForChild("DevTools"):WaitForChild("TuningMenuClient"))
local MoveLabelClient = require(Root:WaitForChild("DevTools"):WaitForChild("MoveLabelClient"))
local GameSystemsTestClient = require(Root:WaitForChild("DevTools"):WaitForChild("GameSystemsTestClient"))
local GameplayHudClient = require(Root:WaitForChild("UI"):WaitForChild("GameplayHudClient"))
local EquipmentClient = require(Root:WaitForChild("UI"):WaitForChild("EquipmentClient"))

local player = Players.LocalPlayer
local state = ClientState.new()
local input = InputClient.new(state)
local camera = CameraClient.new(state, input)
local animation = AnimationClient.new(state)
local motor = KinematicClient.new(state, input, camera, animation)
local melee = MeleeClient.new(state, input, motor, animation)
local gameplayCombat = GameplayCombatClient.new(state, input, camera)
local combatFeedback = CombatFeedbackClient.new()
local settings = SettingsClient.new(state, input)
local debugVisualizer = DebugVisualizer.new(state, input, camera, motor, melee)
local tuningMenu = TuningMenuClient.new(state, input, camera, motor, animation)
local moveLabel = MoveLabelClient.new(state, input, camera, motor)
local gameSystemsUi = GameSystemsTestClient.new(state, input, camera)
local gameplayHud = GameplayHudClient.new(state)
local equipmentUi = EquipmentClient.new(state, input)

local function bind(character)
    Debug.Log(Debug.Channels.Startup, "Binding character %s", character:GetFullName())
    motor:BindCharacter(character)
    camera:BindCharacter(character)
    animation:BindCharacter(character)
end

Debug.Try(Debug.Channels.Startup, "InputClient:Start", function() input:Start() end)
Debug.Try(Debug.Channels.Startup, "CameraClient:Start", function() camera:Start() end)
Debug.Try(Debug.Channels.Startup, "MovementClient:Start", function() motor:Start() end)
Debug.Try(Debug.Channels.Startup, "MeleeClient:Start", function() melee:Start() end)
Debug.Try(Debug.Channels.Startup, "GameplayCombatClient:Start", function() gameplayCombat:Start() end)
Debug.Try(Debug.Channels.Startup, "CombatFeedbackClient:Start", function() combatFeedback:Start() end)
Debug.Try(Debug.Channels.Startup, "SettingsClient:Start", function() settings:Start() end)
Debug.Try(Debug.Channels.Startup, "DebugVisualizer:Start", function() debugVisualizer:Start() end)
Debug.Try(Debug.Channels.Startup, "TuningMenuClient:Start", function() tuningMenu:Start() end)
Debug.Try(Debug.Channels.Startup, "MoveLabelClient:Start", function() moveLabel:Start() end)
Debug.Try(Debug.Channels.Startup, "GameSystemsTestClient:Start", function() gameSystemsUi:Start() end)
Debug.Try(Debug.Channels.Startup, "GameplayHudClient:Start", function() gameplayHud:Start() end)
Debug.Try(Debug.Channels.Startup, "EquipmentClient:Start", function() equipmentUi:Start() end)

Net.GetRemoteEvent(Net.RemoteEvents.StateUpdate).OnClientEvent:Connect(function(payload)
    Debug.Try(Debug.Channels.Network, "StateUpdate", function()
        state:ApplyServerState(payload)
    end)
end)

Net.GetRemoteEvent(Net.RemoteEvents.StatusUpdate).OnClientEvent:Connect(function(payload)
    Debug.Try(Debug.Channels.Status, "StatusUpdate", function()
        if motor.StatusController then
            motor.StatusController:ApplyServerPayload(payload)
        end
    end)
end)

Net.GetRemoteEvent(Net.RemoteEvents.Correction).OnClientEvent:Connect(function(payload)
    Debug.Try(Debug.Channels.Network, "Correction", function()
        if typeof(payload) == "table" and payload.Position and motor.Root then
            motor.Root.CFrame = CFrame.new(payload.Position)
            if payload.Velocity then
                motor.Velocity = payload.Velocity
                motor.Root.AssemblyLinearVelocity = payload.Velocity
            end
        end
    end)
end)

if player.Character then bind(player.Character) end
player.CharacterAdded:Connect(bind)
