--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Armor = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Armor"))

local Power = {}

function Power.Compute(profile)
    if typeof(profile) ~= "table" then return 0 end
    local frameState = profile.Frames and profile.Frames[profile.SelectedFrameId] or {}
    local frameLevel = tonumber(frameState.Level) or 1
    local mastery = tonumber(profile.MasteryRank) or 0

    local weaponTotal = 0
    local weaponCount = 0
    for _, slot in ipairs({ "Primary", "Secondary", "Melee" }) do
        local weaponId = profile.Equipped and profile.Equipped[slot]
        local weaponState = weaponId and profile.Weapons and profile.Weapons[weaponId]
        if weaponState then
            weaponTotal += tonumber(weaponState.Level) or 1
            weaponCount += 1
        end
    end
    local weaponAverage = weaponCount > 0 and weaponTotal / weaponCount or 1

    local armorScore = 0
    for _, itemUid in pairs(profile.EquippedArmor or {}) do
        local item = profile.Inventory and profile.Inventory.Armor and profile.Inventory.Armor[itemUid]
        local def = item and Armor.Get(item.ArmorId)
        if def then
            armorScore += Armor.GetRarityValue(item.Rarity or def.MinRarity) * 2
            armorScore += (tonumber(item.Upgrade) or 0) * 0.7
        end
    end

    return math.floor(frameLevel * 1.8 + weaponAverage * 1.25 + armorScore + mastery * 6)
end

return Power
