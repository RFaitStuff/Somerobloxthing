--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared"):WaitForChild("Config"))

local TuningMenu = {}
TuningMenu.__index = TuningMenu

local TUNABLES = {
    { Section = "Movement", Key = "WalkSpeed", Step = 1 },
    { Section = "Movement", Key = "SprintSpeed", Step = 1 },
    { Section = "Movement", Key = "GroundAcceleration", Step = 5 },
    { Section = "Movement", Key = "GroundDeceleration", Step = 5 },
    { Section = "Movement", Key = "GroundCoastDeceleration", Step = 5 },
    { Section = "Movement", Key = "CounterMoveDeceleration", Step = 5 },
    { Section = "Movement", Key = "AirAcceleration", Step = 2 },
    { Section = "Movement", Key = "AirDrag", Step = 0.05 },
    { Section = "Movement", Key = "Gravity", Step = 5 },
    { Section = "Movement", Key = "RisingGravityScale", Step = 0.05 },
    { Section = "Movement", Key = "FallingGravityScale", Step = 0.05 },
    { Section = "Movement", Key = "JumpVelocity", Step = 1 },
    { Section = "Movement", Key = "DoubleJumpVelocity", Step = 1 },
    { Section = "Movement", Key = "SlideStartSpeed", Step = 1 },
    { Section = "Movement", Key = "SlideStartBoost", Step = 1 },
    { Section = "Movement", Key = "SlideFriction", Step = 2 },
    { Section = "Movement", Key = "SlideMaxPlanarSpeed", Step = 2 },
    { Section = "Movement", Key = "BulletJumpForwardImpulse", Step = 2 },
    { Section = "Movement", Key = "BulletJumpUpImpulse", Step = 2 },
    { Section = "Movement", Key = "AimGlideGravityScale", Step = 0.02 },
    { Section = "Movement", Key = "AimGlideMaxFallSpeed", Step = 1 },
    { Section = "Movement", Key = "AimGlideAirControlMultiplier", Step = 0.05 },
    { Section = "Movement", Key = "RollImpulse", Step = 2 },
    { Section = "Movement", Key = "AirDodgeImpulse", Step = 2 },
    { Section = "Movement", Key = "MaxPlanarSpeed", Step = 2 },
    { Section = "Movement", Key = "HardMaxPlanarSpeed", Step = 2 },
    { Section = "Camera", Key = "Height", Step = 0.1 },
    { Section = "Camera", Key = "ShoulderOffset", Step = 0.1 },
    { Section = "Camera", Key = "AimShoulderOffset", Step = 0.1 },
    { Section = "Camera", Key = "Distance", Step = 0.25 },
    { Section = "Camera", Key = "AimDistance", Step = 0.25 },
}

local SCALE_KEYS = {
    "WalkSpeed",
    "SprintSpeed",
    "GroundAcceleration",
    "GroundCoastDeceleration",
    "CounterMoveDeceleration",
    "AirAcceleration",
    "JumpVelocity",
    "DoubleJumpVelocity",
    "SlideStartSpeed",
    "SlideStartBoost",
    "SlideMaxPlanarSpeed",
    "BulletJumpForwardImpulse",
    "BulletJumpUpImpulse",
    "RollImpulse",
    "AirDodgeImpulse",
    "MaxPlanarSpeed",
    "HardMaxPlanarSpeed",
}

local function round(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function fmt(value)
    return tostring(round(tonumber(value) or 0))
end

function TuningMenu.new(_, _, camera, motor)
    return setmetatable({
        Camera = camera,
        Motor = motor,
        Gui = nil,
        Panel = nil,
        ValueBoxes = {},
        Connections = {},
    }, TuningMenu)
end

function TuningMenu:Start()
    self:BuildGui()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.P then
            self:SetVisible(not self.Gui.Enabled)
        end
    end))
end

function TuningMenu:Destroy()
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    table.clear(self.Connections)
    if self.Gui then self.Gui:Destroy() end
end

function TuningMenu:SetVisible(visible)
    self.Gui.Enabled = visible == true
    if self.Gui.Enabled then
        self:RefreshAll()
    end
end

function TuningMenu:GetValue(entry)
    return Config[entry.Section][entry.Key]
end

function TuningMenu:SetValue(entry, value)
    value = tonumber(value)
    if not value then return end
    Config[entry.Section][entry.Key] = round(value)
    self:Refresh(entry)
end

function TuningMenu:Nudge(entry, direction)
    self:SetValue(entry, (tonumber(self:GetValue(entry)) or 0) + entry.Step * direction)
end

function TuningMenu:ScaleMovement(multiplier)
    for _, key in ipairs(SCALE_KEYS) do
        local value = Config.Movement[key]
        if type(value) == "number" then
            Config.Movement[key] = round(value * multiplier)
        end
    end
    self:RefreshAll()
end

function TuningMenu:Refresh(entry)
    local box = self.ValueBoxes[entry.Section .. "." .. entry.Key]
    if box then box.Text = fmt(self:GetValue(entry)) end
end

function TuningMenu:RefreshAll()
    for _, entry in ipairs(TUNABLES) do
        self:Refresh(entry)
    end
end

function TuningMenu:MakeButton(parent, text, size)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.fromOffset(32, 26)
    button.BackgroundColor3 = Color3.fromRGB(42, 48, 56)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(235, 240, 245)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.Text = text
    button.Parent = parent
    return button
end

function TuningMenu:AddRow(parent, entry)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -170, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(225, 230, 235)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Text = entry.Section .. "." .. entry.Key
    label.Parent = row

    local minus = self:MakeButton(row, "-", UDim2.fromOffset(28, 24))
    minus.Position = UDim2.new(1, -166, 0, 3)

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(82, 24)
    box.Position = UDim2.new(1, -134, 0, 3)
    box.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(245, 248, 250)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Text = fmt(self:GetValue(entry))
    box.Parent = row
    self.ValueBoxes[entry.Section .. "." .. entry.Key] = box

    local plus = self:MakeButton(row, "+", UDim2.fromOffset(28, 24))
    plus.Position = UDim2.new(1, -48, 0, 3)

    minus.MouseButton1Click:Connect(function() self:Nudge(entry, -1) end)
    plus.MouseButton1Click:Connect(function() self:Nudge(entry, 1) end)
    box.FocusLost:Connect(function()
        self:SetValue(entry, box.Text)
    end)
end

function TuningMenu:BuildGui()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "ControllerTuningMenu"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = playerGui
    self.Gui = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(460, 540)
    panel.Position = UDim2.fromOffset(24, 80)
    panel.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    self.Panel = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 34)
    title.Position = UDim2.fromOffset(8, 6)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(245, 248, 250)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Text = "Controller Tuning"
    title.Parent = panel

    local shrink = self:MakeButton(panel, "All -5%", UDim2.fromOffset(82, 26))
    shrink.Position = UDim2.new(1, -178, 0, 10)
    local grow = self:MakeButton(panel, "All +5%", UDim2.fromOffset(82, 26))
    grow.Position = UDim2.new(1, -90, 0, 10)
    shrink.MouseButton1Click:Connect(function() self:ScaleMovement(0.95) end)
    grow.MouseButton1Click:Connect(function() self:ScaleMovement(1.05) end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -54)
    scroll.Position = UDim2.fromOffset(8, 46)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.fromOffset(0, #TUNABLES * 32)
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    for _, entry in ipairs(TUNABLES) do
        self:AddRow(scroll, entry)
    end
end

return TuningMenu
