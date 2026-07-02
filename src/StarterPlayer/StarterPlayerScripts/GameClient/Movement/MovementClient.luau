--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Debug = require(Shared:WaitForChild("Core"):WaitForChild("Debug"))
local Modes = require(Shared:WaitForChild("Core"):WaitForChild("MovementModes"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))

local Movement = script.Parent
local CharacterBinder = require(Movement:WaitForChild("CharacterBinder"))
local GroundProbe = require(Movement:WaitForChild("GroundProbe"))
local WallProbe = require(Movement:WaitForChild("WallProbe"))
local SlopeMotor = require(Movement:WaitForChild("SlopeMotor"))
local VelocityMotor = require(Movement:WaitForChild("VelocityMotor"))
local StateMachine = require(Movement:WaitForChild("MovementStateMachine"))
local ActionExecutor = require(Movement:WaitForChild("ActionExecutor"))
local Orientation = require(Movement:WaitForChild("Orientation"))
local HumanoidAdapter = require(Movement:WaitForChild("HumanoidAdapter"))
local SoftCollision = require(Movement:WaitForChild("PlayerSoftCollision"))
local StatusController = require(Movement:WaitForChild("StatusController"))

local Kinematic = {}
Kinematic.__index = Kinematic

function Kinematic.new(clientState, inputClient, cameraClient, animationClient)
    local self = setmetatable({}, Kinematic)
    self.State = clientState
    self.Input = inputClient
    self.Camera = cameraClient
    self.Animation = animationClient
    self.Character = nil
    self.Humanoid = nil
    self.Root = nil
    self.Mode = Modes.Idle
    self.LastMode = nil
    self.Velocity = Vector3.zero
    self.IsGrounded = false
    self.GroundNormal = Vector3.yAxis
    self.HasWall = false
    self.HasWallContact = false
    self.HasWallAim = false
    self.WallNormal = Vector3.zero
    self.LastWallNormal = Vector3.zero
    self.LastWallNormalTimer = 0
    self.WallTangent = Vector3.zero
    self.WallApproach = 0
    self.WallContactAge = 0
    self.WallContactSide = "None"
    self.WallHopRepeatTimer = 0
    self.ForceFacingDirection = nil
    self.ForceFacingTimer = 0
    self.FocusEnergy = Config.Movement.FocusEnergy
    self.AimGlideTimeRemaining = Config.Movement.AimGlideMaxDuration
    self.AirJumpsRemaining = Config.Movement.AirJumpsPerSurface
    self.BulletJumpAvailable = true
    self.AirDodgeAvailable = true
    self.WallLatchRefreshAvailable = true
    self.BulletJumpCooldown = 0
    self.SlideBoostCooldown = 0
    self.JumpHoldTimer = 0
    self.JumpCutAllowed = false
    self.ModeTimer = 0
    self.MeleeLockTimer = 0
    self.ActionRemote = nil
    self.Connection = nil
    self.Binder = CharacterBinder.new(self)
    self.GroundProbe = GroundProbe.new(self)
    self.WallProbe = WallProbe.new(self)
    self.SlopeMotor = SlopeMotor.new(self)
    self.VelocityMotor = VelocityMotor.new(self)
    self.StateMachine = StateMachine.new(self)
    self.ActionExecutor = ActionExecutor.new(self)
    self.Orientation = Orientation.new(self)
    self.HumanoidAdapter = HumanoidAdapter.new(self)
    self.SoftCollision = SoftCollision.new(self)
    self.StatusController = StatusController.new(self)
    return self
end

function Kinematic:BindCharacter(character)
    self.Binder:Bind(character)
    self.HumanoidAdapter:ApplyCustomMovementSettings()
    self:ResetSurfaceActions()
    self:SetMode(Modes.Idle)
end

function Kinematic:Start()
    self.ActionRemote = Net.GetRemoteEvent(Net.RemoteEvents.ActionRequest)
    local ok, signal = pcall(function() return RunService.PreSimulation end)
    if not ok or not signal then
        signal = RunService.Heartbeat
    end
    self.Connection = signal:Connect(function(dt)
        Debug.Try(Debug.Channels.Movement, "MovementClient:Update", function()
            self:Update(math.clamp(dt, 0, 1 / 20))
        end)
    end)
end

function Kinematic:Destroy()
    if self.Connection then self.Connection:Disconnect() end
end

function Kinematic:SetMode(mode)
    if self.Mode == mode then return end
    self.LastMode = self.Mode
    self.Mode = mode
    self.State.Mode = mode
    if mode == Modes.WallLatched then
        self.WallLatchDampTimer = Config.Movement.WallLatchDampTime or 0.08
    elseif mode ~= Modes.WallLatched then
        self.WallLatchDampTimer = 0
    end
    if self.Animation then self.Animation:OnModeChanged(mode) end
end

function Kinematic:ResetSurfaceActions()
    self.AirJumpsRemaining = Config.Movement.AirJumpsPerSurface
    self.BulletJumpAvailable = true
    self.AirDodgeAvailable = true
    self.WallLatchRefreshAvailable = true
    self.FocusEnergy = Config.Movement.FocusEnergy
    self.AimGlideTimeRemaining = Config.Movement.AimGlideMaxDuration
end

function Kinematic:ApplyImpulse(impulse)
    if typeof(impulse) ~= "Vector3" then return end
    local nextVelocity = self.Velocity + impulse
    local planar = Vector3.new(nextVelocity.X, 0, nextVelocity.Z)
    local maxPlanar = Config.Movement.HardMaxPlanarSpeed
    if planar.Magnitude > maxPlanar then
        planar = planar.Unit * maxPlanar
    end
    local y = math.clamp(nextVelocity.Y, -Config.Movement.HardMaxVerticalSpeed, Config.Movement.HardMaxVerticalSpeed)
    self.Velocity = Vector3.new(planar.X, y, planar.Z)
end

function Kinematic:SetMeleeLock(duration)
    self.MeleeLockTimer = math.max(self.MeleeLockTimer, duration or 0)
    if self.MeleeLockTimer > 0 then self:SetMode(Modes.MeleeLocked) end
end

function Kinematic:IsMeleeLocked()
    return self.MeleeLockTimer > 0
end

function Kinematic:IsMovementLockedByStatus()
    return self.StatusController and self.StatusController:IsMovementLocked() or false
end

function Kinematic:GetSpeedMultiplier()
    return self.StatusController and self.StatusController:GetSpeedMultiplier() or 1
end

function Kinematic:GetMoveDirection()
    if self:IsMovementLockedByStatus() then return Vector3.zero end
    local raw = self.Input:GetMoveVector()
    if raw.Magnitude <= 0.05 then return Vector3.zero end
    local forward = self.Camera and self.Camera:GetFlatForward() or (self.Root and self.Root.CFrame.LookVector or Vector3.zAxis)
    forward = Vector3.new(forward.X, 0, forward.Z)
    if forward.Magnitude <= 0.001 then forward = Vector3.zAxis end
    forward = forward.Unit
    local right = self.Camera and self.Camera:GetRight() or Vector3.new(-forward.Z, 0, forward.X)
    right = Vector3.new(right.X, 0, right.Z)
    if right.Magnitude <= 0.001 then right = Vector3.new(-forward.Z, 0, forward.X) end
    right = right.Unit
    local dir = forward * raw.Y + right * raw.X
    return dir.Magnitude > 1 and dir.Unit or dir
end

function Kinematic:GetAimDirection()
    if self.Camera and self.Camera.Camera then
        return self.Camera.Camera.CFrame.LookVector
    end
    return self.Camera and self.Camera:GetForward() or (self.Root and self.Root.CFrame.LookVector or Vector3.new(0, 0, -1))
end

function Kinematic:GetFlatForward()
    return self.Camera and self.Camera:GetFlatForward() or (self.Root and self.Root.CFrame.LookVector or Vector3.new(0, 0, -1))
end

function Kinematic:SendAction(actionName, data)
    if not self.ActionRemote then return end
    data = data or {}
    if self.Root then data.Position = self.Root.Position end
    self.ActionRemote:FireServer(actionName, data)
end

local function rootSnapshot(root)
    if not root then
        return { V = Vector3.zero, P = Vector3.zero, C = CFrame.identity }
    end
    return { V = root.AssemblyLinearVelocity, P = root.Position, C = root.CFrame }
end

function Kinematic:Update(dt)
    if not self.Root or not self.Humanoid or self.Humanoid.Health <= 0 then return end

    self.DebugFrameId = (self.DebugFrameId or 0) + 1
    self.DebugLastDt = dt
    self.DebugStep = {
        Start = rootSnapshot(self.Root),
        StartVelocity = self.Velocity,
        StartClock = os.clock(),
    }

    self.LastWallNormalTimer = math.max(0, (self.LastWallNormalTimer or 0) - dt)
    self.WallHopRepeatTimer = math.max(0, (self.WallHopRepeatTimer or 0) - dt)
    self.ForceFacingTimer = math.max(0, (self.ForceFacingTimer or 0) - dt)
    self.GroundProbe:Update()
    self.DebugStep.AfterGroundProbe = rootSnapshot(self.Root)
    self.WallProbe:Update(dt)
    self.DebugStep.AfterWallProbe = rootSnapshot(self.Root)
    self.StatusController:Update(dt)
    self.DebugStep.AfterStatus = rootSnapshot(self.Root)
    self.StateMachine:HandleTransitions(dt)
    self.DebugStep.AfterState = rootSnapshot(self.Root)
    self.VelocityMotor:Integrate(dt)
    self.DebugStep.AfterIntegrate = rootSnapshot(self.Root)
    self.DebugStep.AfterIntegrateControllerVelocity = self.Velocity
    self.SoftCollision:Update(dt)
    self.DebugStep.AfterSoftCollision = rootSnapshot(self.Root)
    self.DebugStep.AfterSoftCollisionControllerVelocity = self.Velocity

    -- Anything that writes CFrame or humanoid state must happen before the final velocity write.
    -- Otherwise Roblox can partially discard the AssemblyLinearVelocity commit during the same
    -- simulation step, which shows up as commit/vAsm mismatch and forward rubber-band stutter.
    self.Orientation:Update(dt)
    self.DebugStep.AfterOrientation = rootSnapshot(self.Root)
    self.HumanoidAdapter:Update(dt)
    self.DebugStep.AfterHumanoid = rootSnapshot(self.Root)
    self.VelocityMotor:CommitVelocity()
    self.DebugStep.AfterCommit = rootSnapshot(self.Root)

    if self.Animation then self.Animation:Update(dt, self) end
    self.DebugStep.AfterAnimation = rootSnapshot(self.Root)
    self.DebugStep.EndClock = os.clock()
end

return Kinematic
