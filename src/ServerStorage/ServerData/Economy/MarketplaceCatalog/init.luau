--!nonstrict
local MarketplaceCatalog = {}

MarketplaceCatalog.Currencies = {
    Coins = { Id = "Coins", DisplayName = "Coins", Spendable = true, Premium = false, LegacyIds = { "Credits" } },
    Dallions = { Id = "Dallions", DisplayName = "Dallions", Spendable = true, Premium = true, TradeMasteryRank = 4 },
    Robux = { Id = "Robux", DisplayName = "Robux", Spendable = false, Premium = true, ExternalPurchase = true },
}

MarketplaceCatalog.Categories = {
    Materials = require(script:WaitForChild("Materials")),
    Room = require(script:WaitForChild("Room")),
}

MarketplaceCatalog.Catalog = {}
MarketplaceCatalog.FeaturedOrder = {
    "StarterDallionPack",
    "VanguardCosmeticBundle",
    "OrbiterStyleBundle",
    "RelaySuitePermit",
}

for categoryId, listings in pairs(MarketplaceCatalog.Categories) do
    for listingId, listing in pairs(listings) do
        listing.Id = listing.Id or listingId
        listing.Category = listing.Category or categoryId
        MarketplaceCatalog.Catalog[listingId] = listing
    end
end

function MarketplaceCatalog.GetListing(listingId)
    return MarketplaceCatalog.Catalog[listingId]
end

function MarketplaceCatalog.GetPublicCatalog()
    local catalog = {}
    for id, listing in pairs(MarketplaceCatalog.Catalog) do
        catalog[id] = {
            Id = listing.Id,
            DisplayName = listing.DisplayName,
            Category = listing.Category,
            Cost = listing.Cost,
            OutputType = listing.OutputType,
            OutputId = listing.OutputId,
            Amount = listing.Amount,
            Stock = listing.Stock,
            MasteryRank = listing.MasteryRank,
            DirectRobuxCost = listing.DirectRobuxCost,
            RobuxProductId = listing.RobuxProductId,
            DevProductNote = listing.DevProductNote,
        }
    end
    return {
        Currencies = MarketplaceCatalog.Currencies,
        Catalog = catalog,
        FeaturedOrder = MarketplaceCatalog.FeaturedOrder,
    }
end

return MarketplaceCatalog
