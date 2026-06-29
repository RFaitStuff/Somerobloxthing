--!nonstrict
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Net"))

local Feedback = {}
Feedback.__index = Feedback

function Feedback.new()
    return setmetatable({ Bars = {} }, Feedback)
end

function Feedback:Start()
    Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback).OnClientEvent:Connect(function(payload)
        if typeof(payload) ~= "table" then return end
        if payload.Type == "Shot" then
            self:Tracer(payload.Origin, payload.HitPosition)
        elseif payload.Type == "Explosion" then
            self:Explosion(payload.Position, payload.Radius)
        elseif payload.Type == "Damage" and payload.Target then
            self:EnsureHealthbar(payload.Target)
            self:UpdateHealthbar(payload.Target, payload)
            self:DamageNumber(payload.Target, payload.Amount)
        end
    end)
    RunService.RenderStepped:Connect(function()
        local folder = workspace:FindFirstChild("TestEnemies")
        if not folder then return end
        for _, enemy in ipairs(folder:GetChildren()) do
            self:EnsureHealthbar(enemy)
        end
    end)
end

function Feedback:Explosion(position, radius)
    if typeof(position) ~= "Vector3" then return end
    radius = tonumber(radius) or 10
    local sphere = Instance.new("Part")
    sphere.Name = "ExplosionPreview"
    sphere.Shape = Enum.PartType.Ball
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.CanQuery = false
    sphere.Material = Enum.Material.Neon
    sphere.Color = Color3.fromRGB(255, 155, 70)
    sphere.Transparency = 0.55
    sphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    sphere.CFrame = CFrame.new(position)
    sphere.Parent = workspace
    Debris:AddItem(sphere, 0.16)
end

function Feedback:Tracer(origin, hitPosition)
    if typeof(origin) ~= "Vector3" or typeof(hitPosition) ~= "Vector3" then return end
    local delta = hitPosition - origin
    if delta.Magnitude <= 0.1 then return end
    local part = Instance.new("Part")
    part.Name = "ShotTracer"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(110, 210, 255)
    part.Size = Vector3.new(0.08, 0.08, delta.Magnitude)
    part.CFrame = CFrame.lookAt(origin + delta * 0.5, hitPosition)
    part.Parent = workspace
    Debris:AddItem(part, 0.06)
end

function Feedback:EnsureHealthbar(model)
    if self.Bars[model] or not model or not model.Parent then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "EnemyHealthbar"
    gui.Size = UDim2.fromOffset(120, 28)
    gui.StudsOffset = Vector3.new(0, 4.2, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = root
    gui.Parent = root

    local back = Instance.new("Frame")
    back.Size = UDim2.new(1, 0, 0, 8)
    back.Position = UDim2.fromOffset(0, 14)
    back.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    back.BorderSizePixel = 0
    back.Parent = gui

    local health = Instance.new("Frame")
    health.Name = "Health"
    health.Size = UDim2.fromScale(1, 1)
    health.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
    health.BorderSizePixel = 0
    health.Parent = back

    local shield = Instance.new("Frame")
    shield.Name = "Shield"
    shield.Size = UDim2.fromScale(1, 0.35)
    shield.Position = UDim2.fromScale(0, -0.55)
    shield.BackgroundColor3 = Color3.fromRGB(70, 160, 255)
    shield.BorderSizePixel = 0
    shield.Parent = back

    self.Bars[model] = { Gui = gui, Health = health, Shield = shield }
    self:UpdateHealthbar(model, {
        Health = model:GetAttribute("Health"),
        MaxHealth = model:GetAttribute("MaxHealth"),
        Shield = model:GetAttribute("Shield"),
        MaxShield = model:GetAttribute("MaxShield"),
    })
end

function Feedback:UpdateHealthbar(model, payload)
    local bar = self.Bars[model]
    if not bar then return end
    local health = tonumber(payload.Health) or tonumber(model:GetAttribute("Health")) or 0
    local maxHealth = math.max(tonumber(payload.MaxHealth) or tonumber(model:GetAttribute("MaxHealth")) or 1, 1)
    local shield = tonumber(payload.Shield) or tonumber(model:GetAttribute("Shield")) or 0
    local maxShield = math.max(tonumber(payload.MaxShield) or tonumber(model:GetAttribute("MaxShield")) or 1, 1)
    bar.Health.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
    bar.Shield.Size = UDim2.fromScale(math.clamp(shield / maxShield, 0, 1), 0.35)
end

function Feedback:DamageNumber(model, amount)
    local root = model and model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "DamageNumber"
    gui.Size = UDim2.fromOffset(80, 30)
    gui.StudsOffset = Vector3.new((math.random() - 0.5) * 2, 5.2, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = root
    gui.Parent = root
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 230, 90)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 20
    label.Text = tostring(amount or 0)
    label.Parent = gui
    Debris:AddItem(gui, 0.65)
end

return Feedback
