--!nonstrict
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local MatchmakingService = {}
MatchmakingService.__index = MatchmakingService

local QUEUE_TTL = 90

function MatchmakingService.new(playerState, missions, replicateCallback)
    return setmetatable({
        PlayerState = playerState,
        Missions = missions,
        Replicate = replicateCallback,
        Queues = {},
        Accumulator = 0,
        LocalDevMode = RunService:IsStudio() or game.PlaceId == 0,
    }, MatchmakingService)
end

function MatchmakingService:Start()
    RunService.Heartbeat:Connect(function(dt)
        self.Accumulator += dt
        if self.Accumulator < 1 then return end
        self.Accumulator = 0
        self:Update()
    end)
end

function MatchmakingService:GetQueueKey(locationId, nodeId)
    return tostring(locationId or "Unknown") .. ":" .. tostring(nodeId or "Unknown")
end

function MatchmakingService:GetMemoryQueue(key)
    local ok, queue = pcall(function()
        return MemoryStoreService:GetQueue("ActivityQueue:" .. key, QUEUE_TTL)
    end)
    return ok and queue or nil
end

function MatchmakingService:PublishQueueIntent(player, key, entry)
    local queue = self:GetMemoryQueue(key)
    if not queue then return end
    pcall(function()
        queue:AddAsync({
            UserId = player.UserId,
            SessionId = entry.SessionId,
            Joined = entry.Joined,
            Power = entry.Power,
        }, QUEUE_TTL)
    end)
end

function MatchmakingService:SetPlayerQueueState(player, status, payload)
    local state = self.PlayerState:Get(player)
    state.Matchmaking = payload or {}
    state.Matchmaking.Status = status
    state.Matchmaking.Updated = os.clock()
    if self.Replicate then
        self.Replicate(player, { Matchmaking = state.Matchmaking })
    end
end

function MatchmakingService:EnqueuePlayer(player, locationId, node, rule, power, options)
    options = options or {}
    local key = self:GetQueueKey(locationId, node.Id)
    local queue = self.Queues[key]
    if not queue then
        queue = { Key = key, LocationId = locationId, Node = node, Rule = rule, Entries = {}, Created = os.clock() }
        self.Queues[key] = queue
    end

    for _, entry in ipairs(queue.Entries) do
        if entry.Player == player then
            self:SetPlayerQueueState(player, "Queued", {
                LocationId = locationId,
                NodeId = node.Id,
                NodeName = node.DisplayName,
                QueueSize = #queue.Entries,
                MaxPlayers = rule.MaxPlayers or 4,
            })
            return true
        end
    end

    local entry = {
        Player = player,
        Joined = os.clock(),
        Power = power or 0,
        SessionId = HttpService:GenerateGUID(false),
        Solo = options.Solo == true or rule.Access == "Solo",
    }
    table.insert(queue.Entries, entry)
    self:PublishQueueIntent(player, key, entry)
    self:SetPlayerQueueState(player, "Queued", {
        LocationId = locationId,
        NodeId = node.Id,
        NodeName = node.DisplayName,
        QueueSize = #queue.Entries,
        MaxPlayers = rule.MaxPlayers or 4,
    })

    if self.LocalDevMode or entry.Solo then
        self:LaunchQueue(queue, { entry })
    end
    return true
end

function MatchmakingService:Cancel(player)
    for key, queue in pairs(self.Queues) do
        for index = #queue.Entries, 1, -1 do
            if queue.Entries[index].Player == player then
                table.remove(queue.Entries, index)
                self:SetPlayerQueueState(player, "Cancelled", {})
                if #queue.Entries == 0 then self.Queues[key] = nil end
                return true
            end
        end
    end
    self:SetPlayerQueueState(player, "None", {})
    return false
end

function MatchmakingService:TakeLaunchGroup(queue)
    local maxPlayers = math.max(1, queue.Rule.MaxPlayers or 4)
    local timeout = queue.Rule.QueueTimeout or 15
    if #queue.Entries >= maxPlayers or os.clock() - (queue.Entries[1] and queue.Entries[1].Joined or os.clock()) >= timeout then
        local group = {}
        while #group < maxPlayers and #queue.Entries > 0 do
            table.insert(group, table.remove(queue.Entries, 1))
        end
        return group
    end
    return nil
end

function MatchmakingService:LaunchQueue(queue, forcedGroup)
    local group = forcedGroup or self:TakeLaunchGroup(queue)
    if not group or #group == 0 then return false end
    if forcedGroup then
        local launchPlayers = {}
        for _, entry in ipairs(forcedGroup) do
            launchPlayers[entry.Player] = true
        end
        for index = #queue.Entries, 1, -1 do
            if launchPlayers[queue.Entries[index].Player] then
                table.remove(queue.Entries, index)
            end
        end
    end

    local players = {}
    for _, entry in ipairs(group) do
        if entry.Player and entry.Player.Parent then
            table.insert(players, entry.Player)
        end
    end
    if #players == 0 then return false end

    local sessionId = HttpService:GenerateGUID(false)
    local context = {
        LocationId = queue.LocationId,
        NodeId = queue.Node.Id,
        SessionId = sessionId,
        InstanceMode = queue.Rule.InstanceMode,
    }

    if self.LocalDevMode or not queue.Rule.PlaceId or queue.Rule.PlaceId == 0 then
        for _, player in ipairs(players) do
            self:SetPlayerQueueState(player, "LaunchedLocal", context)
            self.Missions:StartMission(player, queue.Rule.MissionId, context)
        end
        return true
    end

    local ok, reservedCode = pcall(function()
        return TeleportService:ReserveServer(queue.Rule.PlaceId)
    end)
    if not ok or not reservedCode then
        for _, player in ipairs(players) do
            self:SetPlayerQueueState(player, "TeleportFailedLocalFallback", context)
            self.Missions:StartMission(player, queue.Rule.MissionId, context)
        end
        return false
    end

    local teleportOptions = Instance.new("TeleportOptions")
    teleportOptions.ReservedServerAccessCode = reservedCode
    teleportOptions:SetTeleportData({
        SessionId = sessionId,
        LocationId = queue.LocationId,
        NodeId = queue.Node.Id,
        MissionId = queue.Rule.MissionId,
    })

    local teleportOk = pcall(function()
        TeleportService:TeleportAsync(queue.Rule.PlaceId, players, teleportOptions)
    end)
    if not teleportOk then
        for _, player in ipairs(players) do
            self:SetPlayerQueueState(player, "TeleportFailedLocalFallback", context)
            self.Missions:StartMission(player, queue.Rule.MissionId, context)
        end
        return false
    end

    for _, player in ipairs(players) do
        self:SetPlayerQueueState(player, "Teleporting", context)
    end
    return true
end

function MatchmakingService:Update()
    for key, queue in pairs(self.Queues) do
        for index = #queue.Entries, 1, -1 do
            local player = queue.Entries[index].Player
            if not player or not player.Parent then
                table.remove(queue.Entries, index)
            end
        end
        if #queue.Entries == 0 then
            self.Queues[key] = nil
        else
            self:LaunchQueue(queue)
        end
    end
end

return MatchmakingService
