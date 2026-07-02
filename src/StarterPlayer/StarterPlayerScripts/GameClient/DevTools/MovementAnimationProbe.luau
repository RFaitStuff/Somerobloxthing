--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MovementAnimationProbe = {}
MovementAnimationProbe.__index = MovementAnimationProbe

local SAMPLE_LIMIT = 420
local PRINT_INTERVAL = 0.35
local TRACK_PRINT_INTERVAL = 1.0
local Y_SPIKE_THRESHOLD = 0.035
local VEL_MISMATCH_THRESHOLD = 3.0
local COMMIT_MISMATCH_THRESHOLD = 0.65
local POSITION_ERROR_THRESHOLD = 0.35

local function fmt(num, decimals)
    decimals = decimals or 2
    if typeof(num) ~= "number" then return tostring(num) end
    return string.format("%." .. tostring(decimals) .. "f", num)
end

local function safeVector(v)
    if typeof(v) ~= "Vector3" then return Vector3.zero end
    return v
end

local function vecShort(v)
    v = safeVector(v)
    return string.format("%.2f,%.2f,%.2f", v.X, v.Y, v.Z)
end

local function vec2Short(v)
    if typeof(v) ~= "Vector2" then return "0.00,0.00" end
    return string.format("%.2f,%.2f", v.X, v.Y)
end

local function flatMagnitude(v)
    v = safeVector(v)
    return Vector3.new(v.X, 0, v.Z).Magnitude
end

local function safeCall(defaultValue, callback)
    local ok, result = pcall(callback)
    if ok then return result end
    return defaultValue
end

local function instName(inst)
    if typeof(inst) ~= "Instance" then return "nil" end
    return inst:GetFullName()
end

local function firstNames(list, limit)
    local out = {}
    limit = limit or 8
    for i = 1, math.min(#list, limit) do
        table.insert(out, tostring(list[i]))
    end
    if #list > limit then
        table.insert(out, "+" .. tostring(#list - limit) .. " more")
    end
    return #out > 0 and table.concat(out, ",") or "none"
end

local function getTrackNames(animation)
    local items = {}
    local tracks = animation and animation.Tracks and animation.Tracks.Tracks
    if typeof(tracks) ~= "table" then
        return "tracks unavailable"
    end

    for name, track in pairs(tracks) do
        if track and track.IsPlaying then
            local weight = track.WeightCurrent or 0
            if weight > 0.01 then
                table.insert(items, string.format(
                    "%s w%s tw%s t%s/%s s%s loop=%s pri=%s",
                    tostring(name),
                    fmt(weight, 2),
                    fmt(track.WeightTarget or 0, 2),
                    fmt(track.TimePosition or 0, 2),
                    fmt(track.Length or 0, 2),
                    fmt(track.Speed or 0, 2),
                    tostring(track.Looped),
                    tostring(track.Priority)
                ))
            end
        end
    end

    table.sort(items)
    if #items == 0 then return "none" end
    return table.concat(items, " | ")
end

function MovementAnimationProbe.new(state, input, camera, motor, animation)
    return setmetatable({
        State = state,
        Input = input,
        Camera = camera,
        Motor = motor,
        Animation = animation,
        Enabled = true,
        Verbose = false,
        Connections = {},
        InputConnection = nil,
        Gui = nil,
        Label = nil,
        Samples = {},
        StageSamples = {},
        LastRootY = nil,
        LastRootCFrameY = nil,
        LastRootPosition = nil,
        LastMode = nil,
        LastPrint = 0,
        LastWarn = 0,
        LastTrackPrint = 0,
        LastAuditTime = 0,
        LastAudit = {},
        MaxYDelta = 0,
        MaxVelMismatch = 0,
        MaxCommitMismatch = 0,
        MaxPositionError = 0,
    }, MovementAnimationProbe)
end

function MovementAnimationProbe:Start()
    self:CreateGui()

    self.InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F7 then
            if self.Animation and self.Animation.ToggleAnimations then
                local enabled = self.Animation:ToggleAnimations()
                self:Warn("PLAYER ANIMATIONS " .. (enabled and "ENABLED" or "DISABLED") .. " via F7")
                self:DumpRecent("animation toggle")
            else
                self:Warn("Animation toggle unavailable")
            end
        elseif input.KeyCode == Enum.KeyCode.F8 then
            self.Enabled = not self.Enabled
            self:Print("Probe " .. (self.Enabled and "enabled" or "disabled"))
            if self.Gui then self.Gui.Enabled = self.Enabled end
        elseif input.KeyCode == Enum.KeyCode.F9 then
            self:DumpRecent("manual")
        elseif input.KeyCode == Enum.KeyCode.F10 then
            self.Verbose = not self.Verbose
            self:Print("Verbose stage logging " .. (self.Verbose and "enabled" or "disabled"))
        end
    end)

    local function connectStage(stageName, signal)
        if signal then
            table.insert(self.Connections, signal:Connect(function(dt)
                self:Update(dt, stageName)
            end))
        end
    end

    connectStage("PreSim", safeCall(nil, function() return RunService.PreSimulation end))
    connectStage("PostSim", safeCall(nil, function() return RunService.PostSimulation end))
    connectStage("Heartbeat", RunService.Heartbeat)

    self:Print("Movement/animation probe enabled. F7 toggles player animations. F8 toggles probe. F9 dumps recent. F10 toggles verbose PreSim/PostSim/Heartbeat stage logging.")
end

function MovementAnimationProbe:Destroy()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    if self.InputConnection then self.InputConnection:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

function MovementAnimationProbe:CreateGui()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "MovementAnimationProbe"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Enabled = self.Enabled
    gui.Parent = playerGui
    self.Gui = gui

    local label = Instance.new("TextLabel")
    label.Name = "Readout"
    label.Size = UDim2.fromOffset(920, 185)
    label.Position = UDim2.fromOffset(12, 44)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
    label.BorderSizePixel = 0
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextColor3 = Color3.fromRGB(235, 245, 255)
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextWrapped = false
    label.Text = "Movement probe loading..."
    label.Parent = gui
    self.Label = label
end

function MovementAnimationProbe:Print(message)
    print("[MoveAnimProbe] " .. tostring(message))
end

function MovementAnimationProbe:Warn(message)
    warn("[MoveAnimProbe] " .. tostring(message))
end

function MovementAnimationProbe:BuildAudit(root, humanoid)
    local character = self.Motor and self.Motor.Character
    local now = os.clock()
    if now - (self.LastAuditTime or 0) < 0.5 and self.LastAudit then
        return self.LastAudit
    end
    self.LastAuditTime = now

    local audit = {
        CollideParts = {},
        AnchoredParts = {},
        RootOverlap = {},
        Constraints = {},
        BasePartCount = 0,
        CollideCount = 0,
        AnchoredCount = 0,
        ConstraintCount = 0,
        RootOwner = "unknown",
        RootReceiveAge = "unknown",
        RootCollisionGroup = root and root.CollisionGroup or "nil",
        RootCanCollide = root and root.CanCollide or false,
        RootAnchored = root and root.Anchored or false,
        RootMass = root and safeCall(0, function() return root.AssemblyMass end) or 0,
    }

    if root then
        audit.RootOwner = tostring(safeCall("err", function()
            local owner = root:GetNetworkOwner()
            return owner and owner.Name or "server/nil"
        end))
        audit.RootReceiveAge = tostring(safeCall("err", function() return root.ReceiveAge end))
    end

    if character then
        for _, inst in ipairs(character:GetDescendants()) do
            if inst:IsA("BasePart") then
                audit.BasePartCount += 1
                if inst.CanCollide then
                    audit.CollideCount += 1
                    table.insert(audit.CollideParts, inst.Name .. "@" .. inst.CollisionGroup)
                end
                if inst.Anchored then
                    audit.AnchoredCount += 1
                    table.insert(audit.AnchoredParts, inst.Name)
                end
            elseif inst:IsA("LinearVelocity") or inst:IsA("VectorForce") or inst:IsA("AlignPosition") or inst:IsA("AlignOrientation") or inst:IsA("BodyVelocity") or inst:IsA("BodyPosition") or inst:IsA("BodyGyro") or inst:IsA("BodyAngularVelocity") then
                audit.ConstraintCount += 1
                table.insert(audit.Constraints, inst.ClassName .. ":" .. inst.Name)
            end
        end
    end

    if root then
        safeCall(nil, function()
            local overlapParams = OverlapParams.new()
            overlapParams.FilterType = Enum.RaycastFilterType.Exclude
            overlapParams.FilterDescendantsInstances = character and { character } or {}
            local parts = Workspace:GetPartsInPart(root, overlapParams)
            for _, part in ipairs(parts) do
                if part and part.Parent then
                    table.insert(audit.RootOverlap, part.Name .. "<" .. part.Parent.Name .. ">");
                end
            end
        end)
    end

    self.LastAudit = audit
    return audit
end


local function snapshotField(step, name, field)
    if typeof(step) ~= "table" or typeof(step[name]) ~= "table" then
        return field == "C" and CFrame.identity or Vector3.zero
    end
    return step[name][field] or (field == "C" and CFrame.identity or Vector3.zero)
end

local function deltaMag(a, b)
    if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return 0 end
    return (a - b).Magnitude
end

local function cframePosDelta(a, b)
    if typeof(a) ~= "CFrame" or typeof(b) ~= "CFrame" then return 0 end
    return (a.Position - b.Position).Magnitude
end

local function stepVecLine(step)
    if typeof(step) ~= "table" then return "step=none" end
    local startV = snapshotField(step, "Start", "V")
    local afterIntV = snapshotField(step, "AfterIntegrate", "V")
    local afterSoftV = snapshotField(step, "AfterSoftCollision", "V")
    local afterOrientV = snapshotField(step, "AfterOrientation", "V")
    local afterHumV = snapshotField(step, "AfterHumanoid", "V")
    local afterCommitV = snapshotField(step, "AfterCommit", "V")
    local afterAnimV = snapshotField(step, "AfterAnimation", "V")
    return string.format(
        "stepV start=(%s) integrate=(%s) soft=(%s) orient=(%s) hum=(%s) commit=(%s) anim=(%s) dOrient=%s dHum=%s dAnim=%s",
        vecShort(startV), vecShort(afterIntV), vecShort(afterSoftV), vecShort(afterOrientV), vecShort(afterHumV), vecShort(afterCommitV), vecShort(afterAnimV),
        fmt(deltaMag(afterSoftV, afterOrientV), 3), fmt(deltaMag(afterOrientV, afterHumV), 3), fmt(deltaMag(afterCommitV, afterAnimV), 3)
    )
end

local function stepPosLine(step)
    if typeof(step) ~= "table" then return "stepPos=none" end
    local startP = snapshotField(step, "Start", "P")
    local afterOrientP = snapshotField(step, "AfterOrientation", "P")
    local afterHumP = snapshotField(step, "AfterHumanoid", "P")
    local afterCommitP = snapshotField(step, "AfterCommit", "P")
    local afterAnimP = snapshotField(step, "AfterAnimation", "P")
    return string.format(
        "stepP start=(%s) orient=(%s) hum=(%s) commit=(%s) anim=(%s) dOrient=%s dHum=%s dAnim=%s",
        vecShort(startP), vecShort(afterOrientP), vecShort(afterHumP), vecShort(afterCommitP), vecShort(afterAnimP),
        fmt(deltaMag(startP, afterOrientP), 4), fmt(deltaMag(afterOrientP, afterHumP), 4), fmt(deltaMag(afterCommitP, afterAnimP), 4)
    )
end

function MovementAnimationProbe:BuildSample(dt, stage)
    local motor = self.Motor
    local root = motor and motor.Root
    local humanoid = motor and motor.Humanoid
    local animation = self.Animation
    local animDebug = animation and animation.GetDebugState and animation:GetDebugState() or {}

    local pos = root and root.Position or Vector3.zero
    local posY = pos.Y
    local cframeY = root and root.CFrame.Position.Y or posY
    local assemblyVelocity = root and root.AssemblyLinearVelocity or Vector3.zero
    local controllerVelocity = motor and motor.Velocity or Vector3.zero
    local moveDir = motor and motor.GetMoveDirection and motor:GetMoveDirection() or Vector3.zero
    local rawMove = self.Input and self.Input.GetMoveVector and self.Input:GetMoveVector() or Vector2.zero
    local humanoidMove = humanoid and humanoid.MoveDirection or Vector3.zero

    local rootYDelta = self.LastRootY and (posY - self.LastRootY) or 0
    local cframeYDelta = self.LastRootCFrameY and (cframeY - self.LastRootCFrameY) or 0
    local rootDelta = self.LastRootPosition and (pos - self.LastRootPosition) or Vector3.zero
    local predictedDelta = assemblyVelocity * (dt or 0)
    local positionVelocityError = (rootDelta - predictedDelta).Magnitude

    if stage == "Heartbeat" then
        self.LastRootY = posY
        self.LastRootCFrameY = cframeY
        self.LastRootPosition = pos
    end

    local velMismatch = (assemblyVelocity - controllerVelocity).Magnitude
    local debugCommit = motor and motor.DebugCommitVelocity or Vector3.zero
    local debugPreCommit = motor and motor.DebugPreCommitAssemblyVelocity or Vector3.zero
    local debugPostCommit = motor and motor.DebugPostCommitAssemblyVelocity or Vector3.zero
    local commitMismatch = (debugCommit - assemblyVelocity).Magnitude
    local postCommitWriteMismatch = (debugCommit - debugPostCommit).Magnitude
    local preToPostCommitDelta = (debugPostCommit - debugPreCommit).Magnitude

    local mode = motor and motor.Mode or "None"
    local humanoidState = humanoid and humanoid:GetState().Name or "None"
    local floor = humanoid and humanoid.FloorMaterial and humanoid.FloorMaterial.Name or "None"
    local audit = self:BuildAudit(root, humanoid)
    local wallBlock = motor and motor.DebugWallVelocityBlock or {}
    local soft = motor and motor.SoftCollision
    local groundHit = motor and motor.GroundProbe and motor.GroundProbe.LastHit
    local wallHit = motor and motor.WallProbe and motor.WallProbe.LastHit

    return {
        Time = os.clock(),
        Dt = dt or 0,
        Stage = stage or "?",
        Mode = tostring(mode),
        LastMode = motor and tostring(motor.LastMode) or "nil",
        ModeTimer = motor and motor.ModeTimer or 0,
        Grounded = motor and motor.IsGrounded == true or false,
        Floor = floor,
        HumanoidState = humanoidState,
        HumanoidWalkSpeed = humanoid and humanoid.WalkSpeed or 0,
        HumanoidHipHeight = humanoid and humanoid.HipHeight or 0,
        HumanoidAutoRotate = humanoid and humanoid.AutoRotate or false,
        HumanoidPlatformStand = humanoid and humanoid.PlatformStand or false,
        HumanoidSit = humanoid and humanoid.Sit or false,
        HumanoidMoveDirection = humanoidMove,
        RootY = posY,
        RootYDelta = rootYDelta,
        CFrameYDelta = cframeYDelta,
        RootDelta = rootDelta,
        AssemblyVelocity = assemblyVelocity,
        ControllerVelocity = controllerVelocity,
        DebugCommitVelocity = debugCommit,
        DebugPreCommitAssemblyVelocity = debugPreCommit,
        DebugPostCommitAssemblyVelocity = debugPostCommit,
        VelMismatch = velMismatch,
        CommitMismatch = commitMismatch,
        PostCommitWriteMismatch = postCommitWriteMismatch,
        PreToPostCommitDelta = preToPostCommitDelta,
        PositionVelocityError = positionVelocityError,
        PlanarSpeed = flatMagnitude(controllerVelocity),
        AssemblyPlanarSpeed = flatMagnitude(assemblyVelocity),
        MoveDir = moveDir,
        RawMove = rawMove,
        GroundNormal = motor and motor.GroundNormal or Vector3.yAxis,
        GroundDistance = groundHit and groundHit.Distance or -1,
        GroundInstance = groundHit and instName(groundHit.Instance) or "nil",
        Wall = motor and motor.HasWall == true or false,
        WallContact = motor and motor.HasWallContact == true or false,
        WallAim = motor and motor.HasWallAim == true or false,
        WallNormal = motor and motor.WallNormal or Vector3.zero,
        WallDistance = wallHit and wallHit.Distance or -1,
        WallInstance = wallHit and instName(wallHit.Instance) or "nil",
        WallApproach = motor and motor.WallApproach or 0,
        WallAge = motor and motor.WallContactAge or 0,
        WallSide = motor and motor.WallContactSide or "None",
        WallMemory = motor and motor.WallContactIsMemory == true or false,
        WallBlockApplied = wallBlock.Applied == true,
        WallBlockReason = wallBlock.Reason or "nil",
        WallBlockInto = wallBlock.Into or 0,
        WallBlockInputInto = wallBlock.InputIntoWall or 0,
        SoftCollisionStrength = soft and soft.AccumulatedStrength or 0,
        RootCanCollide = audit.RootCanCollide,
        RootAnchored = audit.RootAnchored,
        RootCollisionGroup = audit.RootCollisionGroup,
        RootMass = audit.RootMass,
        RootOwner = audit.RootOwner,
        RootReceiveAge = audit.RootReceiveAge,
        CollideCount = audit.CollideCount,
        CollideParts = firstNames(audit.CollideParts, 10),
        AnchoredCount = audit.AnchoredCount,
        AnchoredParts = firstNames(audit.AnchoredParts, 8),
        ConstraintCount = audit.ConstraintCount,
        Constraints = firstNames(audit.Constraints, 8),
        RootOverlapCount = #audit.RootOverlap,
        RootOverlap = firstNames(audit.RootOverlap, 8),
        AnimationLoop = animDebug.CurrentLoop or (animation and animation.Tracks and animation.Tracks.CurrentLoopName) or "None",
        AnimationAction = animDebug.CurrentAction or (animation and animation.Tracks and animation.Tracks.CurrentActionName) or "None",
        AnimationWeapon = animDebug.CurrentWeapon or (animation and animation.Tracks and animation.Tracks.CurrentWeaponName) or "None",
        AimGlideBlend = animDebug.AimGlideBlend or "",
        TrackSummary = getTrackNames(animation),
        AnimationsEnabled = animDebug.AnimationsEnabled ~= false,
        DebugFrameId = motor and motor.DebugFrameId or -1,
        DebugLastDt = motor and motor.DebugLastDt or 0,
        DebugStepLine = stepVecLine(motor and motor.DebugStep),
        DebugStepPosLine = stepPosLine(motor and motor.DebugStep),
        DebugUpdateMs = motor and motor.DebugStep and motor.DebugStep.EndClock and motor.DebugStep.StartClock and ((motor.DebugStep.EndClock - motor.DebugStep.StartClock) * 1000) or 0,
    }
end

function MovementAnimationProbe:Record(sample)
    table.insert(self.Samples, sample)
    while #self.Samples > SAMPLE_LIMIT do
        table.remove(self.Samples, 1)
    end
    self.StageSamples[sample.Stage or "?"] = sample
    self.MaxYDelta = math.max(self.MaxYDelta, math.abs(sample.RootYDelta or 0))
    self.MaxVelMismatch = math.max(self.MaxVelMismatch, sample.VelMismatch or 0)
    self.MaxCommitMismatch = math.max(self.MaxCommitMismatch, sample.CommitMismatch or 0)
    self.MaxPositionError = math.max(self.MaxPositionError, sample.PositionVelocityError or 0)
end

function MovementAnimationProbe:SampleLine(s)
    return string.format(
        "%s f=%s animOn=%s updMs=%s mode=%s grounded=%s hum=%s floor=%s y=%s dy=%s vCtl=(%s) vAsm=(%s) commit=(%s) mismatch=%s commitMis=%s posErr=%s move=(%s) raw=(%s) wall=%s/%s aim=%s mem=%s dist=%s inst=%s block=%s:%s into=%s input=%s soft=%s anim=%s/%s/%s",
        tostring(s.Stage), tostring(s.DebugFrameId), tostring(s.AnimationsEnabled), fmt(s.DebugUpdateMs, 3), tostring(s.Mode), tostring(s.Grounded), tostring(s.HumanoidState), tostring(s.Floor),
        fmt(s.RootY, 3), fmt(s.RootYDelta, 4),
        vecShort(s.ControllerVelocity), vecShort(s.AssemblyVelocity), vecShort(s.DebugCommitVelocity),
        fmt(s.VelMismatch, 2), fmt(s.CommitMismatch, 2), fmt(s.PositionVelocityError, 3),
        vecShort(s.MoveDir), vec2Short(s.RawMove),
        tostring(s.Wall), tostring(s.WallContact), tostring(s.WallAim), tostring(s.WallMemory), fmt(s.WallDistance, 2), tostring(s.WallInstance),
        tostring(s.WallBlockApplied), tostring(s.WallBlockReason), fmt(s.WallBlockInto, 2), fmt(s.WallBlockInputInto, 2), fmt(s.SoftCollisionStrength, 2),
        tostring(s.AnimationLoop), tostring(s.AnimationAction), tostring(s.AnimationWeapon)
    )
end

function MovementAnimationProbe:DetailLine(s)
    return string.format(
        "root owner=%s recvAge=%s rootCollide=%s group=%s mass=%s overlap=%s[%s] collidable=%s[%s] anchored=%s[%s] constraints=%s[%s] humMove=(%s) hip=%s ws=%s autoRot=%s plat=%s sit=%s groundDist=%s ground=%s groundNorm=(%s) wallNorm=(%s)",
        tostring(s.RootOwner), tostring(s.RootReceiveAge), tostring(s.RootCanCollide), tostring(s.RootCollisionGroup), fmt(s.RootMass, 2),
        tostring(s.RootOverlapCount), tostring(s.RootOverlap), tostring(s.CollideCount), tostring(s.CollideParts),
        tostring(s.AnchoredCount), tostring(s.AnchoredParts), tostring(s.ConstraintCount), tostring(s.Constraints),
        vecShort(s.HumanoidMoveDirection), fmt(s.HumanoidHipHeight, 2), fmt(s.HumanoidWalkSpeed, 2), tostring(s.HumanoidAutoRotate), tostring(s.HumanoidPlatformStand), tostring(s.HumanoidSit),
        fmt(s.GroundDistance, 2), tostring(s.GroundInstance), vecShort(s.GroundNormal), vecShort(s.WallNormal)
    )
end

function MovementAnimationProbe:DumpRecent(reason)
    self:Warn("Dumping recent movement samples: " .. tostring(reason))
    local startIndex = math.max(1, #self.Samples - 20)
    for i = startIndex, #self.Samples do
        self:Print("sample " .. tostring(i) .. ": " .. self:SampleLine(self.Samples[i]))
    end
    local hb = self.StageSamples.Heartbeat or self.Samples[#self.Samples]
    if hb then
        self:Print("details: " .. self:DetailLine(hb))
        self:Print(tostring(hb.DebugStepLine))
        self:Print(tostring(hb.DebugStepPosLine))
    end
    self:Print("activeTracks: " .. getTrackNames(self.Animation))
end

function MovementAnimationProbe:UpdateGui(sample)
    if not self.Label then return end
    self.Label.Text = table.concat({
        "Movement/Animation Probe  |  F7 animations  F8 probe  F9 dump  F10 verbose",
        self:SampleLine(sample),
        self:DetailLine(sample),
        tostring(sample.DebugStepLine),
        tostring(sample.DebugStepPosLine),
        "tracks=" .. tostring(sample.TrackSummary),
        "maxDY=" .. fmt(self.MaxYDelta, 4) .. " maxVelMis=" .. fmt(self.MaxVelMismatch, 2) .. " maxCommitMis=" .. fmt(self.MaxCommitMismatch, 2) .. " maxPosErr=" .. fmt(self.MaxPositionError, 3),
    }, "\n")
end

function MovementAnimationProbe:ShouldWarn(sample)
    local ySpike = math.abs(sample.RootYDelta or 0) >= Y_SPIKE_THRESHOLD
    local velSpike = (sample.VelMismatch or 0) >= VEL_MISMATCH_THRESHOLD
    local commitSpike = (sample.CommitMismatch or 0) >= COMMIT_MISMATCH_THRESHOLD
    local writeFailed = (sample.PostCommitWriteMismatch or 0) >= COMMIT_MISMATCH_THRESHOLD
    local posSpike = (sample.PositionVelocityError or 0) >= POSITION_ERROR_THRESHOLD and (sample.RootDelta or Vector3.zero).Magnitude > 0.05
    local wallAlways = sample.WallContact and sample.MoveDir.Magnitude <= 0.05 and sample.AssemblyPlanarSpeed <= 0.05 and sample.Stage == "Heartbeat"
    return ySpike, velSpike, commitSpike, writeFailed, posSpike, wallAlways
end

function MovementAnimationProbe:Update(dt, stage)
    if not self.Enabled then return end

    local sample = self:BuildSample(dt, stage)
    self:Record(sample)

    if stage == "Heartbeat" then
        self:UpdateGui(sample)
    end

    local now = os.clock()
    local modeChanged = self.LastMode ~= nil and self.LastMode ~= sample.Mode and stage == "Heartbeat"
    if stage == "Heartbeat" then
        self.LastMode = sample.Mode
    end

    local ySpike, velSpike, commitSpike, writeFailed, posSpike, wallAlways = self:ShouldWarn(sample)
    local shouldPrintSummary = stage == "Heartbeat" and (modeChanged or now - self.LastPrint >= PRINT_INTERVAL)
    local shouldPrintWarning = ySpike or velSpike or commitSpike or writeFailed or posSpike

    if shouldPrintWarning and (self.Verbose or now - self.LastWarn >= 0.12) then
        self.LastWarn = now
        local tags = {}
        if ySpike then table.insert(tags, "Y_SPIKE") end
        if velSpike then table.insert(tags, "VEL_MISMATCH") end
        if commitSpike then table.insert(tags, "COMMIT_TO_ASM_MISMATCH") end
        if writeFailed then table.insert(tags, "COMMIT_WRITE_FAILED") end
        if posSpike then table.insert(tags, "POSITION_ERROR") end
        self:Warn(table.concat(tags, "+") .. " " .. self:SampleLine(sample))
        self:Warn("details " .. self:DetailLine(sample))
        self:Warn(tostring(sample.DebugStepLine))
        self:Warn(tostring(sample.DebugStepPosLine))
    elseif shouldPrintSummary then
        self.LastPrint = now
        self:Print(self:SampleLine(sample))
        if wallAlways then
            self:Print("idle wall contact still true: " .. self:DetailLine(sample))
        end
    elseif self.Verbose then
        self:Print(self:SampleLine(sample))
    end

    if stage == "Heartbeat" and now - self.LastTrackPrint >= TRACK_PRINT_INTERVAL then
        self.LastTrackPrint = now
        self:Print("activeTracks: " .. tostring(sample.TrackSummary))
    end
end

return MovementAnimationProbe
