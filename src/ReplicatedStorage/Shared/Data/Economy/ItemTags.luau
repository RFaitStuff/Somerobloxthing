--!nonstrict
local Mods = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("Mods"))
local Armor = require(script.Parent.Parent:WaitForChild("Progression"):WaitForChild("Armor"))

local ItemTags = {}

ItemTags.TypeDefaults = {
    Material = { Stackable = true, Tradable = true },
    Decoration = { Stackable = true, Tradable = true },
    Mod = { Stackable = false, Tradable = true },
    Armor = { Stackable = false, Tradable = true, Unique = true },
    Attachment = { Stackable = false, Tradable = true, Unique = true },
    Dallions = { Stackable = true, Tradable = true, Premium = true, MasteryTradeRank = 4 },
}

ItemTags.ByType = {
    Mod = {
        Vitality = { Tradable = true, Tags = { "Frame", "Survivability" } },
        Redirection = { Tradable = true, Tags = { "Frame", "Shield" } },
        Flow = { Tradable = true, Tags = { "Frame", "Mana" } },
        Serration = { Tradable = true, Tags = { "Weapon", "Damage" } },
        SplitChamber = { Tradable = true, Tags = { "Weapon", "Multishot" } },
        PressurePoint = { Tradable = true, Tags = { "Melee", "Damage" } },
    },
    Armor = {},
    Attachment = {},
}

for armorId in pairs(Armor.ById) do
    ItemTags.ByType.Armor[armorId] = { Tradable = true, Tags = { "Armor", Armor.Get(armorId).Slot or "Armor" } }
end

function ItemTags.GetTypeDefaults(itemType)
    return ItemTags.TypeDefaults[itemType] or {}
end

function ItemTags.Get(itemType, itemId)
    local byType = ItemTags.ByType[itemType]
    if byType and byType[itemId] then return byType[itemId] end
    local defaults = ItemTags.GetTypeDefaults(itemType)
    if itemType == "Mod" and Mods.Get(itemId) then return defaults end
    if itemType == "Armor" and Armor.Get(itemId) then return defaults end
    return defaults
end

function ItemTags.IsTradable(itemType, itemId)
    local typeDefaults = ItemTags.GetTypeDefaults(itemType)
    if typeDefaults.Tradable ~= true then return false end
    local item = ItemTags.Get(itemType, itemId)
    if item.Tradable == false then return false end
    return true
end

return ItemTags
