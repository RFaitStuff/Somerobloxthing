--!nonstrict
local NpcBounties = {}

NpcBounties.ByNpcId = {
    Navigator = {
        Id = "NavigatorBounties",
        DisplayName = "Navigation Bounties",
        ResetSeconds = 24 * 60 * 60,
        Bounties = {
            EarthPatrolSweep = {
                Id = "EarthPatrolSweep",
                DisplayName = "Earth Patrol Sweep",
                Objective = { Type = "CompleteNode", NodeId = "Earth_Greenbelt_Exterminate", Count = 1 },
                Reward = { Coins = 250, Materials = { Alloy = 10 } },
                DailyStock = 1,
            },
            MarsRelicPrep = {
                Id = "MarsRelicPrep",
                DisplayName = "Mars Relic Prep",
                Objective = { Type = "CompleteNode", NodeId = "Mars_Dune_Patrol", Count = 1 },
                Reward = { Coins = 400, Materials = { Ferrite = 8 } },
                DailyStock = 1,
                RequiresStoryStep = "DefeatDeadeye",
            },
            EarthBanditCull = {
                Id = "EarthBanditCull",
                DisplayName = "Cull Earth Bandits",
                Objective = { Type = "DefeatEnemy", Faction = "EarthBandits", Count = 8 },
                Reward = { Coins = 300, Materials = { Alloy = 6 } },
                DailyStock = 1,
            },
            SalvageCircuitCache = {
                Id = "SalvageCircuitCache",
                DisplayName = "Salvage Circuit Cache",
                Objective = { Type = "GatherResource", MaterialId = "Circuit", LocationId = "Earth", Count = 6 },
                Reward = { Coins = 220, Materials = { Alloy = 4 } },
                DailyStock = 1,
            },
            GateRouteSurvey = {
                Id = "GateRouteSurvey",
                DisplayName = "Gate Route Survey",
                Objective = { Type = "UnlockGate", GateId = "MarsGate", Count = 1 },
                Reward = { Coins = 500, Materials = { Circuit = 8 } },
                DailyStock = 1,
                RequiresStoryStep = "RecoverGateParts",
            },
        },
    },
}

function NpcBounties.Get(npcId)
    return NpcBounties.ByNpcId[npcId]
end

return NpcBounties
