--!nonstrict
local Storylines = {}

Storylines.ById = {
    MoonveilAwakening = {
        Id = "MoonveilAwakening",
        DisplayName = "Moonveil Awakening",
        Description = "Awaken as one of the Stained, restore the Moonveil gate, recover Asteri parts from Earth, and reveal the Atlas Shard refuge.",
        Steps = {
            { Id = "AwakenStained", Kind = "CompleteNode", NodeId = "Moon_Awaken_Stained", MissionId = "Moon_Awaken_Stained", Title = "Awaken beneath Moonveil" },
            { Id = "RestoreMoonBase", Kind = "CompleteNode", NodeId = "Moon_Restore_TempBase", MissionId = "Moon_Restore_TempBase", Title = "Restore the temporary Moonveil base" },
            { Id = "OpenEarthGate", Kind = "CompleteNode", NodeId = "Moon_Open_EarthGate", MissionId = "Moon_Open_EarthGate", Title = "Open the Earth gate" },
            { Id = "RecoverGateParts", Kind = "CompleteNode", NodeId = "Earth_Recover_GateParts", MissionId = "Earth_Recover_GateParts", Title = "Recover Asteri gate components on Earth" },
            { Id = "CompleteMarsGate", Kind = "CompleteNode", NodeId = "Moon_Complete_MarsGate", MissionId = "Moon_Complete_MarsGate", Title = "Complete the Mars gate and reveal the Atlas Shard" },
            { Id = "ArriveAtHub", Kind = "VisitLocation", LocationId = "Hub", Title = "Reach the Atlas Shard" },
            { Id = "ExploreAtlasShard", Kind = "TalkToNpc", NpcId = "Navigator", Title = "Explore the Atlas Shard and end the prologue" },
            { Id = "ScoutGreenbelt", Kind = "CompleteNode", NodeId = "Earth_Greenbelt_Exterminate", MissionId = "Earth_Greenbelt_Exterminate", Title = "Clear the Greenbelt" },
            { Id = "HoldRuins", Kind = "CompleteNode", NodeId = "Earth_Ruins_Survival", MissionId = "Earth_Ruins_Survival", Title = "Hold the Ruins" },
            { Id = "StopOutbreak", Kind = "CompleteNode", NodeId = "Earth_Bandit_Wave", MissionId = "Earth_Bandit_Wave", Title = "Stop the Outbreak" },
            { Id = "DefeatDeadeye", Kind = "CompleteNode", NodeId = "Earth_Deadeye_Boss", MissionId = "Earth_Deadeye_Boss", Title = "Defeat the Deadeye" },
            { Id = "ScoutMars", Kind = "CompleteNode", NodeId = "Mars_Dune_Patrol", MissionId = "Mars_Dune_Patrol", Title = "Scout the Martian Dunes" },
            { Id = "HoldRelic", Kind = "CompleteNode", NodeId = "Mars_Relic_Defense", MissionId = "Mars_Relic_Defense", Title = "Defend the Buried Relic" },
            { Id = "SurviveSandstorm", Kind = "CompleteNode", NodeId = "Mars_Sandstorm_Event", MissionId = "Mars_Sandstorm_Event", Title = "Survive the Sandstorm" },
            { Id = "DefeatWarden", Kind = "CompleteNode", NodeId = "Mars_Warden_Boss", MissionId = "Mars_Warden_Boss", Title = "Break the Warden Vault" },
        },
    },
}

Storylines.DefaultStoryId = "MoonveilAwakening"

function Storylines.Get(id)
    return Storylines.ById[id or Storylines.DefaultStoryId]
end

function Storylines.GetStep(storyId, stepId)
    local story = Storylines.Get(storyId)
    if not story then return nil end
    for index, step in ipairs(story.Steps or {}) do
        if step.Id == stepId then
            return step, index
        end
    end
    return nil
end

function Storylines.GetNextStep(storyId, completed)
    local story = Storylines.Get(storyId)
    if not story then return nil end
    completed = completed or {}
    for index, step in ipairs(story.Steps or {}) do
        if completed[step.Id] ~= true then
            return step, index
        end
    end
    return nil
end

return Storylines
