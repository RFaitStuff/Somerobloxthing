--!nonstrict
return {
    NodeId = "Moon_Restore_TempBase",
    MissionId = "Moon_Restore_TempBase",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0, RecommendedPower = 3 },
    Unlock = { Mode = "CompleteAll", Requires = { "Moon_Awaken_Stained" } },
    Mission = {
        MissionType = "StoryRepair",
        EnemyStartingLevel = 3,
        EnemyLevelVariance = 1,
        SpawnCount = 5,
        TargetCount = 5,
        EnemyTable = {
            { EnemyId = "Raider", Weight = 4 },
            { EnemyId = "Gunner", Weight = 1 },
        },
        Setup = {
            AreaId = "Moon_BrokenDome",
            GeneratedLevel = false,
            StoryVariant = true,
            DefensePoint = "TempBaseCore",
            SpawnGroups = { "DomeBreach", "ServiceTunnel" },
            ObjectivePoints = { "PowerCellA", "PowerCellB", "BaseConsole" },
        },
        Drops = { AmmoDropChance = 0.18, HealthOrbChance = 0.06, EnemyDropTable = "Debug" },
    },
    Reward = { XP = 240, Materials = { Alloy = 8, Circuit = 3 } },
}
