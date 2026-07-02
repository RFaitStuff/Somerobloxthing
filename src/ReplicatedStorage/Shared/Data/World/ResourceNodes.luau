--!nonstrict
local ResourceNodes = {}

ResourceNodes.ById = {
    AlloyOutcrop = {
        Id = "AlloyOutcrop",
        DisplayName = "Alloy Outcrop",
        MaterialId = "Alloy",
        AmountMin = 2,
        AmountMax = 5,
        Cooldown = 20,
        Locations = { Earth = true, Mars = true },
    },
    CircuitCache = {
        Id = "CircuitCache",
        DisplayName = "Circuit Cache",
        MaterialId = "Circuit",
        AmountMin = 1,
        AmountMax = 4,
        Cooldown = 25,
        Locations = { Earth = true, Mars = true },
    },
    SparkBloom = {
        Id = "SparkBloom",
        DisplayName = "Spark Bloom",
        MaterialId = "Spark",
        AmountMin = 1,
        AmountMax = 2,
        Cooldown = 35,
        Locations = { Earth = true },
    },
    LensShard = {
        Id = "LensShard",
        DisplayName = "Lens Shard",
        MaterialId = "Lens",
        AmountMin = 1,
        AmountMax = 3,
        Cooldown = 45,
        Locations = { Earth = true, Mars = true },
    },
    FerriteVein = {
        Id = "FerriteVein",
        DisplayName = "Ferrite Vein",
        MaterialId = "Ferrite",
        AmountMin = 3,
        AmountMax = 8,
        Cooldown = 35,
        Locations = { Mars = true },
    },
    CoreRelic = {
        Id = "CoreRelic",
        DisplayName = "Core Relic",
        MaterialId = "Core",
        AmountMin = 1,
        AmountMax = 1,
        Cooldown = 90,
        Locations = { Mars = true },
    },
}

ResourceNodes.DevByLocation = {
    Earth = { "AlloyOutcrop", "CircuitCache", "SparkBloom", "LensShard" },
    Mars = { "AlloyOutcrop", "CircuitCache", "LensShard", "FerriteVein", "CoreRelic" },
}

function ResourceNodes.Get(id)
    return ResourceNodes.ById[id]
end

function ResourceNodes.CanSpawnInLocation(resourceId, locationId)
    local def = ResourceNodes.Get(resourceId)
    return def ~= nil and def.Locations and def.Locations[locationId] == true
end

return ResourceNodes
