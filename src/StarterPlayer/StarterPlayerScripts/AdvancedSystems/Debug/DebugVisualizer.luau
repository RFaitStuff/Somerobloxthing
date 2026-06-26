--!nonstrict
-- ShapeBuilder ------------------------------------------------------------
local ShapeBuilder = {}

function ShapeBuilder.MeleeShape(root, attack)
    if not root or not attack then return nil end
    if attack.Hitbox == "Radius" then
        return {
            Shape = "Radius",
            Center = root.Position + root.CFrame.LookVector * ((attack.Radius or attack.Range or 8) * 0.35),
            Radius = attack.Radius or attack.Range or 8,
        }
    end
    local size = Vector3.new(attack.Width or 5, attack.Height or 5, attack.Range or 8)
    return {
        Shape = "Box",
        CFrame = root.CFrame * CFrame.new(0, 0, -size.Z * 0.5),
        Size = size,
    }
end

-- DebugDraw ------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DebugDraw = {}
DebugDraw.__index = DebugDraw

local function ensureFolder(name)
    local folder = workspace:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = workspace
    end
    return folder
end

function DebugDraw.new(folderName, maxParts)
    return setmetatable({
        Folder = ensureFolder(folderName),
        MaxParts = maxParts or 150,
        Pool = {},
        Active = {},
        Serial = 0,
    }, DebugDraw)
end

function DebugDraw:_makePart()
    local part = table.remove(self.Pool)
    if not part then
        part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
    end
    part.Parent = self.Folder
    return part
end

function DebugDraw:_activate(part, lifetime, tag)
    self.Serial += 1
    part.Name = tag or ("Hitbox_" .. self.Serial)
    part.Material = Config.Debug.Material
    part.Transparency = Config.Debug.Transparency
    self.Active[part] = os.clock() + (lifetime or Config.Debug.LocalHitboxLifetime)
    if #self.Folder:GetChildren() > self.MaxParts then
        self:Step(true)
    end
end

function DebugDraw:_style(part, color)
    part.Color = color or Color3.fromRGB(255, 255, 255)
end

function DebugDraw:Box(cf, size, color, lifetime, tag)
    local part = self:_makePart()
    part.Shape = Enum.PartType.Block
    part.Size = size
    part.CFrame = cf
    self:_style(part, color)
    self:_activate(part, lifetime, tag)
    return part
end

function DebugDraw:Sphere(center, radius, color, lifetime, tag)
    local part = self:_makePart()
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    part.CFrame = CFrame.new(center)
    self:_style(part, color)
    self:_activate(part, lifetime, tag)
    return part
end

function DebugDraw:CylinderBetween(a, b, radius, color, lifetime, tag)
    local delta = b - a
    if delta.Magnitude <= 0.01 then return nil end
    local yAxis = delta.Unit
    local helper = math.abs(yAxis:Dot(Vector3.yAxis)) > 0.95 and Vector3.xAxis or Vector3.yAxis
    local xAxis = helper:Cross(yAxis).Unit
    local zAxis = xAxis:Cross(yAxis).Unit
    local part = self:_makePart()
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(radius * 2, delta.Magnitude, radius * 2)
    -- Roblox cylinders extend along local Y.
    part.CFrame = CFrame.fromMatrix((a + b) * 0.5, xAxis, yAxis, zAxis)
    self:_style(part, color)
    self:_activate(part, lifetime, tag)
    return part
end

function DebugDraw:CapsuleVertical(center, radius, halfHeight, color, lifetime, tag)
    local bodyHeight = math.max(0.05, halfHeight * 2)
    self:CylinderBetween(center - Vector3.new(0, halfHeight, 0), center + Vector3.new(0, halfHeight, 0), radius, color, lifetime, tag .. "Body")
    self:Sphere(center + Vector3.new(0, halfHeight, 0), radius, color, lifetime, tag .. "Top")
    self:Sphere(center - Vector3.new(0, halfHeight, 0), radius, color, lifetime, tag .. "Bottom")
end

function DebugDraw:Step(forceCullOne)
    local now = os.clock()
    local culled = false
    for part, expiresAt in pairs(self.Active) do
        if forceCullOne or now >= expiresAt then
            self.Active[part] = nil
            part.Parent = nil
            table.insert(self.Pool, part)
            culled = true
            if forceCullOne then break end
        end
    end
    return culled
end

function DebugDraw:ClearAll()
    for part in pairs(self.Active) do
        self.Active[part] = nil
        part.Parent = nil
        table.insert(self.Pool, part)
    end
    for _, part in ipairs(self.Folder:GetChildren()) do
        if part:IsA("BasePart") then part:Destroy() end
    end
    table.clear(self.Pool)
end

-- Main ------------------------------------------------------------
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))


local Visualizer = {}
Visualizer.__index = Visualizer

function Visualizer.new(state, input, camera, motor, melee)
    local self = setmetatable({}, Visualizer)
    self.State = state
    self.Input = input
    self.Camera = camera
    self.Motor = motor
    self.Melee = melee
    self.Enabled = Config.Debug.StartEnabled == true
    self.Draw = DebugDraw.new(Config.Debug.FolderName, Config.Debug.MaxParts)
    self.Connection = nil
    self.RemoteConnection = nil
    return self
end

function Visualizer:Start()
    if not Config.Debug.HitboxVisualizerEnabled then return end
    self.RemoteConnection = Net.GetRemoteEvent(Net.RemoteEvents.HitboxDebug).OnClientEvent:Connect(function(payload)
        self:OnServerShape(payload)
    end)
    self.Connection = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)
end

function Visualizer:Destroy()
    if self.Connection then self.Connection:Disconnect() end
    if self.RemoteConnection then self.RemoteConnection:Disconnect() end
    self.Draw:ClearAll()
end

function Visualizer:SetEnabled(enabled)
    self.Enabled = enabled == true
    if not self.Enabled then self.Draw:ClearAll() end
    if self.State then self.State.HitboxDebugEnabled = self.Enabled end
end

function Visualizer:Toggle()
    self:SetEnabled(not self.Enabled)
    warn("[Controller Debug] Hitbox visualizer " .. (self.Enabled and "ON" or "OFF"))
end

function Visualizer:OnServerShape(payload)
    if not self.Enabled or typeof(payload) ~= "table" then return end
    local color = Config.Debug.Colors.MeleeServer
    local lifetime = payload.Lifetime or Config.Debug.ServerHitboxLifetime
    if payload.Shape == "Radius" and typeof(payload.Center) == "Vector3" then
        self.Draw:Sphere(payload.Center, payload.Radius or 4, color, lifetime, "ServerMeleeRadius")
    elseif payload.Shape == "Box" and typeof(payload.CFrame) == "CFrame" and typeof(payload.Size) == "Vector3" then
        self.Draw:Box(payload.CFrame, payload.Size, color, lifetime, "ServerMeleeBox")
    elseif payload.Shape == "Capsule" and typeof(payload.Center) == "Vector3" then
        self.Draw:CapsuleVertical(payload.Center, payload.Radius or 1, payload.HalfHeight or 3, color, lifetime, "ServerCapsule")
    end
end

function Visualizer:DrawLocalMelee()
    if not self.Melee or not self.Melee.LastPredictedAttack or not self.Motor or not self.Motor.Root then return end
    local attack = self.Melee.LastPredictedAttack
    local untilTime = self.Melee.LastPredictedUntil or 0
    if os.clock() > untilTime then return end
    local shape = ShapeBuilder.MeleeShape(self.Motor.Root, attack)
    if not shape then return end
    local color = Config.Debug.Colors.MeleePredicted
    if shape.Shape == "Radius" then
        self.Draw:Sphere(shape.Center, shape.Radius, color, Config.Debug.PersistentProbeLifetime, "PredictedMeleeRadius")
    else
        self.Draw:Box(shape.CFrame, shape.Size, color, Config.Debug.PersistentProbeLifetime, "PredictedMeleeBox")
    end
end

function Visualizer:DrawSoftCollision()
    if not self.Motor or not self.Motor.Root then return end
    local collision = Config.Collision
    if not collision.SoftPlayerCollisionEnabled then return end
    local color = Config.Debug.Colors.SoftCollision
    self.Draw:CapsuleVertical(self.Motor.Root.Position, collision.SoftPlayerRadius, collision.SoftPlayerVerticalHalfHeight, color, Config.Debug.PersistentProbeLifetime, "LocalSoftCapsule")
    local soft = self.Motor.SoftCollision
    if soft and soft.CachedRoots then
        for i, otherRoot in ipairs(soft.CachedRoots) do
            if otherRoot and otherRoot.Parent then
                self.Draw:CapsuleVertical(otherRoot.Position, collision.SoftPlayerRadius, collision.SoftPlayerVerticalHalfHeight, color, Config.Debug.PersistentProbeLifetime, "OtherSoftCapsule" .. i)
            end
        end
    end
end

function Visualizer:DrawMovementProbes()
    if not self.Motor or not self.Motor.Root then return end
    local root = self.Motor.Root
    local colorGround = Config.Debug.Colors.GroundProbe
    self.Draw:Sphere(root.Position - Vector3.new(0, 2.8, 0), 0.45, colorGround, Config.Debug.PersistentProbeLifetime, "GroundProbe")
    if self.Motor.HasWall and self.Motor.WallNormal.Magnitude > 0.01 then
        local origin = root.Position + Vector3.new(0, 2.2, 0)
        local center = origin - self.Motor.WallNormal.Unit * 1.2
        self.Draw:Box(CFrame.lookAt(center, center - self.Motor.WallNormal), Vector3.new(2.4, 2.4, 0.08), Config.Debug.Colors.WallProbe, Config.Debug.PersistentProbeLifetime, "WallProbe")
    end
end

function Visualizer:DrawCameraCollision()
    if not self.Camera or not self.Camera.LastCollisionProbe then return end
    local probe = self.Camera.LastCollisionProbe
    if typeof(probe.Focus) ~= "Vector3" or typeof(probe.Desired) ~= "Vector3" then return end
    local mid = (probe.Focus + probe.Desired) * 0.5
    local delta = probe.Desired - probe.Focus
    if delta.Magnitude > 0.05 then
        self.Draw:CylinderBetween(probe.Focus, probe.Desired, Config.Camera.CollisionRadius, Config.Debug.Colors.CameraCollision, Config.Debug.PersistentProbeLifetime, "CameraSpherecast")
    end
    if probe.HitPosition then
        self.Draw:Sphere(probe.HitPosition, Config.Camera.CollisionRadius * 1.5, Config.Debug.Colors.CameraCollision, Config.Debug.PersistentProbeLifetime, "CameraHit")
    end
end

function Visualizer:Update()
    if self.Input and self.Input:ConsumePressed(Config.Debug.HitboxToggleAction) then
        self:Toggle()
    end
    self.Draw:Step()
    if not self.Enabled then return end
    self:DrawLocalMelee()
    self:DrawSoftCollision()
    self:DrawMovementProbes()
    self:DrawCameraCollision()
end

return Visualizer
