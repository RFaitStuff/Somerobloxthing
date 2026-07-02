--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local TrainingRange = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("TrainingRange"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local TrainingRangeService = {}
TrainingRangeService.__index = TrainingRangeService

function TrainingRangeService.new(playerState)
    return setmetatable({
        PlayerState = playerState,
        Remote = nil,
        Targets = {},
        PlayerStats = {},
        Accumulator = 0,
    }, TrainingRangeService)
end

function TrainingRangeService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.TrainingRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    self:EnsureDevTargets()
    self:BindExistingTargets()
    CollectionService:GetInstanceAddedSignal(TrainingRange.Settings.TargetTag):Connect(function(instance)
        self:BindTarget(instance)
    end)
    RunService.Heartbeat:Connect(function(dt)
        self.Accumulator += dt
        if self.Accumulator < (TrainingRange.Settings.SnapshotInterval or 0.5) then return end
        self.Accumulator = 0
        self:PollTargets()
    end)
    Players.PlayerRemoving:Connect(function(player)
        self.PlayerStats[player.UserId] = nil
    end)
end

function TrainingRangeService:GetFolder()
    local folder = Workspace:FindFirstChild(TrainingRange.Settings.FolderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = TrainingRange.Settings.FolderName
        folder.Parent = Workspace
    end
    return folder
end

function TrainingRangeService:EnsureDevTargets()
    if not RunService:IsStudio() then return end
    local folder = self:GetFolder()
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("Model") and descendant:GetAttribute("TrainingTargetId") then
            return
        end
    end
    local floor = Instance.new("Part")
    floor.Name = "TrainingFloor"
    floor.Anchored = true
    floor.Size = Vector3.new(46, 1, 38)
    floor.Position = Vector3.new(0, 0, -66)
    floor.Color = Color3.fromRGB(35, 40, 46)
    floor.Material = Enum.Material.Metal
    floor.Parent = folder

    for _, targetId in ipairs(TrainingRange.Order) do
        self:CreateTargetModel(folder, targetId)
    end
end

function TrainingRangeService:CreateTargetModel(parent, targetId)
    local def = TrainingRange.Get(targetId)
    if not def then return nil end
    local model = Instance.new("Model")
    model.Name = targetId
    model:SetAttribute("TrainingTargetId", targetId)
    model:SetAttribute("IsTrainingTarget", true)
    model:SetAttribute("Health", def.Health)
    model:SetAttribute("MaxHealth", def.Health)
    model:SetAttribute("Shield", def.Shield or 0)
    model:SetAttribute("MaxShield", def.Shield or 0)
    model.Parent = parent

    local body = Instance.new("Part")
    body.Name = "TargetBody"
    body.Anchored = true
    body.Size = def.Size or Vector3.new(4, 7, 2)
    body.Position = def.Position or Vector3.new(0, 4, -60)
    body.Color = def.Color or Color3.fromRGB(90, 120, 150)
    body.Material = Enum.Material.SmoothPlastic
    body.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = def.Health or 500
    humanoid.Health = humanoid.MaxHealth
    humanoid:SetAttribute("Armor", def.Armor or 0)
    humanoid:SetAttribute("Shield", def.Shield or 0)
    humanoid.Parent = model

    local label = Instance.new("BillboardGui")
    label.Name = "TargetLabel"
    label.Size = UDim2.fromOffset(170, 38)
    label.StudsOffset = Vector3.new(0, 4.8, 0)
    label.AlwaysOnTop = true
    label.Parent = body

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.TextColor3 = Color3.fromRGB(235, 242, 248)
    text.Text = def.DisplayName or targetId
    text.Parent = label

    CollectionService:AddTag(model, TrainingRange.Settings.TargetTag)
    return model
end

function TrainingRangeService:ResetTarget(model)
    local targetId = model and model:GetAttribute("TrainingTargetId")
    local def = TrainingRange.Get(targetId)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not def or not humanoid then return end
    model:SetAttribute("Health", def.Health)
    model:SetAttribute("MaxHealth", def.Health)
    model:SetAttribute("Shield", def.Shield or 0)
    model:SetAttribute("MaxShield", def.Shield or 0)
    model:SetAttribute("LastPolledHealth", def.Health)
    humanoid.MaxHealth = def.Health or humanoid.MaxHealth
    humanoid.Health = humanoid.MaxHealth
    humanoid:SetAttribute("Armor", def.Armor or 0)
    humanoid:SetAttribute("Shield", def.Shield or 0)
end

function TrainingRangeService:BindTarget(instance)
    local model = instance
    if instance:IsA("BasePart") then model = instance:FindFirstAncestorOfClass("Model") end
    if not model or not model:IsA("Model") then return end
    local targetId = model:GetAttribute("TrainingTargetId")
    if not TrainingRange.Get(targetId) then return end
    if self.Targets[model] then return end
    self.Targets[model] = true
    self:ResetTarget(model)
end

function TrainingRangeService:BindExistingTargets()
    for _, instance in ipairs(CollectionService:GetTagged(TrainingRange.Settings.TargetTag)) do
        self:BindTarget(instance)
    end
    local folder = Workspace:FindFirstChild(TrainingRange.Settings.FolderName)
    if folder then
        for _, instance in ipairs(folder:GetDescendants()) do
            if instance:IsA("Model") and instance:GetAttribute("TrainingTargetId") then
                self:BindTarget(instance)
            end
        end
    end
end

function TrainingRangeService:GetStats(player)
    local stats = self.PlayerStats[player.UserId]
    if not stats then
        stats = { Damage = 0, Hits = 0, Kills = 0, Started = os.clock(), LastDamage = 0, LastTargetId = nil }
        self.PlayerStats[player.UserId] = stats
    end
    return stats
end

function TrainingRangeService:RecordDamage(userId, model, amount, killed)
    local player = Players:GetPlayerByUserId(userId)
    if not player then return end
    local stats = self:GetStats(player)
    stats.Damage += math.max(0, amount)
    stats.Hits += 1
    stats.LastDamage = math.floor(amount + 0.5)
    stats.LastTargetId = model:GetAttribute("TrainingTargetId")
    if killed then stats.Kills += 1 end
    self:Replicate(player, { Type = "Damage", TargetId = stats.LastTargetId, Amount = stats.LastDamage, Killed = killed == true })
end

function TrainingRangeService:PollTargets()
    for model in pairs(self.Targets) do
        if not model.Parent then
            self.Targets[model] = nil
        else
            local health = tonumber(model:GetAttribute("Health")) or 0
            local previous = tonumber(model:GetAttribute("LastPolledHealth")) or tonumber(model:GetAttribute("MaxHealth")) or health
            if health < previous then
                local userId = tonumber((model:FindFirstChildOfClass("Humanoid") or model):GetAttribute("LastDamagedBy"))
                if userId then self:RecordDamage(userId, model, previous - health, health <= 0) end
            end
            model:SetAttribute("LastPolledHealth", health)
            if health <= 0 and not model:GetAttribute("ResetQueued") then
                model:SetAttribute("ResetQueued", true)
                task.delay(TrainingRange.Settings.ResetDelay or 1.25, function()
                    if model.Parent then
                        model:SetAttribute("ResetQueued", false)
                        self:ResetTarget(model)
                    end
                end)
            end
        end
    end
end

function TrainingRangeService:GetTargetSnapshot()
    local targets = {}
    for model in pairs(self.Targets) do
        if model.Parent then
            local targetId = model:GetAttribute("TrainingTargetId")
            targets[targetId or model.Name] = {
                Id = targetId,
                Health = model:GetAttribute("Health"),
                MaxHealth = model:GetAttribute("MaxHealth"),
                Shield = model:GetAttribute("Shield"),
                MaxShield = model:GetAttribute("MaxShield"),
            }
        end
    end
    return targets
end

function TrainingRangeService:Replicate(player, extra)
    local stats = table.clone(self:GetStats(player))
    stats.Elapsed = math.max(0.001, os.clock() - (stats.Started or os.clock()))
    stats.Dps = math.floor((stats.Damage / stats.Elapsed) + 0.5)
    local payload = {
        Type = "Snapshot",
        Definitions = TrainingRange.Targets,
        Order = TrainingRange.Order,
        Targets = self:GetTargetSnapshot(),
        Stats = stats,
    }
    for key, value in pairs(extra or {}) do
        payload[key] = value
    end
    Net.GetRemoteEvent(Net.RemoteEvents.TrainingUpdate):FireClient(player, payload)
end

function TrainingRangeService:ResetPlayerStats(player)
    self.PlayerStats[player.UserId] = { Damage = 0, Hits = 0, Kills = 0, Started = os.clock(), LastDamage = 0, LastTargetId = nil }
    self:Replicate(player, { Type = "ResetStats" })
end

function TrainingRangeService:ResetAllTargets()
    for model in pairs(self.Targets) do
        if model.Parent then self:ResetTarget(model) end
    end
end

function TrainingRangeService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Training", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "ResetStats" then
        self:ResetPlayerStats(player)
    elseif payload.Action == "ResetTargets" then
        self:ResetAllTargets()
        self:Replicate(player, { Type = "ResetTargets" })
    else
        ValidationAudit.Reject(player, "Training", "UnknownAction")
    end
end

return TrainingRangeService
