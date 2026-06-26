--!nonstrict
-- ActionState ------------------------------------------------------------
local ActionState = {}
ActionState.__index = ActionState

function ActionState.new()
    return setmetatable({ Held = {}, Pressed = {} }, ActionState)
end

function ActionState:SetHeld(action, isHeld)
    local wasHeld = self.Held[action] == true
    self.Held[action] = isHeld == true
    if isHeld and not wasHeld then
        self.Pressed[action] = true
    end
end

function ActionState:IsHeld(action)
    return self.Held[action] == true
end

function ActionState:ConsumePressed(action)
    if self.Pressed[action] then
        self.Pressed[action] = nil
        return true
    end
    return false
end

function ActionState:ClearTransient()
    table.clear(self.Pressed)
end

-- BindingCodec ------------------------------------------------------------
local Codec = {}

function Codec.EncodeInput(input)
    if typeof(input) == "EnumItem" then
        return input.EnumType.Name .. ":" .. input.Name
    end
    return nil
end

function Codec.DecodeInput(encoded)
    if type(encoded) ~= "string" then return nil end
    local enumType, itemName = encoded:match("^([^:]+):(.+)$")
    if not enumType or not itemName then return nil end
    local enum = Enum[enumType]
    return enum and enum[itemName] or nil
end

function Codec.EncodeList(list)
    local out = {}
    for _, input in ipairs(list or {}) do
        local encoded = Codec.EncodeInput(input)
        if encoded then table.insert(out, encoded) end
    end
    return out
end

function Codec.DecodeList(list)
    local out = {}
    for _, encoded in ipairs(list or {}) do
        local input = Codec.DecodeInput(encoded)
        if input then table.insert(out, input) end
    end
    return out
end

-- ContextBinder ------------------------------------------------------------
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("AdvancedCharacterController"):WaitForChild("Shared")
local Bindings = require(Shared:WaitForChild("InputBindings"))
local BindingCodec = Codec

local ContextBinder = {}
ContextBinder.__index = ContextBinder

function ContextBinder.new(actionState)
    local self = setmetatable({}, ContextBinder)
    self.ActionState = actionState
    self.CurrentBindings = {}
    return self
end

function ContextBinder:_bindAction(actionName, inputs)
    ContextActionService:UnbindAction("Controller_" .. actionName)
    ContextActionService:BindActionAtPriority(
        "Controller_" .. actionName,
        function(_, inputState)
            if inputState == Enum.UserInputState.Begin then
                self.ActionState:SetHeld(actionName, true)
            elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
                self.ActionState:SetHeld(actionName, false)
            end
            return Enum.ContextActionResult.Sink
        end,
        true,
        Enum.ContextActionPriority.High.Value,
        table.unpack(inputs)
    )
end

function ContextBinder:BindDefaults()
    self.CurrentBindings = table.clone(Bindings.Defaults)
    for actionName, inputs in pairs(self.CurrentBindings) do
        self:_bindAction(actionName, inputs)
    end
end

function ContextBinder:ApplyRebinds(serialized)
    if typeof(serialized) ~= "table" then return end
    for actionName, encodedList in pairs(serialized) do
        local decoded = BindingCodec.DecodeList(encodedList)
        if #decoded > 0 then
            self.CurrentBindings[actionName] = decoded
            self:_bindAction(actionName, decoded)
        end
    end
end

function ContextBinder:GetSerializedBindings()
    local out = {}
    for actionName, list in pairs(self.CurrentBindings) do
        out[actionName] = BindingCodec.EncodeList(list)
    end
    return out
end

function ContextBinder:Destroy()
    for actionName in pairs(self.CurrentBindings) do
        ContextActionService:UnbindAction("Controller_" .. actionName)
    end
end

-- DeviceSampler ------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local DeviceSampler = {}
DeviceSampler.__index = DeviceSampler

function DeviceSampler.new(actionState)
    local self = setmetatable({}, DeviceSampler)
    self.ActionState = actionState
    self.MoveVector = Vector2.zero
    self.LookDelta = Vector2.zero
    self.GamepadMove = Vector2.zero
    self.GamepadLook = Vector2.zero
    self.Connections = {}
    return self
end

function DeviceSampler:Start()
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        local x = 0
        local y = 0
        if self.ActionState:IsHeld("MoveRight") then x += 1 end
        if self.ActionState:IsHeld("MoveLeft") then x -= 1 end
        if self.ActionState:IsHeld("MoveForward") then y += 1 end
        if self.ActionState:IsHeld("MoveBackward") then y -= 1 end
        local keyboard = Vector2.new(x, y)
        if keyboard.Magnitude > 1 then keyboard = keyboard.Unit end
        self.MoveVector = keyboard.Magnitude > 0 and keyboard or self.GamepadMove
    end))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self.LookDelta = Vector2.new(input.Delta.X, input.Delta.Y)
        elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
            self.GamepadMove = Vector2.new(input.Position.X, input.Position.Y)
        elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
            self.GamepadLook = Vector2.new(input.Position.X, -input.Position.Y)
        end
    end))
end

function DeviceSampler:GetMoveVector()
    return self.MoveVector
end

function DeviceSampler:GetLookDelta()
    local mouse = self.LookDelta
    self.LookDelta = Vector2.zero
    return mouse + self.GamepadLook * 8
end

function DeviceSampler:Destroy()
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    table.clear(self.Connections)
end

-- Main ------------------------------------------------------------

local InputClient = {}
InputClient.__index = InputClient

function InputClient.new(clientState)
    local self = setmetatable({}, InputClient)
    self.State = clientState
    self.Actions = ActionState.new()
    self.Binder = ContextBinder.new(self.Actions)
    self.Sampler = DeviceSampler.new(self.Actions)
    self.BindingCodec = BindingCodec
    return self
end

function InputClient:Start()
    self.Binder:BindDefaults()
    self.Sampler:Start()
end

function InputClient:Destroy()
    self.Binder:Destroy()
    self.Sampler:Destroy()
end

function InputClient:ApplyRebinds(rebinds)
    self.Binder:ApplyRebinds(rebinds)
end

function InputClient:GetSerializedBindings()
    return self.Binder:GetSerializedBindings()
end

function InputClient:IsHeld(action)
    return self.Actions:IsHeld(action)
end

function InputClient:ConsumePressed(action)
    return self.Actions:ConsumePressed(action)
end

function InputClient:GetMoveVector()
    return self.Sampler:GetMoveVector()
end

function InputClient:GetLookDelta()
    return self.Sampler:GetLookDelta()
end

return InputClient
