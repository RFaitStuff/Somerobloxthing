--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Missions = require(Shared:WaitForChild("GameData"):WaitForChild("Missions"))
local Net = require(Shared:WaitForChild("Net"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local MissionService = {}
MissionService.__index = MissionService

function MissionService.new(playerState, enemies, rewards)
    return setmetatable({ PlayerState = playerState, Enemies = enemies, Rewards = rewards, Remote = nil, Accumulator = 0 }, MissionService)
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

function MissionService:StartMission(player, missionId)
    local def = Missions[missionId]
    if not def then ValidationAudit.Reject(player, "Mission", "InvalidMission") return end
    local state = self.PlayerState:Get(player)
    state.ActiveMission = { Id = missionId, DisplayName = def.DisplayName, Objective = def.Objective, Progress = 0, Target = def.Target or 1, Started = os.clock(), Duration = def.Duration }
    if def.Objective == "Boss" then
        self.Enemies:Spawn(player, def.EnemyRole or "Deadeye")
    elseif def.Objective == "Wave" then
        self.Enemies:SpawnWave(player, def.EnemyRole or "Gunner", def.Target or 5)
    else
        self.Enemies:SpawnWave(player, def.EnemyRole or "Gunner", math.min(def.Target or 5, 8))
    end
    self:Replicate(player)
end

function MissionService:Complete(player)
    local state = self.PlayerState:Get(player)
    if not state.ActiveMission then return end
    self.Rewards:AwardMission(player, state.ActiveMission.Id)
    state.ActiveMission = nil
    self:Replicate(player)
end

function MissionService:CanComplete(player)
    local state = self.PlayerState:Get(player)
    local mission = state.ActiveMission
    local def = mission and Missions[mission.Id]
    if not def then return false end
    if def.Objective == "Timer" then
        return os.clock() - (mission.Started or os.clock()) >= (mission.Duration or 1)
    end
    return (mission.Progress or 0) >= (mission.Target or 1)
end

function MissionService:RecordEnemyKill(player, role, enemyId)
    local state = self.PlayerState:Get(player)
    local mission = state.ActiveMission
    if not mission then return end
    local def = Missions[mission.Id]
    if not def then return end
    if def.Objective ~= "Kill" and def.Objective ~= "Boss" and def.Objective ~= "Wave" then return end
    if def.EnemyRole and role ~= def.EnemyRole and enemyId ~= def.EnemyRole and def.Objective ~= "Kill" then return end
    mission.Progress = math.clamp((mission.Progress or 0) + 1, 0, mission.Target or 1)
    self:Replicate(player)
    if mission.Progress >= (mission.Target or 1) then
        self:Complete(player)
    end
end

function MissionService:UpdateTimers()
    for player, state in pairs(self.PlayerState.States) do
        local mission = state.ActiveMission
        local def = mission and Missions[mission.Id]
        if def and def.Objective == "Timer" then
            mission.Progress = math.clamp(os.clock() - (mission.Started or os.clock()), 0, mission.Duration or 1)
            self:Replicate(player)
            if mission.Progress >= (mission.Duration or 1) then
                self:Complete(player)
            end
        end
    end
end

function MissionService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Mission", "BadPayload") return end
    if payload.Action == "Start" then
        self:StartMission(player, payload.MissionId or "KillCount")
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
