--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local MarketplaceCatalog = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Economy"):WaitForChild("MarketplaceCatalog"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local MarketplaceService = {}
MarketplaceService.__index = MarketplaceService

function MarketplaceService.new(profiles)
    return setmetatable({ Profiles = profiles, Remote = nil }, MarketplaceService)
end

function MarketplaceService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.MarketplaceRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function MarketplaceService:GetSnapshot(player)
    local profile = self.Profiles:Get(player)
    return {
        Catalog = MarketplaceCatalog.GetPublicCatalog(),
        Wallet = profile.Wallet or {},
        Purchases = profile.MarketplacePurchases or {},
    }
end

function MarketplaceService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.MarketplaceUpdate):FireClient(player, self:GetSnapshot(player))
end

function MarketplaceService:Buy(player, listingId)
    local listing = MarketplaceCatalog.GetListing(listingId)
    if not listing then return false, "InvalidListing" end

    local profile = self.Profiles:Get(player)
    profile.MarketplacePurchases = profile.MarketplacePurchases or {}
    local bought = profile.MarketplacePurchases[listingId] or 0
    if (listing.Stock or -1) >= 0 and bought >= listing.Stock then
        return false, "SoldOut"
    end
    if listing.MasteryRank and (profile.MasteryRank or 0) < listing.MasteryRank then
        return false, "MasteryTooLow"
    end
    if listing.Cost and listing.Cost.Robux then
        return false, "UseRobuxPurchase"
    end
    if not self.Profiles:SpendCurrency(player, listing.Cost) then
        return false, "MissingCurrency"
    end
    if not self.Profiles:GrantCraftedOutput(player, listing.OutputType, listing.OutputId, listing.Amount or 1) then
        for currencyId, amount in pairs(listing.Cost or {}) do
            self.Profiles:GrantCurrency(player, currencyId, amount)
        end
        return false, "GrantFailed"
    end

    profile.MarketplacePurchases[listingId] = bought + 1
    self.Profiles:Replicate(player)
    self:Replicate(player)
    return true
end

function MarketplaceService:DebugGrantRobuxProduct(player, listingId)
    if not RunService:IsStudio() then return false, "StudioOnly" end
    local listing = MarketplaceCatalog.GetListing(listingId)
    if not listing or not listing.RobuxProductId then return false, "InvalidProductListing" end
    if not self.Profiles:GrantCraftedOutput(player, listing.OutputType, listing.OutputId, listing.Amount or 1) then
        return false, "GrantFailed"
    end
    self:Replicate(player)
    return true
end

function MarketplaceService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Marketplace", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "Buy" then
        local ok, reason = self:Buy(player, payload.ListingId)
        if not ok then ValidationAudit.Reject(player, "Marketplace", reason or "BuyFailed") end
    elseif payload.Action == "DebugGrantRobuxProduct" then
        local ok, reason = self:DebugGrantRobuxProduct(player, payload.ListingId)
        if not ok then ValidationAudit.Reject(player, "Marketplace", reason or "RobuxGrantFailed") end
    else
        ValidationAudit.Reject(player, "Marketplace", "UnknownAction")
    end
end

return MarketplaceService
