--!nonstrict
return {
    NodeId = "Moon_Dome_Patrol",
    MissionId = "Moon_Dome_Patrol",
    DisplayName = "Broken Dome Patrol",
    Unlock = { Mode = "CompleteAll", Requires = { "CompleteMarsGate" } },
    Rule = {
        Access = "Squad",
        InstanceMode = "PrivateSquad",
        MissionId = "Moon_Dome_Patrol",
        MaxPlayers = 4,
        MinPower = 18,
        RecommendedPower = 24,
        QueueTimeout = 12,
    },
    Mission = {
        MissionType = "Exterminate",
        EnemyStartingLevel = 12,
        EnemyLevelVariance = 3,
        SpawnCount = 8,
        TargetCount = 16,
        EnemyTable = {
            { EnemyId = "RyatoSkirmisher", Weight = 4 },
            { EnemyId = "RyatoGunner", Weight = 3 },
        },
        Setup = {
            AreaId = "Moon_BrokenDome",
            EnemyFaction = "Ryato",
            ObjectiveAnchors = { "DomeSpan", "HabCrack", "SanctumApproach" },
        },
        Drops = { AmmoDropChance = 0.24, HealthOrbChance = 0.06, EnemyDropTable = "Moon_Ryato_PostHub" },
    },
    Reward = { XP = 620, Materials = { Alloy = 16, Circuit = 6, Spark = 2 } },
}
