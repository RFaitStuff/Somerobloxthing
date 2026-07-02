--!nonstrict
local Npcs = {}

Npcs.ById = {
    Quartermaster = {
        Id = "Quartermaster",
        DisplayName = "Quartermaster Vale",
        Role = "Equipment",
        LocationId = "Hub",
        Prompt = "Talk",
        Lines = {
            Default = {
                "The Atlas Shard has old Asteri benches, patched human tools, and enough spare parts to keep you alive.",
                "Gear gets you through broken worlds. Keep your kit upgraded before leaving the Shard.",
            },
        },
        Actions = {
            { Id = "OpenEquipment", Label = "Open Equipment", Kind = "HubPanel", ServiceId = "Equipment" },
            { Id = "OpenMods", Label = "Open Mods", Kind = "HubPanel", ServiceId = "Mods" },
            { Id = "OpenCrafting", Label = "Open Crafting", Kind = "HubPanel", ServiceId = "Crafting" },
            { Id = "OpenShop", Label = "Browse Daily Stock", Kind = "OpenShop" },
        },
    },
    Navigator = {
        Id = "Navigator",
        DisplayName = "Navigator Ilyan",
        Role = "Missions",
        LocationId = "Hub",
        Prompt = "Briefing",
        Lines = {
            Default = {
                "Moonveil woke you. Earth gives us the parts. The completed gate gives us Mars and the Atlas Shard route.",
                "Pick a node from navigation or ask me for the next story step.",
            },
        },
        Actions = {
            { Id = "NextStory", Label = "Start Next Story Node", Kind = "StartNextStory" },
            { Id = "MissionBoard", Label = "Open Mission Board", Kind = "HubPanel", ServiceId = "Missions" },
            { Id = "Navigation", Label = "Open Navigation", Kind = "HubPanel", ServiceId = "Navigation" },
            { Id = "OpenBounties", Label = "Browse Bounties", Kind = "OpenBounties" },
        },
    },
    RoomSteward = {
        Id = "RoomSteward",
        DisplayName = "Room Steward",
        Role = "Housing",
        LocationId = "Hub",
        Prompt = "Customize",
        Lines = {
            Default = {
                "Your room is a reclaimed corner of the Atlas Shard. Private by default, shared only when you choose.",
                "Drop room models in ServerStorage later and the renderer will prefer them over placeholders.",
            },
        },
        Actions = {
            { Id = "EnterRoom", Label = "Enter Room", Kind = "EnterRoom" },
            { Id = "RoomPanel", Label = "Open Room Console", Kind = "HubPanel", ServiceId = "Room" },
        },
    },
    RangeOfficer = {
        Id = "RangeOfficer",
        DisplayName = "Range Officer Kade",
        Role = "Training",
        LocationId = "Hub",
        Prompt = "Train",
        Lines = {
            Default = {
                "Weapons stay cold in the hub. Step into the range if you want to test damage.",
                "Training uses mission rules so combat stays blocked everywhere else.",
            },
        },
        Actions = {
            { Id = "Training", Label = "Enter Shooting Range", Kind = "EnterTraining" },
        },
    },
}

Npcs.DevOrder = { "Navigator", "Quartermaster", "RoomSteward", "RangeOfficer" }

function Npcs.Get(id)
    return Npcs.ById[id]
end

function Npcs.GetPublic(npcId)
    local npc = Npcs.Get(npcId)
    if not npc then return nil end
    return {
        Id = npc.Id,
        DisplayName = npc.DisplayName,
        Role = npc.Role,
        LocationId = npc.LocationId,
        Lines = npc.Lines,
        Actions = npc.Actions,
    }
end

return Npcs
