--!nonstrict
local ObjectiveRuntime = {}

local function objectiveKind(def, missionConfig)
    local missionType = missionConfig.MissionType
    if missionType == "Assassination" then return "Boss" end
    if missionType == "Defense" or missionType == "GateDefense" or missionType == "PublicEvent" then return "Wave" end
    if missionType == "Survival" or missionType == "Salvage" or missionType == "StorySalvage" then return "Timer" end
    return def.Objective or "Kill"
end

function ObjectiveRuntime.Build(def, missionConfig)
    missionConfig = missionConfig or {}
    local kind = objectiveKind(def, missionConfig)
    local target = missionConfig.TargetCount or def.Target or 1
    if kind == "Timer" then
        target = missionConfig.Duration or def.Duration or target
    end
    return {
        Kind = kind,
        Target = target,
        Duration = missionConfig.Duration or def.Duration,
        SpawnCount = missionConfig.SpawnCount or def.SpawnCount or math.min(target, 10),
        WaveSize = missionConfig.WaveSize or missionConfig.SpawnCount or math.min(target, 8),
        MaxWaves = missionConfig.MaxWaves or (kind == "Wave" and math.max(1, math.ceil(target / math.max(missionConfig.WaveSize or missionConfig.SpawnCount or 5, 1))) or 1),
        BossId = missionConfig.BossId or def.EnemyRole,
        RequiresExtraction = missionConfig.RequiresExtraction == true,
        ExtractionAvailable = kind == "Timer" and true or false,
    }
end

function ObjectiveRuntime.ApplyToMission(mission, runtime)
    mission.ObjectiveRuntime = runtime
    mission.Objective = runtime.Kind
    mission.Progress = 0
    mission.Target = runtime.Target
    mission.Duration = runtime.Duration
    mission.Wave = 0
    mission.ExtractionAvailable = runtime.ExtractionAvailable
    mission.RequiresExtraction = runtime.RequiresExtraction
end

function ObjectiveRuntime.CanComplete(mission)
    local runtime = mission and mission.ObjectiveRuntime
    if not runtime then return false end
    if runtime.RequiresExtraction and not mission.Extracted then return false end
    if runtime.Kind == "Timer" then
        return (mission.Progress or 0) >= (runtime.Duration or mission.Duration or 1)
    end
    return (mission.Progress or 0) >= (mission.Target or runtime.Target or 1)
end

function ObjectiveRuntime.ShouldCountKill(mission, role, enemyId)
    local runtime = mission and mission.ObjectiveRuntime
    if not runtime then return false end
    if runtime.Kind ~= "Kill" and runtime.Kind ~= "Boss" and runtime.Kind ~= "Wave" then return false end
    if runtime.Kind == "Boss" then
        return not runtime.BossId or role == runtime.BossId or enemyId == runtime.BossId
    end
    return true
end

function ObjectiveRuntime.RecordKill(mission)
    mission.Progress = math.clamp((mission.Progress or 0) + 1, 0, mission.Target or 1)
end

function ObjectiveRuntime.UpdateTimer(mission, now)
    local runtime = mission and mission.ObjectiveRuntime
    if not runtime or runtime.Kind ~= "Timer" then return false end
    local duration = runtime.Duration or mission.Duration or 1
    mission.Progress = math.clamp(now - (mission.Started or now), 0, duration)
    if mission.Progress >= duration then
        mission.ExtractionAvailable = true
    end
    return true
end

return ObjectiveRuntime
