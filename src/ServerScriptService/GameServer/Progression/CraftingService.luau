--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local RecipeBook = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Crafting"):WaitForChild("RecipeBook"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local CraftingService = {}
CraftingService.__index = CraftingService

function CraftingService.new(profiles)
    return setmetatable({ Profiles = profiles, Remote = nil, Accumulator = 0 }, CraftingService)
end

function CraftingService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.CraftingRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    RunService.Heartbeat:Connect(function(dt)
        self.Accumulator += dt
        if self.Accumulator < 1 then return end
        self.Accumulator = 0
        self:ReplicateAll()
    end)
end

function CraftingService:GetSnapshot(player)
    local profile = self.Profiles:Get(player)
    return {
        Recipes = RecipeBook.GetPublic(),
        RecipeOrder = RecipeBook.Order,
        RecipeCategories = RecipeBook.Categories,
        Jobs = profile.Crafting and profile.Crafting.Jobs or {},
        Completed = profile.Crafting and profile.Crafting.Completed or {},
        Materials = profile.Inventory and profile.Inventory.Materials or {},
    }
end

function CraftingService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.CraftingUpdate):FireClient(player, self:GetSnapshot(player))
end

function CraftingService:ReplicateAll()
    for player in pairs(self.Profiles.Profiles) do
        if player and player.Parent then
            self:Replicate(player)
        end
    end
end

function CraftingService:StartRecipe(player, recipeId)
    local recipe = RecipeBook.Get(recipeId)
    if not recipe then return false, "InvalidRecipe" end
    if recipe.MasteryRank and self.Profiles:Get(player).MasteryRank < recipe.MasteryRank then
        return false, "MasteryTooLow"
    end
    if recipe.MasteryGate then
        local ok = self.Profiles:CanUseMasteryGate(player, recipe.MasteryGate)
        if not ok then return false, "MasteryTooLow" end
    end
    local spent, missing = self.Profiles:SpendMaterials(player, recipe.Costs)
    if not spent then return false, "MissingMaterial:" .. tostring(missing) end

    local profile = self.Profiles:Get(player)
    profile.Crafting.Jobs = profile.Crafting.Jobs or {}
    local jobId = HttpService:GenerateGUID(false)
    profile.Crafting.Jobs[jobId] = {
        JobId = jobId,
        RecipeId = recipeId,
        Started = os.clock(),
        FinishAt = os.clock() + math.max(0, recipe.TimeSeconds or 0),
        OutputType = recipe.OutputType,
        OutputId = recipe.OutputId,
        DisplayName = recipe.DisplayName or recipe.OutputId,
    }
    self.Profiles:Replicate(player)
    self:Replicate(player)
    return true
end

function CraftingService:ClaimJob(player, jobId)
    local profile = self.Profiles:Get(player)
    local job = profile.Crafting and profile.Crafting.Jobs and profile.Crafting.Jobs[jobId]
    if not job then return false, "InvalidJob" end
    if os.clock() < (job.FinishAt or 0) then return false, "NotFinished" end
    if not self.Profiles:GrantCraftedOutput(player, job.OutputType, job.OutputId, 1) then
        return false, "GrantFailed"
    end
    profile.Crafting.Jobs[jobId] = nil
    profile.Crafting.Completed[jobId] = { RecipeId = job.RecipeId, Claimed = os.clock() }
    self:Replicate(player)
    return true
end

function CraftingService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Crafting", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "StartRecipe" then
        local ok, reason = self:StartRecipe(player, payload.RecipeId)
        if not ok then ValidationAudit.Reject(player, "Crafting", reason or "StartFailed") end
    elseif payload.Action == "ClaimJob" then
        local ok, reason = self:ClaimJob(player, payload.JobId)
        if not ok then ValidationAudit.Reject(player, "Crafting", reason or "ClaimFailed") end
    else
        ValidationAudit.Reject(player, "Crafting", "UnknownAction")
    end
end

return CraftingService
