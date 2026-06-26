--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("MovementModes"))

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(controller)
    return setmetatable({ Controller = controller }, StateMachine)
end

function StateMachine:HandleTransitions(dt)
    local c = self.Controller
    c.BulletJumpCooldown = math.max(0, c.BulletJumpCooldown - dt)
    c.ModeTimer = math.max(0, c.ModeTimer - dt)
    c.MeleeLockTimer = math.max(0, c.MeleeLockTimer - dt)

    if c.StatusController and c.StatusController:IsMovementLocked() then return end
    if c.MeleeLockTimer > 0 then return end
    if c.Mode == Modes.BulletJumping and c.ModeTimer <= 0 then c:SetMode(Modes.Airborne) end
    if (c.Mode == Modes.Rolling or c.Mode == Modes.AirDodging or c.Mode == Modes.WallHopping) and c.ModeTimer <= 0 then
        c:SetMode(c.IsGrounded and Modes.Grounded or Modes.Airborne)
    end

    local jump = c.Input:ConsumePressed("Jump")
    local bullet = c.Input:ConsumePressed("BulletJump")
    local roll = c.Input:ConsumePressed("Roll") or c.Input:ConsumeDoubleTapped("Slide", Config.Movement.RollDoubleTapWindow, Config.Movement.DodgeTapMaxTime)
    local dodgeTapped = c.Input:ConsumeTapped("Sprint", Config.Movement.DodgeTapMaxTime) or c.Input:ConsumeTapped("AirDodge", Config.Movement.DodgeTapMaxTime)
    local slideHeld = c.Input:IsHeld("Slide")
    local crouchHeld = c.Input:IsHeld("Crouch")
    local aimHeld = c.Input:IsHeld("Aim")

    if bullet or (jump and (slideHeld or crouchHeld or c.Mode == Modes.Sliding or c.Mode == Modes.WallLatched)) then
        if c.ActionExecutor:TryBulletJump() then return end
    end
    if jump then
        if not c.IsGrounded and c.HasWall and c.ActionExecutor:TryWallHop() then return end
        if c.ActionExecutor:TryJump() then return end
    end
    if (roll or dodgeTapped) and c.IsGrounded then c.ActionExecutor:DoRoll(); return end
    if dodgeTapped or (roll and not c.IsGrounded) then
        if c.AirDodgeAvailable then c.ActionExecutor:DoAirDodge(); return end
    end

    if c.IsGrounded then
        c:ResetSurfaceActions()
        if self:ShouldSlide() then c.ActionExecutor:StartSlide(); return end
        if crouchHeld or slideHeld then c:SetMode(Modes.Crouching); return end
        c:SetMode(c.Input:IsHeld("Sprint") and Modes.Grounded or Modes.Sprinting)
        return
    end

    if aimHeld and c.State.CanAimGlide and c.HasWall and c.FocusEnergy > 0 then
        c:SetMode(Modes.WallLatched)
    elseif aimHeld and c.State.CanAimGlide and c.FocusEnergy > 0 then
        c:SetMode(Modes.Gliding)
    elseif c.Mode ~= Modes.BulletJumping and c.Mode ~= Modes.AirDodging and c.Mode ~= Modes.WallHopping then
        c:SetMode(Modes.Airborne)
    end
end

function StateMachine:ShouldSlide()
    local c = self.Controller
    if not c.Input:IsHeld("Slide") then return false end
    if c.Input.GetHeldDuration and c.Input:GetHeldDuration("Slide") < Config.Movement.SlideHoldToStartTime then return false end
    if c:GetMoveDirection().Magnitude < Config.Movement.SlideMinInput then return false end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    return planar.Magnitude >= Config.Movement.SlideStartSpeed
end

return StateMachine
