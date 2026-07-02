--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Config"))
local Modes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("MovementModes"))

local HumanoidAdapter = {}
HumanoidAdapter.__index = HumanoidAdapter

local COLLISION_ENFORCE_INTERVAL = 0.15

local function getCharacterPhysicalProperties()
    local collisionConfig = Config.Collision or {}
    local density = collisionConfig.CharacterDensity or 1
    local friction = collisionConfig.CharacterFriction or 0
    local elasticity = collisionConfig.CharacterElasticity or 0
    local frictionWeight = collisionConfig.CharacterFrictionWeight or 0
    local elasticityWeight = collisionConfig.CharacterElasticityWeight or 0
    return PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
end

function HumanoidAdapter.new(controller)
    return setmetatable({
        Controller = controller,
        DefaultHipHeight = nil,
        CollisionTimer = 0,
        CollisionProperties = getCharacterPhysicalProperties(),
    }, HumanoidAdapter)
end

function HumanoidAdapter:ApplyPartCollision(part)
    if not part or not part:IsA("BasePart") then return end

    local collisionConfig = Config.Collision or {}
    local rootOnlyCollision = collisionConfig.RootOnlyCharacterCollision ~= false
    local rootCollides = collisionConfig.RootCanCollide ~= false
    local group = collisionConfig.CharacterCollisionGroup or "PlayerCharacters"

    part.CollisionGroup = group
    part.CustomPhysicalProperties = self.CollisionProperties

    if rootOnlyCollision then
        if part.Name == "HumanoidRootPart" then
            part.CanCollide = rootCollides
            part.CanTouch = false
            part.Massless = false
        else
            -- The server tries to set this too, but Roblox character scripts/accessory insertion can
            -- restore torso/accessory collision on the client. Enforce it locally so the custom
            -- velocity controller only has one physical collider to push.
            part.CanCollide = false
            part.CanTouch = false
            part.Massless = true
        end
    elseif part:FindFirstAncestorOfClass("Accessory") and collisionConfig.DisableAccessoryCollision ~= false then
        part.CanCollide = false
        part.CanTouch = false
        part.Massless = true
    end
end

function HumanoidAdapter:EnforceCharacterCollision(force)
    local controller = self.Controller
    local character = controller.Character
    if not character then return end

    if not force then
        self.CollisionTimer -= 1 / 60
        if self.CollisionTimer > 0 then return end
    end
    self.CollisionTimer = COLLISION_ENFORCE_INTERVAL

    for _, descendant in ipairs(character:GetDescendants()) do
        self:ApplyPartCollision(descendant)
    end
end

function HumanoidAdapter:ApplyCustomMovementSettings()
    local humanoid = self.Controller.Humanoid
    if not humanoid then return end
    self.DefaultHipHeight = humanoid.HipHeight
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    humanoid.AutoRotate = false
    humanoid.PlatformStand = false
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

    self:EnforceCharacterCollision(true)
end

function HumanoidAdapter:Update(dt)
    local controller = self.Controller
    local humanoid = controller.Humanoid
    if not humanoid or not self.DefaultHipHeight then return end

    self.CollisionTimer -= dt
    if self.CollisionTimer <= 0 then
        self.CollisionTimer = COLLISION_ENFORCE_INTERVAL
        self:EnforceCharacterCollision(true)
    end

    local target = self.DefaultHipHeight
    if controller.Mode == Modes.Sliding or controller.Mode == Modes.KnockedDown then
        target = self.DefaultHipHeight * Config.Movement.SlideHipHeightScale
    elseif controller.Input:IsHeld("Crouch") or controller.Mode == Modes.Crouching then
        target = self.DefaultHipHeight * Config.Movement.CrouchHipHeightScale
    end
    local sharpness = Config.Movement.HipHeightSharpness or 12
    humanoid.HipHeight += (target - humanoid.HipHeight) * (1 - math.exp(-sharpness * dt))
    humanoid.AutoRotate = false
    humanoid.PlatformStand = false

    -- Do not call Humanoid:Move(Vector3.zero) here. This controller drives the root velocity
    -- directly; repeatedly feeding a zero humanoid move vector lets Roblox's built-in character
    -- controller fight the custom sprint/glide velocity after physics simulation.
end

return HumanoidAdapter
