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
        warn("[AnimationRegistry] ReplicatedStorage.Animations was not found. Add the animation folder in Studio; Rojo does not manage it.")
        return nil
    end

    return folder
end

return Registry
