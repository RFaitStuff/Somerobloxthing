--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local Storylines = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Storylines"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local StoryService = {}
StoryService.__index = StoryService

function StoryService.new(playerState, profiles, world)
    return setmetatable({
        PlayerState = playerState,
        Profiles = profiles,
        World = world,
        Remote = nil,
    }, StoryService)
end

function StoryService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.StoryRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function StoryService:GetNodeForStep(step)
    if not step or not step.NodeId then return nil end
    for locationId in pairs(Locations.ById) do
        local node = Locations.GetNode(locationId, step.NodeId)
        if node then return locationId, node end
    end
    return nil
end

function StoryService:GetSnapshot(player)
    local progress = self.Profiles:GetStoryProgress(player)
    local storyId = progress.ActiveStoryId or Storylines.DefaultStoryId
    local story = Storylines.Get(storyId)
    local nextStep = Storylines.GetNextStep(storyId, progress.CompletedSteps)
    local steps = {}
    for index, step in ipairs(story and story.Steps or {}) do
        local locationId, node = self:GetNodeForStep(step)
        table.insert(steps, {
            Id = step.Id,
            Index = index,
            Kind = step.Kind,
            Title = step.Title,
            LocationId = step.LocationId or locationId,
            NodeId = step.NodeId,
            MissionId = step.MissionId,
            Completed = progress.CompletedSteps[step.Id] == true,
            IsNext = nextStep and nextStep.Id == step.Id or false,
            Node = node,
        })
    end
    return {
        Type = "Snapshot",
        ActiveStoryId = storyId,
        Story = story,
        Steps = steps,
        NextStep = nextStep,
        Progress = progress,
        UnlockedLocations = progress.UnlockedLocations or {},
    }
end

function StoryService:Replicate(player, extra)
    local payload = self:GetSnapshot(player)
    for key, value in pairs(extra or {}) do
        payload[key] = value
    end
    Net.GetRemoteEvent(Net.RemoteEvents.StoryUpdate):FireClient(player, payload)
end

function StoryService:StartNextStep(player)
    local snapshot = self:GetSnapshot(player)
    local step = snapshot.NextStep
    if not step then
        self:Replicate(player, { Type = "Complete" })
        return true
    end
    if step.Kind == "VisitLocation" and step.LocationId then
        if self.World and not self.World:IsLocationUnlockedForDisplay(snapshot.Progress, step.LocationId) then
            return false, "LocationLocked"
        end
        self.Profiles:MarkStoryStepComplete(player, step.Id)
        self:Replicate(player, { Type = "CompletedVisitStep", StepId = step.Id })
        return true
    end
    if step.Kind == "TalkToNpc" then
        self:Replicate(player, { Type = "TalkToNpcStep", StepId = step.Id, NpcId = step.NpcId })
        return true
    end
    local locationId, node = self:GetNodeForStep(step)
    if not locationId or not node then return false, "NoNodeForStep" end
    if self.World then
        self.World:ActivateNode(player, locationId, node.Id, { Solo = true })
    end
    self:Replicate(player, { Type = "StartedStep", StartedStepId = step.Id })
    return true
end

function StoryService:DebugCompleteStep(player, stepId)
    if not RunService:IsStudio() then return false, "StudioOnly" end
    local progress = self.Profiles:GetStoryProgress(player)
    local step = Storylines.GetStep(progress.ActiveStoryId, stepId)
    if not step then return false, "InvalidStep" end
    progress.CompletedSteps[step.Id] = true
    if step.MissionId or step.NodeId then
        self.Profiles:MarkMissionComplete(player, step.MissionId, step.NodeId)
    else
        self.Profiles:Replicate(player)
    end
    self:Replicate(player, { Type = "DebugCompleteStep", StepId = step.Id })
    return true
end

function StoryService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Story", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "StartNextStep" then
        local ok, reason = self:StartNextStep(player)
        if not ok then ValidationAudit.Reject(player, "Story", reason or "StartFailed") end
    elseif payload.Action == "DebugCompleteStep" then
        local ok, reason = self:DebugCompleteStep(player, payload.StepId)
        if not ok then ValidationAudit.Reject(player, "Story", reason or "DebugCompleteFailed") end
    else
        ValidationAudit.Reject(player, "Story", "UnknownAction")
    end
end

return StoryService
