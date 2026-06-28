--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationRegistry = require(Shared:WaitForChild("AnimationRegistry"))
local Debug = require(Shared:WaitForChild("Debug"))
local Util = require(Shared:WaitForChild("Util"))
local StatusTypes = require(Shared:WaitForChild("StatusTypes"))

local SOURCE_NAMES = {
    Idle = "Idle",
    Sprint = "Sprint",
    Crouch = "Crouch",
    Block = "Block",
    SlideStart = "Slide Start",
    SlideLoop = "Slide Loop",
    Hit1 = "Hit1",
    Hit2 = "Hit2",
    Hit3 = "Hit3",
    Hit4 = "Hit4",
    RollForward = "RollForward",
    RollBackward = "RollBackward",
    RollLeft = "RollLeft",
    RollRight = "RollRight",
}

local LOOPED = {
    Idle = true,
    Sprint = true,
    Crouch = true,
    SlideLoop = true,
    Block = true,
}

local ACTION_PRIORITY = {
    Block = Enum.AnimationPriority.Action,
    Hit1 = Enum.AnimationPriority.Action,
    Hit2 = Enum.AnimationPriority.Action,
    Hit3 = Enum.AnimationPriority.Action,
    Hit4 = Enum.AnimationPriority.Action,
    RollForward = Enum.AnimationPriority.Action,
    RollBackward = Enum.AnimationPriority.Action,
    RollLeft = Enum.AnimationPriority.Action,
    RollRight = Enum.AnimationPriority.Action,
    SlideStart = Enum.AnimationPriority.Action,
}

local Tracks = {}
Tracks.__index = Tracks

function Tracks.new()
    return setmetatable({
        Animator = nil,
        Tracks = {},
        CurrentLoop = nil,
        CurrentLoopName = "None",
        CurrentAction = nil,
        CurrentActionName = "None",
        LoadedCount = 0,
        Missing = {},
        Failed = {},
    }, Tracks)
end

function Tracks:LoadFromFolder(folder)
    self.LoadedCount = 0
    table.clear(self.Missing)
    table.clear(self.Failed)

    for alias, sourceName in pairs(SOURCE_NAMES) do
        local anim = folder:FindFirstChild(sourceName)
        if not anim then
            table.insert(self.Missing, sourceName)
        elseif not anim:IsA("Animation") then
            table.insert(self.Failed, sourceName .. " is " .. anim.ClassName)
        elseif anim.AnimationId == "" then
            table.insert(self.Failed, sourceName .. " has blank AnimationId")
        else
            local ok, track = pcall(function()
                return self.Animator:LoadAnimation(anim)
            end)
            if ok and track then
                self.LoadedCount += 1
                track.Looped = LOOPED[alias] == true
                track.Priority = ACTION_PRIORITY[alias] or Enum.AnimationPriority.Movement
                self.Tracks[alias] = track
            else
                table.insert(self.Failed, sourceName .. " failed LoadAnimation")
            end
        end
    end

    if #self.Missing > 0 or #self.Failed > 0 then
        Debug.Warn(
            Debug.Channels.Animation,
            "Loaded %d controller animations. Missing: %s. Failed: %s.",
            self.LoadedCount,
            table.concat(self.Missing, ", "),
            table.concat(self.Failed, ", ")
        )
    else
        Debug.Log(Debug.Channels.Animation, "Loaded %d controller animations.", self.LoadedCount)
    end
end

function Tracks:GetDebugState()
    return {
        LoadedCount = self.LoadedCount,
        CurrentLoop = self.CurrentLoopName,
        CurrentAction = self.CurrentActionName,
        Missing = table.concat(self.Missing, ", "),
        Failed = table.concat(self.Failed, ", "),
    }
end

function Tracks:BindCharacter(character)
    self:StopAll(0)
    table.clear(self.Tracks)
    self.CurrentLoop = nil
    self.CurrentLoopName = "None"
    self.CurrentAction = nil
    self.CurrentActionName = "None"
    self.LoadedCount = 0
    table.clear(self.Missing)
    table.clear(self.Failed)

    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local defaultAnimate = character and character:FindFirstChild("Animate")
    if defaultAnimate and defaultAnimate:IsA("LocalScript") then
        defaultAnimate.Disabled = true
    end

    self.Animator = Util.GetAnimator(humanoid)
    if not self.Animator then
        table.insert(self.Failed, "Humanoid has no Animator")
        return
    end

    local folder = AnimationRegistry.Ensure()
    if folder then
        self:LoadFromFolder(folder)
    else
        table.insert(self.Missing, "ReplicatedStorage.Animations")
    end
end

function Tracks:StopAll(fade)
    for _, track in pairs(self.Tracks) do
        pcall(function()
            track:Stop(fade or 0.12)
        end)
    end
end

function Tracks:PlayLoop(name, fade)
    local track = self.Tracks[name]
    if not track then return end
    if self.CurrentLoop == track and track.IsPlaying then return end
    if self.CurrentLoop then
        self.CurrentLoop:Stop(fade or 0.14)
    end
    self.CurrentLoop = track
    self.CurrentLoopName = name
    track:Play(fade or 0.14)
end

function Tracks:PlayAction(name, fade)
    local track = self.Tracks[name]
    if not track then return end
    if self.CurrentAction == track and track.IsPlaying then return end
    if self.CurrentAction and self.CurrentAction ~= track then
        self.CurrentAction:Stop(fade or 0.08)
    end
    self.CurrentAction = track
    self.CurrentActionName = name
    track:Play(fade or 0.08)
end

function Tracks:PlayMode(mode, params)
    local speed = params and params.Speed or 0
    local moving = speed > 2

    if mode == "Sliding" then
        self:PlayAction("SlideStart", 0.06)
        self:PlayLoop("SlideLoop", 0.1)
    elseif mode == "BulletJumping" then
        self:PlayAction("SlideStart", 0.05)
        self:PlayLoop("SlideLoop", 0.08)
    elseif mode == "Gliding" or mode == "AimGliding" then
        self:PlayLoop(moving and "SlideLoop" or "Idle", 0.16)
    elseif mode == "Rolling" or mode == "AirDodging" then
        self:PlayAction(params and params.RollDirection or "RollForward", 0.05)
    elseif mode == "Crouching" then
        self:PlayLoop("Crouch", 0.12)
    elseif mode == "Grounded" then
        self:PlayLoop(moving and "Sprint" or "Idle", 0.14)
    elseif mode == "Sprinting" then
        self:PlayLoop(moving and "Sprint" or "Idle", 0.12)
    elseif mode == "MeleeLocked" then
        -- Keep the current locomotion loop under melee actions.
    elseif mode == "Idle" then
        self:PlayLoop("Idle", 0.16)
    end
end

function Tracks:PlayStatus(statusName)
    local map = {
        [StatusTypes.Stagger] = "Hit1",
        [StatusTypes.Knockback] = "Hit2",
        [StatusTypes.KnockedDown] = "Hit3",
        [StatusTypes.GetUp] = "Hit4",
    }
    local animation = map[statusName]
    if animation then self:PlayAction(animation, 0.08) end
end

function Tracks:PlayMelee(animationName)
    local map = {
        MeleeLight1 = "Hit1",
        MeleeLight2 = "Hit2",
        MeleeLight3 = "Hit3",
        MeleeHeavy = "Hit4",
        Light = "Hit1",
        Heavy = "Hit4",
        Air = "Hit2",
        Slide = "Hit3",
        Slam = "Hit4",
    }
    self:PlayAction(map[animationName] or animationName, 0.06)
end

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
        RollDirection = "RollForward",
        LastStatus = nil,
    }, Params)
end

function Params:UpdateRollDirection(motor)
    local input = motor.Input
    local move = input and input:GetMoveVector() or Vector2.zero
    if move.Magnitude <= 0.1 then
        self.RollDirection = "RollForward"
    elseif math.abs(move.X) > math.abs(move.Y) then
        self.RollDirection = move.X > 0 and "RollRight" or "RollLeft"
    else
        self.RollDirection = move.Y < 0 and "RollBackward" or "RollForward"
    end
end

function Params:UpdateFromMotor(motor)
    if not motor then return end
    self.Mode = motor.Mode or self.Mode

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
    self:UpdateRollDirection(motor)

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

local AnimationClient = {}
AnimationClient.__index = AnimationClient

function AnimationClient.new(clientState)
    return setmetatable({
        State = clientState,
        Tracks = Tracks.new(),
        Params = Params.new(),
    }, AnimationClient)
end

function AnimationClient:BindCharacter(character)
    self.Tracks:BindCharacter(character)
end

function AnimationClient:OnModeChanged(mode)
    self.Params.Mode = mode
end

function AnimationClient:OnStatusChanged(statusName)
    self.Params.LastStatus = statusName
    self.Tracks:PlayStatus(statusName)
end

function AnimationClient:PlayMelee(animationName)
    self.Tracks:PlayMelee(animationName)
end

function AnimationClient:GetDebugState()
    local trackState = self.Tracks:GetDebugState()
    trackState.Mode = self.Params.Mode
    trackState.Speed = self.Params.Speed
    trackState.VerticalSpeed = self.Params.VerticalSpeed
    return trackState
end

function AnimationClient:Update(_, motor)
    self.Params:UpdateFromMotor(motor)
    if self.Params.IsBlocking then
        self.Tracks:PlayLoop("Block", 0.08)
        return
    end
    self.Tracks:PlayMode(self.Params.Mode, self.Params)
end

return AnimationClient
