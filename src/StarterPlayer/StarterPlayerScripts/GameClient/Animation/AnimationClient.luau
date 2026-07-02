--!nonstrict
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationRegistry = require(Shared:WaitForChild("Core"):WaitForChild("AnimationRegistry"))
local Debug = require(Shared:WaitForChild("Core"):WaitForChild("Debug"))
local TempAnimationIds = require(Shared:WaitForChild("Core"):WaitForChild("TempAnimationIds"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local StatusTypes = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Statuses"))

local SOURCE_NAMES = {
    Idle = "Idle",
    Walk = "Walk",
    Sprint = "Sprint(remp)",
    Crouch = "Crouch",
    CrouchWalk = "CrouchWalk",
    Block = "Block",
    Jump = "Jump",
    Fall = "Fall",
    SlideStart = "Slide Start",
    SlideLoop = "Slide Loop",
    BulletJump = "BulletJump",
    DoubleJump = "DoubleJump",
    AimGlide = "AimGlide",
    AimGlideForward = "AimGlideForward",
    AimGlideBackward = "AimGlideBackward",
    AimGlideTurn = "AimGlideTurn",
    WallLatch = "WallLatch",
    WallHopVertical = "WallHopVertical",
    WallHopHorizontal = "WallHopHorizontal",
    HardLanding = "HardLanding",
    Hit1 = "Hit1",
    Hit2 = "Hit2",
    Hit3 = "Hit3",
    Hit4 = "Hit4",
    RollForward = "RollForward",
    RollBackward = "RollBackward",
    RollLeft = "RollLeft",
    RollRight = "RollRight",
    DodgeForward = "DodgeForward",
    DodgeBackward = "DodgeBackward",
    DodgeLeft = "DodgeLeft",
    DodgeRight = "DodgeRight",
    AirDodgeForward = "AirDodgeForward",
    AirDodgeBackward = "AirDodgeBackward",
    AirDodgeLeft = "AirDodgeLeft",
    AirDodgeRight = "AirDodgeRight",
    WeaponRelaxed = "Idle_Rifle",
    WeaponAim = "Idle_rifle_aim",
}

local DEFAULT_ANIMATE_PATHS = {
    Idle = { "idle", "Animation1" },
    Walk = { "walk", "WalkAnim" },
    Sprint = { "run", "RunAnim" },
    Crouch = { "idle", "Animation1" },
    CrouchWalk = { "walk", "WalkAnim" },
    Jump = { "jump", "JumpAnim" },
    Fall = { "fall", "FallAnim" },
}

local LOOPED = {
    Idle = true,
    Sprint = true,
    Crouch = true,
    CrouchWalk = true,
    Fall = true,
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
    DodgeForward = Enum.AnimationPriority.Action,
    DodgeBackward = Enum.AnimationPriority.Action,
    DodgeLeft = Enum.AnimationPriority.Action,
    DodgeRight = Enum.AnimationPriority.Action,
    AirDodgeForward = Enum.AnimationPriority.Action,
    AirDodgeBackward = Enum.AnimationPriority.Action,
    AirDodgeLeft = Enum.AnimationPriority.Action,
    AirDodgeRight = Enum.AnimationPriority.Action,
    SlideStart = Enum.AnimationPriority.Action,
    BulletJump = Enum.AnimationPriority.Action,
    DoubleJump = Enum.AnimationPriority.Action,
    WallHopVertical = Enum.AnimationPriority.Action,
    WallHopHorizontal = Enum.AnimationPriority.Action,
    HardLanding = Enum.AnimationPriority.Action,
    WeaponRelaxed = Enum.AnimationPriority.Action,
    WeaponAim = Enum.AnimationPriority.Action,
}

local MOVEMENT_PRIORITY = {
    Idle = Enum.AnimationPriority.Idle,
    Walk = Enum.AnimationPriority.Movement,
    Sprint = Enum.AnimationPriority.Movement,
    Crouch = Enum.AnimationPriority.Movement,
    CrouchWalk = Enum.AnimationPriority.Movement,
    Jump = Enum.AnimationPriority.Movement,
    Fall = Enum.AnimationPriority.Movement,
    SlideLoop = Enum.AnimationPriority.Action,
    AimGlide = Enum.AnimationPriority.Action,
    AimGlideForward = Enum.AnimationPriority.Action,
    AimGlideBackward = Enum.AnimationPriority.Action,
    AimGlideTurn = Enum.AnimationPriority.Action,
    WallLatch = Enum.AnimationPriority.Action,
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
        CurrentWeapon = nil,
        CurrentWeaponName = "None",
        LoadedCount = 0,
        FallbackCount = 0,
        RigType = "Unknown",
        Missing = {},
        Failed = {},
        Sources = {},
        LastKeyframe = "None",
        Connections = {},
        DefaultAnimate = nil,
        SlideLoopDelayUntil = 0,
        AimGlideBlendForward = 0,
        AimGlideBlendBackward = 0,
        AimGlideBlendTurn = 0,
        Character = nil,
        AimMotors = {},
    }, Tracks)
end

function Tracks:CleanupTrackConnections()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
end

function Tracks:GetAnimationId(anim)
    if not anim or not anim:IsA("Animation") then return nil end
    local animationId = anim.AnimationId
    if type(animationId) ~= "string" or animationId == "" then return nil end
    return animationId
end

function Tracks:MakeFallbackAnimation(alias, sourceName)
    local rigIds = TempAnimationIds[self.RigType] or TempAnimationIds.R15 or {}
    local animationId = rigIds[sourceName] or rigIds[alias]
    if type(animationId) ~= "string" or animationId == "" then return nil end

    local anim = Instance.new("Animation")
    anim.Name = alias .. "Fallback"
    anim.AnimationId = animationId
    return anim
end

function Tracks:MakeAnimationFromSource(alias, source)
    if source and source:IsA("Animation") and self:GetAnimationId(source) then
        return source, source.AnimationId
    end

    if source and source:IsA("KeyframeSequence") then
        local ok, animationId = pcall(function()
            return KeyframeSequenceProvider:RegisterKeyframeSequence(source)
        end)
        if ok and type(animationId) == "string" and animationId ~= "" then
            local anim = Instance.new("Animation")
            anim.Name = alias .. "FromSequence"
            anim.AnimationId = animationId
            return anim, source:GetFullName()
        end
        table.insert(self.Failed, alias .. " failed RegisterKeyframeSequence")
    end

    return nil, nil
end

function Tracks:GetDefaultAnimateAnimation(alias)
    local path = DEFAULT_ANIMATE_PATHS[alias]
    local current = self.DefaultAnimate
    if not path or not current then return nil end

    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end

    if current:IsA("Animation") and self:GetAnimationId(current) then
        return current
    end
    return nil
end

function Tracks:LoadTrack(alias, anim, sourceLabel)
    local ok, track = pcall(function()
        return self.Animator:LoadAnimation(anim)
    end)
    if not ok or not track then
        table.insert(self.Failed, alias .. " failed LoadAnimation from " .. sourceLabel)
        return false
    end

    self.LoadedCount += 1
    if sourceLabel == "fallback" then
        self.FallbackCount += 1
    end

    track.Looped = LOOPED[alias] == true
    track.Priority = ACTION_PRIORITY[alias] or MOVEMENT_PRIORITY[alias] or Enum.AnimationPriority.Movement
    self.Tracks[alias] = track
    self.Sources[alias] = sourceLabel .. ":" .. tostring(anim.AnimationId)

    table.insert(self.Connections, track.KeyframeReached:Connect(function(keyframeName)
        self.LastKeyframe = alias .. "." .. tostring(keyframeName)
    end))

    return true
end

function Tracks:LoadAlias(folder, alias, sourceName)
    local source, registryName = AnimationRegistry.GetSource(folder, alias)
    if not source and folder then
        source = folder:FindFirstChild(sourceName)
        registryName = sourceName
    end

    local anim = self:MakeAnimationFromSource(alias, source)
    if anim then
        if self:LoadTrack(alias, anim, source and source:IsA("KeyframeSequence") and "sequence" or "folder") then return end
    elseif source and not source:IsA("Animation") and not source:IsA("KeyframeSequence") then
        table.insert(self.Failed, registryName .. " is " .. source.ClassName)
    elseif source then
        table.insert(self.Failed, registryName .. " has blank AnimationId")
    else
        table.insert(self.Missing, registryName or sourceName)
    end

    local defaultAnim = self:GetDefaultAnimateAnimation(alias)
    if defaultAnim and self:LoadTrack(alias, defaultAnim, "animate") then
        return
    end

    local fallback = self:MakeFallbackAnimation(alias, sourceName)
    if fallback then
        self:LoadTrack(alias, fallback, "fallback")
    else
        table.insert(self.Failed, sourceName .. " has no fallback AnimationId")
    end
end

function Tracks:LoadFromFolder(folder)
    self.LoadedCount = 0
    self.FallbackCount = 0
    table.clear(self.Missing)
    table.clear(self.Failed)
    table.clear(self.Sources)

    for alias, sourceName in pairs(SOURCE_NAMES) do
        self:LoadAlias(folder, alias, sourceName)
    end

    if #self.Missing > 0 or #self.Failed > 0 then
        Debug.Warn(
            Debug.Channels.Animation,
            "Loaded %d controller animations (%d fallback). Missing: %s. Failed: %s.",
            self.LoadedCount,
            self.FallbackCount,
            table.concat(self.Missing, ", "),
            table.concat(self.Failed, ", ")
        )
    else
        Debug.Log(Debug.Channels.Animation, "Loaded %d controller animations (%d fallback).", self.LoadedCount, self.FallbackCount)
    end
end

function Tracks:GetDebugState()
    return {
        LoadedCount = self.LoadedCount,
        FallbackCount = self.FallbackCount,
        RigType = self.RigType,
        CurrentLoop = self.CurrentLoopName,
        CurrentAction = self.CurrentActionName,
        CurrentWeapon = self.CurrentWeaponName,
        CurrentLoopSource = self.Sources[self.CurrentLoopName] or "None",
        CurrentActionSource = self.Sources[self.CurrentActionName] or "None",
        CurrentWeaponSource = self.Sources[self.CurrentWeaponName] or "None",
        LastKeyframe = self.LastKeyframe,
        Missing = table.concat(self.Missing, ", "),
        Failed = table.concat(self.Failed, ", "),
    }
end

function Tracks:BindCharacter(character)
    self:StopAll(0)
    self:CleanupTrackConnections()
    self.Character = character
    table.clear(self.Tracks)
    table.clear(self.AimMotors)
    self.CurrentLoop = nil
    self.CurrentLoopName = "None"
    self.CurrentAction = nil
    self.CurrentActionName = "None"
    self.CurrentWeapon = nil
    self.CurrentWeaponName = "None"
    self.LoadedCount = 0
    self.FallbackCount = 0
    self.LastKeyframe = "None"
    self.DefaultAnimate = nil
    self.SlideLoopDelayUntil = 0
    self.AimGlideBlendForward = 0
    self.AimGlideBlendBackward = 0
    self.AimGlideBlendTurn = 0
    table.clear(self.Missing)
    table.clear(self.Failed)
    table.clear(self.Sources)

    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    self.RigType = humanoid and humanoid.RigType and humanoid.RigType.Name or "Unknown"
    local defaultAnimate = character and character:FindFirstChild("Animate")
    self.DefaultAnimate = defaultAnimate
    if defaultAnimate and defaultAnimate:IsA("LocalScript") then
        defaultAnimate.Disabled = true
    end

    self.Animator = Util.GetAnimator(humanoid)
    if not self.Animator then
        table.insert(self.Failed, "Humanoid has no Animator")
        return
    end

    local folder = AnimationRegistry.Ensure()
    if not folder then
        table.insert(self.Missing, "ReplicatedStorage.Animations")
    end
    self:LoadFromFolder(folder)
    self:CacheAimMotors(character)
end

function Tracks:StopAll(fade)
    for _, track in pairs(self.Tracks) do
        pcall(function()
            track:Stop(fade or 0.12)
        end)
    end
    self.CurrentWeapon = nil
    self.CurrentWeaponName = "None"
    self:ResetProceduralAim()
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
function Tracks:EnsureWeightedLoop(name, targetWeight, fade)
    local track = self.Tracks[name]
    if not track then return end
    fade = fade or 0.14
    if not track.IsPlaying then
        track:Play(fade, 0, 1)
    end
    track:AdjustWeight(math.clamp(targetWeight or 0, 0, 1), fade)
end

function Tracks:StopAimGlideBlend(fade)
    fade = fade or 0.12
    for _, name in ipairs({ "AimGlide", "AimGlideForward", "AimGlideBackward", "AimGlideTurn" }) do
        local track = self.Tracks[name]
        if track and track.IsPlaying then
            track:AdjustWeight(0, fade)
            track:Stop(fade)
        end
    end
    self.AimGlideBlendForward = 0
    self.AimGlideBlendBackward = 0
    self.AimGlideBlendTurn = 0
end

function Tracks:PlayAimGlideBlend(params, fade)
    fade = fade or 0.16
    local forwardWeight = 1
    local backwardWeight = 0
    local turnWeight = 0

    if params then
        forwardWeight = math.clamp(params.AimGlideForwardWeight or 1, 0, 1)
        backwardWeight = math.clamp(params.AimGlideBackwardWeight or 0, 0, 1)
        turnWeight = math.clamp(params.AimGlideTurnWeight or 0, 0, 1)
    end

    -- Keep a generic AimGlide fallback alive at low weight so old projects with only
    -- one AimGlide animation still work. Dedicated directional tracks override it.
    local hasDirectional = self.Tracks.AimGlideForward or self.Tracks.AimGlideBackward or self.Tracks.AimGlideTurn
    if hasDirectional then
        self:EnsureWeightedLoop("AimGlide", 0, fade)
        self:EnsureWeightedLoop("AimGlideForward", forwardWeight, fade)
        self:EnsureWeightedLoop("AimGlideBackward", backwardWeight, fade)
        self:EnsureWeightedLoop("AimGlideTurn", turnWeight, fade)
        self.CurrentLoop = self.Tracks.AimGlideForward or self.Tracks.AimGlide or self.CurrentLoop
        self.CurrentLoopName = string.format("AimGlide %.2f/%.2f/%.2f", forwardWeight, backwardWeight, turnWeight)
    else
        self:PlayLoop("AimGlide", fade)
    end

    self.AimGlideBlendForward = forwardWeight
    self.AimGlideBlendBackward = backwardWeight
    self.AimGlideBlendTurn = turnWeight
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

function Tracks:PlayWeaponPose(name, fade)
    local track = self.Tracks[name]
    if not track then return end
    if self.CurrentWeapon == track and track.IsPlaying then
        track:AdjustWeight(1, fade or 0.12)
        return
    end
    if self.CurrentWeapon and self.CurrentWeapon ~= track then
        self.CurrentWeapon:Stop(fade or 0.12)
    end
    self.CurrentWeapon = track
    self.CurrentWeaponName = name
    track:Play(fade or 0.12, 1, 1)
end

function Tracks:StopWeaponPose(fade)
    if self.CurrentWeapon then
        self.CurrentWeapon:Stop(fade or 0.12)
    end
    self.CurrentWeapon = nil
    self.CurrentWeaponName = "None"
    self:ResetProceduralAim()
end

function Tracks:CacheAimMotors(character)
    table.clear(self.AimMotors)
    if not character then return end
    local upperTorso = character:FindFirstChild("UpperTorso")
    local lowerTorso = character:FindFirstChild("LowerTorso")
    if upperTorso then
        self.AimMotors.Neck = upperTorso:FindFirstChild("Neck")
        self.AimMotors.RightShoulder = upperTorso:FindFirstChild("RightShoulder")
        self.AimMotors.LeftShoulder = upperTorso:FindFirstChild("LeftShoulder")
    end
    if lowerTorso then
        self.AimMotors.Waist = lowerTorso:FindFirstChild("Waist")
    end
end

function Tracks:ResetProceduralAim()
    for _, motor in pairs(self.AimMotors) do
        if motor and motor:IsA("Motor6D") then
            motor.Transform = CFrame.identity
        end
    end
end

function Tracks:ApplyProceduralAim(motor, isAiming, dt)
    if not isAiming then
        self:ResetProceduralAim()
        return
    end

    local aim = motor and motor.GetAimDirection and motor:GetAimDirection() or Vector3.new(0, 0, -1)
    local root = motor and motor.Root
    if not root then return end

    local localAim = root.CFrame:VectorToObjectSpace(aim)
    local pitch = math.asin(math.clamp(localAim.Y, -1, 1))
    local yaw = math.atan2(-localAim.X, -localAim.Z)
    local alpha = Util.ExpDecaySharpness(18, dt or 1 / 60)

    local function apply(name, pitchLimit, yawLimit, scale)
        local joint = self.AimMotors[name]
        if not joint or not joint:IsA("Motor6D") then return end
        local target = CFrame.Angles(
            math.clamp(pitch * scale, math.rad(-pitchLimit), math.rad(pitchLimit)),
            math.clamp(yaw * scale, math.rad(-yawLimit), math.rad(yawLimit)),
            0
        )
        joint.Transform = joint.Transform:Lerp(target, alpha)
    end

    apply("Neck", 35, 24, 0.55)
    apply("Waist", 18, 18, 0.32)
    apply("RightShoulder", 15, 15, 0.22)
    apply("LeftShoulder", 15, 15, 0.22)
end

function Tracks:AdjustLoopSpeed(speed, referenceSpeed)
    if not self.CurrentLoop then return end
    local playbackSpeed = math.clamp(speed / math.max(referenceSpeed or 16, 1), 0.7, 1.45)
    pcall(function()
        self.CurrentLoop:AdjustSpeed(playbackSpeed)
    end)
end

function Tracks:PlayMode(mode, params)
    local speed = params and params.Speed or 0
    local moving = speed > 2

    if mode ~= "Gliding" and mode ~= "AimGliding" then
        self:StopAimGlideBlend(0.12)
    end

    if mode == "Sliding" then
        if os.clock() < (self.SlideLoopDelayUntil or 0) then
            return
        end
        self:PlayLoop("SlideLoop", 0.1)
    elseif mode == "BulletJumping" then
        self:PlayLoop("Fall", 0.1)
    elseif mode == "Gliding" or mode == "AimGliding" then
        self:PlayAimGlideBlend(params, 0.18)
    elseif mode == "WallLatched" then
        self:PlayLoop("WallLatch", 0.08)
    elseif mode == "WallHopping" then
        -- One-shot wall hop action is started by PlayParkour; keep fall/air loop underneath.
        self:PlayLoop("Fall", 0.12)
    elseif mode == "Rolling" then
        self:PlayAction(params and params.RollDirection or "RollForward", 0.05)
    elseif mode == "AirDodging" then
        self:PlayAction(params and params.AirDodgeDirection or "AirDodgeForward", 0.05)
    elseif mode == "Crouching" then
        self:PlayLoop(moving and "CrouchWalk" or "Crouch", 0.12)
        self:AdjustLoopSpeed(speed, 10)
    elseif mode == "Grounded" then
        self:PlayLoop(moving and "Walk" or "Idle", 0.14)
        self:AdjustLoopSpeed(speed, 16)
    elseif mode == "Sprinting" then
        self:PlayLoop(moving and "Sprint" or "Idle", 0.12)
        self:AdjustLoopSpeed(speed, 22)
    elseif mode == "Airborne" then
        self:PlayLoop("Fall", 0.12)
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
        SwordLight1 = "Hit1",
        SwordLight2 = "Hit2",
        SwordLight3 = "Hit3",
        SwordForward1 = "Hit2",
        SwordForward2 = "Hit3",
        SwordHeavy = "Hit4",
        SwordAir = "Hit2",
        SwordSlide = "Hit3",
        SwordSlam = "Hit4",
        HeavyBladeLight1 = "Hit1",
        HeavyBladeLight2 = "Hit2",
        HeavyBladeLight3 = "Hit3",
        HeavyBladeForward1 = "Hit3",
        HeavyBladeHeavy = "Hit4",
        HeavyBladeAir = "Hit2",
        HeavyBladeSlide = "Hit3",
        HeavyBladeSlam = "Hit4",
        FistLight1 = "Hit1",
        FistLight2 = "Hit2",
        FistLight3 = "Hit3",
        FistForward1 = "Hit2",
        FistForward2 = "Hit3",
        FistHeavy = "Hit4",
        FistAir = "Hit2",
        FistSlide = "Hit3",
        FistSlam = "Hit4",
        Light = "Hit1",
        Forward = "Hit2",
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
        IsShooting = false,
        IsBlocking = false,
        IsSlowed = false,
        IsStaggered = false,
        IsKnockedDown = false,
        SpeedMultiplier = 1,
        SlopeAngle = 0,
        DownhillStrength = 0,
        SoftPlayerCollisionStrength = 0,
        RollDirection = "RollForward",
        AirDodgeDirection = "AirDodgeForward",
        AimGlideForwardWeight = 1,
        AimGlideBackwardWeight = 0,
        AimGlideTurnWeight = 0,
        AimGlideFacingDot = 1,
        LastStatus = nil,
    }, Params)
end

function Params:GetDirectionalAlias(prefix, motor)
    local input = motor.Input
    local move = input and input:GetMoveVector() or Vector2.zero
    if move.Magnitude <= 0.1 then
        return prefix .. "Forward"
    elseif math.abs(move.X) > math.abs(move.Y) then
        return move.X > 0 and (prefix .. "Right") or (prefix .. "Left")
    else
        return move.Y < 0 and (prefix .. "Backward") or (prefix .. "Forward")
    end
end

function Params:UpdateRollDirection(motor)
    self.RollDirection = self:GetDirectionalAlias("Roll", motor)
    self.AirDodgeDirection = self:GetDirectionalAlias("AirDodge", motor)
end

function Params:UpdateAimGlideBlend(motor)
    local velocity = motor.Velocity or Vector3.zero
    local planar = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = planar.Magnitude

    if speed <= 3 then
        self.AimGlideForwardWeight = 1
        self.AimGlideBackwardWeight = 0
        self.AimGlideTurnWeight = 0
        self.AimGlideFacingDot = 1
        return
    end

    local aim = motor.GetAimDirection and motor:GetAimDirection() or Vector3.new(0, 0, -1)
    local aimFlat = Vector3.new(aim.X, 0, aim.Z)
    if aimFlat.Magnitude <= 0.001 then aimFlat = planar end

    local dot = math.clamp(aimFlat.Unit:Dot(planar.Unit), -1, 1)
    self.AimGlideFacingDot = dot

    -- Warframe-like aim glide keeps the gun/camera aim authoritative. If the player
    -- looks opposite their travel, blend toward a reverse/turn pose instead of snapping.
    self.AimGlideForwardWeight = math.clamp((dot + 0.25) / 1.25, 0, 1)
    self.AimGlideBackwardWeight = math.clamp((-dot - 0.15) / 0.85, 0, 1)
    self.AimGlideTurnWeight = math.clamp((1 - math.abs(dot)) / 0.8, 0, 1) * 0.65

    local total = self.AimGlideForwardWeight + self.AimGlideBackwardWeight + self.AimGlideTurnWeight
    if total > 1 then
        self.AimGlideForwardWeight /= total
        self.AimGlideBackwardWeight /= total
        self.AimGlideTurnWeight /= total
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
    self.IsShooting = motor.Input and motor.Input:IsHeld("Fire") or false
    self.IsBlocking = motor.Input and motor.Input:IsHeld("MeleeBlock") or false
    self.SpeedMultiplier = motor.GetSpeedMultiplier and motor:GetSpeedMultiplier() or 1
    self.IsSlowed = motor.StatusController and motor.StatusController:IsSlowed() or false
    self.IsKnockedDown = motor.StatusController and motor.StatusController:IsKnockedDown() or false
    self.IsStaggered = motor.Mode == "Staggered"
    self.SoftPlayerCollisionStrength = motor.SoftCollision and motor.SoftCollision.AccumulatedStrength or 0
    self:UpdateRollDirection(motor)
    self:UpdateAimGlideBlend(motor)

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
        WeaponRemote = nil,
        WeaponAttachMode = "RightHand",
        HolsterUntil = 0,
    }, AnimationClient)
end

function AnimationClient:BindCharacter(character)
    self.Tracks:BindCharacter(character)
    self.WeaponAttachMode = "RightHand"
    self.HolsterUntil = 0
    self.WeaponRemote = self.WeaponRemote or Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
end

function AnimationClient:OnModeChanged(mode)
    self.Params.Mode = mode
    if mode == "Sliding" then
        self:PlayParkour("SlideStart")
    elseif mode == "WallLatched" then
        self.Tracks:PlayLoop("WallLatch", 0.08)
    elseif mode == "AimGliding" then
        self.Tracks:PlayAimGlideBlend(self.Params, 0.18)
    end
end

function AnimationClient:OnStatusChanged(statusName)
    self.Params.LastStatus = statusName
    self.Tracks:PlayStatus(statusName)
end

function AnimationClient:PlayMelee(animationName)
    self.Tracks:PlayMelee(animationName)
end

function AnimationClient:PlayParkour(animationName)
    if animationName == "SlideStart" then
        self.Tracks.SlideLoopDelayUntil = os.clock() + 0.18
    elseif animationName == "DoubleJump" then
        self.HolsterUntil = os.clock() + 0.42
        self:SetWeaponAttachMode("BackHolster")
    end
    self.Tracks:PlayAction(animationName, 0.055)
end

function AnimationClient:SetWeaponAttachMode(mode)
    if self.WeaponAttachMode == mode then return end
    self.WeaponAttachMode = mode
    self.WeaponRemote = self.WeaponRemote or Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
    self.WeaponRemote:FireServer({ Action = "VisualAttachMode", Mode = mode })
end

function AnimationClient:IsRangedWeaponEquipped()
    local weapon = Weapons.Get(self.State.EquippedWeaponId)
    return weapon and weapon.Kind == "Ranged"
end

function AnimationClient:UpdateWeaponPose(dt, motor)
    if not self:IsRangedWeaponEquipped() then
        self.Tracks:StopWeaponPose(0.12)
        return
    end

    local activeAim = self.Params.IsAiming or self.Params.IsShooting
    if activeAim or os.clock() >= (self.HolsterUntil or 0) then
        self:SetWeaponAttachMode("RightHand")
    end

    self.Tracks:PlayWeaponPose(activeAim and "WeaponAim" or "WeaponRelaxed", 0.14)
    self.Tracks:ApplyProceduralAim(motor, activeAim, dt)
end

function AnimationClient:DebugPlayAnimation(alias)
    if alias == "Idle_Rifle" or alias == "WeaponRelaxed" then alias = "WeaponRelaxed" end
    if alias == "Idle_rifle_aim" or alias == "WeaponAim" then alias = "WeaponAim" end
    if alias == "Sprint(remp)" then alias = "Sprint" end
    if alias == "Jump_Start" then alias = "Jump" end
    if alias == "Jump_Loop" then alias = "Fall" end
    if alias == "Float" then alias = "AimGlideForward" end
    if alias == "Float_Reverse" then alias = "AimGlideBackward" end
    if alias == "Double_Jump" then alias = "DoubleJump" end
    if alias == "Crouch_Idle" then alias = "Crouch" end

    if alias == "WeaponRelaxed" or alias == "WeaponAim" then
        self.Tracks:PlayWeaponPose(alias, 0.08)
    elseif LOOPED[alias] then
        self.Tracks:PlayLoop(alias, 0.08)
    else
        self.Tracks:PlayAction(alias, 0.08)
    end
end

function AnimationClient:GetDebugState()
    local trackState = self.Tracks:GetDebugState()
    trackState.Mode = self.Params.Mode
    trackState.Speed = self.Params.Speed
    trackState.VerticalSpeed = self.Params.VerticalSpeed
    trackState.AimGlideFacingDot = self.Params.AimGlideFacingDot
    trackState.AimGlideBlend = string.format("F %.2f / B %.2f / T %.2f", self.Params.AimGlideForwardWeight, self.Params.AimGlideBackwardWeight, self.Params.AimGlideTurnWeight)
    return trackState
end

function AnimationClient:Update(dt, motor)
    self.Params:UpdateFromMotor(motor)
    if self.Params.IsBlocking then
        self.Tracks:PlayLoop("Block", 0.08)
        return
    end
    self.Tracks:PlayMode(self.Params.Mode, self.Params)
    self:UpdateWeaponPose(dt, motor)
end

return AnimationClient
