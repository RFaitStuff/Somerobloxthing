--!nonstrict
return {
    NodeId = "Mars_Dune_Patrol",
    MissionId = "Mars_Dune_Patrol",
    Rule = { Access = "Squad", InstanceMode = "PrivateSquad", MaxPlayers = 4, MinPower = 28, RecommendedPower = 38, QueueTimeout = 16 },
    Unlock = { Mode = "StoryStep", Requires = { "DefeatDeadeye" }, CanTravelBeforeComplete = false },
    Mission = {
        MissionType = "Exterminate",
        EnemyStartingLevel = 24,
        EnemyLevelVariance = 3,
        SpawnCount = 8,
        TargetCount = 18,
        EnemyTable = {
            { EnemyId = "Sniper", Weight = 4 },
            { EnemyId = "Gunner", Weight = 3 },
            { EnemyId = "Shield", Weight = 1 },
        },
        Setup = {
            AreaId = "Mars_Dunes",
            GeneratedLevel = true,
            TileSet = "MarsDesert",
            SpawnGroups = { "DuneRoad", "Cliff", "BuriedGate" },
            FastTravelPoint = "DuneRelay",
            DropPlacement = "BuriedCaches",
        },
        Drops = {
            AmmoDropChance = 0.20,
            HealthOrbChance = 0.05,
            MaterialDropScale = 1.1,
            EnemyDropTable = "MarsLow",
        },
    },
    Reward = { XP = 780, Materials = { Alloy = 18, Lens = 3, Ferrite = 4 } },
}
