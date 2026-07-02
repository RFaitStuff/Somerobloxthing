--!nonstrict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local HubServices = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("HubServices"))
local HubLayout = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("HubLayout"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local HubService = {}
HubService.__index = HubService

function HubService.new(playerState, world, roomService)
    return setmetatable({ PlayerState = playerState, World = world, Rooms = roomService, Remote = nil, PromptConnections = {} }, HubService)
end

function HubService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.HubRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    self:EnsureDevHubStations()
    self:BindExistingPrompts()
    CollectionService:GetInstanceAddedSignal(HubLayout.InteractTag):Connect(function(instance)
        self:BindPromptInstance(instance)
    end)
end

function HubService:GetHubFolder()
    local hub = Workspace:FindFirstChild(HubLayout.RootFolderName)
    if not hub then
        hub = Instance.new("Folder")
        hub.Name = HubLayout.RootFolderName
        hub.Parent = Workspace
    end
    return hub
end

function HubService:GetHubSpawnCFrame()
    local hub = Workspace:FindFirstChild(HubLayout.RootFolderName)
    local spawn = hub and (hub:FindFirstChild("HubSpawn", true) or hub:FindFirstChild("Spawn", true))
    if spawn and spawn:IsA("BasePart") then
        return spawn.CFrame + Vector3.new(0, 4, 0)
    end
    return CFrame.new(0, 8, 0)
end

function HubService:EnsureDevHubStations()
    if not RunService:IsStudio() then return end
    local hub = self:GetHubFolder()
    for _, descendant in ipairs(hub:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute(HubLayout.Attributes.ServiceId) then
            return
        end
    end

    local stations = Instance.new("Folder")
    stations.Name = HubLayout.DevStationsFolderName
    stations.Parent = hub

    local spawn = Instance.new("Part")
    spawn.Name = "HubSpawn"
    spawn.Anchored = true
    spawn.Size = HubLayout.DevRing.SpawnSize
    spawn.CFrame = HubLayout.DevRing.SpawnCFrame
    spawn.Color = Color3.fromRGB(56, 102, 130)
    spawn.Material = Enum.Material.SmoothPlastic
    spawn.Parent = stations

    for index, serviceId in ipairs(HubServices.Order) do
        local spec = HubLayout.GetStationSpec(serviceId)
        local part = Instance.new("Part")
        part.Name = serviceId .. "Station"
        part.Anchored = true
        part.Size = HubLayout.DevRing.StationSize
        part.CFrame = HubLayout.GetDevStationCFrame(index, #HubServices.Order)
        part.Color = spec and spec.Color or Color3.fromRGB(38, 47, 58)
        part.Material = Enum.Material.SmoothPlastic
        part:SetAttribute(HubLayout.Attributes.ServiceId, serviceId)
        part.Parent = stations
        CollectionService:AddTag(part, HubLayout.InteractTag)

        local label = Instance.new("SurfaceGui")
        label.Name = "StationLabel"
        label.Face = Enum.NormalId.Front
        label.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        label.PixelsPerStud = 40
        label.Parent = part

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextScaled = true
        text.TextColor3 = Color3.fromRGB(235, 242, 248)
        text.Text = spec and spec.DisplayName or serviceId
        text.Parent = label
    end
end

function HubService:IsInHub(player)
    local state = self.PlayerState:Get(player)
    return state.LocationId == "Hub" or state.LocationId == nil
end

function HubService:ApplyHubRules(player)
    if self.World and self.World.CanAccessLocation and not self.World:CanAccessLocation(player, "Hub") then
        local state = self.PlayerState:Get(player)
        state.LocationId = "Moon"
        state.SafeZone = true
        state.TrainingRange = false
        Net.GetRemoteEvent(Net.RemoteEvents.HubUpdate):FireClient(player, {
            Type = "HubLocked",
            LocationId = "Moon",
            DisplayName = "Moonveil Ruins",
            ActivePanel = "Story",
        })
        return false
    end
    local state = self.PlayerState:Get(player)
    state.LocationId = "Hub"
    state.SafeZone = true
    state.TrainingRange = false
    state.ActiveMission = nil
    state.Matchmaking = nil
    Net.GetRemoteEvent(Net.RemoteEvents.MissionUpdate):FireClient(player, { Mission = nil })
    Net.GetRemoteEvent(Net.RemoteEvents.HubUpdate):FireClient(player, {
        Type = "HubRules",
        Services = HubServices.ById,
        Order = HubServices.Order,
        SafeZoneRules = HubServices.SafeZoneRules,
        ActivePanel = state.ActiveHubPanel,
    })
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = self:GetHubSpawnCFrame()
    end
    return true
end

function HubService:OpenPanel(player, serviceId)
    if self.World and self.World.CanAccessLocation and not self.World:CanAccessLocation(player, "Hub") then
        self:ApplyHubRules(player)
        return false
    end
    local service = HubServices.Get(serviceId)
    if not service then return false end
    local state = self.PlayerState:Get(player)
    state.ActiveHubPanel = service.Panel
    state.LocationId = "Hub"
    state.SafeZone = true
    Net.GetRemoteEvent(Net.RemoteEvents.HubUpdate):FireClient(player, {
        Type = "OpenPanel",
        ServiceId = service.Id,
        Panel = service.Panel,
        Services = HubServices.ById,
        Order = HubServices.Order,
        SafeZoneRules = HubServices.SafeZoneRules,
    })
    return true
end

function HubService:BindPromptInstance(instance)
    if not instance:IsA("BasePart") then return end
    local serviceId = instance:GetAttribute(HubLayout.Attributes.ServiceId)
    if not serviceId then
        local tags = CollectionService:GetTags(instance)
        for _, tag in ipairs(tags) do
            local service = HubServices.GetByTag(tag)
            if service then serviceId = service.Id break end
        end
    end
    if not serviceId or not HubServices.Get(serviceId) then return end
    local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = HubLayout.PromptDefaults.ActionText
        prompt.ObjectText = HubServices.Get(serviceId).DisplayName
        prompt.HoldDuration = HubLayout.PromptDefaults.HoldDuration
        prompt.MaxActivationDistance = HubLayout.PromptDefaults.MaxActivationDistance
        prompt.RequiresLineOfSight = HubLayout.PromptDefaults.RequiresLineOfSight
        prompt.Parent = instance
    end
    if self.PromptConnections[prompt] then return end
    self.PromptConnections[prompt] = prompt.Triggered:Connect(function(player)
        self:OpenPanel(player, serviceId)
    end)
end

function HubService:BindExistingPrompts()
    for _, instance in ipairs(CollectionService:GetTagged(HubLayout.InteractTag)) do
        self:BindPromptInstance(instance)
    end
    local hub = Workspace:FindFirstChild(HubLayout.RootFolderName)
    if hub then
        for _, instance in ipairs(hub:GetDescendants()) do
            if instance:IsA("BasePart") and instance:GetAttribute(HubLayout.Attributes.ServiceId) then
                self:BindPromptInstance(instance)
            end
        end
    end
end

function HubService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Hub", "BadPayload") return end
    if payload.Action == "RequestHub" then
        self:ApplyHubRules(player)
    elseif payload.Action == "OpenPanel" then
        if not self:OpenPanel(player, payload.ServiceId) then ValidationAudit.Reject(player, "Hub", "InvalidService") end
    elseif payload.Action == "EnterRoom" then
        if self.Rooms then self.Rooms:TeleportToRoom(player) end
        self:OpenPanel(player, "Room")
    elseif payload.Action == "EnterTraining" then
        if self.World then
            self.World:ActivateNode(player, "Hub", "Hub_TrainingRoom", { Solo = true })
        end
    else
        ValidationAudit.Reject(player, "Hub", "UnknownAction")
    end
end

return HubService
