--!nonstrict
-- Consolidated gameplay/camera/combat/security tuning.

return {
    Movement = {
    -- Scale basis: Warframe base walk/sprint is 6/7.5 m/s. Roblox movement is studs/s.
    -- Using 1 stud ~= 0.28m gives 3.571 studs/m, so 6m/s ~= 21.4 and 7.5m/s ~= 26.8.
    StudsPerMeter = 3.571,
    WalkSpeed = 23,
    SprintSpeed = 34,

    -- Acceleration is derived from target-speed / time-to-target.
    -- Sprint target in ~0.18s: 30 / 0.18 ~= 167. Decel in ~0.14s: 30 / 0.14 ~= 214.
    GroundAcceleration = 185,
    GroundDeceleration = 150,
    GroundCoastDeceleration = 55,
    CounterMoveDeceleration = 230,
    AirAcceleration = 40,
    AirDrag = 0.24,

    -- Slightly floatier than Roblox default gravity, tuned for a ~2m Warframe-like hop.
    Gravity = -108,
    RisingGravityScale = 0.82,
    FallingGravityScale = 1.18,
    GroundStickVelocity = -9,

    -- Normal/double jump give useful height; bullet jump is still the main vertical parkour burst.
    JumpVelocity = 42,
    DoubleJumpVelocity = 40,
    DoubleJumpForwardBoost = 4,
    AirJumpsPerSurface = 1,

    CrouchHipHeightScale = 0.55,
    CrouchSpeed = 12,
    SlideHoldToStartTime = 0.12,
    SlideStartSpeed = 22,
    SlideMinInput = 0.15,
    SlideMinTime = 0.22,
    SlideStartBoost = 10,
    SlideFriction = 18,
    SlideUphillFriction = 36,
    SlideSteer = 6,
    SlideExitSpeed = 12,
    SlideMaxPlanarSpeed = 56,
    SlideSlopeGravityMultiplier = 0.28,
    SlideDownhillExtraAcceleration = 9,
    SlideDownhillNormalYThreshold = 0.985,
    SlideGroundStickVelocity = -10,
    SlideLaunchVerticalClamp = 2,

    SlopeProjectGroundMovement = true,
    SlopeLimitNormalY = 0.54,
    SlopeUphillSlowMultiplier = 0.32,
    SlopeDownhillAcceleration = 7,
    SlopeSnapMaxDownVelocity = -24,

    -- Parkour bursts are capped around 1.7x base sprint, enough to feel fast without Roblox tunneling.
    BulletJumpForwardImpulse = 42,
    BulletJumpUpImpulse = 48,
    BulletJumpCooldown = 0.12,
    BulletJumpModeTime = 0.18,
    BulletJumpMinUpWhenLookingDown = 0.62,
    BulletJumpMoveInfluence = 0.45,
    BulletJumpMaxAddedPlanarSpeed = 44,
    BulletJumpMaxAddedVerticalSpeed = 52,

    FocusEnergy = 6,
    AimGlideDrain = 2,
    WallLatchDrain = 1,
    AimGlideGravityScale = 0.36,
    AimGlideMaxFallSpeed = -20,
    AimGlideAirControlMultiplier = 0.75,

    DodgeTapMaxTime = 0.18,
    RollDoubleTapWindow = 0.26,
    RollImpulse = 34,
    RollModeTime = 0.24,
    AirDodgeImpulse = 40,
    AirDodgeUpImpulse = 4,
    AirDodgeModeTime = 0.22,

    GroundProbeExtra = 0.45,
    GroundNormalMinY = 0.54,
    WallProbeHeight = 2.2,
    WallProbeDistance = 3.0,
    WallProbeRadius = 1.1,
    MaxWallNormalY = 0.25,
    WallHopAwayImpulse = 30,
    WallHopUpImpulse = 34,
    WallHopForwardImpulse = 18,
    WallHopModeTime = 0.16,

    OrientationSharpness = 22,
    MaxPlanarSpeed = 60,
    MaxVerticalSpeed = 90,
    HardMaxPlanarSpeed = 78,
    HardMaxVerticalSpeed = 110,
},

    Camera = {
    MouseSensitivity = 1.0,
    GamepadSensitivity = 2.2,
    MinPitch = -70,
    MaxPitch = 78,
    LockMouse = true,

    Height = 2.85,
    Distance = 9.25,
    AimDistance = 6.5,
    WallLatchDistance = 7.4,
    ShoulderOffset = 3.3,
    AimShoulderOffset = 3.45,
    LookAhead = 5.0,

    ShoulderSharpness = 28,
    FocusSharpness = 36,
    PositionSharpness = 42,
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
    AntiCheatEnabled = false,
    ActionRateLimitPerSecond = 24,
    PositionReportMaxDistance = 35,
    MaxHorizontalSpeedSoft = 96,
    MaxHorizontalSpeedHard = 130,
    MaxVerticalSpeedHard = 120,
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
