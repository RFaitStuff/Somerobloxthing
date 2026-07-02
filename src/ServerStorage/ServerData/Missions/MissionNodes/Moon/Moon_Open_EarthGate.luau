--!nonstrict
return {
    NodeId = "Moon_Open_EarthGate",
    MissionId = "Moon_Open_EarthGate",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 2, RecommendedPower = 5 },
    Unlock = { Mode = "CompleteAll", Requires = { "Moon_Restore_TempBase" } },
    Mission = {
        MissionType = "GateStabilize",
        EnemyStartingLevel = 5,
        EnemyLevelVariance = 1,
        SpawnCount = 6,
        Duration = 75,
        EnemyTable = {
            { EnemyId = "Gunner", Weight = 3 },
            { EnemyId = "Raider", Weight = 2 },
        },
        Setup = {
            AreaId = "Moon_WarpSanctum",
            GeneratedLevel = false,
            StoryVariant = true,
            DefensePoint = "EarthGateConsole",
            SpawnGroups = { "GateLeft", "GateRight" },
            ObjectivePoints = { "EarthGlyph", "GateStabilizer", "ExitGate" },
        },
        Drops = { AmmoDropChance = 0.22, HealthOrbChance = 0.08, EnemyDropTable = "Debug" },
    },
    Reward = { XP = 360, Materials = { Circuit = 6, Spark = 1 } },
}
