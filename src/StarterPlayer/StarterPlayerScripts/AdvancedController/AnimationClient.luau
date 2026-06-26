--!nonstrict
-- AnimationIds ------------------------------------------------------------
local AnimationIds = {
    Idle = 0,
    Run = 0,
    Sprint = 0,
    Crouch = 0,
    Jump = 0,
    Fall = 0,
    Slide = 0,
    SlideDownhill = 0,
    BulletJump = 0,
    AimGlide = 0,
    WallLatch = 0,
    Roll = 0,
    AirDodge = 0,
    Stagger = 0,
    Knockback = 0,
    KnockDown = 0,
    KnockDownLoop = 0,
    GetUp = 0,
    Slowed = 0,
    MeleeLight1 = 0,
    MeleeLight2 = 0,
    MeleeLight3 = 0,
    MeleeHeavy = 0,
    MeleeAir = 0,
    MeleeSlide = 0,
    MeleeSlam = 0,
    MeleeBlock = 0,
}

-- AnimationTracks ------------------------------------------------------------
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Util"))
local StatusTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("StatusTypes"))


local Tracks = {}
Tracks.__index = Tracks

function Tracks.new()
    return setmetatable({ Animator = nil, Tracks = {} }, Tracks)
end

function Tracks:BindCharacter(character)
    table.clear(self.Tracks)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    self.Animator = Util.GetAnimator(humanoid)
    if not self.Animator then return end
    for name, id in pairs(AnimationIds) do
        if type(id) == "number" and id > 0 then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. tostring(id)
            self.Tracks[name] = self.Animator:LoadAnimation(anim)
        end
    end
end

function Tracks:Play(name, fade)
    local track = self.Tracks[name]
    if track then track:Play(fade or 0.08) end
end

function Tracks:Stop(name, fade)
    local track = self.Tracks[name]
    if track then track:Stop(fade or 0.08) end
end

function Tracks:PlayMode(mode)
    local map = {
        Grounded = "Run",
        Sprinting = "Sprint",
        Crouching = "Crouch",
        Sliding = "Slide",
        BulletJumping = "BulletJump",
        AimGliding = "AimGlide",
        WallLatched = "WallLatch",
        Rolling = "Roll",
        AirDodging = "AirDodge",
        Airborne = "Fall",
        Staggered = "Stagger",
        KnockedDown = "KnockDown",
        GettingUp = "GetUp",
    }
    self:Play(map[mode] or mode)
end

function Tracks:PlayStatus(statusName)
    local map = {
        [StatusTypes.Stagger] = "Stagger",
        [StatusTypes.Knockback] = "Knockback",
        [StatusTypes.KnockedDown] = "KnockDown",
        [StatusTypes.GetUp] = "GetUp",
        [StatusTypes.Slow] = "Slowed",
    }
    self:Play(map[statusName] or statusName)
end

-- AnimatorParams ------------------------------------------------------------
local Params = {}
Params.__index = Params

function Params.new()
    return setmetatable({
        Mode = "Idle",
        Speed = 0,
        VerticalSpeed = 0,
        IsGrounded = false,
        IsAiming = false,
        IsBlocking = false,
        IsSlowed = false,
        IsStaggered = false,
        IsKnockedDown = false,
        SpeedMultiplier = 1,
        SlopeAngle = 0,
        DownhillStrength = 0,
        SoftPlayerCollisionStrength = 0,
        LastStatus = nil,
    }, Params)
end

function Params:UpdateFromMotor(motor)
    if not motor then return end
    local v = motor.Velocity or Vector3.zero
    self.Speed = Vector3.new(v.X, 0, v.Z).Magnitude
    self.VerticalSpeed = v.Y
    self.IsGrounded = motor.IsGrounded
    self.IsAiming = motor.Input and motor.Input:IsHeld("Aim") or false
    self.IsBlocking = motor.Input and motor.Input:IsHeld("MeleeBlock") or false
    self.SpeedMultiplier = motor.GetSpeedMultiplier and motor:GetSpeedMultiplier() or 1
    self.IsSlowed = motor.StatusController and motor.StatusController:IsSlowed() or false
    self.IsKnockedDown = motor.StatusController and motor.StatusController:IsKnockedDown() or false
    self.IsStaggered = motor.Mode == "Staggered"
    self.SoftPlayerCollisionStrength = motor.SoftCollision and motor.SoftCollision.AccumulatedStrength or 0
    local normal = motor.GroundNormal or Vector3.yAxis
    self.SlopeAngle = math.deg(math.acos(math.clamp(normal.Y, -1, 1)))
    self.DownhillStrength = motor.SlopeMotor and motor.SlopeMotor.DownhillStrength or 0
    if motor.State then
        motor.State.IsSlowed = self.IsSlowed
        motor.State.IsStaggered = self.IsStaggered
        motor.State.IsKnockedDown = self.IsKnockedDown
        motor.State.SpeedMultiplier = self.SpeedMultiplier
        motor.State.SoftPlayerCollisionStrength = self.SoftPlayerCollisionStrength
    end
end

-- Main ------------------------------------------------------------

local AnimationClient = {}
AnimationClient.__index = AnimationClient

function AnimationClient.new(clientState)
    return setmetatable({ State = clientState, Tracks = Tracks.new(), Params = Params.new() }, AnimationClient)
end

function AnimationClient:BindCharacter(character)
    self.Tracks:BindCharacter(character)
end

function AnimationClient:OnModeChanged(mode)
    self.Params.Mode = mode
    self.Tracks:PlayMode(mode)
end

function AnimationClient:OnStatusChanged(statusName)
    self.Params.LastStatus = statusName
    self.Tracks:PlayStatus(statusName)
end

function AnimationClient:PlayMelee(animationName)
    self.Tracks:Play(animationName)
end

function AnimationClient:Update(_, motor)
    self.Params:UpdateFromMotor(motor)
end

return AnimationClient
