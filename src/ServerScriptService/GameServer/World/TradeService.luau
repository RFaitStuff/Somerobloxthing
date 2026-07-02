--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local TradeConfig = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("TradeConfig"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local TradeService = {}
TradeService.__index = TradeService

function TradeService.new(profiles)
    return setmetatable({ Profiles = profiles, Remote = nil, Listings = {} }, TradeService)
end

function TradeService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.TradeRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function TradeService:GetPublicListings()
    local listings = {}
    for listingId, listing in pairs(self.Listings) do
        listings[listingId] = listing
    end
    return listings
end

function TradeService:GetSnapshot(player)
    local mine = {}
    for listingId, listing in pairs(self.Listings) do
        if listing.SellerUserId == player.UserId then
            mine[listingId] = listing
        end
    end
    return {
        Listings = self:GetPublicListings(),
        Mine = mine,
        Config = {
            MaxListingsPerPlayer = TradeConfig.MaxListingsPerPlayer,
            MaxQuantity = TradeConfig.MaxQuantity,
            MinCoins = TradeConfig.MinCoins,
            MaxCoins = TradeConfig.MaxCoins,
            MinCredits = TradeConfig.MinCredits,
            MaxCredits = TradeConfig.MaxCredits,
            MinDallions = TradeConfig.MinDallions,
            MaxDallions = TradeConfig.MaxDallions,
            DallionTradeMasteryRank = TradeConfig.DallionTradeMasteryRank,
        },
    }
end

function TradeService:CanUseDallions(player)
    local profile = self.Profiles:Get(player)
    return (profile.MasteryRank or 0) >= (TradeConfig.DallionTradeMasteryRank or 4)
end

function TradeService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.TradeUpdate):FireClient(player, self:GetSnapshot(player))
end

function TradeService:ReplicateAll()
    for player in pairs(self.Profiles.Profiles) do
        if player and player.Parent then
            self:Replicate(player)
        end
    end
end

function TradeService:CountPlayerListings(player)
    local count = 0
    for _, listing in pairs(self.Listings) do
        if listing.SellerUserId == player.UserId then count += 1 end
    end
    return count
end

function TradeService:CreateListing(player, payload)
    if self:CountPlayerListings(player) >= TradeConfig.MaxListingsPerPlayer then
        return false, "TooManyListings"
    end
    local clean, reason = TradeConfig.SanitizeListing(payload)
    if not clean then return false, reason end
    if (clean.ItemType == "Dallions" or clean.PriceCurrency == "Dallions") and not self:CanUseDallions(player) then
        return false, "DallionTradeMasteryTooLow"
    end
    local removed, itemPayload = self.Profiles:RemoveTradable(player, clean.ItemType, clean.ItemId, clean.Quantity)
    if not removed then
        return false, "MissingItem"
    end

    local listingId = HttpService:GenerateGUID(false)
    self.Listings[listingId] = {
        ListingId = listingId,
        SellerUserId = player.UserId,
        SellerName = player.DisplayName or player.Name,
        ItemType = clean.ItemType,
        ItemId = clean.ItemId,
        ItemPayload = itemPayload,
        Quantity = clean.Quantity,
        PriceCurrency = clean.PriceCurrency,
        PriceAmount = clean.PriceAmount,
        PriceCoins = clean.PriceCoins,
        PriceCredits = clean.PriceCredits,
        PriceDallions = clean.PriceDallions,
        Created = os.time(),
    }
    self:ReplicateAll()
    return true
end

function TradeService:CancelListing(player, listingId)
    local listing = self.Listings[listingId]
    if not listing then return false, "InvalidListing" end
    if listing.SellerUserId ~= player.UserId then return false, "NotSeller" end
    self.Listings[listingId] = nil
    self.Profiles:GrantTradable(player, listing.ItemType, listing.ItemId, listing.Quantity, listing.ItemPayload)
    self:ReplicateAll()
    return true
end

function TradeService:CancelPlayerListings(player)
    local changed = false
    for listingId, listing in pairs(self.Listings) do
        if listing.SellerUserId == player.UserId then
            self.Listings[listingId] = nil
            self.Profiles:GrantTradable(player, listing.ItemType, listing.ItemId, listing.Quantity, listing.ItemPayload)
            changed = true
        end
    end
    if changed then
        self:ReplicateAll()
    end
end

function TradeService:BuyListing(player, listingId)
    local listing = self.Listings[listingId]
    if not listing then return false, "InvalidListing" end
    if listing.SellerUserId == player.UserId then return false, "OwnListing" end

    local seller
    for other in pairs(self.Profiles.Profiles) do
        if other.UserId == listing.SellerUserId then
            seller = other
            break
        end
    end
    if not seller then return false, "SellerOffline" end
    if listing.PriceCurrency == "Dallions" and not self:CanUseDallions(player) then
        return false, "DallionTradeMasteryTooLow"
    end
    local priceCurrency = listing.PriceCurrency or "Coins"
    if priceCurrency == "Credits" then priceCurrency = "Coins" end
    local priceAmount = listing.PriceAmount or listing.PriceCoins or listing.PriceCredits
    local spent
    if priceCurrency == "Dallions" then
        spent = self.Profiles:RemoveTradeableDallions(player, priceAmount)
    else
        spent = self.Profiles:SpendCurrency(player, { [priceCurrency] = priceAmount })
    end
    if not spent then
        return false, priceCurrency == "Coins" and "MissingCoins" or "MissingCurrency"
    end
    if not self.Profiles:GrantTradable(player, listing.ItemType, listing.ItemId, listing.Quantity, listing.ItemPayload) then
        if priceCurrency == "Dallions" then
            self.Profiles:GrantTradedDallions(player, priceAmount)
        else
            self.Profiles:GrantCurrency(player, priceCurrency, priceAmount)
        end
        return false, "GrantFailed"
    end

    self.Listings[listingId] = nil
    if priceCurrency == "Dallions" then
        self.Profiles:GrantTradedDallions(seller, priceAmount)
    else
        self.Profiles:GrantCurrency(seller, priceCurrency, priceAmount)
    end
    self:ReplicateAll()
    return true
end

function TradeService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Trade", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "CreateListing" then
        local ok, reason = self:CreateListing(player, payload)
        if not ok then ValidationAudit.Reject(player, "Trade", reason or "CreateFailed") end
    elseif payload.Action == "CancelListing" then
        local ok, reason = self:CancelListing(player, payload.ListingId)
        if not ok then ValidationAudit.Reject(player, "Trade", reason or "CancelFailed") end
    elseif payload.Action == "BuyListing" then
        local ok, reason = self:BuyListing(player, payload.ListingId)
        if not ok then ValidationAudit.Reject(player, "Trade", reason or "BuyFailed") end
    else
        ValidationAudit.Reject(player, "Trade", "UnknownAction")
    end
end

return TradeService
