--!nonstrict
local Players = game:GetService("Players")

local Hud = {}
Hud.__index = Hud

function Hud.new(state)
    return setmetatable({ State = state, Gui = nil, Labels = {}, Bars = {} }, Hud)
end

function Hud:MakeBar(parent, name, y, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromOffset(90, 18)
    label.Position = UDim2.fromOffset(0, y)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(235, 240, 245)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Text = name
    label.Parent = parent

    local back = Instance.new("Frame")
    back.Size = UDim2.fromOffset(230, 14)
    back.Position = UDim2.fromOffset(92, y + 2)
    back.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
    back.BorderSizePixel = 0
    back.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = back

    self.Bars[name] = fill
    self.Labels[name] = label
end

function Hud:Start()
    local gui = Instance.new("ScreenGui")
    gui.Name = "GameplayHud"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui

    local dot = Instance.new("Frame")
    dot.Name = "CrosshairDot"
    dot.Size = UDim2.fromOffset(5, 5)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(360, 128)
    panel.Position = UDim2.new(0, 18, 1, -150)
    panel.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
    panel.BackgroundTransparency = 0.18
    panel.BorderSizePixel = 0
    panel.Parent = gui

    self:MakeBar(panel, "Health", 10, Color3.fromRGB(220, 70, 70))
    self:MakeBar(panel, "Shield", 34, Color3.fromRGB(80, 160, 255))
    self:MakeBar(panel, "Mana", 58, Color3.fromRGB(150, 95, 255))

    local weapon = Instance.new("TextLabel")
    weapon.Name = "Weapon"
    weapon.Size = UDim2.new(1, -16, 0, 22)
    weapon.Position = UDim2.fromOffset(8, 84)
    weapon.BackgroundTransparency = 1
    weapon.TextXAlignment = Enum.TextXAlignment.Left
    weapon.TextColor3 = Color3.fromRGB(245, 248, 250)
    weapon.Font = Enum.Font.GothamBold
    weapon.TextSize = 14
    weapon.Parent = panel
    self.Labels.Weapon = weapon

    local abilities = Instance.new("TextLabel")
    abilities.Name = "Abilities"
    abilities.Size = UDim2.new(1, -16, 0, 18)
    abilities.Position = UDim2.fromOffset(8, 106)
    abilities.BackgroundTransparency = 1
    abilities.TextXAlignment = Enum.TextXAlignment.Left
    abilities.TextColor3 = Color3.fromRGB(200, 220, 240)
    abilities.Font = Enum.Font.Gotham
    abilities.TextSize = 12
    abilities.Parent = panel
    self.Labels.Abilities = abilities

    game:GetService("RunService").RenderStepped:Connect(function()
        self:Update()
    end)
end

function Hud:SetBar(name, current, maxValue)
    local fill = self.Bars[name]
    local label = self.Labels[name]
    if not fill or not label then return end
    current = tonumber(current) or 0
    maxValue = math.max(tonumber(maxValue) or 1, 1)
    fill.Size = UDim2.fromScale(math.clamp(current / maxValue, 0, 1), 1)
    label.Text = string.format("%s %.0f/%.0f", name, current, maxValue)
end

function Hud:Update()
    local stats = self.State.Stats or {}
    local res = self.State.Resources or {}
    local profile = self.State.Profile
    self:SetBar("Health", res.Health, stats.Health)
    self:SetBar("Shield", res.Shield, stats.Shield)
    self:SetBar("Mana", res.Mana, stats.Mana)

    local equipped = profile and profile.Equipped
    local weaponId = equipped and equipped.ActiveWeapon or self.State.EquippedWeaponId or "None"
    local runtime = self.State.WeaponRuntime[weaponId] or {}
    self.Labels.Weapon.Text = string.format("Weapon: %s  Ammo: %s/%s  [Z swap]", weaponId, tostring(runtime.Ammo or "-"), tostring(runtime.Magazine or "-"))

    local frameState = profile and profile.Frames and profile.Frames[profile.SelectedFrameId]
    local variants = frameState and frameState.SelectedVariants or {}
    self.Labels.Abilities.Text = string.format("[1] %s   [2] %s   [3] %s   [4] %s   [V] melee", tostring(variants[1] or "-"), tostring(variants[2] or "-"), tostring(variants[3] or "-"), tostring(variants[4] or "-"))
end

return Hud
