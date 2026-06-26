--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Net"))
local Debug = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Debug"))

local Systems = script.Parent.Parent:WaitForChild("AdvancedSystems")
local ClientState = require(script.Parent:WaitForChild("ClientState"))
local InputClient = require(script.Parent:WaitForChild("InputClient"))
local CameraClient = require(script.Parent:WaitForChild("CameraClient"))
local KinematicClient = require(script.Parent:WaitForChild("MovementClient"))
local AnimationClient = require(Systems:WaitForChild("Animation"):WaitForChild("AnimationClient"))
local MeleeClient = require(Systems:WaitForChild("Combat"):WaitForChild("MeleeClient"))
local SettingsClient = require(Systems:WaitForChild("Settings"):WaitForChild("SettingsClient"))
local DebugVisualizer = require(Systems:WaitForChild("Debug"):WaitForChild("DebugVisualizer"))
local TuningMenuClient = require(Systems:WaitForChild("Debug"):WaitForChild("TuningMenuClient"))

local player = Players.LocalPlayer
local state = ClientState.new()
local input = InputClient.new(state)
local camera = CameraClient.new(state, input)
local animation = AnimationClient.new(state)
local motor = KinematicClient.new(state, input, camera, animation)
local melee = MeleeClient.new(state, input, motor, animation)
local settings = SettingsClient.new(state, input)
local debugVisualizer = DebugVisualizer.new(state, input, camera, motor, melee)
local tuningMenu = TuningMenuClient.new(state, input, camera, motor)

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
Debug.Try(Debug.Channels.Startup, "SettingsClient:Start", function() settings:Start() end)
Debug.Try(Debug.Channels.Startup, "DebugVisualizer:Start", function() debugVisualizer:Start() end)
Debug.Try(Debug.Channels.Startup, "TuningMenuClient:Start", function() tuningMenu:Start() end)

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
