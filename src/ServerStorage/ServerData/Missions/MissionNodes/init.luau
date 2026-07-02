--!nonstrict
local MissionNodes = {}

MissionNodes.Planets = {
    Hub = {
        require(script:WaitForChild("Hub"):WaitForChild("Hub_TrainingRoom")),
    },
    Moon = {
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Awaken_Stained")),
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Restore_TempBase")),
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Open_EarthGate")),
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Complete_MarsGate")),
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Dome_Patrol")),
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Crater_Scavenge")),
        require(script:WaitForChild("Moon"):WaitForChild("Moon_Ryato_Outpost")),
    },
    Earth = {
        require(script:WaitForChild("Earth"):WaitForChild("Earth_Recover_GateParts")),
        require(script:WaitForChild("Earth"):WaitForChild("Earth_Greenbelt_Exterminate")),
        require(script:WaitForChild("Earth"):WaitForChild("Earth_Ruins_Survival")),
        require(script:WaitForChild("Earth"):WaitForChild("Earth_Bandit_Wave")),
        require(script:WaitForChild("Earth"):WaitForChild("Earth_Deadeye_Boss")),
    },
    Mars = {
        require(script:WaitForChild("Mars"):WaitForChild("Mars_Dune_Patrol")),
        require(script:WaitForChild("Mars"):WaitForChild("Mars_Relic_Defense")),
        require(script:WaitForChild("Mars"):WaitForChild("Mars_Sandstorm_Event")),
        require(script:WaitForChild("Mars"):WaitForChild("Mars_Warden_Boss")),
    },
    Debug = {
        require(script:WaitForChild("Debug"):WaitForChild("KillCount")),
        require(script:WaitForChild("Debug"):WaitForChild("Boss")),
        require(script:WaitForChild("Debug"):WaitForChild("Survival")),
        require(script:WaitForChild("Debug"):WaitForChild("EndlessWave")),
    },
}

MissionNodes.ByNodeId = {}
MissionNodes.ByMissionId = {}

for planetId, nodes in pairs(MissionNodes.Planets) do
    for _, config in ipairs(nodes) do
        config.PlanetId = config.PlanetId or planetId
        if config.NodeId then
            MissionNodes.ByNodeId[config.NodeId] = config
        end
        if config.MissionId then
            MissionNodes.ByMissionId[config.MissionId] = config
        end
    end
end

function MissionNodes.GetNode(nodeId)
    return MissionNodes.ByNodeId[nodeId]
end

function MissionNodes.GetMission(missionId)
    return MissionNodes.ByMissionId[missionId]
end

function MissionNodes.Resolve(missionId, nodeId)
    return (nodeId and MissionNodes.GetNode(nodeId)) or (missionId and MissionNodes.GetMission(missionId))
end

function MissionNodes.GetRule(nodeId)
    local config = MissionNodes.GetNode(nodeId)
    return config and config.Rule
end

function MissionNodes.GetReward(missionId, nodeId)
    local config = MissionNodes.Resolve(missionId, nodeId)
    return config and config.Reward
end

function MissionNodes.GetMissionSetup(missionId, nodeId)
    local config = MissionNodes.Resolve(missionId, nodeId)
    return config and config.Mission
end

return MissionNodes
