--!nonstrict
local HubServices = require(script.Parent:WaitForChild("HubServices"))

local HubLayout = {}

HubLayout.RootFolderName = "Hub"
HubLayout.DevStationsFolderName = "DevStations"
HubLayout.InteractTag = "HubInteract"
HubLayout.NpcInteractTag = "NpcInteract"

HubLayout.Attributes = {
    ServiceId = "HubServiceId",
    NpcId = "NpcId",
}

HubLayout.PromptDefaults = {
    ActionText = "Open",
    HoldDuration = 0.1,
    MaxActivationDistance = 12,
    RequiresLineOfSight = false,
}

HubLayout.DevRing = {
    Radius = 24,
    StationSize = Vector3.new(7, 5, 3),
    SpawnSize = Vector3.new(8, 1, 8),
    SpawnCFrame = CFrame.new(0, 1, 0),
}

HubLayout.StationSpecs = {
    Equipment = { Color = Color3.fromRGB(42, 58, 72), AngleOffset = 0 },
    Mods = { Color = Color3.fromRGB(56, 48, 82), AngleOffset = 0 },
    Crafting = { Color = Color3.fromRGB(73, 61, 42), AngleOffset = 0 },
    Missions = { Color = Color3.fromRGB(45, 67, 64), AngleOffset = 0 },
    Navigation = { Color = Color3.fromRGB(44, 62, 86), AngleOffset = 0 },
    Marketplace = { Color = Color3.fromRGB(74, 52, 72), AngleOffset = 0 },
    Room = { Color = Color3.fromRGB(52, 70, 58), AngleOffset = 0 },
    Training = { Color = Color3.fromRGB(78, 50, 45), AngleOffset = 0 },
    Codex = { Color = Color3.fromRGB(48, 60, 78), AngleOffset = 0 },
}

function HubLayout.GetStationSpec(serviceId)
    local service = HubServices.Get(serviceId)
    if not service then return nil end
    local spec = table.clone(HubLayout.StationSpecs[serviceId] or {})
    spec.ServiceId = serviceId
    spec.DisplayName = service.DisplayName
    spec.Description = service.Description
    spec.Panel = service.Panel
    spec.InteractTags = service.InteractTags
    spec.Color = spec.Color or Color3.fromRGB(38, 47, 58)
    return spec
end

function HubLayout.GetDevStationCFrame(index, count)
    local angle = ((index - 1) / math.max(1, count)) * math.pi * 2
    local radius = HubLayout.DevRing.Radius
    return CFrame.new(math.cos(angle) * radius, 3, math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
end

return HubLayout
