--!nonstrict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local Npcs = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Npcs"))
local Storylines = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Storylines"))
local NpcShops = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Npcs"):WaitForChild("NpcShops"))
local NpcBounties = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Npcs"):WaitForChild("NpcBounties"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local NpcService = {}
NpcService.__index = NpcService

function NpcService.new(playerState, profiles, world, hub, rooms, quests)
    return setmetatable({
        PlayerState = playerState,
        Profiles = profiles,
        World = world,
        Hub = hub,
        Rooms = rooms,
        Quests = quests,
        Remote = nil,
        PromptConnections = {},
    }, NpcService)
end

function NpcService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.NpcRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    self:EnsureDevNpcs()
    self:BindExistingPrompts()
    CollectionService:GetInstanceAddedSignal("NpcInteract"):Connect(function(instance)
        self:BindPromptInstance(instance)
    end)
end

function NpcService:GetHubFolder()
    local hub = Workspace:FindFirstChild("Hub")
    if not hub then
        hub = Instance.new("Folder")
        hub.Name = "Hub"
        hub.Parent = Workspace
    end
    return hub
end

function NpcService:EnsureDevNpcs()
    if not RunService:IsStudio() then return end
    local hub = self:GetHubFolder()
    for _, descendant in ipairs(hub:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("NpcId") then
            return
        end
    end

    local folder = Instance.new("Folder")
    folder.Name = "DevNpcs"
    folder.Parent = hub

    for index, npcId in ipairs(Npcs.DevOrder) do
        local npc = Npcs.Get(npcId)
        local part = Instance.new("Part")
        part.Name = npcId
        part.Anchored = true
        part.Size = Vector3.new(4, 7, 4)
        part.Position = Vector3.new(-21 + (index - 1) * 14, 4, -30)
        part.Color = Color3.fromRGB(58, 68, 82)
        part.Material = Enum.Material.SmoothPlastic
        part:SetAttribute("NpcId", npcId)
        part.Parent = folder
        CollectionService:AddTag(part, "NpcInteract")

        local label = Instance.new("BillboardGui")
        label.Name = "Nameplate"
        label.Size = UDim2.fromOffset(180, 40)
        label.StudsOffset = Vector3.new(0, 5, 0)
        label.AlwaysOnTop = true
        label.Parent = part

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextScaled = true
        text.TextColor3 = Color3.fromRGB(235, 242, 248)
        text.Text = npc and npc.DisplayName or npcId
        text.Parent = label
    end
end

function NpcService:BindPromptInstance(instance)
    if not instance:IsA("BasePart") then return end
    local npcId = instance:GetAttribute("NpcId")
    if not npcId then return end
    local npc = Npcs.Get(npcId)
    if not npc then return end
    local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = npc.Prompt or "Talk"
        prompt.ObjectText = npc.DisplayName
        prompt.HoldDuration = 0.1
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.Parent = instance
    end
    if self.PromptConnections[prompt] then return end
    self.PromptConnections[prompt] = prompt.Triggered:Connect(function(player)
        self:OpenNpc(player, npcId)
    end)
end

function NpcService:BindExistingPrompts()
    for _, instance in ipairs(CollectionService:GetTagged("NpcInteract")) do
        self:BindPromptInstance(instance)
    end
    local hub = Workspace:FindFirstChild("Hub")
    if hub then
        for _, instance in ipairs(hub:GetDescendants()) do
            if instance:IsA("BasePart") and instance:GetAttribute("NpcId") then
                self:BindPromptInstance(instance)
            end
        end
    end
end

function NpcService:GetNextStoryNode(player)
    local progress = self.Profiles and self.Profiles:GetStoryProgress(player)
    local storyId = progress and progress.ActiveStoryId
    local story = storyId and Storylines.Get(storyId)
    if not story then return nil end
    for _, step in ipairs(story.Steps or {}) do
        if not progress.CompletedSteps[step.Id] and step.NodeId then
            for locationId in pairs(Locations.ById) do
                local node = Locations.GetNode(locationId, step.NodeId)
                if node then return locationId, node, step end
            end
        end
    end
    return nil
end

function NpcService:OpenNpc(player, npcId)
    local npc = Npcs.GetPublic(npcId)
    if not npc then return false end
    Net.GetRemoteEvent(Net.RemoteEvents.NpcUpdate):FireClient(player, {
        Type = "Open",
        Npc = npc,
        NextStory = ({ self:GetNextStoryNode(player) })[3],
        Shop = self:GetShopSnapshot(player, npcId),
        Bounties = self:GetBountySnapshot(player, npcId),
    })
    if self.Quests and self.Quests.RecordTalkToNpc then
        self.Quests:RecordTalkToNpc(player, npcId)
    end
    return true
end

function NpcService:GetDailyBucket(resetSeconds)
    return math.floor(os.time() / math.max(60, resetSeconds or 86400))
end

function NpcService:GetNpcLedger(profile, ledgerName, id, resetSeconds)
    profile.NpcLedgers = profile.NpcLedgers or {}
    profile.NpcLedgers[ledgerName] = profile.NpcLedgers[ledgerName] or {}
    local bucket = self:GetDailyBucket(resetSeconds)
    local ledger = profile.NpcLedgers[ledgerName][id]
    if not ledger or ledger.Bucket ~= bucket then
        ledger = { Bucket = bucket, Purchases = {}, Accepted = {} }
        profile.NpcLedgers[ledgerName][id] = ledger
    end
    return ledger
end

function NpcService:GetShopSnapshot(player, npcId)
    local shop = NpcShops.Get(npcId)
    if not shop then return nil end
    local profile = self.Profiles:Get(player)
    local ledger = self:GetNpcLedger(profile, "Shops", shop.Id, shop.ResetSeconds)
    return { Definition = shop, Ledger = ledger }
end

function NpcService:GetBountySnapshot(player, npcId)
    local board = NpcBounties.Get(npcId)
    if not board then return nil end
    local profile = self.Profiles:Get(player)
    local ledger = self:GetNpcLedger(profile, "Bounties", board.Id, board.ResetSeconds)
    return { Definition = board, Ledger = ledger, Active = profile.Bounties or {} }
end

function NpcService:GrantBountyReward(player, reward)
    if typeof(reward) ~= "table" then return end
    local profile = self.Profiles:Get(player)
    if not profile then return end
    if reward.Materials then
        profile.Inventory = profile.Inventory or {}
        profile.Inventory.Materials = profile.Inventory.Materials or {}
        for materialId, amount in pairs(reward.Materials) do
            profile.Inventory.Materials[materialId] = (profile.Inventory.Materials[materialId] or 0) + math.max(0, tonumber(amount) or 0)
        end
    end
    for _, currencyId in ipairs({ "Coins", "Credits", "Dallions" }) do
        local amount = tonumber(reward[currencyId])
        if amount and amount > 0 and self.Profiles and self.Profiles.GrantCurrency then
            self.Profiles:GrantCurrency(player, currencyId, amount)
        end
    end
end

function NpcService:CompleteBounty(player, bountyId, activeBounty)
    if activeBounty.Completed or activeBounty.Rewarded then return end
    activeBounty.Completed = true
    activeBounty.CompletedAt = os.time()
    activeBounty.Rewarded = true
    self:GrantBountyReward(player, activeBounty.Reward)
    if self.Quests and self.Quests.RecordBountyComplete then
        self.Quests:RecordBountyComplete(player, bountyId)
    end
end

function NpcService:ObjectiveMatches(objective, eventType, context)
    if typeof(objective) ~= "table" or objective.Type ~= eventType then return false end
    context = context or {}
    if eventType == "CompleteNode" then
        return not objective.NodeId or objective.NodeId == context.NodeId
    elseif eventType == "DefeatEnemy" then
        local matchesEnemy = not objective.EnemyId or objective.EnemyId == context.EnemyId
        local matchesRole = not objective.EnemyRole or objective.EnemyRole == context.EnemyRole
        local matchesFaction = not objective.Faction or objective.Faction == context.Faction
        return matchesEnemy and matchesRole and matchesFaction
    elseif eventType == "GatherResource" then
        local matchesMaterial = not objective.MaterialId or objective.MaterialId == context.MaterialId
        local matchesLocation = not objective.LocationId or objective.LocationId == context.LocationId
        return matchesMaterial and matchesLocation
    elseif eventType == "VisitLocation" then
        return not objective.LocationId or objective.LocationId == context.LocationId
    elseif eventType == "UnlockGate" then
        return not objective.GateId or objective.GateId == context.GateId
    end
    return false
end

function NpcService:RecordObjectiveProgress(player, eventType, context, amount)
    local profile = self.Profiles:Get(player)
    if not profile then return end
    profile.Bounties = profile.Bounties or {}
    local changed = false
    for bountyId, activeBounty in pairs(profile.Bounties) do
        local objective = activeBounty.Objective
        if self:ObjectiveMatches(objective, eventType, context)
            and not activeBounty.Completed
            and not activeBounty.Rewarded then
            local target = math.max(1, tonumber(objective.Count or objective.Amount) or 1)
            activeBounty.Progress = math.min(target, (activeBounty.Progress or 0) + (amount or 1))
            changed = true
            if activeBounty.Progress >= target then
                self:CompleteBounty(player, bountyId, activeBounty)
            end
        end
    end
    if changed then
        self.Profiles:Replicate(player)
    end
end

function NpcService:RecordCompleteNode(player, nodeId)
    self:RecordObjectiveProgress(player, "CompleteNode", { NodeId = nodeId }, 1)
end

function NpcService:RecordEnemyKill(player, role, enemyId, faction)
    self:RecordObjectiveProgress(player, "DefeatEnemy", { EnemyRole = role, EnemyId = enemyId, Faction = faction }, 1)
end

function NpcService:RecordGather(player, materialId, amount, locationId)
    self:RecordObjectiveProgress(player, "GatherResource", { MaterialId = materialId, LocationId = locationId }, amount or 1)
end

function NpcService:RecordVisitLocation(player, locationId)
    self:RecordObjectiveProgress(player, "VisitLocation", { LocationId = locationId }, 1)
end

function NpcService:RecordGateUnlock(player, gateId)
    self:RecordObjectiveProgress(player, "UnlockGate", { GateId = gateId }, 1)
end

function NpcService:BuyShopItem(player, npcId, listingId)
    local shop = NpcShops.Get(npcId)
    local listing = shop and shop.Listings and shop.Listings[listingId]
    if not listing then return false, "InvalidShopListing" end
    local profile = self.Profiles:Get(player)
    local ledger = self:GetNpcLedger(profile, "Shops", shop.Id, shop.ResetSeconds)
    local bought = ledger.Purchases[listingId] or 0
    if listing.DailyStock and bought >= listing.DailyStock then return false, "SoldOut" end
    if not self.Profiles:SpendCurrency(player, listing.Cost) then return false, "MissingCurrency" end
    if not self.Profiles:GrantCraftedOutput(player, listing.OutputType, listing.OutputId, listing.Amount or 1) then
        for currencyId, amount in pairs(listing.Cost or {}) do
            self.Profiles:GrantCurrency(player, currencyId, amount)
        end
        return false, "GrantFailed"
    end
    ledger.Purchases[listingId] = bought + 1
    self.Profiles:Replicate(player)
    self:OpenNpc(player, npcId)
    return true
end

function NpcService:AcceptBounty(player, npcId, bountyId)
    local board = NpcBounties.Get(npcId)
    local bounty = board and board.Bounties and board.Bounties[bountyId]
    if not bounty then return false, "InvalidBounty" end
    local profile = self.Profiles:Get(player)
    local progress = self.Profiles:GetStoryProgress(player)
    if bounty.RequiresStoryStep and not (progress.CompletedSteps and progress.CompletedSteps[bounty.RequiresStoryStep]) then
        return false, "BountyLocked"
    end
    local ledger = self:GetNpcLedger(profile, "Bounties", board.Id, board.ResetSeconds)
    if ledger.Accepted[bountyId] then return false, "AlreadyAccepted" end
    profile.Bounties = profile.Bounties or {}
    profile.Bounties[bountyId] = {
        BountyId = bountyId,
        NpcId = npcId,
        DisplayName = bounty.DisplayName,
        Progress = 0,
        Accepted = os.time(),
        Objective = bounty.Objective,
        Reward = bounty.Reward,
        Completed = false,
        Rewarded = false,
    }
    ledger.Accepted[bountyId] = true
    self.Profiles:Replicate(player)
    self:OpenNpc(player, npcId)
    return true
end

function NpcService:RunAction(player, npcId, actionId)
    local npc = Npcs.Get(npcId)
    if not npc then return false, "InvalidNpc" end
    local selected
    for _, action in ipairs(npc.Actions or {}) do
        if action.Id == actionId then selected = action break end
    end
    if not selected then return false, "InvalidAction" end

    if selected.Kind == "HubPanel" then
        if self.Hub then self.Hub:OpenPanel(player, selected.ServiceId) end
    elseif selected.Kind == "EnterRoom" then
        if self.Rooms then self.Rooms:TeleportToRoom(player) end
    elseif selected.Kind == "EnterTraining" then
        if self.World then self.World:ActivateNode(player, "Hub", "Hub_TrainingRoom", { Solo = true }) end
    elseif selected.Kind == "OpenShop" or selected.Kind == "OpenBounties" then
        self:OpenNpc(player, npcId)
    elseif selected.Kind == "StartNextStory" then
        local locationId, node = self:GetNextStoryNode(player)
        if not locationId or not node then return false, "NoStoryNode" end
        if self.World then self.World:ActivateNode(player, locationId, node.Id, { Solo = true }) end
    else
        return false, "UnsupportedAction"
    end

    Net.GetRemoteEvent(Net.RemoteEvents.NpcUpdate):FireClient(player, {
        Type = "ActionResult",
        NpcId = npcId,
        ActionId = actionId,
    })
    return true
end

function NpcService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Npc", "BadPayload") return end
    if payload.Action == "Open" then
        if not self:OpenNpc(player, payload.NpcId) then ValidationAudit.Reject(player, "Npc", "InvalidNpc") end
    elseif payload.Action == "RunAction" then
        local ok, reason = self:RunAction(player, payload.NpcId, payload.ActionId)
        if not ok then ValidationAudit.Reject(player, "Npc", reason or "ActionFailed") end
    elseif payload.Action == "BuyShopItem" then
        local ok, reason = self:BuyShopItem(player, payload.NpcId, payload.ListingId)
        if not ok then ValidationAudit.Reject(player, "Npc", reason or "ShopBuyFailed") end
    elseif payload.Action == "AcceptBounty" then
        local ok, reason = self:AcceptBounty(player, payload.NpcId, payload.BountyId)
        if not ok then ValidationAudit.Reject(player, "Npc", reason or "BountyAcceptFailed") end
    else
        ValidationAudit.Reject(player, "Npc", "UnknownAction")
    end
end

return NpcService
