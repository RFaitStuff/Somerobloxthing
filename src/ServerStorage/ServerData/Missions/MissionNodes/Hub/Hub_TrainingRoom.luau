--!nonstrict
return {
    NodeId = "Hub_TrainingRoom",
    MissionId = "TrainingRoom",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 0 },
    Mission = {
        MissionType = "Training",
        EnemyStartingLevel = 1,
        EnemyLevelVariance = 0,
        SpawnCount = 4,
        EnemyTable = {
            { EnemyId = "Raider", Weight = 1 },
        },
        Setup = {
            ArenaId = "HubTrainingRange",
            GeneratedLevel = false,
            DefensePoint = nil,
            SpawnGroups = { "TargetLane" },
        },
        Drops = {
            AmmoDropChance = 0.35,
            HealthOrbChance = 0.08,
            MaterialDropScale = 0,
        },
    },
    Reward = { XP = 120, Materials = {} },
}
