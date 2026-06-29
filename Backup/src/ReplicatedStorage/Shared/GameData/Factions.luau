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
}
