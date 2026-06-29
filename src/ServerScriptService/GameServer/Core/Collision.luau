--!nonstrict
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Config"))

local Collision = {}
Collision.__index = Collision

function Collision.new()
    return setmetatable({ Connections = {} }, Collision)
end

function Collision:Start()
    self:EnsureCollisionGroups()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:ApplyCharacter(character)
        end)
        if player.Character then self:ApplyCharacter(player.Character) end
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then self:ApplyCharacter(player.Character) end
    end
end

function Collision:EnsureCollisionGroups()
    local group = Config.Collision.CharacterCollisionGroup
    pcall(function()
        PhysicsService:RegisterCollisionGroup(group)
    end)
    if Config.Collision.DisablePhysicalPlayerPlayerCollision then
        PhysicsService:CollisionGroupSetCollidable(group, group, false)
    end
end

function Collision:ApplyCharacter(character)
    local group = Config.Collision.CharacterCollisionGroup
    local function apply(instance)
        if instance:IsA("BasePart") then
            -- Modern API: set the BasePart.CollisionGroup property directly.
            -- Do not force CanCollide here; keep Roblox rig/world collision behavior intact
            -- while disabling character-vs-character collision through the group matrix.
            instance.CollisionGroup = group
        end
    end
    for _, descendant in ipairs(character:GetDescendants()) do
        apply(descendant)
    end
    character.DescendantAdded:Connect(apply)
end

return Collision
