--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("Core"):WaitForChild("MovementModes"))

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(controller)
    return setmetatable({ Controller = controller }, StateMachine)
end

function StateMachine:HandleTransitions(dt)
    local c = self.Controller
    c.BulletJumpCooldown = math.max(0, c.BulletJumpCooldown - dt)
    c.SlideBoostCooldown = math.max(0, (c.SlideBoostCooldown or 0) - dt)
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

    if bullet or (jump and (slideHeld or crouchHeld or c.Mode == Modes.Sliding)) then
        if c.ActionExecutor:TryBulletJump() then return end
    end

    if jump then
        -- Wall hop only wins over double jump when the player is actually trying to continue up/along the wall.
        if not c.IsGrounded and c.ActionExecutor:TryWallHop(false) then return end
        if c.ActionExecutor:TryJump() then return end
    elseif not c.IsGrounded and c.Input:IsHeld("Jump") then
        -- Held jump makes wall climbing easy like a wall-hop chain, without forcing perfectly timed presses.
        if c.ActionExecutor:TryWallHop(true) then return end
    end

    if roll and c.IsGrounded then c.ActionExecutor:DoRoll(); return end
    if dodgeTapped then
        if c.IsGrounded or c.AirDodgeAvailable then c.ActionExecutor:DoDodge(); return end
    end
    if roll and not c.IsGrounded then
        if c.AirDodgeAvailable then c.ActionExecutor:DoAirDodge(); return end
    end

    if c.IsGrounded then
        c:ResetSurfaceActions()
        if self:ShouldSlide() then c.ActionExecutor:StartSlide(); return end
        if crouchHeld then c:SetMode(Modes.Crouching); return end
        -- Sprint is intentionally default; holding Sprint is treated as walk/precision movement.
        c:SetMode(c.Input:IsHeld("Sprint") and Modes.Grounded or Modes.Sprinting)
        return
    end

    if c.Mode == Modes.WallHopping and c.ModeTimer > 0 then
        return
    end

    if aimHeld and c.State.CanAimGlide and c.HasWallAim and c.FocusEnergy > 0 then
        if c.Mode ~= Modes.WallLatched and c.WallLatchRefreshAvailable then
            c.AirJumpsRemaining = math.max(c.AirJumpsRemaining, 1)
            c.WallLatchRefreshAvailable = false
            c.FocusEnergy = math.max(c.FocusEnergy, Config.Movement.FocusEnergy * Config.Movement.WallLatchRefreshFraction)
        end
        c:SetMode(Modes.WallLatched)
        return
    end

    if aimHeld and c.State.CanAimGlide and c.FocusEnergy > 0 then
        c:SetMode(Modes.AimGliding)
        return
    end

    if c.Mode ~= Modes.BulletJumping and c.Mode ~= Modes.AirDodging then
        c:SetMode(Modes.Airborne)
    end
end

function StateMachine:ShouldSlide()
    local c = self.Controller
    local slideHeld = c.Input:IsHeld("Slide")
    if not slideHeld then return false end
    if c.Mode == Modes.Sliding then return false end
    if c.Input:GetHeldDuration("Slide") < Config.Movement.SlideHoldToStartTime then return false end
    local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
    return planar.Magnitude >= Config.Movement.SlideStartSpeed or c.Input:GetMoveVector().Magnitude > 0.05
end

return StateMachine
