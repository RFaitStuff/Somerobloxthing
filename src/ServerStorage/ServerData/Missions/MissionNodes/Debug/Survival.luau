--!nonstrict
return {
    NodeId = "Debug_Survival",
    MissionId = "Survival",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0 },
    Mission = { MissionType = "Survival", EnemyStartingLevel = 3, EnemyLevelVariance = 1, SpawnCount = 5, Duration = 90, EnemyTable = { { EnemyId = "Raider", Weight = 1 } }, Drops = { AmmoDropChance = 0.25, EnemyDropTable = "Debug" } },
    Reward = { XP = 650, Materials = { Alloy = 10, Spark = 4 } },
}
