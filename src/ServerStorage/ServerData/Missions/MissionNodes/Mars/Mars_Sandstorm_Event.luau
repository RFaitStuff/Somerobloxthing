--!nonstrict
return {
    NodeId = "Mars_Sandstorm_Event",
    MissionId = "Mars_Sandstorm_Event",
    Rule = { Access = "Public", InstanceMode = "PublicZone", MaxPlayers = 20, MinPower = 30, RecommendedPower = 42 },
    Unlock = { Mode = "Encounter", CanTravelBeforeComplete = true, PublicEvent = true },
    Mission = {
        MissionType = "PublicEvent",
        EnemyStartingLevel = 27,
        EnemyLevelVariance = 5,
        SpawnCount = 10,
        Duration = 150,
        EnemyTable = {
            { EnemyId = "Gunner", Weight = 4 },
            { EnemyId = "Sniper", Weight = 3 },
            { EnemyId = "Caster", Weight = 1 },
        },
        Setup = {
            AreaId = "Mars_OpenDunes",
            GeneratedLevel = false,
            PublicEventMarker = "Sandstorm",
            Weather = "Sandstorm",
            SpawnGroups = { "StormFront", "OldRoad", "Wreckage" },
            DropPlacement = "StormCaches",
        },
        Drops = {
            AmmoDropChance = 0.18,
            HealthOrbChance = 0.06,
            MaterialDropScale = 0.9,
            EnemyDropTable = "MarsEvent",
        },
    },
    Reward = { XP = 680, Materials = { Alloy = 12, Ferrite = 8 } },
}
