--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local Storylines = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Storylines"))
local Power = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Power"))
local MissionNodes = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Missions"):WaitForChild("MissionNodes"))
local NodeRules = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("World"):WaitForChild("NodeRules"))
local MatchmakingService = require(script.Parent:WaitForChild("MatchmakingService"))

local WorldService = {}
WorldService.__index = WorldService

local function cloneTable(value)
    if typeof(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = cloneTable(child)
    end
    return copy
end

function WorldService.new(playerState, missions, profiles)
    return setmetatable({
        PlayerState = playerState,
        Missions = missions,
        Profiles = profiles,
        QuestTracker = nil,
        BountyTracker = nil,
        Remote = nil,
        Matchmaking = nil,
    }, WorldService)
end

function WorldService:Start()
    self.Matchmaking = MatchmakingService.new(self.PlayerState, self.Missions, function(player, payload)
        self:Replicate(player, payload)
    end)
    self.Matchmaking:Start()
    if Net.RemoteEvents.WorldRequest then
        self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.WorldRequest)
        self.Remote.OnServerEvent:Connect(function(player, payload) self:Handle(player, payload) end)
    end
end

function WorldService:Replicate(player, extra)
    if not Net.RemoteEvents.WorldUpdate then return end
    local profile = self.Profiles and self.Profiles:Get(player)
    local state = self.PlayerState:Get(player)
    local storyProgress = self.Profiles and self.Profiles:GetStoryProgress(player)
    local activeStoryId = storyProgress and storyProgress.ActiveStoryId or Storylines.DefaultStoryId
    local nextStep = Storylines.GetNextStep(activeStoryId, storyProgress and storyProgress.CompletedSteps)
    local payload = {
        Locations = self:GetVisibleLocations(player),
        Story = {
            ActiveStoryId = activeStoryId,
            NextStep = nextStep,
            Progress = storyProgress,
        },
        Power = Power.Compute(profile),
        Matchmaking = state.Matchmaking,
    }
    for key, value in pairs(extra or {}) do
        payload[key] = value
    end
    Net.GetRemoteEvent(Net.RemoteEvents.WorldUpdate):FireClient(player, payload)
end

function WorldService:IsLocationUnlockedForDisplay(progress, locationId)
    if not progress then return locationId == "Moon" end
    if locationId == "Moon" then return true end
    return progress.UnlockedLocations and progress.UnlockedLocations[locationId] == true
end

function WorldService:IsNodeVisible(progress, node)
    local visibility = node.Visibility
    if not visibility then return true end
    local unlocked = progress and progress.UnlockedLocations or {}
    local completedSteps = progress and progress.CompletedSteps or {}
    if visibility.RequiresLocation and unlocked[visibility.RequiresLocation] ~= true then
        return false
    end
    if visibility.RequiresStoryStep and completedSteps[visibility.RequiresStoryStep] ~= true then
        return false
    end
    return true
end

function WorldService:GetVisibleLocations(player)
    local progress = self.Profiles and self.Profiles:GetStoryProgress(player)
    local visible = {}
    for locationId, location in pairs(Locations.ById) do
        if self:IsLocationUnlockedForDisplay(progress, locationId) then
            local locationCopy = cloneTable(location)
            local nodes = {}
            for _, node in ipairs(location.Nodes or {}) do
                if self:IsNodeVisible(progress, node) then
                    table.insert(nodes, cloneTable(node))
                end
            end
            locationCopy.Nodes = nodes
            visible[locationId] = locationCopy
        end
    end
    return visible
end

function WorldService:GetNode(locationId, nodeId)
    local publicNode = Locations.GetNode(locationId, nodeId)
    local rule = MissionNodes.GetRule(nodeId) or NodeRules[nodeId]
    if not publicNode or not rule then return nil end
    return publicNode, rule
end

function WorldService:CanAccessLocation(player, locationId)
    if RunService:IsStudio() then return true end
    local progress = self.Profiles and self.Profiles:GetStoryProgress(player)
    if not progress then return true end
    return progress.UnlockedLocations and progress.UnlockedLocations[locationId] == true
end

function WorldService:RequirementComplete(progress, requirementId)
    return (progress.CompletedNodes and progress.CompletedNodes[requirementId] == true)
        or (progress.CompletedMissions and progress.CompletedMissions[requirementId] == true)
        or (progress.CompletedSteps and progress.CompletedSteps[requirementId] == true)
end

function WorldService:CanAccessNode(player, nodeId)
    if RunService:IsStudio() then return true end
    local config = MissionNodes.GetNode(nodeId)
    local unlock = config and config.Unlock
    if not unlock then return true end
    if unlock.CanTravelBeforeComplete == true then return true end
    local progress = self.Profiles and self.Profiles:GetStoryProgress(player)
    if not progress then return true end
    local requirements = unlock.Requires or {}
    if #requirements == 0 then return true end
    if unlock.Mode == "CompleteAll" then
        for _, requirementId in ipairs(requirements) do
            if not self:RequirementComplete(progress, requirementId) then return false end
        end
        return true
    end
    for _, requirementId in ipairs(requirements) do
        if self:RequirementComplete(progress, requirementId) then return true end
    end
    return false
end

function WorldService:GetPower(player)
    local profile = self.Profiles and self.Profiles:Get(player)
    return Power.Compute(profile)
end

function WorldService:ValidateNodeAccess(player, locationId, node, rule)
    if not self:CanAccessLocation(player, locationId) then
        return false, "LocationLocked"
    end
    if not self:CanAccessNode(player, node.Id) then
        return false, "NodeLocked"
    end
    local power = self:GetPower(player)
    if power < (rule.MinPower or 0) then
        return false, "PowerTooLow"
    end
    return true, nil, power
end

function WorldService:ActivateNode(player, locationId, nodeId, options)
    locationId = locationId or "Earth"
    local node, rule = self:GetNode(locationId, nodeId)
    if not node or not rule then
        self:Replicate(player, { Error = "InvalidNode" })
        return
    end

    local ok, reason, power = self:ValidateNodeAccess(player, locationId, node, rule)
    if not ok then
        self:Replicate(player, { Error = reason, NodeId = nodeId, Power = power or self:GetPower(player) })
        return
    end

    if rule.InstanceMode == "PublicZone" then
        if self.QuestTracker and self.QuestTracker.RecordVisitLocation then
            self.QuestTracker:RecordVisitLocation(player, locationId)
        end
        if self.BountyTracker and self.BountyTracker.RecordVisitLocation then
            self.BountyTracker:RecordVisitLocation(player, locationId)
        end
        self.Missions:StartMission(player, rule.MissionId, {
            LocationId = locationId,
            NodeId = node.Id,
            InstanceMode = rule.InstanceMode,
        })
        self:Replicate(player, { ActivatedNode = node.Id, Power = power })
        return
    end

    if self.QuestTracker and self.QuestTracker.RecordVisitLocation then
        self.QuestTracker:RecordVisitLocation(player, locationId)
    end
    if self.BountyTracker and self.BountyTracker.RecordVisitLocation then
        self.BountyTracker:RecordVisitLocation(player, locationId)
    end
    self.Matchmaking:EnqueuePlayer(player, locationId, node, rule, power, options)
end

function WorldService:Handle(player, payload)
    if typeof(payload) ~= "table" then return end
    if payload.Action == "ActivateNode" then
        self:ActivateNode(player, payload.LocationId or "Earth", payload.NodeId, { Solo = payload.Solo == true })
    elseif payload.Action == "QueueNode" then
        self:ActivateNode(player, payload.LocationId or "Earth", payload.NodeId, { Solo = false })
    elseif payload.Action == "StartSolo" then
        self:ActivateNode(player, payload.LocationId or "Earth", payload.NodeId, { Solo = true })
    elseif payload.Action == "CancelMatchmaking" then
        if self.Matchmaking then self.Matchmaking:Cancel(player) end
    elseif payload.Action == "RequestLocations" and Net.RemoteEvents.WorldUpdate then
        self:Replicate(player)
    end
end

return WorldService
