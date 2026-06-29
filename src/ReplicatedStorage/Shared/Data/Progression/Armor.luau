--!nonstrict
local Armor = {}

Armor.Slots = { "Helmet", "Chest", "Gloves", "Leggings" }
Armor.RarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }

Armor.ById = {
    FieldHelmet = { Id = "FieldHelmet", Name = "Field Helmet", Slot = "Helmet", MinRarity = "Common", MaxRarity = "Uncommon", Stats = { Health = 12, Shield = 8 }, UpgradeSteps = 3, Perks = {} },
    FieldChest = { Id = "FieldChest", Name = "Field Chestplate", Slot = "Chest", MinRarity = "Common", MaxRarity = "Uncommon", Stats = { Health = 28, Armor = 4 }, UpgradeSteps = 3, Perks = {} },
    FieldGloves = { Id = "FieldGloves", Name = "Field Gloves", Slot = "Gloves", MinRarity = "Common", MaxRarity = "Uncommon", Stats = { Mana = 8, Haste = 2 }, UpgradeSteps = 3, Perks = {} },
    FieldLeggings = { Id = "FieldLeggings", Name = "Field Leggings", Slot = "Leggings", MinRarity = "Common", MaxRarity = "Uncommon", Stats = { Shield = 12, Speed = 0.01 }, UpgradeSteps = 3, Perks = {} },

    RaiderHelmet = { Id = "RaiderHelmet", Name = "Raider Visor", Slot = "Helmet", MinRarity = "Rare", MaxRarity = "Epic", Stats = { Health = 22, Shield = 18, Focus = 4 }, UpgradeSteps = 5, Perks = { "Precision kills restore a small amount of mana." } },
    RaiderChest = { Id = "RaiderChest", Name = "Raider Plate", Slot = "Chest", MinRarity = "Rare", MaxRarity = "Epic", Stats = { Health = 55, Armor = 12 }, UpgradeSteps = 5, Perks = { "Taking heavy damage grants brief stagger resistance." } },
    AcolyteGloves = { Id = "AcolyteGloves", Name = "Acolyte Grips", Slot = "Gloves", MinRarity = "Rare", MaxRarity = "Legendary", Stats = { Mana = 28, Focus = 8 }, UpgradeSteps = 6, Perks = { "Ability hits have a small chance to refund mana." } },
    AcolyteLeggings = { Id = "AcolyteLeggings", Name = "Acolyte Striders", Slot = "Leggings", MinRarity = "Rare", MaxRarity = "Legendary", Stats = { Shield = 34, Speed = 0.025 }, UpgradeSteps = 6, Perks = { "Sliding after casting gives a short movement burst." } },
}

function Armor.Get(id)
    return Armor.ById[id]
end

function Armor.GetRarityValue(rarity)
    return Armor.RarityOrder[rarity or "Common"] or 1
end

function Armor.GetLevelScale(frameLevel)
    frameLevel = math.clamp(tonumber(frameLevel) or 1, 1, 30)
    return math.clamp(0.20 + ((frameLevel - 1) / 29) * 0.80, 0.20, 1)
end

function Armor.GetUpgradeScale(def, item)
    local steps = math.max(def and def.UpgradeSteps or 0, 0)
    if steps <= 0 then return 1 end
    local upgrade = math.clamp(tonumber(item and item.Upgrade) or 0, 0, steps)
    return 1 + (upgrade / steps) * 0.25
end

function Armor.ComputeEffectiveStats(armorId, item, frameLevel)
    local def = Armor.Get(armorId)
    local out = {}
    if not def then return out end
    local scale = Armor.GetLevelScale(frameLevel) * Armor.GetUpgradeScale(def, item)
    for stat, value in pairs(def.Stats or {}) do
        out[stat] = value * scale
    end
    return out
end

function Armor.CanUpgrade(armorId, item)
    local def = Armor.Get(armorId)
    if not def then return false end
    return (tonumber(item and item.Upgrade) or 0) < (def.UpgradeSteps or 0)
end

return Armor
