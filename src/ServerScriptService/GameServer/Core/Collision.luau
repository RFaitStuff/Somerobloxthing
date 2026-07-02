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

local function getCharacterPhysicalProperties()
    local density = Config.Collision.CharacterDensity or 1
    local friction = Config.Collision.CharacterFriction or 0
    local elasticity = Config.Collision.CharacterElasticity or 0
    local frictionWeight = Config.Collision.CharacterFrictionWeight or 0
    local elasticityWeight = Config.Collision.CharacterElasticityWeight or 0
    return PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
end

local function isAccessoryPart(part)
    return part:FindFirstAncestorOfClass("Accessory") ~= nil
end

function Collision:ApplyCharacter(character)
    local player = Players:GetPlayerFromCharacter(character)
    local group = Config.Collision.CharacterCollisionGroup
    local rootOnlyCollision = Config.Collision.RootOnlyCharacterCollision ~= false
    local rootCollides = Config.Collision.RootCanCollide ~= false
    local physicalProperties = getCharacterPhysicalProperties()

    local function apply(instance)
        if not instance:IsA("BasePart") then return end

        instance.CollisionGroup = group
        instance.CustomPhysicalProperties = physicalProperties

        if rootOnlyCollision then
            -- The custom controller drives HumanoidRootPart velocity directly. If the torso,
            -- head, accessories, or clothing handles also collide, Roblox physics fights the
            -- controller every frame and the rig looks like it is rubber-banding. Keep one
            -- clean root collider and make the visual body non-physical.
            if instance.Name == "HumanoidRootPart" then
                instance.CanCollide = rootCollides
                instance.CanTouch = false
                instance.Massless = false
            else
                instance.CanCollide = false
                instance.CanTouch = false
                instance.Massless = true
            end
        elseif isAccessoryPart(instance) and Config.Collision.DisableAccessoryCollision ~= false then
            instance.CanCollide = false
            instance.CanTouch = false
            instance.Massless = true
        end
    end

    for _, descendant in ipairs(character:GetDescendants()) do
        apply(descendant)
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") and player then
        -- The client owns the custom velocity controller. If the server owns the assembly,
        -- server replication can shave/overwrite AssemblyLinearVelocity and look like rubber-band stutter.
        pcall(function()
            root:SetNetworkOwner(player)
        end)
    end

    character.DescendantAdded:Connect(function(instance)
        apply(instance)
        if instance.Name == "HumanoidRootPart" and instance:IsA("BasePart") and player then
            pcall(function()
                instance:SetNetworkOwner(player)
            end)
        end
    end)
end

return Collision
