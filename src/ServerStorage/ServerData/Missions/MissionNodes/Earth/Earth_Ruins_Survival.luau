--!nonstrict
return {
    NodeId = "Earth_Ruins_Survival",
    MissionId = "Earth_Ruins_Survival",
    Rule = { Access = "Squad", InstanceMode = "PrivateSquad", MaxPlayers = 4, MinPower = 8, RecommendedPower = 20, QueueTimeout = 16 },
    Unlock = { Mode = "CompleteAny", Requires = { "Earth_Greenbelt_Exterminate" } },
    Mission = {
        MissionType = "Survival",
        EnemyStartingLevel = 9,
        EnemyLevelVariance = 3,
        SpawnCount = 8,
        Duration = 120,
        EnemyTable = {
            { EnemyId = "Raider", Weight = 4 },
            { EnemyId = "Gunner", Weight = 3 },
            { EnemyId = "Caster", Weight = 1 },
        },
        Setup = {
            AreaId = "Earth_Ruins",
            GeneratedLevel = true,
            TileSet = "EarthRuins",
            ObjectivePoints = { "LifeSupportA", "LifeSupportB" },
            SpawnGroups = { "OuterRing", "LowerHall", "UpperHall" },
            DropPlacement = "NearObjectiveAndSideRooms",
        },
        Drops = {
            AmmoDropChance = 0.25,
            HealthOrbChance = 0.07,
            MaterialDropScale = 1.05,
            EnemyDropTable = "EarthMid",
        },
    },
    Reward = { XP = 720, Materials = { Alloy = 12, Spark = 5 } },
}
