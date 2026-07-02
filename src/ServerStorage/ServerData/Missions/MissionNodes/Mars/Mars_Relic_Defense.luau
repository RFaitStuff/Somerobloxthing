--!nonstrict
return {
    NodeId = "Mars_Relic_Defense",
    MissionId = "Mars_Relic_Defense",
    Rule = { Access = "Squad", InstanceMode = "PrivateSquad", MaxPlayers = 4, MinPower = 34, RecommendedPower = 44, QueueTimeout = 18 },
    Unlock = { Mode = "CompleteAny", Requires = { "Mars_Dune_Patrol" } },
    Mission = {
        MissionType = "Defense",
        EnemyStartingLevel = 29,
        EnemyLevelVariance = 3,
        SpawnCount = 10,
        TargetCount = 10,
        EnemyTable = {
            { EnemyId = "Shield", Weight = 4 },
            { EnemyId = "Gunner", Weight = 3 },
            { EnemyId = "Heavy", Weight = 1 },
        },
        Setup = {
            AreaId = "Mars_RelicSite",
            GeneratedLevel = true,
            TileSet = "MarsRelic",
            DefensePoint = "BuriedRelicCore",
            SpawnGroups = { "NorthGate", "SouthTunnel", "UpperRidge" },
            DropPlacement = "DefenseSideRooms",
        },
        Drops = {
            AmmoDropChance = 0.28,
            HealthOrbChance = 0.08,
            MaterialDropScale = 1.15,
            EnemyDropTable = "MarsDefense",
        },
    },
    Reward = { XP = 920, Materials = { Alloy = 22, Circuit = 10, Ferrite = 6 } },
}
