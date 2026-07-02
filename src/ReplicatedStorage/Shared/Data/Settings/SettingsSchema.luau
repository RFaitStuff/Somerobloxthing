--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputBindings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("InputBindings"))

local SettingsSchema = {}

SettingsSchema.Version = 1

SettingsSchema.Fields = {
    MouseSensitivity = { Type = "number", Default = 1, Min = 0.2, Max = 3 },
    GamepadSensitivity = { Type = "number", Default = 1, Min = 0.2, Max = 3 },
    InvertY = { Type = "boolean", Default = false },
    ToggleCrouch = { Type = "boolean", Default = true },
    UiScale = { Type = "number", Default = 1, Min = 0.75, Max = 1.4 },
    CameraFov = { Type = "number", Default = 70, Min = 60, Max = 90 },
    ChatEnabled = { Type = "boolean", Default = true },
    ShowTradeChat = { Type = "boolean", Default = true },
    ShowDamageNumbers = { Type = "boolean", Default = true },
    ReduceMotion = { Type = "boolean", Default = false },
}

function SettingsSchema.GetDefaults()
    local settings = {}
    for key, def in pairs(SettingsSchema.Fields) do
        settings[key] = def.Default
    end
    return settings
end

function SettingsSchema.SanitizeSettings(input)
    local settings = SettingsSchema.GetDefaults()
    if typeof(input) ~= "table" then return settings end
    for key, def in pairs(SettingsSchema.Fields) do
        local value = input[key]
        if def.Type == "number" then
            local numberValue = tonumber(value)
            if numberValue then
                settings[key] = math.clamp(numberValue, def.Min or -math.huge, def.Max or math.huge)
            end
        elseif def.Type == "boolean" and typeof(value) == "boolean" then
            settings[key] = value
        elseif def.Type == "string" and type(value) == "string" then
            settings[key] = string.sub(value, 1, def.MaxLength or 64)
        end
    end
    return settings
end

local function isEncodedInput(value)
    if type(value) ~= "string" then return false end
    local enumType, itemName = value:match("^([^:]+):(.+)$")
    if not enumType or not itemName then return false end
    local enum = Enum[enumType]
    return enum ~= nil and enum[itemName] ~= nil
end

function SettingsSchema.SanitizeRebinds(input)
    local rebinds = {}
    if typeof(input) ~= "table" then return rebinds end
    for actionName, encodedList in pairs(input) do
        if InputBindings.Actions[actionName] and typeof(encodedList) == "table" then
            local clean = {}
            for _, encoded in ipairs(encodedList) do
                if isEncodedInput(encoded) then
                    table.insert(clean, encoded)
                end
                if #clean >= 4 then break end
            end
            if #clean > 0 then
                rebinds[actionName] = clean
            end
        end
    end
    return rebinds
end

function SettingsSchema.SanitizePayload(payload)
    payload = typeof(payload) == "table" and payload or {}
    return {
        Version = SettingsSchema.Version,
        Settings = SettingsSchema.SanitizeSettings(payload.Settings),
        Rebinds = SettingsSchema.SanitizeRebinds(payload.Rebinds),
    }
end

return SettingsSchema
