--!nonstrict
-- Consolidated gameplay/camera/combat/security tuning.

return {
    Movement = {
    WalkSpeed = 18,
    SprintSpeed = 28,
    GroundAcceleration = 135,
    GroundDeceleration = 155,
    AirAcceleration = 70,
    AirDrag = 0.15,
    Gravity = -120,
    GroundStickVelocity = -9,

    JumpVelocity = 47,
    DoubleJumpVelocity = 42,
    DoubleJumpForwardBoost = 12,
    AirJumpsPerSurface = 1,

    CrouchHipHeightScale = 0.55,
    SlideStartSpeed = 20,
    SlideStartBoost = 22,
    SlideFriction = 12,
    SlideUphillFriction = 26,
    SlideSteer = 11,
    SlideExitSpeed = 9,
    SlideMaxPlanarSpeed = 145,
    SlideSlopeGravityMultiplier = 1.15,
    SlideDownhillExtraAcceleration = 42,
    SlideDownhillNormalYThreshold = 0.985,
    SlideGroundStickVelocity = -14,
    SlideLaunchVerticalClamp = 10,

    SlopeProjectGroundMovement = true,
    SlopeLimitNormalY = 0.54,
    SlopeUphillSlowMultiplier = 0.32,
    SlopeDownhillAcceleration = 16,
    SlopeSnapMaxDownVelocity = -34,

    BulletJumpForwardImpulse = 78,
    BulletJumpUpImpulse = 54,
    BulletJumpCooldown = 0.12,
    BulletJumpModeTime = 0.18,
    BulletJumpMinUpWhenLookingDown = 0.62,
    BulletJumpMaxAddedPlanarSpeed = 92,
    BulletJumpMaxAddedVerticalSpeed = 64,

    FocusEnergy = 6,
    AimGlideDrain = 2,
    WallLatchDrain = 1,
    AimGlideGravityScale = 0.18,
    AimGlideMaxFallSpeed = -13,
    AimGlideAirControlMultiplier = 1.25,

    RollImpulse = 42,
    RollModeTime = 0.24,
    AirDodgeImpulse = 56,
    AirDodgeUpImpulse = 7,
    AirDodgeModeTime = 0.22,

    GroundProbeExtra = 0.45,
    GroundNormalMinY = 0.54,
    WallProbeHeight = 2.2,
    WallProbeDistance = 3.0,
    WallProbeRadius = 1.1,
    MaxWallNormalY = 0.25,
    WallHopAwayImpulse = 48,
    WallHopUpImpulse = 44,
    WallHopForwardImpulse = 30,
    WallHopModeTime = 0.16,

    OrientationSharpness = 22,
    MaxPlanarSpeed = 115,
    MaxVerticalSpeed = 140,
    HardMaxPlanarSpeed = 170,
    HardMaxVerticalSpeed = 150,
},

    Camera = {
    MouseSensitivity = 1.0,
    GamepadSensitivity = 2.2,
    MinPitch = -70,
    MaxPitch = 78,
    LockMouse = true,

    Height = 3.1,
    Distance = 9.5,
    AimDistance = 6.7,
    WallLatchDistance = 7.5,
    ShoulderOffset = 2.15,
    AimShoulderOffset = 2.45,
    LookAhead = 5.0,

    ShoulderSharpness = 18,
    PositionSharpness = 28,
    FovSharpness = 16,

    NormalFov = 72,
    AimFov = 56,
    ParkourFov = 82,
    WallLatchFov = 68,

    CollisionRadius = 0.65,
    CollisionPadding = 0.2,
    MinCameraDistance = 1.25,
},

    Combat = {
    DefaultHealthDamage = 25,
    QuickMeleeAutoEquip = true,
    MeleeComboResetTime = 0.85,
    BlockDamageMultiplier = 0.35,
    DefaultMeleeRange = 8,
    ServerHitboxLinger = 0.08,
    MaxTargetsPerSwing = 8,
},

    Security = {
    ActionRateLimitPerSecond = 24,
    PositionReportMaxDistance = 35,
    MaxHorizontalSpeedSoft = 135,
    MaxHorizontalSpeedHard = 190,
    MaxVerticalSpeedHard = 185,
    TeleportDistanceHard = 85,
    CorrectionCooldown = 0.35,
    MeleeRequestRatePerSecond = 12,
},

    Networking = {
    RemotesFolderName = "Remotes",
    SettingsDataStoreName = "AdvancedCharacterControllerSettings_v1",
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
    Channels = {
        Startup = true,
        Network = false,
        Movement = false,
        Combat = false,
        Status = false,
        Validation = true,
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
