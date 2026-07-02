--!nonstrict
return {
    NodeId = "Debug_Boss",
    MissionId = "Boss",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0 },
    Mission = { MissionType = "Assassination", EnemyStartingLevel = 5, EnemyLevelVariance = 1, SpawnCount = 1, BossId = "Deadeye", EnemyTable = { { EnemyId = "Deadeye", Weight = 1 } }, Drops = { AmmoDropChance = 0.3, EnemyDropTable = "DebugBoss" } },
    Reward = { XP = 900, Materials = { Core = 1, Alloy = 20 } },
}
