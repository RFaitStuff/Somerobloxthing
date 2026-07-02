--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local ChatChannels = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("ChatChannels"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local SocialChatService = {}
SocialChatService.__index = SocialChatService

function SocialChatService.new(playerState, clanService)
    return setmetatable({ PlayerState = playerState, Clans = clanService, Remote = nil, LastSent = {} }, SocialChatService)
end

function SocialChatService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.SocialChatRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function SocialChatService:GetChannelStatus(player, channel)
    if not channel then return false, "InvalidChannel" end
    local state = self.PlayerState:Get(player)
    if channel.Scope == "Clan" and (not self.Clans or not self.Clans:GetClanId(player)) then
        return false, "NoClan"
    end
    if channel.Scope == "Party" and not (state.ActiveMission and state.ActiveMission.SessionId) then
        return false, "NoSquad"
    end
    if channel.Scope == "Room" and state.LocationId ~= "Room" then
        return false, "NotInRoom"
    end
    if channel.Scope == "Location" and channel.LocationId and state.LocationId ~= channel.LocationId then
        return false, "WrongLocation"
    end
    return true
end

function SocialChatService:GetAllowedChannels(player)
    local channels = {}
    for channelId, channel in pairs(ChatChannels.ById) do
        local copy = table.clone(channel)
        local available, reason = self:GetChannelStatus(player, channel)
        copy.Available = available
        copy.LockReason = reason
        channels[channelId] = copy
    end
    return channels, ChatChannels.Order
end

function SocialChatService:Filter(player, message)
    local ok, result = pcall(function()
        local filter = TextService:FilterStringAsync(message, player.UserId)
        return filter:GetNonChatStringForBroadcastAsync()
    end)
    if ok and type(result) == "string" then
        return result
    end
    return "[message unavailable]"
end

function SocialChatService:GetRecipients(player, channel)
    if channel.Scope == "System" then return {} end
    if channel.Scope == "Party" then
        local state = self.PlayerState:Get(player)
        local sessionId = state.ActiveMission and state.ActiveMission.SessionId
        if not sessionId then return { player } end
        local recipients = {}
        for other, otherState in pairs(self.PlayerState.States) do
            if otherState.ActiveMission and otherState.ActiveMission.SessionId == sessionId then
                table.insert(recipients, other)
            end
        end
        return recipients
    elseif channel.Scope == "Location" then
        local recipients = {}
        for other, otherState in pairs(self.PlayerState.States) do
            if (otherState.LocationId or "Hub") == (channel.LocationId or "Hub") then
                table.insert(recipients, other)
            end
        end
        return recipients
    elseif channel.Scope == "Room" then
        local state = self.PlayerState:Get(player)
        local roomOwner = state.RoomOwnerUserId or player.UserId
        local recipients = {}
        for other, otherState in pairs(self.PlayerState.States) do
            if (otherState.RoomOwnerUserId or other.UserId) == roomOwner then
                table.insert(recipients, other)
            end
        end
        return recipients
    elseif channel.Scope == "Clan" then
        if not self.Clans then return { player } end
        local clanId = self.Clans:GetClanId(player)
        if not clanId then return { player } end
        local recipients = {}
        for other in pairs(self.PlayerState.States) do
            if self.Clans:GetClanId(other) == clanId then
                table.insert(recipients, other)
            end
        end
        return recipients
    elseif channel.Scope == "Direct" then
        return { player }
    end
    return Players:GetPlayers()
end

function SocialChatService:FindPlayerByName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local lowered = string.lower(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == lowered or string.lower(player.DisplayName) == lowered then
            return player
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), lowered, 1, true) or string.find(string.lower(player.DisplayName), lowered, 1, true) then
            return player
        end
    end
    return nil
end

function SocialChatService:ResolveCommand(channelId, message)
    if type(message) ~= "string" then return channelId, message, nil end
    local command, rest = string.match(message, "^/(%S+)%s+(.+)$")
    if not command then return channelId, message, nil end
    command = string.lower(command)
    local aliases = {
        s = "Server",
        server = "Server",
        h = "Hub",
        hub = "Hub",
        sq = "Squad",
        squad = "Squad",
        c = "Clan",
        clan = "Clan",
        t = "Trade",
        trade = "Trade",
        r = "Room",
        room = "Room",
        w = "Whisper",
        whisper = "Whisper",
        tell = "Whisper",
    }
    local resolved = aliases[command]
    if not resolved then return channelId, message, nil end
    if resolved == "Whisper" then
        local targetName, whisperText = string.match(rest, "^(%S+)%s+(.+)$")
        return resolved, whisperText or "", targetName
    end
    return resolved, rest, nil
end

function SocialChatService:ReplicateChannels(player)
    local channels, order = self:GetAllowedChannels(player)
    Net.GetRemoteEvent(Net.RemoteEvents.SocialChatUpdate):FireClient(player, {
        Type = "Channels",
        Channels = channels,
        Order = order,
    })
end

function SocialChatService:Send(player, channelId, message)
    local targetName
    channelId, message, targetName = self:ResolveCommand(channelId, message)
    local channel = ChatChannels.Get(channelId or "Server")
    if not channel or channel.ReadOnly then return false, "InvalidChannel" end
    if type(message) ~= "string" or message == "" then return false, "EmptyMessage" end
    local available, lockReason = self:GetChannelStatus(player, channel)
    if not available then return false, lockReason or "ChannelUnavailable" end
    message = string.sub(message, 1, channel.MaxLength or 180)

    local now = os.clock()
    self.LastSent[player] = self.LastSent[player] or {}
    local last = self.LastSent[player][channel.Id] or 0
    if now - last < (channel.Cooldown or 0.6) then
        return false, "RateLimited"
    end
    self.LastSent[player][channel.Id] = now

    local filtered = self:Filter(player, message)
    local packet = {
        Type = "Message",
        MessageId = HttpService:GenerateGUID(false),
        ChannelId = channel.Id,
        ChannelName = channel.DisplayName,
        FromUserId = player.UserId,
        FromName = player.DisplayName or player.Name,
        Text = filtered,
        Sent = now,
    }
    local recipients = self:GetRecipients(player, channel)
    if channel.Scope == "Direct" then
        local target = self:FindPlayerByName(targetName)
        if not target then return false, "WhisperTargetMissing" end
        packet.TargetUserId = target.UserId
        packet.TargetName = target.DisplayName or target.Name
        packet.ChannelName = "Whisper"
        recipients = target == player and { player } or { player, target }
    end
    for _, recipient in ipairs(recipients) do
        Net.GetRemoteEvent(Net.RemoteEvents.SocialChatUpdate):FireClient(recipient, packet)
    end
    return true
end

function SocialChatService:System(player, text)
    Net.GetRemoteEvent(Net.RemoteEvents.SocialChatUpdate):FireClient(player, {
        Type = "Message",
        MessageId = "System:" .. tostring(os.clock()),
        ChannelId = "System",
        ChannelName = "System",
        FromName = "System",
        Text = text,
        Sent = os.clock(),
    })
end

function SocialChatService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Chat", "BadPayload") return end
    if payload.Action == "RequestChannels" then
        self:ReplicateChannels(player)
    elseif payload.Action == "Send" then
        local ok, reason = self:Send(player, payload.ChannelId, payload.Text)
        if not ok then ValidationAudit.Reject(player, "Chat", reason or "SendFailed") end
    else
        ValidationAudit.Reject(player, "Chat", "UnknownAction")
    end
end

return SocialChatService
