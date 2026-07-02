--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Questlines = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Quests"):WaitForChild("Questlines"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local QuestService = {}
QuestService.__index = QuestService

function QuestService.new(profiles, world)
    return setmetatable({ Profiles = profiles, World = world, Remote = nil }, QuestService)
end

function QuestService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.QuestRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function QuestService:GetQuestState(player)
    local profile = self.Profiles:Get(player)
    profile.Quests = profile.Quests or { ActiveQuestId = Questlines.DefaultQuestId, Completed = {}, Progress = {} }
    profile.Quests.Completed = profile.Quests.Completed or {}
    profile.Quests.Progress = profile.Quests.Progress or {}
    profile.Quests.ActiveQuestId = profile.Quests.ActiveQuestId or Questlines.DefaultQuestId
    return profile.Quests
end

function QuestService:GetSnapshot(player)
    local questState = self:GetQuestState(player)
    local quest = Questlines.Get(questState.ActiveQuestId)
    local progress = questState.Progress[questState.ActiveQuestId] or {}
    return {
        Type = "Snapshot",
        ActiveQuestId = questState.ActiveQuestId,
        Quest = quest,
        Progress = progress,
        Completed = questState.Completed,
    }
end

function QuestService:Replicate(player, extra)
    local payload = self:GetSnapshot(player)
    for key, value in pairs(extra or {}) do payload[key] = value end
    Net.GetRemoteEvent(Net.RemoteEvents.QuestUpdate):FireClient(player, payload)
end

function QuestService:StartQuest(player, questId)
    if not Questlines.Get(questId) then return false, "InvalidQuest" end
    local questState = self:GetQuestState(player)
    questState.ActiveQuestId = questId
    questState.Progress[questId] = questState.Progress[questId] or { CompletedSteps = {} }
    self:EvaluatePassiveSteps(player, Questlines.Get(questId))
    self.Profiles:Replicate(player)
    self:Replicate(player, { Type = "StartedQuest" })
    return true
end

function QuestService:GrantQuestRewards(player, quest)
    local rewards = quest and quest.Rewards
    if type(rewards) ~= "table" then return end
    local profile = self.Profiles:Get(player)
    for materialId, amount in pairs(rewards.Materials or {}) do
        profile.Inventory.Materials[materialId] = (profile.Inventory.Materials[materialId] or 0) + amount
    end
    for _, currencyId in ipairs({ "Coins", "Credits", "Dallions" }) do
        if rewards[currencyId] then
            self.Profiles:GrantCurrency(player, currencyId, rewards[currencyId])
        end
    end
end

function QuestService:CompleteStep(player, stepId)
    local questState = self:GetQuestState(player)
    local quest = Questlines.Get(questState.ActiveQuestId)
    if not quest then return false, "InvalidQuest" end
    local found = false
    for _, step in ipairs(quest.Steps or {}) do
        if step.Id == stepId then found = true break end
    end
    if not found then return false, "InvalidStep" end
    questState.Progress[quest.Id] = questState.Progress[quest.Id] or { CompletedSteps = {} }
    if questState.Progress[quest.Id].CompletedSteps[stepId] then return true end
    questState.Progress[quest.Id].CompletedSteps[stepId] = true
    local allDone = true
    for _, step in ipairs(quest.Steps or {}) do
        if not questState.Progress[quest.Id].CompletedSteps[step.Id] then allDone = false break end
    end
    if allDone and not questState.Completed[quest.Id] then
        questState.Completed[quest.Id] = true
        self:GrantQuestRewards(player, quest)
    end
    self.Profiles:Replicate(player)
    self:Replicate(player, { Type = "StepCompleted", StepId = stepId })
    return true
end

function QuestService:StepComplete(player, quest, step)
    local questState = self:GetQuestState(player)
    local progress = questState.Progress[quest.Id] or {}
    local completed = progress.CompletedSteps or {}
    return completed[step.Id] == true
end

function QuestService:IncrementStep(player, quest, step, amount)
    if self:StepComplete(player, quest, step) then return end
    local questState = self:GetQuestState(player)
    questState.Progress[quest.Id] = questState.Progress[quest.Id] or { CompletedSteps = {}, Counters = {} }
    local progress = questState.Progress[quest.Id]
    progress.Counters = progress.Counters or {}
    local target = math.max(1, tonumber(step.Count or step.Amount) or 1)
    progress.Counters[step.Id] = math.clamp((progress.Counters[step.Id] or 0) + (amount or 1), 0, target)
    if progress.Counters[step.Id] >= target then
        self:CompleteStep(player, step.Id)
    else
        self.Profiles:Replicate(player)
        self:Replicate(player, { Type = "StepProgress", StepId = step.Id, Progress = progress.Counters[step.Id], Target = target })
    end
end

function QuestService:OwnsStepOutput(player, step)
    local profile = self.Profiles:Get(player)
    local outputType = step.OutputType or step.ItemType
    local outputId = step.OutputId or step.ItemId
    if outputType == "Weapon" then
        return profile.Weapons and profile.Weapons[outputId] ~= nil
    elseif outputType == "Material" then
        return (profile.Inventory.Materials[outputId] or 0) >= (step.Amount or step.Count or 1)
    elseif outputType == "Mod" then
        return profile.Inventory.Mods[outputId] ~= nil
    elseif outputType == "Armor" then
        for _, item in pairs(profile.Inventory.Armor or {}) do
            if item.ArmorId == outputId then return true end
        end
    elseif outputType == "Decoration" then
        return (profile.Inventory.Decorations[outputId] or 0) >= (step.Amount or step.Count or 1)
    end
    return false
end

function QuestService:EvaluatePassiveSteps(player, quest)
    quest = quest or Questlines.Get(self:GetQuestState(player).ActiveQuestId)
    if not quest then return end
    for _, step in ipairs(quest.Steps or {}) do
        if (step.Type == "CraftOrOwn" or step.Type == "OwnItem") and self:OwnsStepOutput(player, step) then
            self:CompleteStep(player, step.Id)
        end
    end
end

function QuestService:RecordTalkToNpc(player, npcId)
    local questState = self:GetQuestState(player)
    local quest = Questlines.Get(questState.ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "TalkToNpc" and step.NpcId == npcId then
            self:CompleteStep(player, step.Id)
            if self.Profiles.MarkStoryStepComplete then
                self.Profiles:MarkStoryStepComplete(player, step.Id)
            end
        end
    end
end

function QuestService:RecordCompleteNode(player, nodeId)
    local questState = self:GetQuestState(player)
    local quest = Questlines.Get(questState.ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "CompleteNode" and step.NodeId == nodeId then
            self:CompleteStep(player, step.Id)
        end
    end
end

function QuestService:RecordVisitLocation(player, locationId)
    local quest = Questlines.Get(self:GetQuestState(player).ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "VisitLocation" and step.LocationId == locationId then
            self:CompleteStep(player, step.Id)
        end
    end
end

function QuestService:RecordGather(player, materialId, amount, locationId)
    local quest = Questlines.Get(self:GetQuestState(player).ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "GatherResource" and (not step.MaterialId or step.MaterialId == materialId) and (not step.LocationId or step.LocationId == locationId) then
            self:IncrementStep(player, quest, step, amount or 1)
        end
    end
end

function QuestService:RecordEnemyKill(player, role, enemyId, faction)
    local quest = Questlines.Get(self:GetQuestState(player).ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "DefeatEnemy" then
            local matchesEnemy = not step.EnemyId or step.EnemyId == enemyId
            local matchesRole = not step.EnemyRole or step.EnemyRole == role
            local matchesFaction = not step.Faction or step.Faction == faction
            if matchesEnemy and matchesRole and matchesFaction then
                self:IncrementStep(player, quest, step, 1)
            end
        end
    end
end

function QuestService:RecordBountyComplete(player, bountyId)
    local quest = Questlines.Get(self:GetQuestState(player).ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "CompleteBounty" and (not step.BountyId or step.BountyId == bountyId) then
            self:IncrementStep(player, quest, step, 1)
        end
    end
end

function QuestService:RecordGateUnlock(player, gateId)
    local quest = Questlines.Get(self:GetQuestState(player).ActiveQuestId)
    for _, step in ipairs(quest and quest.Steps or {}) do
        if step.Type == "UnlockGate" and step.GateId == gateId then
            self:CompleteStep(player, step.Id)
        end
    end
end

function QuestService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Quest", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:EvaluatePassiveSteps(player)
        self:Replicate(player)
    elseif payload.Action == "StartQuest" then
        local ok, reason = self:StartQuest(player, payload.QuestId)
        if not ok then ValidationAudit.Reject(player, "Quest", reason or "StartFailed") end
    elseif payload.Action == "Evaluate" then
        self:EvaluatePassiveSteps(player)
        self:Replicate(player)
    else
        ValidationAudit.Reject(player, "Quest", "UnknownAction")
    end
end

return QuestService
