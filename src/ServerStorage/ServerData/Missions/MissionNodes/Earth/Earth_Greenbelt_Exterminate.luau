--!nonstrict
return {
    NodeId = "Earth_Greenbelt_Exterminate",
    MissionId = "Earth_Greenbelt_Exterminate",
    Rule = { Access = "Squad", InstanceMode = "PrivateSquad", MaxPlayers = 4, MinPower = 0, RecommendedPower = 10, QueueTimeout = 12 },
    Unlock = { Mode = "EncounterOrStory", CanTravelBeforeComplete = true, Requires = { "ArriveAtHub" } },
    Mission = {
        MissionType = "Exterminate",
        EnemyStartingLevel = 4,
        EnemyLevelVariance = 2,
        SpawnCount = 8,
        TargetCount = 14,
        EnemyTable = {
            { EnemyId = "Gunner", Weight = 4 },
            { EnemyId = "Raider", Weight = 3 },
        },
        Setup = {
            AreaId = "Earth_Greenbelt",
            GeneratedLevel = true,
            TileSet = "EarthForest",
            SpawnGroups = { "Trail", "Ruins", "Overlook" },
            DropPlacement = "ScatterNearPatrols",
        },
        Drops = {
            AmmoDropChance = 0.22,
            HealthOrbChance = 0.06,
            MaterialDropScale = 1,
            EnemyDropTable = "EarthLow",
        },
    },
    Reward = { XP = 520, Materials = { Alloy = 14, Circuit = 7 } },
}
