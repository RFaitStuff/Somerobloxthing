--!nonstrict
return {
    NodeId = "Mars_Warden_Boss",
    MissionId = "Mars_Warden_Boss",
    Rule = { Access = "Squad", InstanceMode = "PrivateSquad", MaxPlayers = 4, MinPower = 42, RecommendedPower = 52, QueueTimeout = 22 },
    Unlock = { Mode = "CompleteAll", Requires = { "Mars_Dune_Patrol", "Mars_Relic_Defense", "Mars_Sandstorm_Event" } },
    Mission = {
        MissionType = "Assassination",
        EnemyStartingLevel = 38,
        EnemyLevelVariance = 2,
        SpawnCount = 1,
        BossId = "Heavy",
        EnemyTable = {
            { EnemyId = "Heavy", Weight = 1 },
            { EnemyId = "Shield", Weight = 2, Support = true },
        },
        Setup = {
            AreaId = "Mars_WardenVault",
            GeneratedLevel = true,
            TileSet = "MarsVault",
            BossArena = "VaultCore",
            SpawnGroups = { "BossArena", "ShieldAdds", "SniperBalcony" },
            DropPlacement = "VaultRewardRoom",
        },
        Drops = {
            AmmoDropChance = 0.32,
            HealthOrbChance = 0.10,
            MaterialDropScale = 1.25,
            EnemyDropTable = "MarsBoss",
        },
    },
    Reward = { XP = 1450, Materials = { Core = 2, Lens = 5, Ferrite = 18 } },
}
