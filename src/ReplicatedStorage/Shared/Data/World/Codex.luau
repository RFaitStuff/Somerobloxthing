--!nonstrict
local Codex = {}

Codex.Categories = {
    Story = { Id = "Story", DisplayName = "Story" },
    Locations = { Id = "Locations", DisplayName = "Locations" },
    Origins = { Id = "Origins", DisplayName = "Origins" },
    People = { Id = "People", DisplayName = "People" },
    Systems = { Id = "Systems", DisplayName = "Systems" },
}

Codex.Entries = {
    AtlasShard = {
        Id = "AtlasShard",
        Category = "Locations",
        DisplayName = "Atlas Shard",
        Unlock = { LocationId = "Hub" },
        Summary = "A surviving fragment of Atlas hidden inside a warped pocket of space.",
        Body = "The Atlas Shard contains an Asteri sanctuary and part of the old warp-gate network. Survivors rebuilt it into the last major refuge for Stained, traders, researchers, Atherins, Star Eyed, Adapted, Altered, and humans.",
        Related = { "Atlas", "Asteri", "WarpGates" },
    },
    Moonveil = {
        Id = "Moonveil",
        Category = "Locations",
        DisplayName = "Moonveil",
        Unlock = { LocationId = "Moon" },
        Summary = "The ruined hidden moon colony where the player awakens.",
        Body = "Moonveil was built beneath a concealed dome after Earth fell deeper into war. The Ryato destroyed it, and years later Poise returned with The Purest, creating the conditions that woke the first Stained.",
        Related = { "Poise", "Stained", "Ryato" },
    },
    Stained = {
        Id = "Stained",
        Category = "People",
        DisplayName = "Stained",
        Unlock = { StoryStepId = "AwakenStained" },
        Summary = "Beings born from Poise, The Purest, and the dead of Moonveil.",
        Body = "The player is one of the Stained. Their powers can grow through Vestiges, fragments connected to fallen Altered and the history of The Purest.",
        Related = { "Poise", "Purest", "Vestiges" },
    },
    Purest = {
        Id = "Purest",
        Category = "Systems",
        DisplayName = "The Purest",
        Unlock = { StoryStepId = "AwakenStained" },
        Summary = "The unstable Asteri-improved form of The Pure.",
        Body = "The Purest gave rise to Altered and eventually the Stained. It carries survival, adaptation, and danger in the same breath.",
        Related = { "Pure", "Altered", "Stained" },
    },
    Ryato = {
        Id = "Ryato",
        Category = "Origins",
        DisplayName = "Ryato",
        Unlock = { LocationId = "Moon" },
        Summary = "The hostile origin force that destroyed Moonveil.",
        Body = "Ryato patrols return to the moon after the Atlas Shard route is restored. Their outposts pressure the damaged gate network and threaten survivor routes.",
        Related = { "Moonveil", "Origins" },
    },
    Kharons = {
        Id = "Kharons",
        Category = "Origins",
        DisplayName = "Kharons",
        Unlock = { LocationId = "Hub" },
        Summary = "An enemy origin connected to the destruction of Atlas.",
        Body = "The Kharons are tied to the Eclipsion attack that destroyed Atlas. Their full role is still hidden from the player during the prologue.",
        Related = { "Atlas", "Eclipsion" },
    },
    WarpGates = {
        Id = "WarpGates",
        Category = "Systems",
        DisplayName = "Warp Gates",
        Unlock = { StoryStepId = "OpenEarthGate" },
        Summary = "Asteri-linked routes used to move between worlds and hidden pockets of space.",
        Body = "The Moonveil gate starts damaged and can only reach Earth. Recovering Asteri parts lets the player complete the Mars and Atlas Shard route.",
        Related = { "AtlasShard", "Moonveil" },
    },
}

Codex.Order = { "Moonveil", "Stained", "Purest", "WarpGates", "AtlasShard", "Ryato", "Kharons" }

function Codex.Get(id)
    return Codex.Entries[id]
end

return Codex
