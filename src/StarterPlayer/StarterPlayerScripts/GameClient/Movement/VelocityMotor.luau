--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("Core"):WaitForChild("MovementModes"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))

local VelocityMotor = {}
VelocityMotor.__index = VelocityMotor

function VelocityMotor.new(controller)
    return setmetatable({ Controller = controller }, VelocityMotor)
end

function VelocityMotor:Integrate(dt)
    local c = self.Controller
    local mode = c.Mode
    if mode == Modes.KnockedDown or mode == Modes.GettingUp then
        self:LockedMove(dt, 0.92)
    elseif mode == Modes.Staggered then
        self:LockedMove(dt, 0.78)
    elseif mode == Modes.WallLatched then
        c.FocusEnergy = math.max(0, c.FocusEnergy - Config.Movement.WallLatchDrain * dt)
        local damp = c.WallLatchDampTimer or 0
        if damp > 0 then
            c.WallLatchDampTimer = math.max(0, damp - dt)
            local t = 1 - math.exp(-42 * dt)
            c.Velocity = c.Velocity:Lerp(Vector3.zero, t)
        else
            c.Velocity = Vector3.zero
        end
        if c.FocusEnergy <= 0 or not c.Input:IsHeld("Aim") then
            if c.HasWallContact and c.WallNormal.Magnitude > 0.05 then
                c:ApplyImpulse(c.WallNormal.Unit * (Config.Movement.WallLatchDetachPush or 8))
            end
            c:SetMode(Modes.Airborne)
        end
    elseif mode == Modes.AimGliding then
        c.FocusEnergy = math.max(0, c.FocusEnergy - Config.Movement.AimGlideDrain * dt)
        c.AimGlideTimeRemaining = math.max(0, (c.AimGlideTimeRemaining or Config.Movement.AimGlideMaxDuration) - dt)
        local beforePlanar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
        self:AirMove(dt, Config.Movement.AimGlideAirControlMultiplier)
        local afterPlanar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
        local preservedPlanar = beforePlanar * (Config.Movement.AimGlideMomentumPreserve or 0.985)
        if preservedPlanar.Magnitude > afterPlanar.Magnitude then
            c.Velocity = Vector3.new(preservedPlanar.X, c.Velocity.Y, preservedPlanar.Z)
        end
        if c.Velocity.Y < 0 then
            self:ApplyGravity(dt, Config.Movement.AimGlideGravityScale)
            c.Velocity = Vector3.new(c.Velocity.X, math.max(c.Velocity.Y, Config.Movement.AimGlideMaxFallSpeed), c.Velocity.Z)
        else
            self:ApplyGravity(dt, 1)
        end
        if c.FocusEnergy <= 0 or (c.AimGlideTimeRemaining or 0) <= 0 or not c.Input:IsHeld("Aim") or not c.State.CanAimGlide then c:SetMode(Modes.Airborne) end
    elseif mode == Modes.Sliding then
        self:SlideMove(dt)
        self:ApplyGravity(dt, 1)
    elseif c.IsGrounded then
        self:GroundMove(dt)
        self:ApplyGravity(dt, 1)
    else
        self:AirMove(dt, 1)
        self:ApplyGravity(dt, 1)
    end
    self:ApplyVariableJump(dt)
    self:ClampVelocity()
    self:AvoidDrivingIntoWalls()
end

function VelocityMotor:CommitVelocity()
    local c = self.Controller
    if c.Root then
        c.DebugPreCommitAssemblyVelocity = c.Root.AssemblyLinearVelocity
        c.DebugCommitVelocity = c.Velocity
        c.DebugCommitClock = os.clock()
        c.Root.AssemblyLinearVelocity = c.Velocity
        c.DebugPostCommitAssemblyVelocity = c.Root.AssemblyLinearVelocity
    end
end

function VelocityMotor:LockedMove(dt, damping)
    local c = self.Controller
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z) * math.clamp(damping, 0, 1)
    c.Velocity = Vector3.new(planar.X, c.Velocity.Y, planar.Z)
    self:ApplyGravity(dt, 1)
end

function VelocityMotor:GroundMove(dt)
    local c = self.Controller
    local move = c:GetMoveDirection()
    local speedMult = c:GetSpeedMultiplier()
    local targetSpeed = c.Input:IsHeld("Sprint") and Config.Movement.WalkSpeed or Config.Movement.SprintSpeed
    if c.Mode == Modes.Crouching then
        targetSpeed = Config.Movement.CrouchSpeed
    end
    targetSpeed *= speedMult
    if Config.Movement.SlopeProjectGroundMovement and move.Magnitude > 0.05 then
        move = c.SlopeMotor:GetGroundTangentDirection(move)
    end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    local accel = move.Magnitude > 0.05 and Config.Movement.GroundAcceleration or Config.Movement.GroundDeceleration
    if move.Magnitude > 0.05 and targetSpeed >= Config.Movement.SprintSpeed then
        accel = Config.Movement.SprintRampAcceleration or accel
    end
    planar = self:MoveToward(planar, move * targetSpeed, accel * speedMult * dt)
    planar = c.SlopeMotor:ApplyGroundSlopeAssist(planar, dt)
    c.Velocity = Vector3.new(planar.X, c.Velocity.Y, planar.Z)
end

function VelocityMotor:AirMove(dt, multiplier)
    local c = self.Controller
    local move = c:GetMoveDirection()
    local speedMult = c:GetSpeedMultiplier()
    if move.Magnitude > 0.05 then
        local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
        planar += move.Unit * Config.Movement.AirAcceleration * multiplier * speedMult * dt
        planar = Util.ClampMagnitude(planar, self:GetPlanarCap())
        c.Velocity = Vector3.new(planar.X, c.Velocity.Y, planar.Z)
    end
    local dragFactor = math.clamp(1 - Config.Movement.AirDrag * dt, 0, 1)
    c.Velocity = Vector3.new(c.Velocity.X * dragFactor, c.Velocity.Y, c.Velocity.Z * dragFactor)
end

function VelocityMotor:GetPlanarCap()
    local mode = self.Controller.Mode
    if mode == Modes.Sliding then
        return Config.Movement.SlideMaxPlanarSpeed
    end
    if mode == Modes.BulletJumping or mode == Modes.AirDodging or mode == Modes.WallHopping then
        return Config.Movement.HardMaxPlanarSpeed
    end
    return Config.Movement.MaxPlanarSpeed
end

function VelocityMotor:SlideMove(dt)
    local c = self.Controller
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    local rawMove = c.Input and c.Input:GetMoveVector() or Vector2.zero
    local speedMult = c:GetSpeedMultiplier()
    planar = c.SlopeMotor:ApplySlideSlope(planar, dt)

    if rawMove.Y > Config.Movement.SlideForwardExitInput and c.ModeTimer <= 0 then
        c:SetMode(c.IsGrounded and Modes.Sprinting or Modes.Airborne)
        return
    end

    if math.abs(rawMove.X) > 0.05 and planar.Magnitude > 0.05 then
        local currentDir = planar.Unit
        local right = c.Camera and c.Camera:GetRight() or Vector3.new(-currentDir.Z, 0, currentDir.X)
        right = Util.SafeUnit(Vector3.new(right.X, 0, right.Z), Vector3.new(-currentDir.Z, 0, currentDir.X))
        local steerDir = Util.SafeUnit(currentDir + right * rawMove.X * 0.55, currentDir)
        planar = planar:Lerp(steerDir * planar.Magnitude, math.clamp(Config.Movement.SlideSteer * dt * math.max(speedMult, 0.2), 0, 1))
    end
    planar = self:MoveToward(planar, Vector3.zero, (Config.Movement.SlideFriction + c.SlopeMotor:GetUphillFriction(planar)) * dt)
    planar = Util.ClampMagnitude(planar, Config.Movement.SlideMaxPlanarSpeed)
    local y = c.Velocity.Y
    if c.IsGrounded then
        y = math.max(Config.Movement.SlopeSnapMaxDownVelocity, math.min(y, Config.Movement.SlideLaunchVerticalClamp))
    end
    c.Velocity = Vector3.new(planar.X, y, planar.Z)
    if planar.Magnitude <= Config.Movement.SlideExitSpeed and c.ModeTimer <= 0 then
        if c.IsGrounded then
            c:SetMode(c.Input:IsHeld("Slide") and Modes.Crouching or Modes.Grounded)
        else
            c:SetMode(Modes.Airborne)
        end
    elseif not c.Input:IsHeld("Slide") and c.ModeTimer <= 0 then
        c:SetMode(c.IsGrounded and Modes.Grounded or Modes.Airborne)
    end
end

function VelocityMotor:GetGroundStickVelocity()
    local c = self.Controller
    if c.Mode == Modes.Sliding then
        return Config.Movement.SlideGroundStickVelocity or -6
    end

    -- The old controller forced a fairly strong negative Y velocity every grounded frame.
    -- Roblox then corrected the HumanoidRootPart back up through floor collision, which looked
    -- like a constant animation/rig bounce. Only apply real ground-stick when it is needed.
    local planarSpeed = Vector3.new(c.Velocity.X, 0, c.Velocity.Z).Magnitude
    local normal = c.GroundNormal or Vector3.yAxis
    local flatGround = normal.Y >= (Config.Movement.FlatGroundNormalY or 0.985)
    local stableSpeed = Config.Movement.StableGroundMaxSpeed or 2

    if flatGround and planarSpeed <= stableSpeed and c.Mode ~= Modes.Crouching then
        return Config.Movement.StableGroundStickVelocity or 0
    end

    return Config.Movement.GroundStickVelocity or -2.5
end

function VelocityMotor:ApplyGravity(dt, scale)
    local c = self.Controller
    if c.IsGrounded and c.Velocity.Y <= 0 then
        local stick = self:GetGroundStickVelocity()
        -- Never slam the root downward while grounded. A small/zero stick velocity is enough for
        -- flat ground, while slopes/sliding still get a little downward bias.
        c.Velocity = Vector3.new(c.Velocity.X, math.max(stick, math.min(c.Velocity.Y, 0)), c.Velocity.Z)
    else
        c.Velocity += Vector3.yAxis * Config.Movement.Gravity * scale * dt
    end
end

function VelocityMotor:ApplyVariableJump(dt)
    local c = self.Controller
    if not c.JumpCutAllowed or c.Velocity.Y <= 0 then return end

    c.JumpHoldTimer = math.max(0, (c.JumpHoldTimer or 0) - dt)
    if c.Input:IsHeld("Jump") then
        if c.JumpHoldTimer > 0 then
            return
        end
        c.JumpCutAllowed = false
        return
    end

    local cutVelocity = Config.Movement.JumpCutMinVelocity or 22
    if c.Velocity.Y > cutVelocity then
        c.Velocity = Vector3.new(c.Velocity.X, cutVelocity, c.Velocity.Z)
    end
    c.JumpCutAllowed = false
end

function VelocityMotor:AvoidDrivingIntoWalls()
    local c = self.Controller
    c.DebugWallVelocityBlock = { Applied = false, Reason = "NoWallContact" }
    if not c.HasWallContact then return end
    if c.WallContactIsMemory and Config.Movement.WallCollisionBlockMemory ~= true then
        c.DebugWallVelocityBlock = { Applied = false, Reason = "MemoryIgnored" }
        return
    end
    if not c.WallNormal or c.WallNormal.Magnitude <= 0.05 then
        c.DebugWallVelocityBlock = { Applied = false, Reason = "NoNormal" }
        return
    end
    if math.abs(c.WallNormal.Y) > (Config.Movement.MaxWallNormalY or 0.25) then
        c.DebugWallVelocityBlock = { Applied = false, Reason = "VerticalNormal", Normal = c.WallNormal }
        return
    end

    local normal = c.WallNormal.Unit
    local into = c.Velocity:Dot(-normal)
    if into <= (Config.Movement.WallCollisionMinIntoSpeed or 1.5) then
        c.DebugWallVelocityBlock = { Applied = false, Reason = "NotDrivingIntoWall", Into = into, Normal = normal }
        return
    end

    local move = c:GetMoveDirection()
    local inputIntoWall = move.Magnitude > 0.05 and move.Unit:Dot(-normal) or 0
    local mode = c.Mode
    local isParkourWallMode = mode == Modes.WallLatched or mode == Modes.WallHopping or mode == Modes.BulletJumping or mode == Modes.AimGliding or mode == Modes.Sliding
    if c.IsGrounded and not isParkourWallMode and inputIntoWall < (Config.Movement.WallCollisionMinInputIntoWall or 0.12) then
        c.DebugWallVelocityBlock = {
            Applied = false,
            Reason = "InputNotIntoWall",
            Into = into,
            InputIntoWall = inputIntoWall,
            Normal = normal,
        }
        return
    end

    local before = c.Velocity
    c.Velocity += normal * into
    c.DebugWallVelocityBlock = {
        Applied = true,
        Reason = "Blocked",
        Into = into,
        InputIntoWall = inputIntoWall,
        Normal = normal,
        Before = before,
        After = c.Velocity,
    }
end

function VelocityMotor:ClampVelocity()
    local c = self.Controller
    local maxPlanar = self:GetPlanarCap()
    local planar = Util.ClampMagnitude(Vector3.new(c.Velocity.X, 0, c.Velocity.Z), maxPlanar)
    local yMax = c.Mode == Modes.BulletJumping and Config.Movement.HardMaxVerticalSpeed or Config.Movement.MaxVerticalSpeed
    c.Velocity = Vector3.new(planar.X, math.clamp(c.Velocity.Y, -Config.Movement.HardMaxVerticalSpeed, yMax), planar.Z)
end

function VelocityMotor:MoveToward(current, target, maxDelta)
    local delta = target - current
    if delta.Magnitude <= maxDelta or delta.Magnitude < 1e-5 then return target end
    return current + delta.Unit * maxDelta
end

return VelocityMotor
