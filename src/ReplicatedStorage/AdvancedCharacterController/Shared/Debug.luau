--!nonstrict
local Config = require(script.Parent:WaitForChild("Config"))

local Debug = {}
Debug.Channels = {
    Startup = "Startup",
    Network = "Network",
    Movement = "Movement",
    Combat = "Combat",
    Status = "Status",
    Validation = "Validation",
}

local debugConfig = Config.Debug or {}
local channelConfig = debugConfig.Channels or {}

local function isChannelEnabled(channel)
    if debugConfig.Enabled == false then return false end
    if debugConfig.LogsEnabled ~= true then return false end
    if channelConfig[channel] == nil then return debugConfig.DefaultChannelEnabled == true end
    return channelConfig[channel] == true
end

local function formatMessage(level, channel, message)
    return string.format("[Controller:%s:%s] %s", tostring(level), tostring(channel), tostring(message))
end

function Debug.IsEnabled(channel)
    return isChannelEnabled(channel)
end

function Debug.Log(channel, message, ...)
    if not isChannelEnabled(channel) then return end
    print(formatMessage("Info", channel, string.format(tostring(message), ...)))
end

function Debug.Warn(channel, message, ...)
    if not isChannelEnabled(channel) then return end
    warn(formatMessage("Warn", channel, string.format(tostring(message), ...)))
end

function Debug.Error(channel, message, ...)
    warn(formatMessage("Error", channel, string.format(tostring(message), ...)))
end

function Debug.Try(channel, label, callback, ...)
    local args = table.pack(...)
    local result = table.pack(xpcall(function()
        return callback(table.unpack(args, 1, args.n))
    end, debug.traceback))
    if not result[1] then
        Debug.Error(channel, "%s failed:\n%s", label, result[2])
        return false
    end
    return true, table.unpack(result, 2, result.n)
end

return Debug
