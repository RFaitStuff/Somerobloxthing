--!nonstrict
return {
    NodeId = "Debug_EndlessWave",
    MissionId = "EndlessWave",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0 },
    Mission = { MissionType = "Wave", EnemyStartingLevel = 3, EnemyLevelVariance = 2, SpawnCount = 5, TargetCount = 5, EnemyTable = { { EnemyId = "Gunner", Weight = 1 } }, Drops = { AmmoDropChance = 0.25, EnemyDropTable = "Debug" } },
    Reward = { XP = 350, Materials = { Alloy = 6 } },
}
