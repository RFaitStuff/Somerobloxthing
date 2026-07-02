--!nonstrict
return {
    NodeId = "Moon_Crater_Scavenge",
    MissionId = "Moon_Crater_Scavenge",
    DisplayName = "Crater Salvage Run",
    Unlock = { Mode = "CompleteAll", Requires = { "CompleteMarsGate" } },
    Rule = {
        Access = "Squad",
        InstanceMode = "PrivateSquad",
        MissionId = "Moon_Crater_Scavenge",
        MaxPlayers = 4,
        MinPower = 20,
        RecommendedPower = 28,
        QueueTimeout = 12,
    },
    Mission = {
        MissionType = "Salvage",
        EnemyStartingLevel = 14,
        EnemyLevelVariance = 4,
        SpawnCount = 8,
        Duration = 120,
        EnemyTable = {
            { EnemyId = "MoonveilRemnant", Weight = 4 },
            { EnemyId = "RyatoSkirmisher", Weight = 2 },
        },
        Setup = {
            AreaId = "Moon_BrokenDome",
            EnemyFaction = "MoonveilRemnants",
            ObjectiveAnchors = { "CraterLip", "BuriedHab", "DomeServiceLift" },
            ResourceCaches = { "Alloy", "Circuit", "Lens" },
        },
        Drops = { AmmoDropChance = 0.26, HealthOrbChance = 0.08, EnemyDropTable = "Moon_Salvage_PostHub" },
    },
    Reward = { XP = 700, Materials = { Alloy = 14, Circuit = 10, Lens = 2 } },
}
