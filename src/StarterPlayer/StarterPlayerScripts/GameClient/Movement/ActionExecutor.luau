--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("Core"):WaitForChild("MovementModes"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))

local ActionExecutor = {}
ActionExecutor.__index = ActionExecutor

function ActionExecutor.new(controller)
    return setmetatable({ Controller = controller }, ActionExecutor)
end

function ActionExecutor:GetWallIntent()
    local c = self.Controller
    if not c.HasWallContact then return 0 end
    local intoWall = -c.WallNormal
    local move = c:GetMoveDirection()
    local moveDot = move.Magnitude > 0.05 and move.Unit:Dot(intoWall) or 0
    local aimDot = Util.SafeUnit(c:GetAimDirection(), c:GetFlatForward()):Dot(intoWall)
    return math.max(moveDot, aimDot * 0.85, c.WallApproach or 0)
end

function ActionExecutor:ShouldWallHop(fromHeld)
    local c = self.Controller
    if not c.HasWallContact then return false end
    local intent = self:GetWallIntent()
    if fromHeld and not (Config.Movement.WallHopChainEnabled == true) then return false end
    if fromHeld and (c.WallHopRepeatTimer or 0) > 0 then return false end
    if fromHeld and intent < (Config.Movement.WallHopMoveIntoWallDotMin or 0.08) then return false end
    if not fromHeld and intent < (Config.Movement.WallHopLookDotMin or 0.06) then return false end
    return true
end

function ActionExecutor:TryJump()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return false end
    if c.IsGrounded then
        local preserve = Config.Movement.JumpPlanarPreserve or 1
        c.Velocity = Vector3.new(c.Velocity.X * preserve, Config.Movement.JumpVelocity, c.Velocity.Z * preserve)
        c.JumpHoldTimer = Config.Movement.JumpHoldMaxTime
        c.JumpCutAllowed = true
        c:SetMode(Modes.Airborne)
        if c.Animation and c.Animation.PlayParkour then c.Animation:PlayParkour("Jump") end
        c:SendAction("Jump")
        return true
    end
    if c.AirJumpsRemaining > 0 then
        c.AirJumpsRemaining -= 1
        local move = c:GetMoveDirection()
        local preserve = Config.Movement.DoubleJumpPlanarPreserve or 1
        c.Velocity = Vector3.new(c.Velocity.X * preserve, math.max(c.Velocity.Y, Config.Movement.DoubleJumpVelocity), c.Velocity.Z * preserve)
        if move.Magnitude > 0 then c:ApplyImpulse(move.Unit * Config.Movement.DoubleJumpForwardBoost) end

        -- If the previous wall hop pushed you away, allow a normal double jump to drive back into
        -- the wall instead of accidentally forcing another wall hop behind the player.
        if (c.LastWallNormalTimer or 0) > 0 and c.LastWallNormal and c.LastWallNormal.Magnitude > 0.05 then
            local intoWall = -c.LastWallNormal.Unit
            local aimDot = Util.SafeUnit(c:GetAimDirection(), intoWall):Dot(intoWall)
            local moveDot = move.Magnitude > 0.05 and move.Unit:Dot(intoWall) or 0
            if math.max(aimDot, moveDot) > 0.12 then
                c:ApplyImpulse(intoWall * (Config.Movement.DoubleJumpWallReturnAssist or 18))
            end
        end

        c.JumpHoldTimer = Config.Movement.JumpHoldMaxTime
        c.JumpCutAllowed = true
        c:SetMode(Modes.Airborne)
        if c.Animation and c.Animation.PlayParkour then c.Animation:PlayParkour("DoubleJump") end
        c:SendAction("DoubleJump")
        return true
    end
    return false
end

function ActionExecutor:TryBulletJump()
    local c = self.Controller
    if c:IsMovementLockedByStatus() or not c.BulletJumpAvailable or c.BulletJumpCooldown > 0 then return false end
    c.BulletJumpAvailable = false
    c.BulletJumpCooldown = Config.Movement.BulletJumpCooldown
    c.ModeTimer = Config.Movement.BulletJumpModeTime
    c.JumpCutAllowed = false

    local aim = Util.SafeUnit(c:GetAimDirection(), Vector3.yAxis)
    local move = c:GetMoveDirection()
    local flatAim = Vector3.new(aim.X, 0, aim.Z)
    local rocketPitchY = Config.Movement.BulletJumpRocketPitchY or 0.74
    local planar
    local vertical

    if aim.Y >= rocketPitchY then
        local fallback = move.Magnitude > 0.05 and move.Unit or c:GetFlatForward()
        local flat = Util.SafeUnit(flatAim, fallback)
        local t = math.clamp((aim.Y - rocketPitchY) / math.max(1 - rocketPitchY, 0.001), 0, 1)
        local planarScale = (Config.Movement.BulletJumpRocketPlanarScale or 0.24) * (1 - t * 0.6)
        planar = Util.ClampMagnitude(flat * Config.Movement.BulletJumpForwardImpulse * planarScale, Config.Movement.BulletJumpMaxAddedPlanarSpeed)
        vertical = math.min(Config.Movement.BulletJumpRocketUpImpulse or Config.Movement.BulletJumpUpImpulse, Config.Movement.BulletJumpMaxAddedVerticalSpeed)
    else
        local blended = aim
        if move.Magnitude > 0.05 then
            blended = aim + move.Unit * Config.Movement.BulletJumpMoveInfluence
        end

        local direction = Util.SafeUnit(blended, aim)
        if direction.Y < -0.15 then
            local flat = Util.SafeUnit(Vector3.new(direction.X, 0, direction.Z), c:GetFlatForward())
            direction = Util.SafeUnit(flat + Vector3.yAxis * Config.Movement.BulletJumpMinUpWhenLookingDown, Vector3.yAxis)
        end

        planar = Util.ClampMagnitude(Vector3.new(direction.X, 0, direction.Z) * Config.Movement.BulletJumpForwardImpulse, Config.Movement.BulletJumpMaxAddedPlanarSpeed)
        vertical = math.min(Config.Movement.BulletJumpUpImpulse + math.max(direction.Y, 0) * 28, Config.Movement.BulletJumpMaxAddedVerticalSpeed)
    end

    local fromSlide = c.Mode == Modes.Sliding
    if fromSlide then
        local currentPlanar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
        planar += Util.ClampMagnitude(currentPlanar * 0.5, Config.Movement.BulletJumpMaxAddedPlanarSpeed * 0.55)
    end

    c:ApplyImpulse(planar + Vector3.yAxis * vertical)
    c:SetMode(Modes.BulletJumping)
    if c.Animation and c.Animation.PlayParkour then c.Animation:PlayParkour("BulletJump") end
    c:SendAction("BulletJump")
    return true
end

function ActionExecutor:TryWallHop(fromHeld)
    local c = self.Controller
    if c:IsMovementLockedByStatus() or not self:ShouldWallHop(fromHeld) then return false end
    local away = Util.SafeUnit(c.WallNormal, Vector3.yAxis)
    local move = c:GetMoveDirection()
    local tangent = c.WallTangent and c.WallTangent.Magnitude > 0.05 and c.WallTangent or c:GetFlatForward()
    if move.Magnitude > 0.05 and move.Unit:Dot(tangent) < 0 then
        tangent = -tangent
    end
    local forward = Util.SafeUnit(tangent + c:GetFlatForward() * 0.35, c:GetFlatForward())
    local wallPlaneCarry = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    wallPlaneCarry -= away * wallPlaneCarry:Dot(away)
    c.Velocity = Vector3.new(wallPlaneCarry.X * 0.75, math.max(c.Velocity.Y, 0), wallPlaneCarry.Z * 0.75)
    c:ApplyImpulse(away * Config.Movement.WallHopAwayImpulse + Vector3.yAxis * Config.Movement.WallHopUpImpulse + forward * Config.Movement.WallHopForwardImpulse)
    c.ModeTimer = Config.Movement.WallHopModeTime
    c.WallHopRepeatTimer = Config.Movement.WallHopHeldRepeatInterval or 0.18
    c.LastWallNormal = away
    c.LastWallNormalTimer = Config.Movement.WallRecontactAssistTime or 0.38
    c.ForceFacingDirection = c:GetFlatForward()
    c.ForceFacingTimer = Config.Movement.WallHopFaceCameraTime or 0.22
    c:ResetSurfaceActions()
    if c.WallProbe then
        c.WallProbe.MemoryTime = 0
    end
    c:SetMode(Modes.WallHopping)
    if c.Animation and c.Animation.PlayParkour then
        local anim = math.abs(c:GetAimDirection().Y) > 0.35 and "WallHopVertical" or "WallHopHorizontal"
        c.Animation:PlayParkour(anim)
    end
    c:SendAction("WallHop")
    return true
end

function ActionExecutor:StartSlide()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    local dir = planar.Magnitude > 1 and planar.Unit or c:GetFlatForward()
    if planar.Magnitude < Config.Movement.SlideStartSpeed then
        planar = dir * Config.Movement.SlideStartSpeed
        c.Velocity = Vector3.new(planar.X, math.min(c.Velocity.Y, Config.Movement.SlideLaunchVerticalClamp), planar.Z)
    end
    if (c.SlideBoostCooldown or 0) <= 0 then
        local currentSpeed = Vector3.new(c.Velocity.X, 0, c.Velocity.Z).Magnitude
        local boostScale = math.clamp(currentSpeed / math.max(Config.Movement.SprintSpeed, 1), 0.35, 1)
        c:ApplyImpulse(dir * Config.Movement.SlideStartBoost * boostScale)
        c.SlideBoostCooldown = Config.Movement.SlideBoostCooldown
    end
    c.ModeTimer = Config.Movement.SlideMinTime
    c:SetMode(Modes.Sliding)
    if c.Animation and c.Animation.PlayParkour then c.Animation:PlayParkour("SlideStart") end
    c:SendAction("Slide")
end

function ActionExecutor:DoRoll()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return end
    local dir = c:GetMoveDirection()
    if dir.Magnitude < 0.05 then dir = c:GetFlatForward() end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    if planar.Magnitude > 1 then
        c.Velocity = Vector3.new(planar.X * 0.96, c.Velocity.Y, planar.Z * 0.96)
    end
    c:ApplyImpulse(dir.Unit * Config.Movement.RollImpulse)
    c.AirDodgeAvailable = true
    c.ModeTimer = Config.Movement.RollModeTime
    c:SetMode(Modes.Rolling)
    c:SendAction("Roll")
end

function ActionExecutor:DoDodge()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return end
    local dir = c:GetMoveDirection()
    if dir.Magnitude < 0.05 then dir = c:GetFlatForward() end
    c:ApplyImpulse(dir.Unit * Config.Movement.AirDodgeImpulse + Vector3.yAxis * Config.Movement.AirDodgeUpImpulse)
    if not c.IsGrounded then
        c.AirDodgeAvailable = false
    end
    c.ModeTimer = Config.Movement.AirDodgeModeTime
    c:SetMode(Modes.AirDodging)
    c:SendAction("Dodge")
end

function ActionExecutor:DoAirDodge()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return end
    local dir = c:GetMoveDirection()
    if dir.Magnitude < 0.05 then dir = c:GetAimDirection() end
    c:ApplyImpulse(dir.Unit * Config.Movement.AirDodgeImpulse + Vector3.yAxis * Config.Movement.AirDodgeUpImpulse)
    c.AirDodgeAvailable = false
    c.ModeTimer = Config.Movement.AirDodgeModeTime
    c:SetMode(Modes.AirDodging)
    c:SendAction("AirDodge")
end

return ActionExecutor
