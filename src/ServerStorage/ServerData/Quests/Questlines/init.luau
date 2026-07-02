--!nonstrict
local Questlines = {}

Questlines.ById = {
    MoonveilAwakening = {
        Id = "MoonveilAwakening",
        DisplayName = "Moonveil Awakening",
        Description = "Wake as a Stained in Moonveil, restore the temporary base, reach Earth, recover gate components, and reveal the Atlas Shard.",
        Steps = {
            { Id = "AwakenStained", Type = "CompleteNode", NodeId = "Moon_Awaken_Stained", StoryVariant = true, Title = "Rise from Stillwater" },
            { Id = "RestoreMoonBase", Type = "CompleteNode", NodeId = "Moon_Restore_TempBase", StoryVariant = true, Title = "Restore the Moonveil temporary base" },
            { Id = "OpenEarthGate", Type = "CompleteNode", NodeId = "Moon_Open_EarthGate", StoryVariant = true, Title = "Stabilize the Earth warp gate" },
            { Id = "UnlockEarthGate", Type = "UnlockGate", GateId = "EarthGate", Title = "Open the route to Earth" },
            { Id = "RecoverGateParts", Type = "CompleteNode", NodeId = "Earth_Recover_GateParts", StoryVariant = true, Title = "Recover Asteri gate parts on Earth" },
            { Id = "CompleteMarsGate", Type = "CompleteNode", NodeId = "Moon_Complete_MarsGate", StoryVariant = true, Title = "Complete the Mars gate" },
            { Id = "UnlockMarsGate", Type = "UnlockGate", GateId = "MarsGate", Title = "Open the route to Mars" },
            { Id = "RevealAtlasShardGate", Type = "UnlockGate", GateId = "AtlasShardGate", Title = "Reveal the Atlas Shard route" },
            { Id = "ExploreAtlasShard", Type = "TalkToNpc", NpcId = "Navigator", Title = "Explore the Atlas Shard and meet the navigator" },
            { Id = "CraftRifle", Type = "CraftOrOwn", OutputType = "Weapon", OutputId = "Rifle", Title = "Prepare a rifle for wider patrols" },
        },
        Rewards = {
            Coins = 1000,
            Materials = { Alloy = 25, Circuit = 10 },
        },
    },
}

Questlines.DefaultQuestId = "MoonveilAwakening"

function Questlines.Get(id)
    return Questlines.ById[id or Questlines.DefaultQuestId]
end

return Questlines
