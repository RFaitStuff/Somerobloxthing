--!nonstrict
local Config = require(script.Parent:WaitForChild("Config"))

local Net = {}

Net.RemotesFolderName = Config.Networking.RemotesFolderName

Net.RemoteEvents = {
    ActionRequest = "ActionRequest",
    MeleeRequest = "MeleeRequest",
    StateUpdate = "StateUpdate",
    StatusUpdate = "StatusUpdate",
    Correction = "Correction",
    HitboxDebug = "HitboxDebug",
}

Net.RemoteFunctions = {
    Settings = "Settings",
    Rebind = "Rebind",
}

function Net.GetRemotesFolder()
    return game:GetService("ReplicatedStorage"):WaitForChild("AdvancedCharacterController"):WaitForChild(Net.RemotesFolderName)
end

function Net.GetRemoteEvent(name)
    return Net.GetRemotesFolder():WaitForChild(name)
end

function Net.GetRemoteFunction(name)
    return Net.GetRemotesFolder():WaitForChild(name)
end

return Net
