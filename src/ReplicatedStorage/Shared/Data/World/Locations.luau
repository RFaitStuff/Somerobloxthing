--!nonstrict
local Locations = {}

Locations.ById = {
    Earth = {
        Id = "Earth",
        DisplayName = "Earth",
        Kind = "PublicZone",
        MaxPublicPlayers = 24,
        Description = "First public patrol zone. Players can roam, meet others, and enter mission nodes.",
        Nodes = {
            { Id = "Earth_Greenbelt_Exterminate", DisplayName = "Greenbelt Sweep", MissionId = "KillCount", NodeType = "SquadInstance", RecommendedPower = 10 },
            { Id = "Earth_Ruins_Survival", DisplayName = "Ruins Survival", MissionId = "Survival", NodeType = "SquadInstance", RecommendedPower = 20 },
            { Id = "Earth_Bandit_Wave", DisplayName = "Bandit Outbreak", MissionId = "EndlessWave", NodeType = "PublicEvent", RecommendedPower = 15 },
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
