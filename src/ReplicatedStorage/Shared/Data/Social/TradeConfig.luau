--!nonstrict
local TradeConfig = {}

TradeConfig.MaxListingsPerPlayer = 8
TradeConfig.MaxQuantity = 999
TradeConfig.MinCoins = 1
TradeConfig.MaxCoins = 1000000
TradeConfig.MinCredits = TradeConfig.MinCoins
TradeConfig.MaxCredits = TradeConfig.MaxCoins
TradeConfig.MinDallions = 1
TradeConfig.MaxDallions = 100000
TradeConfig.DallionTradeMasteryRank = 4
TradeConfig.AllowedItemTypes = {
    Material = true,
    Decoration = true,
    Mod = true,
    Armor = true,
    Attachment = true,
    Dallions = true,
}
TradeConfig.AllowedPriceCurrencies = {
    Coins = true,
    Credits = true,
    Dallions = true,
}

function TradeConfig.SanitizeListing(input)
    input = typeof(input) == "table" and input or {}
    local itemType = tostring(input.ItemType or "")
    if not TradeConfig.AllowedItemTypes[itemType] then
        return nil, "InvalidItemType"
    end
    local itemId = itemType == "Dallions" and "Dallions" or tostring(input.ItemId or "")
    if itemId == "" then return nil, "InvalidItemId" end
    local quantity = math.clamp(math.floor(tonumber(input.Quantity) or 0), 1, TradeConfig.MaxQuantity)
    local priceCurrency = tostring(input.PriceCurrency or (input.PriceDallions and "Dallions") or "Coins")
    if priceCurrency == "Credits" then priceCurrency = "Coins" end
    if not TradeConfig.AllowedPriceCurrencies[priceCurrency] then return nil, "InvalidPriceCurrency" end
    local rawPrice = tonumber(input.PriceAmount or input.PriceCoins or input.PriceCredits or input.PriceDallions) or 0
    local minPrice = priceCurrency == "Dallions" and TradeConfig.MinDallions or TradeConfig.MinCoins
    local maxPrice = priceCurrency == "Dallions" and TradeConfig.MaxDallions or TradeConfig.MaxCoins
    local price = math.clamp(math.floor(rawPrice), minPrice, maxPrice)
    return {
        ItemType = itemType,
        ItemId = itemId,
        Quantity = quantity,
        PriceCurrency = priceCurrency,
        PriceAmount = price,
        PriceCoins = priceCurrency == "Coins" and price or nil,
        PriceCredits = priceCurrency == "Coins" and price or nil,
        PriceDallions = priceCurrency == "Dallions" and price or nil,
    }
end

return TradeConfig
