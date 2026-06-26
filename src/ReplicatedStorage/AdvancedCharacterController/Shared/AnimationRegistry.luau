--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = {}

Registry.Names = {
    "Slide Loop",
    "Idle",
    "Sprint",
    "Block",
    "Crouch",
    "Hit1",
    "Hit2",
    "Hit3",
    "Hit4",
    "RollBackward",
    "RollForward",
    "RollLeft",
    "RollRight",
    "Slide Start",
}

function Registry.Ensure()
    local folder = ReplicatedStorage:FindFirstChild("Animations")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Animations"
        folder.Parent = ReplicatedStorage
    end

    for _, name in ipairs(Registry.Names) do
        local animation = folder:FindFirstChild(name)
        if not animation then
            animation = Instance.new("Animation")
            animation.Name = name
            animation.Parent = folder
        end
    end

    return folder
end

return Registry
