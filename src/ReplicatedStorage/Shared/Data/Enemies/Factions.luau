--!nonstrict
return {
    EarthBandits = {
        Id = "EarthBandits",
        DisplayName = "Earth Bandits",
        Description = "Scrappy raiders with kinetic weapons, armor plates, and blunt-force pressure.",
        TypeBias = { Earth = 1, Poison = 0.5 },
        EnemyIds = { "Raider", "Gunner", "Bulwark" },
    },
    VoidCult = {
        Id = "VoidCult",
        DisplayName = "Void Cult",
        Description = "Ritual fighters using dark energy, shields, and long-range pressure.",
        TypeBias = { Dark = 1, Light = 0.25 },
        EnemyIds = { "Acolyte", "Caster", "Deadeye" },
    },
    Ryato = {
        Id = "Ryato",
        DisplayName = "Ryato",
        Description = "The origin force that destroyed Moonveil. Their patrols favor fast pressure, suppression fire, and heavy gate anchors.",
        TypeBias = { Kinetic = 0.75, Dark = 0.35 },
        EnemyIds = { "RyatoSkirmisher", "RyatoGunner", "RyatoBulwark" },
    },
    MoonveilRemnants = {
        Id = "MoonveilRemnants",
        DisplayName = "Moonveil Remnants",
        Description = "Unstable echoes and scavenged defense systems left inside the broken moon colony.",
        TypeBias = { Light = 0.4, Kinetic = 0.4 },
        EnemyIds = { "MoonveilRemnant" },
    },
    MarsRemnant = {
        Id = "MarsRemnant",
        DisplayName = "Mars Remnant",
        Description = "Shielded survivors, machines, and bunker troops hardened by the buried Martian relay sites.",
        TypeBias = { Earth = 0.5, Kinetic = 0.75 },
        EnemyIds = { "Shield" },
    },
}
