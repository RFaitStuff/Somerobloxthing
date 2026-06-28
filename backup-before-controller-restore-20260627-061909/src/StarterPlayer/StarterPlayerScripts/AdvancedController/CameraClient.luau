--!nonstrict
-- CameraMath ------------------------------------------------------------
local CameraMath = {}

function CameraMath.Forward(yaw, pitch)
    return (CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)).LookVector
end

function CameraMath.FlatForward(yaw)
    return Vector3.new(-math.sin(yaw), 0, -math.cos(yaw)).Unit
end

function CameraMath.Right(yaw)
    return Vector3.new(math.cos(yaw), 0, -math.sin(yaw)).Unit
end

-- ShoulderRig ------------------------------------------------------------
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))

local ShoulderRig = {}
ShoulderRig.__index = ShoulderRig

function ShoulderRig.new()
    return setmetatable({ CurrentShoulder = 1, DesiredShoulder = 1 }, ShoulderRig)
end

function ShoulderRig:Swap()
    self.DesiredShoulder *= -1
end

function ShoulderRig:Update(dt)
    self.CurrentShoulder += (self.DesiredShoulder - self.CurrentShoulder) * Util.ExpDecaySharpness(Config.Camera.ShoulderSharpness, dt)
end

-- CameraCollision ------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Debug = require(Shared:WaitForChild("Debug"))
local Util = require(Shared:WaitForChild("Util"))

local CameraCollision = {}
CameraCollision.__index = CameraCollision

function CameraCollision.new(owner)
    return setmetatable({ Owner = owner }, CameraCollision)
end

function CameraCollision:BuildIgnoreList(extra)
    local ignore = {}
    if extra then
        for _, item in ipairs(extra) do table.insert(ignore, item) end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then table.insert(ignore, player.Character) end
    end
    return ignore
end

function CameraCollision:Resolve(focus, desired, ignoreList)
    local delta = desired - focus
    if delta.Magnitude < 0.05 then return desired end
    local params = Util.MakeRaycastParams(self:BuildIgnoreList(ignoreList))
    local hit = Util.Spherecast(focus, Config.Camera.CollisionRadius, delta, params)
    if self.Owner then
        self.Owner.LastCollisionProbe = { Focus = focus, Desired = desired, HitPosition = hit and hit.Position or nil }
    end
    if not hit then return desired end
    local distance = math.max(Config.Camera.MinCameraDistance, hit.Distance - Config.Camera.CollisionPadding)
    return focus + delta.Unit * distance
end

-- AimRay ------------------------------------------------------------
local AimRay = {}
AimRay.__index = AimRay

function AimRay.new(cameraClient)
    return setmetatable({ CameraClient = cameraClient }, AimRay)
end

function AimRay:GetCameraRay()
    local camera = self.CameraClient.Camera
    return Ray.new(camera.CFrame.Position, camera.CFrame.LookVector)
end

function AimRay:GetMuzzleRay(muzzleWorldPosition)
    local ray = self:GetCameraRay()
    local target = ray.Origin + ray.Direction * 1000
    return Ray.new(muzzleWorldPosition, (target - muzzleWorldPosition).Unit)
end

-- Main ------------------------------------------------------------
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))


local CameraClient = {}
CameraClient.__index = CameraClient

function CameraClient.new(clientState, inputClient)
    local self = setmetatable({}, CameraClient)
    self.State = clientState
    self.Input = inputClient
    self.Camera = workspace.CurrentCamera
    self.Character = nil
    self.Root = nil
    self.Yaw = 0
    self.Pitch = math.rad(12)
    self.CurrentPosition = nil
    self.CurrentFocus = nil
    self.CurrentFov = Config.Camera.NormalFov
    self.MouseUnlocked = false
    self.Rig = ShoulderRig.new()
    self.Collision = CameraCollision.new(self)
    self.AimRay = AimRay.new(self)
    return self
end

function CameraClient:BindCharacter(character)
    self.Character = character
    local _, root = Util.GetCharacterParts(character)
    self.Root = root
    if root then
        local look = root.CFrame.LookVector
        self.Yaw = math.atan2(-look.X, -look.Z)
    end
end

function CameraClient:Start()
    self.Camera = workspace.CurrentCamera
    self.Camera.CameraType = Enum.CameraType.Scriptable
    if Config.Camera.LockMouse then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
    RunService:BindToRenderStep("Controller_Camera", Enum.RenderPriority.Camera.Value + 1, function(dt)
        Debug.Try(Debug.Channels.Movement, "CameraClient:Update", function()
            self:Update(dt)
        end)
    end)
end

function CameraClient:Destroy()
    RunService:UnbindFromRenderStep("Controller_Camera")
end

function CameraClient:UpdateMouseLock()
    local unlocked = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
    if self.MouseUnlocked == unlocked then return end
    self.MouseUnlocked = unlocked
    if unlocked then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif Config.Camera.LockMouse then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end

function CameraClient:GetForward()
    return CameraMath.Forward(self.Yaw, self.Pitch)
end

function CameraClient:GetFlatForward()
    return CameraMath.FlatForward(self.Yaw)
end

function CameraClient:GetRight()
    return CameraMath.Right(self.Yaw)
end

function CameraClient:GetAimRay()
    return self.AimRay:GetCameraRay()
end

function CameraClient:GetAimRayFromMuzzle(muzzleWorldPosition)
    return self.AimRay:GetMuzzleRay(muzzleWorldPosition)
end

function CameraClient:UpdateLook(dt)
    if self.MouseUnlocked then
        self.Input:GetLookDelta()
        return
    end
    local delta = self.Input:GetLookDelta()
    local sensitivity = (self.State.Settings.MouseSensitivity or 1) * Config.Camera.MouseSensitivity
    local invert = self.State.Settings.InvertY and -1 or 1
    self.Yaw -= delta.X * sensitivity * 0.0045
    self.Pitch -= delta.Y * sensitivity * 0.0045 * invert
    self.Pitch = math.clamp(self.Pitch, math.rad(Config.Camera.MinPitch), math.rad(Config.Camera.MaxPitch))
    if self.Input:ConsumePressed("ShoulderSwap") then
        self.Rig:Swap()
        self.State.ShoulderSign = self.Rig.DesiredShoulder
    end
end

function CameraClient:Update(dt)
    if not self.Camera or not self.Root then return end
    self:UpdateMouseLock()
    self:UpdateLook(dt)
    self.Rig:Update(dt)

    local camConfig = Config.Camera
    local mode = self.State.Mode
    local aiming = self.Input:IsHeld("Aim")
    local distance = aiming and camConfig.AimDistance or camConfig.Distance
    local shoulder = math.abs(aiming and camConfig.AimShoulderOffset or camConfig.ShoulderOffset)
    local targetFov = aiming and camConfig.AimFov or camConfig.NormalFov
    if mode == "BulletJumping" or mode == "AirDodging" or mode == "WallHopping" then
        targetFov = camConfig.ParkourFov
    elseif mode == "WallLatched" then
        targetFov = camConfig.WallLatchFov
        distance = camConfig.WallLatchDistance
    end

    self.CurrentFov += (targetFov - self.CurrentFov) * Util.ExpDecaySharpness(camConfig.FovSharpness, dt)
    self.Camera.FieldOfView = self.CurrentFov

    local rawFocus = self.Root.Position + Vector3.new(0, camConfig.Height, 0)
    local focusT = Util.ExpDecaySharpness(camConfig.FocusSharpness or camConfig.PositionSharpness, dt)
    local focus = self.CurrentFocus and self.CurrentFocus:Lerp(rawFocus, focusT) or rawFocus
    self.CurrentFocus = focus

    local shoulderSide = math.clamp(self.Rig.CurrentShoulder, -1, 1)
    local desired = focus + self:GetRight() * (shoulder * shoulderSide) - self:GetForward() * distance
    desired = self.Collision:Resolve(focus, desired, { self.Character })
    self.CurrentPosition = self.CurrentPosition and self.CurrentPosition:Lerp(desired, Util.ExpDecaySharpness(camConfig.PositionSharpness, dt)) or desired

    self.Camera.CFrame = CFrame.lookAt(self.CurrentPosition, focus + self:GetForward() * camConfig.LookAhead)
end

return CameraClient
