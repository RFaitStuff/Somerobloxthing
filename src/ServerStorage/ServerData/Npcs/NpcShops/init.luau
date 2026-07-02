--!nonstrict
local NpcShops = {}

NpcShops.ByNpcId = {
    Quartermaster = {
        Id = "QuartermasterDaily",
        DisplayName = "Quartermaster Daily Stock",
        ResetSeconds = 24 * 60 * 60,
        RotationGroup = "HubDaily",
        Listings = {
            AlloyDaily = { Id = "AlloyDaily", DisplayName = "Alloy Cache", Cost = { Coins = 90 }, OutputType = "Material", OutputId = "Alloy", Amount = 20, DailyStock = 2 },
            CircuitDaily = { Id = "CircuitDaily", DisplayName = "Circuit Pack", Cost = { Coins = 140 }, OutputType = "Material", OutputId = "Circuit", Amount = 10, DailyStock = 2 },
            BannerStandDaily = { Id = "BannerStandDaily", DisplayName = "Banner Stand", Cost = { Coins = 220 }, OutputType = "Decoration", OutputId = "BannerStand", Amount = 1, DailyStock = 1 },
        },
    },
}

function NpcShops.Get(npcId)
    return NpcShops.ByNpcId[npcId]
end

return NpcShops
