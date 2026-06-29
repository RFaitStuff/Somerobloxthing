--!nonstrict
-- Consolidated gameplay/camera/combat/security tuning.

return {
    Movement = {
    -- Scale basis: Warframe base walk/sprint is 6/7.5 m/s. Roblox movement is studs/s.
    -- Using 1 stud ~= 0.28m gives 3.571 studs/m, so 6m/s ~= 21.4 and 7.5m/s ~= 26.8.
    StudsPerMeter = 3.571,
    WalkSpeed = 27.5,
    SprintSpeed = 40,

    -- Acceleration is derived from target-speed / time-to-target.
    -- Sprint target in ~0.18s: 26.8 / 0.18 ~= 149. Decel in ~0.14s: 26.8 / 0.14 ~= 191.
    GroundAcceleration = 150,
    GroundDeceleration = 190,
    SprintRampAcceleration = 115,
    AirAcceleration = 27,
    AirDrag = 0.45,

    -- Slightly floatier than Roblox default gravity. Jump values are kept below parkour burst power
    -- so slide -> bullet jump remains the primary Warframe-like movement chain.
    Gravity = -93,
    GroundStickVelocity = -9,

    -- Jump height formula: h = v^2 / (2g). 42 studs/s at 93g reaches ~9.5 studs.
    JumpVelocity = 44,
    JumpPlanarPreserve = 0.9,
    JumpHoldMaxTime = 0.14,
    JumpCutMinVelocity = 24,
    DoubleJumpVelocity = 48,
    DoubleJumpPlanarPreserve = 0.9,
    DoubleJumpForwardBoost = 7,
    AirJumpsPerSurface = 1,

    CrouchHipHeightScale = 0.72,
    SlideHipHeightScale = 0.55,
    HipHeightSharpness = 12,
    CrouchSpeed = 23,
    SlideHoldToStartTime = 0.1,
    SlideStartSpeed = 29,
    SlideMinTime = 0.22,
    SlideStartBoost = 3.2,
    SlideBoostCooldown = 0.9,
    -- Linear friction in studs/s^2. At sprint 40, 7.5 decel takes ~2.5s to reach exit speed.
    SlideFriction = 6.8,
    SlideUphillFriction = 42,
    SlideSteer = 1.3,
    SlideForwardExitInput = 0.55,
    SlideExitSpeed = 18,
    SlideMaxPlanarSpeed = 66,
    SlideSlopeGravityMultiplier = 0.28,
    SlideDownhillExtraAcceleration = 11,
    SlideDownhillNormalYThreshold = 0.985,
    SlideGroundStickVelocity = -10,
    SlideLaunchVerticalClamp = 2,

    SlopeProjectGroundMovement = true,
    SlopeLimitNormalY = 0.54,
    SlopeUphillSlowMultiplier = 0.32,
    SlopeDownhillAcceleration = 7,
    SlopeSnapMaxDownVelocity = -24,

    -- Parkour bursts are capped around 1.7x base sprint, enough to feel fast without Roblox tunneling.
    BulletJumpForwardImpulse = 64,
    BulletJumpUpImpulse = 56,
    BulletJumpRocketUpImpulse = 82,
    BulletJumpRocketPitchY = 0.74,
    BulletJumpRocketPlanarScale = 0.24,
    BulletJumpCooldown = 0.12,
    BulletJumpModeTime = 0.24,
    BulletJumpMinUpWhenLookingDown = 0.62,
    BulletJumpMoveInfluence = 0.45,
    BulletJumpMaxAddedPlanarSpeed = 74,
    BulletJumpMaxAddedVerticalSpeed = 88,

    FocusEnergy = 6,
    AimGlideDrain = 2,
    AimGlideMaxDuration = 6,
    WallLatchDrain = 1,
    AimGlideGravityScale = 0.24,
    AimGlideMaxFallSpeed = -4,
    AimGlideAirControlMultiplier = 0.78,
    AimGlideMomentumPreserve = 0.985,

    DodgeTapMaxTime = 0.18,
    RollDoubleTapWindow = 0.26,
    RollImpulse = 24,
    RollModeTime = 0.24,
    AirDodgeImpulse = 36,
    AirDodgeUpImpulse = 3,
    AirDodgeModeTime = 0.22,

    GroundProbeExtra = 0.45,
    GroundProbeRadius = 0.92,
    GroundNormalMinY = 0.54,
    WallProbeHeight = 2.2,
    WallProbeDistance = 3.4,
    WallProbeRadius = 1.1,
    MaxWallNormalY = 0.25,
    WallLookDotMin = 0.18,
    WallStickMemoryTime = 0.16,
    WallLatchRefreshFraction = 0.55,
    WallHopAwayImpulse = 30,
    WallHopUpImpulse = 34,
    WallHopForwardImpulse = 30,
    WallHopModeTime = 0.16,
    WallContactProbeHeights = { 1.1, 2.2, 3.25 },
    WallAimDotMin = 0.18,
    WallContactDotMin = -0.12,
    WallHopLookDotMin = 0.06,
    WallHopMoveIntoWallDotMin = 0.08,
    WallHopHeldRepeatInterval = 0.18,
    WallHopChainEnabled = true,
    WallRecontactAssistTime = 0.38,
    DoubleJumpWallReturnAssist = 18,
    WallLatchDampTime = 0.08,
    WallLatchDetachPush = 8,
    WallHopFaceCameraTime = 0.22,

    OrientationSharpness = 22,
    MaxPlanarSpeed = 64,
    MaxVerticalSpeed = 82,
    HardMaxPlanarSpeed = 86,
    HardMaxVerticalSpeed = 90,
},

    Camera = {
    MouseSensitivity = 1.0,
    GamepadSensitivity = 2.2,
    MinPitch = -70,
    MaxPitch = 78,
    LockMouse = true,

    Height = 3.1,
    Distance = 6.15,
    AimDistance = 7.15,
    WallLatchDistance = 7.2,
    ShoulderOffset = 4.9,
    AimShoulderOffset = 4.15,
    LookAhead = 5.0,

    ShoulderSharpness = 18,
    FocusSharpness = 24,
    PositionSharpness = 28,
    ParkourFocusSharpness = 42,
    ParkourPositionSharpness = 48,
    FovSharpness = 12,

    NormalFov = 72,
    AimFov = 56,
    ParkourFov = 82,
    WallLatchFov = 68,

    CollisionRadius = 0.65,
    CollisionPadding = 0.2,
    MinCameraDistance = 1.25,
    IgnoreOtherPlayerCharacters = false,
    IgnoreCompanions = false,
},

    Combat = {
    DefaultHealthDamage = 25,
    QuickMeleeAutoEquip = true,
    MeleeComboResetTime = 0.85,
    BlockDamageMultiplier = 0.35,
    DefaultMeleeRange = 8,
    ServerHitboxLinger = 0.08,
    MaxTargetsPerSwing = 8,
    MeleeHitboxStep = 0.045,
    MeleeServerActiveSampleClamp = 6,
},

    Security = {
    ActionRateLimitPerSecond = 24,
    PositionReportMaxDistance = 35,
    MaxHorizontalSpeedSoft = 115,
    MaxHorizontalSpeedHard = 150,
    MaxVerticalSpeedHard = 130,
    TeleportDistanceHard = 85,
    CorrectionCooldown = 0.35,
    MeleeRequestRatePerSecond = 12,
},

    Networking = {
    RemotesFolderName = "Remotes",
    SettingsDataStoreName = "MovementControllerSettings_v1",
},

    Collision = {
    CharacterCollisionGroup = "PlayerCharacters",
    WorldCollisionGroup = "Default",

    -- Players do not physically block each other. The controller adds a custom thin capsule/oval
    -- soft collision so players can pass through but cannot comfortably occupy the exact same point.
    DisablePhysicalPlayerPlayerCollision = true,
    SoftPlayerCollisionEnabled = true,
    SoftPlayerRadius = 1.35,
    SoftPlayerVerticalHalfHeight = 3.75,
    SoftPlayerMaxPositionNudge = 0.18,
    SoftPlayerPushSpeed = 18,
    SoftPlayerVelocityDeflect = 0.42,
    SoftPlayerThroughVelocityPreserve = 0.72,
    SoftPlayerQueryInterval = 0.025,
},

    Status = {
    SlowMinMultiplier = 0.25,
    StaggerDefaultDuration = 0.45,
    KnockedDownDefaultDuration = 1.2,
    KnockedDownGetUpDuration = 0.45,
    KnockbackMaxImpulse = 95,
    KnockbackVerticalMax = 65,
    ClientStatusSmoothing = 18,
},

    Debug = {
    Enabled = true,
    LogsEnabled = false,
    DefaultChannelEnabled = false,
    ErrorRepeatCooldown = 1.5,
    Channels = {
        Startup = true,
        Network = false,
        Movement = false,
        Combat = false,
        Status = false,
        Validation = true,
        Animation = true,
    },

    HitboxVisualizerEnabled = true,
    HitboxToggleAction = "HitboxDebugToggle",
    StartEnabled = false,

    -- Server-side hitboxes are still server-authoritative. This only mirrors debug shapes to clients.
    ReplicateServerHitboxes = true,
    ServerHitboxLifetime = 0.18,
    LocalHitboxLifetime = 0.075,
    PersistentProbeLifetime = 0.04,

    FolderName = "Controller_HitboxDebug",
    MaxParts = 180,
    Material = Enum.Material.Neon,
    Transparency = 0.72,

    Colors = {
        MeleePredicted = Color3.fromRGB(255, 210, 60),
        MeleeServer = Color3.fromRGB(255, 80, 80),
        SoftCollision = Color3.fromRGB(90, 180, 255),
        GroundProbe = Color3.fromRGB(80, 255, 120),
        WallProbe = Color3.fromRGB(180, 120, 255),
        CameraCollision = Color3.fromRGB(255, 120, 220),
        Status = Color3.fromRGB(255, 145, 70),
    },
},
}
