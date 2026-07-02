--!nonstrict
return {
    NodeId = "Earth_Deadeye_Boss",
    MissionId = "Earth_Deadeye_Boss",
    Rule = { Access = "Squad", InstanceMode = "PrivateSquad", MaxPlayers = 4, MinPower = 18, RecommendedPower = 32, QueueTimeout = 20 },
    Unlock = { Mode = "CompleteAll", Requires = { "Earth_Greenbelt_Exterminate", "Earth_Ruins_Survival", "Earth_Bandit_Wave" } },
    Mission = {
        MissionType = "Assassination",
        EnemyStartingLevel = 18,
        EnemyLevelVariance = 2,
        SpawnCount = 1,
        BossId = "Deadeye",
        EnemyTable = {
            { EnemyId = "Deadeye", Weight = 1 },
            { EnemyId = "Gunner", Weight = 2, Support = true },
        },
        Setup = {
            AreaId = "Earth_SignalNest",
            GeneratedLevel = true,
            TileSet = "EarthBoss",
            BossArena = "SignalNest",
            SpawnGroups = { "BossArena", "AddWaveLeft", "AddWaveRight" },
            DropPlacement = "BossCache",
        },
        Drops = {
            AmmoDropChance = 0.30,
            HealthOrbChance = 0.10,
            MaterialDropScale = 1.2,
            EnemyDropTable = "EarthBoss",
        },
    },
    Reward = { XP = 1100, Materials = { Core = 1, Alloy = 24, Lens = 3 } },
}
