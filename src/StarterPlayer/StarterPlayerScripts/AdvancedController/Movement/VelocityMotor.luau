--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("MovementModes"))
local Util = require(Shared:WaitForChild("Util"))

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
        c.Velocity = Vector3.zero
        if c.FocusEnergy <= 0 or not c.Input:IsHeld("Aim") then c:SetMode(Modes.Airborne) end
    elseif mode == Modes.AimGliding then
        c.FocusEnergy = math.max(0, c.FocusEnergy - Config.Movement.AimGlideDrain * dt)
        self:AirMove(dt, Config.Movement.AimGlideAirControlMultiplier)
        c.Velocity = Vector3.new(c.Velocity.X, math.max(c.Velocity.Y, Config.Movement.AimGlideMaxFallSpeed), c.Velocity.Z)
        self:ApplyGravity(dt, Config.Movement.AimGlideGravityScale)
        if c.FocusEnergy <= 0 or not c.Input:IsHeld("Aim") or not c.State.CanAimGlide then c:SetMode(Modes.Airborne) end
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
    self:ClampVelocity()
    self:AvoidDrivingIntoWalls()
end

function VelocityMotor:CommitVelocity()
    local c = self.Controller
    if c.Root then c.Root.AssemblyLinearVelocity = c.Velocity end
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
    local targetSpeed = (c.Input:IsHeld("Sprint") and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed) * speedMult
    if Config.Movement.SlopeProjectGroundMovement and move.Magnitude > 0.05 then
        move = c.SlopeMotor:GetGroundTangentDirection(move)
    end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    local accel = move.Magnitude > 0.05 and Config.Movement.GroundAcceleration or Config.Movement.GroundDeceleration
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
        planar = Util.ClampMagnitude(planar, Config.Movement.MaxPlanarSpeed)
        c.Velocity = Vector3.new(planar.X, c.Velocity.Y, planar.Z)
    end
    local dragFactor = math.clamp(1 - Config.Movement.AirDrag * dt, 0, 1)
    c.Velocity = Vector3.new(c.Velocity.X * dragFactor, c.Velocity.Y, c.Velocity.Z * dragFactor)
end

function VelocityMotor:SlideMove(dt)
    local c = self.Controller
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    local move = c:GetMoveDirection()
    local speedMult = c:GetSpeedMultiplier()
    planar = c.SlopeMotor:ApplySlideSlope(planar, dt)
    if move.Magnitude > 0.05 and planar.Magnitude > 0.05 then
        planar = planar:Lerp(move.Unit * planar.Magnitude, math.clamp(Config.Movement.SlideSteer * dt * math.max(speedMult, 0.2), 0, 1))
    end
    planar = self:MoveToward(planar, Vector3.zero, (Config.Movement.SlideFriction + c.SlopeMotor:GetUphillFriction(planar)) * dt)
    planar = Util.ClampMagnitude(planar, Config.Movement.SlideMaxPlanarSpeed)
    local y = c.Velocity.Y
    if c.IsGrounded then
        y = math.max(Config.Movement.SlopeSnapMaxDownVelocity, math.min(y, Config.Movement.SlideLaunchVerticalClamp))
    end
    c.Velocity = Vector3.new(planar.X, y, planar.Z)
    if not c.Input:IsHeld("Slide") and planar.Magnitude <= Config.Movement.SlideExitSpeed then
        c:SetMode(c.IsGrounded and Modes.Grounded or Modes.Airborne)
    end
end

function VelocityMotor:ApplyGravity(dt, scale)
    local c = self.Controller
    if c.IsGrounded and c.Velocity.Y < 0 then
        local stick = c.Mode == Modes.Sliding and Config.Movement.SlideGroundStickVelocity or Config.Movement.GroundStickVelocity
        c.Velocity = Vector3.new(c.Velocity.X, stick, c.Velocity.Z)
    else
        c.Velocity += Vector3.yAxis * Config.Movement.Gravity * scale * dt
    end
end

function VelocityMotor:AvoidDrivingIntoWalls()
    local c = self.Controller
    if not c.HasWall then return end
    local into = c.Velocity:Dot(-c.WallNormal)
    if into > 0 then c.Velocity += c.WallNormal * into end
end

function VelocityMotor:ClampVelocity()
    local c = self.Controller
    local maxPlanar = Config.Movement.MaxPlanarSpeed
    if c.Mode == Modes.Sliding then
        maxPlanar = Config.Movement.SlideMaxPlanarSpeed
    elseif c.Mode == Modes.BulletJumping or c.Mode == Modes.AirDodging or c.Mode == Modes.WallHopping then
        maxPlanar = Config.Movement.HardMaxPlanarSpeed
    end
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
