--!nonstrict
local HubServices = {}

HubServices.SafeZoneRules = {
    DisableWeapons = true,
    DisableDamage = true,
    DisableEnemyAggro = true,
    AllowMovementAbilities = true,
    AllowTrainingWeaponsOnly = true,
}

HubServices.ById = {
    Equipment = {
        Id = "Equipment",
        DisplayName = "Equipment",
        Panel = "Equipment",
        Description = "Frames, weapons, armor, loadouts, and cosmetics.",
        InteractTags = { "EquipmentStation", "Arsenal" },
    },
    Mods = {
        Id = "Mods",
        DisplayName = "Mods",
        Panel = "Mods",
        Description = "Equip, rank, and inspect frame/weapon/melee mods.",
        InteractTags = { "ModStation" },
    },
    Crafting = {
        Id = "Crafting",
        DisplayName = "Foundry",
        Panel = "Crafting",
        Description = "Craft weapons, frames, consumables, and housing items.",
        InteractTags = { "CraftingStation", "Foundry" },
    },
    Missions = {
        Id = "Missions",
        DisplayName = "Mission Board",
        Panel = "Missions",
        Description = "Queue activities, story missions, public events, and alerts.",
        InteractTags = { "MissionBoard" },
    },
    Navigation = {
        Id = "Navigation",
        DisplayName = "Navigation",
        Panel = "Navigation",
        Description = "Orbiter-style star chart and destination selector.",
        InteractTags = { "Navigation", "OrbiterNavigation" },
    },
    Marketplace = {
        Id = "Marketplace",
        DisplayName = "Marketplace",
        Panel = "Marketplace",
        Description = "Cosmetics, convenience items, slots, and trade listings.",
        InteractTags = { "Marketplace" },
    },
    Room = {
        Id = "Room",
        DisplayName = "Personal Room",
        Panel = "Room",
        Description = "Private customizable orbiter room and housing access.",
        InteractTags = { "RoomAccess", "HousingAccess" },
    },
    Training = {
        Id = "Training",
        DisplayName = "Training Range",
        Panel = "Training",
        Description = "Shooting range and movement test space where weapons are allowed.",
        InteractTags = { "TrainingRange" },
    },
    Codex = {
        Id = "Codex",
        DisplayName = "Codex",
        Panel = "Codex",
        Description = "Story archive, faction notes, world history, and discovered records.",
        InteractTags = { "Codex", "CodexTerminal", "ArchiveTerminal" },
    },
}

HubServices.Order = { "Equipment", "Mods", "Crafting", "Missions", "Navigation", "Marketplace", "Room", "Training", "Codex" }

function HubServices.Get(id)
    return HubServices.ById[id]
end

function HubServices.GetByTag(tag)
    for _, service in pairs(HubServices.ById) do
        for _, serviceTag in ipairs(service.InteractTags or {}) do
            if serviceTag == tag then
                return service
            end
        end
    end
    return nil
end

return HubServices
