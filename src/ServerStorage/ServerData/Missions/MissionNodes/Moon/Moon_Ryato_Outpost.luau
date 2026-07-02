--!nonstrict
return {
    NodeId = "Moon_Ryato_Outpost",
    MissionId = "Moon_Ryato_Outpost",
    DisplayName = "Ryato Outpost",
    Unlock = { Mode = "CompleteAll", Requires = { "CompleteMarsGate", "Moon_Dome_Patrol" } },
    Rule = {
        Access = "Squad",
        InstanceMode = "PrivateSquad",
        MissionId = "Moon_Ryato_Outpost",
        MaxPlayers = 4,
        MinPower = 28,
        RecommendedPower = 36,
        QueueTimeout = 15,
    },
    Mission = {
        MissionType = "Assassination",
        EnemyStartingLevel = 18,
        EnemyLevelVariance = 4,
        SpawnCount = 6,
        BossId = "RyatoBulwark",
        EnemyTable = {
            { EnemyId = "RyatoSkirmisher", Weight = 3 },
            { EnemyId = "RyatoGunner", Weight = 3 },
            { EnemyId = "RyatoBulwark", Weight = 1 },
        },
        Setup = {
            AreaId = "Moon_WarpSanctum",
            EnemyFaction = "Ryato",
            ObjectiveAnchors = { "OuterGate", "OutpostCore", "GateRelay" },
        },
        Drops = { AmmoDropChance = 0.30, HealthOrbChance = 0.10, EnemyDropTable = "Moon_Ryato_Outpost" },
    },
    Reward = { XP = 1050, Materials = { Core = 1, Alloy = 22, Spark = 4 } },
}
