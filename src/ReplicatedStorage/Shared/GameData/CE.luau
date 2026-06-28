--!nonstrict
local CE = {}

CE.Stats = { "Vitality", "Guard", "Haste", "Focus", "Flow", "Might" }
CE.TotalCap = 510
CE.StatCap = 160
CE.RepeatEnemyLimit = 60

CE.RoleRewards = {
    Melee = { Might = 2 },
    Gunner = { Haste = 1, Focus = 0.5 },
    Heavy = { Vitality = 1, Guard = 2 },
    Shield = { Guard = 3 },
    Caster = { Focus = 2, Flow = 1 },
    Sniper = { Haste = 2 },
    Elite = { Might = 2, Focus = 2, Guard = 1 },
}

return CE