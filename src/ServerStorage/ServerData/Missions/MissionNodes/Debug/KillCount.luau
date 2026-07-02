--!nonstrict
return {
    NodeId = "Debug_KillCount",
    MissionId = "KillCount",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0 },
    Mission = { MissionType = "Exterminate", EnemyStartingLevel = 1, EnemyLevelVariance = 1, SpawnCount = 5, TargetCount = 10, EnemyTable = { { EnemyId = "Gunner", Weight = 1 } }, Drops = { AmmoDropChance = 0.25, EnemyDropTable = "Debug" } },
    Reward = { XP = 500, Materials = { Alloy = 12, Circuit = 6 } },
}
