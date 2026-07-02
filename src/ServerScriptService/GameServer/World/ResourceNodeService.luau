--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local ResourceNodes = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("ResourceNodes"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local ResourceNodeService = {}
ResourceNodeService.__index = ResourceNodeService

function ResourceNodeService.new(playerState, profiles)
    return setmetatable({
        PlayerState = playerState,
        Profiles = profiles,
        Quests = nil,
        Bounties = nil,
        Remote = nil,
        PromptConnections = {},
        Cooldowns = {},
    }, ResourceNodeService)
end

function ResourceNodeService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.ResourceNodeRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    self:EnsureDevResourceNodes()
    self:BindExistingNodes()
    CollectionService:GetInstanceAddedSignal("ResourceNode"):Connect(function(instance)
        self:BindNodeInstance(instance)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self.Cooldowns[player] = nil
    end)
end

function ResourceNodeService:GetWorldResourcesFolder()
    local folder = Workspace:FindFirstChild("WorldResources")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "WorldResources"
        folder.Parent = Workspace
    end
    return folder
end

function ResourceNodeService:EnsureDevResourceNodes()
    if not RunService:IsStudio() then return end
    local folder = self:GetWorldResourcesFolder()
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("ResourceId") then
            return
        end
    end

    for locationIndex, locationId in ipairs({ "Earth", "Mars" }) do
        local locationFolder = Instance.new("Folder")
        locationFolder.Name = locationId
        locationFolder.Parent = folder
        local ids = ResourceNodes.DevByLocation[locationId] or {}
        for index, resourceId in ipairs(ids) do
            local def = ResourceNodes.Get(resourceId)
            local part = Instance.new("Part")
            part.Name = resourceId
            part.Anchored = true
            part.Size = Vector3.new(4, 3, 4)
            part.Position = Vector3.new(-36 + index * 9, 2, 85 + locationIndex * 18)
            part.Color = locationId == "Mars" and Color3.fromRGB(142, 86, 62) or Color3.fromRGB(62, 116, 78)
            part.Material = Enum.Material.Slate
            part:SetAttribute("ResourceId", resourceId)
            part:SetAttribute("LocationId", locationId)
            part.Parent = locationFolder
            CollectionService:AddTag(part, "ResourceNode")

            local label = Instance.new("BillboardGui")
            label.Name = "ResourceLabel"
            label.Size = UDim2.fromOffset(160, 34)
            label.StudsOffset = Vector3.new(0, 3.5, 0)
            label.AlwaysOnTop = true
            label.Parent = part

            local text = Instance.new("TextLabel")
            text.BackgroundTransparency = 1
            text.Size = UDim2.fromScale(1, 1)
            text.Font = Enum.Font.GothamBold
            text.TextScaled = true
            text.TextColor3 = Color3.fromRGB(235, 242, 248)
            text.Text = (def and def.DisplayName or resourceId) .. " / " .. locationId
            text.Parent = label
        end
    end
end

function ResourceNodeService:GetNodeKey(instance)
    return instance:GetDebugId()
end

function ResourceNodeService:IsOnCooldown(player, nodeKey, cooldown)
    self.Cooldowns[player] = self.Cooldowns[player] or {}
    local readyAt = self.Cooldowns[player][nodeKey] or 0
    return os.clock() < readyAt, math.max(0, readyAt - os.clock())
end

function ResourceNodeService:SetCooldown(player, nodeKey, cooldown)
    self.Cooldowns[player] = self.Cooldowns[player] or {}
    self.Cooldowns[player][nodeKey] = os.clock() + math.max(1, cooldown or 15)
end

function ResourceNodeService:CanGatherAtLocation(player, locationId)
    if RunService:IsStudio() then return true end
    local state = self.PlayerState:Get(player)
    return (state.LocationId or "Hub") == locationId
end

function ResourceNodeService:Gather(player, instance)
    if not instance or not instance:IsA("BasePart") then return false, "InvalidNode" end
    local resourceId = instance:GetAttribute("ResourceId")
    local locationId = instance:GetAttribute("LocationId") or "Earth"
    local def = ResourceNodes.Get(resourceId)
    if not def then return false, "InvalidResource" end
    if not Locations.Get(locationId) then return false, "InvalidLocation" end
    if not ResourceNodes.CanSpawnInLocation(resourceId, locationId) then return false, "WrongLocation" end
    if not self:CanGatherAtLocation(player, locationId) then return false, "WrongPlayerLocation" end

    local nodeKey = self:GetNodeKey(instance)
    local onCooldown, remaining = self:IsOnCooldown(player, nodeKey, def.Cooldown)
    if onCooldown then return false, "Cooldown:" .. tostring(math.ceil(remaining)) end

    local amount = math.random(def.AmountMin or 1, def.AmountMax or def.AmountMin or 1)
    if not self.Profiles:GrantMaterial(player, def.MaterialId, amount) then
        return false, "GrantFailed"
    end
    if self.Quests and self.Quests.RecordGather then
        self.Quests:RecordGather(player, def.MaterialId, amount, locationId)
    end
    if self.Bounties and self.Bounties.RecordGather then
        self.Bounties:RecordGather(player, def.MaterialId, amount, locationId)
    end
    self:SetCooldown(player, nodeKey, def.Cooldown)
    Net.GetRemoteEvent(Net.RemoteEvents.ResourceNodeUpdate):FireClient(player, {
        Type = "Gathered",
        ResourceId = resourceId,
        MaterialId = def.MaterialId,
        Amount = amount,
        LocationId = locationId,
        Cooldown = def.Cooldown,
    })
    Net.GetRemoteEvent(Net.RemoteEvents.RewardUpdate):FireClient(player, {
        Type = "ResourceNode",
        MaterialId = def.MaterialId,
        Amount = amount,
        LocationId = locationId,
    })
    return true
end

function ResourceNodeService:BindNodeInstance(instance)
    if not instance:IsA("BasePart") then return end
    local resourceId = instance:GetAttribute("ResourceId")
    local def = ResourceNodes.Get(resourceId)
    if not def then return end
    local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Gather"
        prompt.ObjectText = def.DisplayName
        prompt.HoldDuration = 0.4
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = instance
    end
    if self.PromptConnections[prompt] then return end
    self.PromptConnections[prompt] = prompt.Triggered:Connect(function(player)
        local ok, reason = self:Gather(player, instance)
        if not ok then ValidationAudit.Reject(player, "ResourceNode", reason or "GatherFailed") end
    end)
end

function ResourceNodeService:BindExistingNodes()
    for _, instance in ipairs(CollectionService:GetTagged("ResourceNode")) do
        self:BindNodeInstance(instance)
    end
    local folder = Workspace:FindFirstChild("WorldResources")
    if folder then
        for _, instance in ipairs(folder:GetDescendants()) do
            if instance:IsA("BasePart") and instance:GetAttribute("ResourceId") then
                self:BindNodeInstance(instance)
            end
        end
    end
end

function ResourceNodeService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "ResourceNode", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        Net.GetRemoteEvent(Net.RemoteEvents.ResourceNodeUpdate):FireClient(player, {
            Type = "Snapshot",
            Definitions = ResourceNodes.ById,
            DevByLocation = ResourceNodes.DevByLocation,
        })
    else
        ValidationAudit.Reject(player, "ResourceNode", "UnknownAction")
    end
end

return ResourceNodeService
