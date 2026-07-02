--!nonstrict
return {
    NodeId = "Earth_Bandit_Wave",
    MissionId = "Earth_Bandit_Wave",
    Rule = { Access = "Public", InstanceMode = "PublicZone", MaxPlayers = 24, MinPower = 0, RecommendedPower = 15 },
    Unlock = { Mode = "Encounter", CanTravelBeforeComplete = true, PublicEvent = true },
    Mission = {
        MissionType = "PublicEvent",
        EnemyStartingLevel = 7,
        EnemyLevelVariance = 3,
        SpawnCount = 8,
        TargetCount = 8,
        EnemyTable = {
            { EnemyId = "Gunner", Weight = 5 },
            { EnemyId = "Heavy", Weight = 1 },
        },
        Setup = {
            AreaId = "Earth_OpenPatrol",
            GeneratedLevel = false,
            PublicEventMarker = "BanditOutbreak",
            SpawnGroups = { "Road", "Camp", "Ridge" },
            DropPlacement = "PublicEventCrates",
        },
        Drops = {
            AmmoDropChance = 0.18,
            HealthOrbChance = 0.05,
            MaterialDropScale = 0.8,
            EnemyDropTable = "EarthEvent",
        },
    },
    Reward = { XP = 420, Materials = { Alloy = 8, Circuit = 2 } },
}
