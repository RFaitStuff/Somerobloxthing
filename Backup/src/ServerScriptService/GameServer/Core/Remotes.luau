--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Remotes = {}

function Remotes.Ensure()
    local folder = ReplicatedStorage:FindFirstChild(Net.RemotesFolderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = Net.RemotesFolderName
        folder.Parent = ReplicatedStorage
    end
    for _, name in pairs(Net.RemoteEvents) do
        if not folder:FindFirstChild(name) then
            local event = Instance.new("RemoteEvent")
            event.Name = name
            event.Parent = folder
        end
    end
    for _, name in pairs(Net.RemoteFunctions) do
        if not folder:FindFirstChild(name) then
            local fn = Instance.new("RemoteFunction")
            fn.Name = name
            fn.Parent = folder
        end
    end
    return folder
end

return Remotes
