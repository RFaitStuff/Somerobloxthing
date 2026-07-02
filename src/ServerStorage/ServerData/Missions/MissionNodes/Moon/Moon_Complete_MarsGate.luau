--!nonstrict
return {
    NodeId = "Moon_Complete_MarsGate",
    MissionId = "Moon_Complete_MarsGate",
    Rule = { Access = "Solo", InstanceMode = "LocalDevOrPrivate", MaxPlayers = 1, MinPower = 10, RecommendedPower = 18 },
    Unlock = { Mode = "CompleteAll", Requires = { "Earth_Recover_GateParts" } },
    Mission = {
        MissionType = "GateDefense",
        EnemyStartingLevel = 14,
        EnemyLevelVariance = 2,
        SpawnCount = 6,
        TargetCount = 6,
        EnemyTable = {
            { EnemyId = "Gunner", Weight = 3 },
            { EnemyId = "Caster", Weight = 1 },
            { EnemyId = "Raider", Weight = 2 },
        },
        Setup = {
            AreaId = "Moon_WarpSanctum",
            GeneratedLevel = false,
            StoryVariant = true,
            DefensePoint = "MarsGateCore",
            SpawnGroups = { "GateLeft", "GateRight", "SanctumBack" },
            ObjectivePoints = { "AsteriRegulator", "MarsGlyph", "AtlasShardSignal" },
        },
        Drops = { AmmoDropChance = 0.25, HealthOrbChance = 0.08, EnemyDropTable = "EarthMid" },
    },
    Reward = { XP = 760, Materials = { Alloy = 16, Circuit = 8, Lens = 1 } },
}
