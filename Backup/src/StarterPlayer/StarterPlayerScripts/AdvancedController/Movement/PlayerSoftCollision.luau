--!nonstrict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local SoftCollision = {}
SoftCollision.__index = SoftCollision

function SoftCollision.new(controller)
    return setmetatable({ Controller = controller, LocalPlayer = Players.LocalPlayer, AccumulatedStrength = 0, QueryTimer = 0, CachedRoots = {} }, SoftCollision)
end

function SoftCollision:RefreshRoots()
    table.clear(self.CachedRoots)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= self.LocalPlayer then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 then table.insert(self.CachedRoots, root) end
        end
    end
end

function SoftCollision:Update(dt)
    local c = self.Controller
    self.AccumulatedStrength = 0
    if not Config.Collision.SoftPlayerCollisionEnabled or not c.Root then return end
    self.QueryTimer -= dt
    if self.QueryTimer <= 0 then
        self.QueryTimer = Config.Collision.SoftPlayerQueryInterval
        self:RefreshRoots()
    end

    local pos = c.Root.Position
    local velocity = c.Velocity
    local totalNudge = Vector3.zero
    local radius = Config.Collision.SoftPlayerRadius
    local halfHeight = Config.Collision.SoftPlayerVerticalHalfHeight

    for _, otherRoot in ipairs(self.CachedRoots) do
        if otherRoot and otherRoot.Parent then
            local offset = pos - otherRoot.Position
            if math.abs(offset.Y) <= halfHeight then
                local flat = Vector3.new(offset.X, 0, offset.Z)
                local dist = flat.Magnitude
                if dist < radius then
                    local normal = dist > 0.001 and flat / dist or c.Root.CFrame.RightVector
                    local strength = (1 - dist / radius) * (1 - math.abs(offset.Y) / halfHeight)
                    self.AccumulatedStrength = math.max(self.AccumulatedStrength, strength)
                    local into = velocity:Dot(normal)
                    if into < 0 then
                        velocity -= normal * into * Config.Collision.SoftPlayerVelocityDeflect
                        velocity *= Config.Collision.SoftPlayerThroughVelocityPreserve
                    end
                    velocity += normal * (Config.Collision.SoftPlayerPushSpeed * strength)
                    totalNudge += normal * (Config.Collision.SoftPlayerMaxPositionNudge * strength)
                end
            end
        end
    end

    if totalNudge.Magnitude > Config.Collision.SoftPlayerMaxPositionNudge then
        totalNudge = totalNudge.Unit * Config.Collision.SoftPlayerMaxPositionNudge
    end
    if totalNudge.Magnitude > 0 then c.Root.CFrame = c.Root.CFrame + totalNudge end
    c.Velocity = velocity
end

return SoftCollision
