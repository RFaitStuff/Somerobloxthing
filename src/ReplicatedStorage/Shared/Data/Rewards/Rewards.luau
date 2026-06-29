--!nonstrict
return {
    Enemy = {
        Melee = { XP = 35, Materials = { Alloy = 1 } },
        Gunner = { XP = 45, Materials = { Alloy = 1, Circuit = 1 } },
        Heavy = { XP = 95, Materials = { Alloy = 3 } },
        Shield = { XP = 70, Materials = { Circuit = 2 } },
        Caster = { XP = 80, Materials = { Spark = 1 } },
        Sniper = { XP = 85, Materials = { Lens = 1 } },
        Elite = { XP = 180, Materials = { Alloy = 4, Spark = 2 } },
    },
    Mission = {
        KillCount = { XP = 500, Materials = { Alloy = 12, Circuit = 6 } },
        Boss = { XP = 900, Materials = { Core = 1, Alloy = 20 } },
        Survival = { XP = 650, Materials = { Alloy = 10, Spark = 4 } },
        EndlessWave = { XP = 350, Materials = { Alloy = 6 } },
    },
}
