--!nonstrict
-- Client-safe marketplace vocabulary only. Authoritative listings live in ServerStorage.ServerData.Economy.MarketplaceCatalog.
local Marketplace = {}

Marketplace.Currencies = {
    Coins = { Id = "Coins", DisplayName = "Coins", Spendable = true, Premium = false, LegacyIds = { "Credits" } },
    Dallions = { Id = "Dallions", DisplayName = "Dallions", Spendable = true, Premium = true, TradeMasteryRank = 4 },
    Robux = { Id = "Robux", DisplayName = "Robux", Spendable = false, Premium = true, ExternalPurchase = true },
}

Marketplace.Catalog = {}
Marketplace.FeaturedOrder = {}

function Marketplace.GetListing(listingId)
    return Marketplace.Catalog[listingId]
end

function Marketplace.GetPublicCatalog()
    return {
        Currencies = Marketplace.Currencies,
        Catalog = Marketplace.Catalog,
        FeaturedOrder = Marketplace.FeaturedOrder,
    }
end

return Marketplace
