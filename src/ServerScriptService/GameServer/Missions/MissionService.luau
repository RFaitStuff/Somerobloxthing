--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Missions = require(Shared:WaitForChild("Data"):WaitForChild("Missions"):WaitForChild("Missions"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local MissionNodes = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Missions"):WaitForChild("MissionNodes"))
local ObjectiveRuntime = require(script.Parent:WaitForChild("MissionObjectiveRuntime"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local MissionService = {}
MissionService.__index = MissionService

function MissionService.new(playerState, enemies, rewards, profiles)
    return setmetatable({ PlayerState = playerState, Enemies = enemies, Rewards = rewards, Profiles = profiles, QuestTracker = nil, BountyTracker = nil, Remote = nil, Accumulator = 0 }, MissionService)
end

function MissionService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.MissionRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload) self:Handle(player, payload) end)
    RunService.Heartbeat:Connect(function(dt)
        self.Accumulator += dt
        if self.Accumulator < 1 then return end
        self.Accumulator = 0
        self:UpdateTimers()
    end)
end

function MissionService:Replicate(player)
    local remote = Net.GetRemoteEvent(Net.RemoteEvents.MissionUpdate)
    local state = self.PlayerState:Get(player)
    remote:FireClient(player, { Mission = state.ActiveMission })
end

function MissionService:GetMissionConfig(missionId, nodeId)
    local nodeConfig = MissionNodes.Resolve(missionId, nodeId)
    return nodeConfig and nodeConfig.Mission or {}
end

function MissionService:ChooseEnemy(def, missionConfig)
    local total = 0
    for _, entry in ipairs(missionConfig.EnemyTable or {}) do
        total += math.max(0, tonumber(entry.Weight) or 0)
    end
    if total <= 0 then return def.EnemyRole or "Gunner" end
    local roll = math.random() * total
    local cursor = 0
    for _, entry in ipairs(missionConfig.EnemyTable or {}) do
        cursor += math.max(0, tonumber(entry.Weight) or 0)
        if roll <= cursor then
            return entry.EnemyId or def.EnemyRole or "Gunner"
        end
    end
    return def.EnemyRole or "Gunner"
end

function MissionService:StartMission(player, missionId, context)
    local def = Missions[missionId]
    if not def then ValidationAudit.Reject(player, "Mission", "InvalidMission") return end
    local state = self.PlayerState:Get(player)
    context = context or {}
    local missionConfig = self:GetMissionConfig(missionId, context.NodeId)
    local objectiveRuntime = ObjectiveRuntime.Build(def, missionConfig)
    state.LocationId = context.LocationId
    state.SafeZone = false
    state.TrainingRange = missionId == "TrainingRoom"
    state.ActiveMission = {
        Id = missionId,
        DisplayName = def.DisplayName,
        Objective = def.Objective,
        ActivityType = def.ActivityType,
        Progress = 0,
        Target = objectiveRuntime.Target,
        Started = os.clock(),
        Duration = objectiveRuntime.Duration,
        LocationId = context.LocationId,
        NodeId = context.NodeId,
        SessionId = context.SessionId,
        InstanceMode = context.InstanceMode,
        StoryStepId = def.StoryStepId,
        MissionType = missionConfig.MissionType,
        EnemyStartingLevel = missionConfig.EnemyStartingLevel,
        Setup = missionConfig.Setup,
    }
    ObjectiveRuntime.ApplyToMission(state.ActiveMission, objectiveRuntime)
    if objectiveRuntime.Kind == "Boss" then
        self.Enemies:Spawn(player, objectiveRuntime.BossId or def.EnemyRole or "Deadeye", nil, nil, missionConfig.EnemyStartingLevel)
    elseif objectiveRuntime.Kind == "Wave" then
        state.ActiveMission.Wave = 1
        self.Enemies:SpawnWave(player, self:ChooseEnemy(def, missionConfig), objectiveRuntime.WaveSize or objectiveRuntime.Target or 5, missionConfig.EnemyStartingLevel)
    else
        self.Enemies:SpawnWave(player, self:ChooseEnemy(def, missionConfig), objectiveRuntime.SpawnCount or 5, missionConfig.EnemyStartingLevel)
    end
    self:Replicate(player)
end

function MissionService:Complete(player)
    local state = self.PlayerState:Get(player)
    if not state.ActiveMission then return end
    local mission = state.ActiveMission
    self.Rewards:AwardMission(player, state.ActiveMission.Id)
    local unlockedGates = nil
    if self.Profiles and self.Profiles.MarkMissionComplete then
        unlockedGates = self.Profiles:MarkMissionComplete(player, mission.Id, mission.NodeId)
    end
    if self.QuestTracker and self.QuestTracker.RecordCompleteNode and mission.NodeId then
        self.QuestTracker:RecordCompleteNode(player, mission.NodeId)
    end
    if self.BountyTracker and self.BountyTracker.RecordCompleteNode and mission.NodeId then
        self.BountyTracker:RecordCompleteNode(player, mission.NodeId)
    end
    for _, gateId in ipairs(unlockedGates or {}) do
        if self.QuestTracker and self.QuestTracker.RecordGateUnlock then
            self.QuestTracker:RecordGateUnlock(player, gateId)
        end
        if self.BountyTracker and self.BountyTracker.RecordGateUnlock then
            self.BountyTracker:RecordGateUnlock(player, gateId)
        end
    end
    state.ActiveMission = nil
    self:Replicate(player)
end

function MissionService:CanComplete(player)
    local state = self.PlayerState:Get(player)
    local mission = state.ActiveMission
    return ObjectiveRuntime.CanComplete(mission)
end

function MissionService:RecordEnemyKill(player, role, enemyId, faction)
    local state = self.PlayerState:Get(player)
    local mission = state.ActiveMission
    if not mission then return end
    local def = Missions[mission.Id]
    if not def then return end
    if self.QuestTracker and self.QuestTracker.RecordEnemyKill then
        self.QuestTracker:RecordEnemyKill(player, role, enemyId, faction)
    end
    if self.BountyTracker and self.BountyTracker.RecordEnemyKill then
        self.BountyTracker:RecordEnemyKill(player, role, enemyId, faction)
    end
    if not ObjectiveRuntime.ShouldCountKill(mission, role, enemyId) then return end
    ObjectiveRuntime.RecordKill(mission)
    self:Replicate(player)
    if mission.Progress >= (mission.Target or 1) then
        self:Complete(player)
    end
end

function MissionService:UpdateTimers()
    for player, state in pairs(self.PlayerState.States) do
        local mission = state.ActiveMission
        local def = mission and Missions[mission.Id]
        if def and ObjectiveRuntime.UpdateTimer(mission, os.clock()) then
            self:Replicate(player)
            if ObjectiveRuntime.CanComplete(mission) then
                self:Complete(player)
            end
        end
    end
end

function MissionService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Mission", "BadPayload") return end
    if payload.Action == "Start" then
        local missionId = payload.MissionId or "KillCount"
        local def = Missions[missionId]
        if not RunService:IsStudio() and def and def.ActivityType ~= "Debug" then
            ValidationAudit.Reject(player, "Mission", "UseWorldNavigation")
            return
        end
        self:StartMission(player, missionId, payload.Context)
    elseif payload.Action == "Complete" then
        if self:CanComplete(player) then
            self:Complete(player)
        else
            ValidationAudit.Reject(player, "Mission", "ObjectiveIncomplete")
            self:Replicate(player)
        end
    elseif payload.Action == "ClearEnemies" then
        self.Enemies:Clear()
    else
        ValidationAudit.Reject(player, "Mission", "UnknownAction")
    end
end

return MissionService
