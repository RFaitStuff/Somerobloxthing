--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("MovementModes"))
local Util = require(Shared:WaitForChild("Util"))

local ActionExecutor = {}
ActionExecutor.__index = ActionExecutor

function ActionExecutor.new(controller)
    return setmetatable({ Controller = controller }, ActionExecutor)
end

function ActionExecutor:TryJump()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return false end
    if c.IsGrounded then
        c.Velocity = Vector3.new(c.Velocity.X, Config.Movement.JumpVelocity, c.Velocity.Z)
        c:SetMode(Modes.Airborne)
        c:SendAction("Jump")
        return true
    end
    if c.AirJumpsRemaining > 0 then
        c.AirJumpsRemaining -= 1
        local move = c:GetMoveDirection()
        c.Velocity = Vector3.new(c.Velocity.X, math.max(c.Velocity.Y, Config.Movement.DoubleJumpVelocity), c.Velocity.Z)
        if move.Magnitude > 0 then c:ApplyImpulse(move.Unit * Config.Movement.DoubleJumpForwardBoost) end
        c:SetMode(Modes.Airborne)
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

    local aim = c:GetAimDirection()
    if aim.Y < -0.15 then
        local flat = Util.SafeUnit(Vector3.new(aim.X, 0, aim.Z), c:GetFlatForward())
        aim = Util.SafeUnit(flat * (1 - Config.Movement.BulletJumpMinUpWhenLookingDown) + Vector3.yAxis * Config.Movement.BulletJumpMinUpWhenLookingDown, Vector3.yAxis)
    end

    local planar = Util.ClampMagnitude(Vector3.new(aim.X, 0, aim.Z) * Config.Movement.BulletJumpForwardImpulse, Config.Movement.BulletJumpMaxAddedPlanarSpeed)
    local vertical = math.min(Config.Movement.BulletJumpUpImpulse + math.max(aim.Y, 0) * 14, Config.Movement.BulletJumpMaxAddedVerticalSpeed)
    c:ApplyImpulse(planar + Vector3.yAxis * vertical)
    c:SetMode(Modes.BulletJumping)
    c:SendAction("BulletJump")
    return true
end

function ActionExecutor:TryWallHop()
    local c = self.Controller
    if c:IsMovementLockedByStatus() or not c.HasWall then return false end
    c:ApplyImpulse(c.WallNormal * Config.Movement.WallHopAwayImpulse + Vector3.yAxis * Config.Movement.WallHopUpImpulse + c:GetFlatForward() * Config.Movement.WallHopForwardImpulse)
    c.ModeTimer = Config.Movement.WallHopModeTime
    c:ResetSurfaceActions()
    c:SetMode(Modes.WallHopping)
    c:SendAction("WallHop")
    return true
end

function ActionExecutor:StartSlide()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return end
    local move = c:GetMoveDirection()
    if move.Magnitude < Config.Movement.SlideMinInput then return end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    local dir = planar.Magnitude > 1 and planar.Unit or move.Unit
    if planar.Magnitude < Config.Movement.SlideStartSpeed then
        planar = dir * Config.Movement.SlideStartSpeed
    end
    c.Velocity = Vector3.new(planar.X, math.min(c.Velocity.Y, Config.Movement.SlideLaunchVerticalClamp), planar.Z)
    c:ApplyImpulse(dir * Config.Movement.SlideStartBoost)
    c.ModeTimer = Config.Movement.SlideMinTime
    c:SetMode(Modes.Sliding)
    c:SendAction("Slide")
end

function ActionExecutor:DoRoll()
    local c = self.Controller
    if c:IsMovementLockedByStatus() then return end
    local dir = c:GetMoveDirection()
    if dir.Magnitude < 0.05 then dir = c:GetFlatForward() end
    c:ApplyImpulse(dir.Unit * Config.Movement.RollImpulse)
    c.ModeTimer = Config.Movement.RollModeTime
    c:SetMode(Modes.Rolling)
    c:SendAction("Roll")
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
