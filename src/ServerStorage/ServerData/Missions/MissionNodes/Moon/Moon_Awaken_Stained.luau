--!nonstrict
return {
    NodeId = "Moon_Awaken_Stained",
    MissionId = "Moon_Awaken_Stained",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0, RecommendedPower = 0 },
    Unlock = { Mode = "Default" },
    Mission = {
        MissionType = "StoryIntro",
        EnemyStartingLevel = 1,
        EnemyLevelVariance = 0,
        SpawnCount = 2,
        Duration = 45,
        EnemyTable = { { EnemyId = "Raider", Weight = 1 } },
        Setup = {
            AreaId = "Moon_Stillwater",
            GeneratedLevel = false,
            StoryVariant = true,
            SpawnGroups = { "StillwaterEdge" },
            ObjectivePoints = { "PoisePond", "FirstVestige", "BaseDoor" },
        },
        Drops = { AmmoDropChance = 0.1, EnemyDropTable = "Debug" },
    },
    Reward = { XP = 120, Materials = { Alloy = 4 } },
}
