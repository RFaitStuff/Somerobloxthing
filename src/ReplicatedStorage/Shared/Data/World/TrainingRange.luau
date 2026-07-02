--!nonstrict
local TrainingRange = {}

TrainingRange.Settings = {
    FolderName = "TrainingRange",
    TargetTag = "TrainingTarget",
    ResetDelay = 1.25,
    SnapshotInterval = 0.5,
}

TrainingRange.Targets = {
    LightDummy = {
        Id = "LightDummy",
        DisplayName = "Light Target",
        Health = 500,
        Shield = 0,
        Armor = 0,
        Size = Vector3.new(4, 7, 2),
        Color = Color3.fromRGB(80, 135, 100),
        Position = Vector3.new(-12, 4, -60),
    },
    ArmoredDummy = {
        Id = "ArmoredDummy",
        DisplayName = "Armored Target",
        Health = 900,
        Shield = 0,
        Armor = 80,
        Size = Vector3.new(4, 7, 2),
        Color = Color3.fromRGB(140, 112, 74),
        Position = Vector3.new(0, 4, -70),
    },
    ShieldDummy = {
        Id = "ShieldDummy",
        DisplayName = "Shielded Target",
        Health = 650,
        Shield = 300,
        Armor = 20,
        Size = Vector3.new(4, 7, 2),
        Color = Color3.fromRGB(75, 120, 170),
        Position = Vector3.new(12, 4, -60),
    },
}

TrainingRange.Order = { "LightDummy", "ArmoredDummy", "ShieldDummy" }

function TrainingRange.Get(id)
    return TrainingRange.Targets[id]
end

return TrainingRange
