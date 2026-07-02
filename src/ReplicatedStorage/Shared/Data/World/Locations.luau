--!nonstrict
local Locations = {}

Locations.ById = {
    Hub = {
        Id = "Hub",
        DisplayName = "Atlas Shard",
        Kind = "SocialHub",
        MaxPublicPlayers = 40,
        Description = "A hidden fragment of Atlas rebuilt into the last major safe haven for survivors, traders, researchers, and Stained.",
        Unlock = { StoryStepId = "CompleteMarsGate", RecommendedPower = 20 },
        Services = {
            "MissionBoard",
            "FrameStation",
            "WeaponBench",
            "ArmorStation",
            "ModStation",
            "Crafting",
            "Trading",
            "ClanHall",
            "HousingAccess",
            "TrainingRoom",
            "EventBoard",
        },
        Nodes = {
            { Id = "Hub_TrainingRoom", DisplayName = "Training Room", MissionId = "TrainingRoom", NodeType = "SoloInstance", RecommendedPower = 0, Matchmaking = "Solo" },
        },
    },
    Moon = {
        Id = "Moon",
        DisplayName = "Moonveil Ruins",
        Kind = "StarterZone",
        MaxPublicPlayers = 12,
        Description = "The broken moon colony where Poise awakened the first Stained. Tutorial base, ruined dome paths, and the damaged warp gate live here.",
        Resources = { "Alloy", "Circuit", "Spark" },
        Factions = { "Ryato", "MoonveilRemnants" },
        Areas = {
            { Id = "Stillwater", DisplayName = "Stillwater Cradle", LevelRange = { 1, 4 }, FastTravelId = "MoonveilBase", Nodes = { "Moon_Awaken_Stained" } },
            { Id = "MoonveilBase", DisplayName = "Moonveil Temporary Base", LevelRange = { 1, 6 }, FastTravelId = "MoonveilBase", Nodes = { "Moon_Restore_TempBase" } },
            { Id = "BrokenDome", DisplayName = "Broken Dome", LevelRange = { 3, 14 }, Nodes = { "Moon_Dome_Patrol", "Moon_Crater_Scavenge" } },
            { Id = "WarpSanctum", DisplayName = "Warp Sanctum", LevelRange = { 5, 22 }, Nodes = { "Moon_Open_EarthGate", "Moon_Complete_MarsGate", "Moon_Ryato_Outpost" } },
        },
        FastTravel = {
            { Id = "MoonveilBase", DisplayName = "Moonveil Temporary Base", AreaId = "Stillwater", Unlock = { Mode = "Default" } },
            { Id = "WarpSanctum", DisplayName = "Warp Sanctum", AreaId = "WarpSanctum", Unlock = { Mode = "Node", NodeId = "Moon_Restore_TempBase" } },
        },
        Nodes = {
            { Id = "Moon_Awaken_Stained", DisplayName = "Awaken Beneath Moonveil", MissionId = "Moon_Awaken_Stained", NodeType = "SoloInstance", RecommendedPower = 0, Matchmaking = "Solo", Visibility = { Phase = "Prologue" } },
            { Id = "Moon_Restore_TempBase", DisplayName = "Restore the Temporary Base", MissionId = "Moon_Restore_TempBase", NodeType = "SoloInstance", RecommendedPower = 3, Matchmaking = "Solo", Visibility = { Phase = "Prologue" } },
            { Id = "Moon_Open_EarthGate", DisplayName = "Open the Earth Gate", MissionId = "Moon_Open_EarthGate", NodeType = "SoloInstance", RecommendedPower = 5, Matchmaking = "Solo", Visibility = { Phase = "Prologue" } },
            { Id = "Moon_Complete_MarsGate", DisplayName = "Complete the Mars Gate", MissionId = "Moon_Complete_MarsGate", NodeType = "SoloInstance", RecommendedPower = 18, Matchmaking = "Solo", Visibility = { Phase = "Prologue" } },
            { Id = "Moon_Dome_Patrol", DisplayName = "Broken Dome Patrol", MissionId = "Moon_Dome_Patrol", NodeType = "SquadInstance", RecommendedPower = 24, Matchmaking = "PublicOrSolo", Visibility = { RequiresLocation = "Hub" } },
            { Id = "Moon_Crater_Scavenge", DisplayName = "Crater Salvage Run", MissionId = "Moon_Crater_Scavenge", NodeType = "SquadInstance", RecommendedPower = 28, Matchmaking = "PublicOrSolo", Visibility = { RequiresLocation = "Hub" } },
            { Id = "Moon_Ryato_Outpost", DisplayName = "Ryato Outpost", MissionId = "Moon_Ryato_Outpost", NodeType = "BossInstance", RecommendedPower = 36, Matchmaking = "PublicOrSolo", Visibility = { RequiresLocation = "Hub" } },
        },
    },
    Earth = {
        Id = "Earth",
        DisplayName = "Earth",
        Kind = "PublicZone",
        MaxPublicPlayers = 24,
        Description = "First open patrol planet reached through the repaired Moonveil warp gate. Players explore, recover salvage, find resources, and enter mission nodes.",
        Resources = { "Alloy", "Circuit", "Spark", "Lens" },
        Factions = { "EarthBandits", "VoidCult" },
        Areas = {
            { Id = "Greenbelt", DisplayName = "Greenbelt", LevelRange = { 4, 10 }, FastTravelId = "GreenbeltRelay", PublicEvents = { "Earth_Bandit_Wave" } },
            { Id = "OldRuins", DisplayName = "Old Relay Ruins", LevelRange = { 9, 18 }, FastTravelId = "RuinsCamp", Nodes = { "Earth_Ruins_Survival" } },
            { Id = "SignalNest", DisplayName = "Signal Nest", LevelRange = { 18, 24 }, Nodes = { "Earth_Deadeye_Boss" } },
        },
        FastTravel = {
            { Id = "GreenbeltRelay", DisplayName = "Greenbelt Relay", AreaId = "Greenbelt", Unlock = { Mode = "Default" } },
            { Id = "RuinsCamp", DisplayName = "Ruins Camp", AreaId = "OldRuins", Unlock = { Mode = "EncounterOrNode", NodeId = "Earth_Greenbelt_Exterminate" } },
        },
        Nodes = {
            { Id = "Earth_Recover_GateParts", DisplayName = "Recover Gate Components", MissionId = "Earth_Recover_GateParts", NodeType = "SoloInstance", RecommendedPower = 12, Matchmaking = "Solo", Visibility = { Phase = "Prologue" } },
            { Id = "Earth_Greenbelt_Exterminate", DisplayName = "Greenbelt Sweep", MissionId = "Earth_Greenbelt_Exterminate", NodeType = "SquadInstance", RecommendedPower = 10, Matchmaking = "PublicOrSolo", Visibility = { RequiresLocation = "Hub" } },
            { Id = "Earth_Ruins_Survival", DisplayName = "Ruins Survival", MissionId = "Earth_Ruins_Survival", NodeType = "SquadInstance", RecommendedPower = 20, Matchmaking = "PublicOrSolo", Visibility = { RequiresLocation = "Hub" } },
            { Id = "Earth_Bandit_Wave", DisplayName = "Bandit Outbreak", MissionId = "Earth_Bandit_Wave", NodeType = "PublicEvent", RecommendedPower = 15, Matchmaking = "PublicZone", Visibility = { RequiresLocation = "Hub" } },
            { Id = "Earth_Deadeye_Boss", DisplayName = "Deadeye Signal", MissionId = "Earth_Deadeye_Boss", NodeType = "BossInstance", RecommendedPower = 32, Matchmaking = "PublicOrSolo", Visibility = { RequiresLocation = "Hub" } },
        },
    },
    Mars = {
        Id = "Mars",
        DisplayName = "Mars",
        Kind = "PublicZone",
        MaxPublicPlayers = 20,
        Description = "First major post-Atlas Shard patrol planet with harsher ranged enemies, open dunes, buried ruins, and higher-tier crafting materials.",
        Resources = { "Alloy", "Circuit", "Lens", "Core", "Ferrite" },
        Factions = { "MarsRemnant", "VoidCult" },
        Unlock = { StoryStepId = "CompleteMarsGate", RecommendedPower = 20 },
        Areas = {
            { Id = "Dunes", DisplayName = "Open Dunes", LevelRange = { 24, 34 }, FastTravelId = "DuneRelay", PublicEvents = { "Mars_Sandstorm_Event" } },
            { Id = "RelicSite", DisplayName = "Buried Relic Site", LevelRange = { 29, 40 }, FastTravelId = "RelicCamp", Nodes = { "Mars_Relic_Defense" } },
            { Id = "WardenVault", DisplayName = "Warden Vault", LevelRange = { 38, 46 }, Nodes = { "Mars_Warden_Boss" } },
        },
        FastTravel = {
            { Id = "DuneRelay", DisplayName = "Dune Relay", AreaId = "Dunes", Unlock = { Mode = "StoryStep", StepId = "DefeatDeadeye" } },
            { Id = "RelicCamp", DisplayName = "Relic Camp", AreaId = "RelicSite", Unlock = { Mode = "Node", NodeId = "Mars_Dune_Patrol" } },
        },
        Nodes = {
            { Id = "Mars_Dune_Patrol", DisplayName = "Dune Patrol", MissionId = "Mars_Dune_Patrol", NodeType = "SquadInstance", RecommendedPower = 38, Matchmaking = "PublicOrSolo" },
            { Id = "Mars_Relic_Defense", DisplayName = "Relic Defense", MissionId = "Mars_Relic_Defense", NodeType = "SquadInstance", RecommendedPower = 44, Matchmaking = "PublicOrSolo" },
            { Id = "Mars_Sandstorm_Event", DisplayName = "Sandstorm Event", MissionId = "Mars_Sandstorm_Event", NodeType = "PublicEvent", RecommendedPower = 42, Matchmaking = "PublicZone" },
            { Id = "Mars_Warden_Boss", DisplayName = "Warden Vault", MissionId = "Mars_Warden_Boss", NodeType = "BossInstance", RecommendedPower = 52, Matchmaking = "PublicOrSolo" },
        },
    },
}

function Locations.Get(id)
    return Locations.ById[id]
end

function Locations.GetNode(locationId, nodeId)
    local location = Locations.Get(locationId)
    if not location then return nil end
    for _, node in ipairs(location.Nodes or {}) do
        if node.Id == nodeId then return node end
    end
    return nil
end

return Locations
