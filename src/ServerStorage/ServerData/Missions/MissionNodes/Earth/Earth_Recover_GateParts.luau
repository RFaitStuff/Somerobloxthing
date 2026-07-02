--!nonstrict
return {
    NodeId = "Earth_Recover_GateParts",
    MissionId = "Earth_Recover_GateParts",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 5, RecommendedPower = 12 },
    Unlock = { Mode = "CompleteAll", Requires = { "Moon_Open_EarthGate" }, CanTravelBeforeComplete = true },
    Mission = {
        MissionType = "StorySalvage",
        EnemyStartingLevel = 8,
        EnemyLevelVariance = 2,
        SpawnCount = 7,
        TargetCount = 10,
        EnemyTable = {
            { EnemyId = "Gunner", Weight = 4 },
            { EnemyId = "Raider", Weight = 2 },
            { EnemyId = "Caster", Weight = 1 },
        },
        Setup = {
            AreaId = "Earth_Greenbelt",
            GeneratedLevel = true,
            StoryVariant = true,
            TileSet = "EarthForest",
            SpawnGroups = { "Trail", "Ruins", "Overlook" },
            ObjectivePoints = { "AsteriRegulator", "GateLens", "OldRelayCache" },
            DropPlacement = "GateSalvageCaches",
        },
        Drops = { AmmoDropChance = 0.24, HealthOrbChance = 0.06, MaterialDropScale = 1.05, EnemyDropTable = "EarthLow" },
    },
    Reward = { XP = 540, Materials = { Alloy = 12, Circuit = 8, Lens = 1 } },
}
