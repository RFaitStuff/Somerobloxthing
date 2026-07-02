--!nonstrict
local Rooms = {}

Rooms.Privacy = { "Private", "Friends", "Invite", "Clan", "Public" }

Rooms.Templates = {
    OrbiterPod = {
        Id = "OrbiterPod",
        DisplayName = "Orbiter Pod",
        Tier = 1,
        SlotLimit = 35,
        Unlock = { Type = "Default" },
        Bounds = Vector3.new(48, 22, 48),
    },
    RelaySuite = {
        Id = "RelaySuite",
        DisplayName = "Relay Suite",
        Tier = 2,
        SlotLimit = 70,
        Unlock = { Type = "Mastery", Rank = 3 },
        Costs = { Alloy = 150, Circuit = 60 },
        Bounds = Vector3.new(72, 30, 72),
    },
    ClanLoft = {
        Id = "ClanLoft",
        DisplayName = "Clan Loft",
        Tier = 3,
        SlotLimit = 120,
        Unlock = { Type = "Mastery", Rank = 6 },
        Costs = { Alloy = 300, Circuit = 150, Core = 2 },
        Bounds = Vector3.new(96, 36, 96),
    },
}

Rooms.Decorations = {
    BasicCrate = { Id = "BasicCrate", DisplayName = "Supply Crate", Category = "Props", Cost = { Alloy = 5 }, Size = Vector3.new(3, 3, 3) },
    ArsenalBench = { Id = "ArsenalBench", DisplayName = "Arsenal Bench", Category = "Utility", Cost = { Alloy = 30, Circuit = 8 }, Size = Vector3.new(7, 4, 3) },
    ModKiosk = { Id = "ModKiosk", DisplayName = "Mod Kiosk", Category = "Utility", Cost = { Circuit = 18, Spark = 2 }, Size = Vector3.new(4, 6, 3) },
    BannerStand = { Id = "BannerStand", DisplayName = "Banner Stand", Category = "Cosmetic", Cost = { Alloy = 10 }, Size = Vector3.new(2, 7, 2) },
}

function Rooms.GetTemplate(id)
    return Rooms.Templates[id]
end

function Rooms.GetDecoration(id)
    return Rooms.Decorations[id]
end

return Rooms
