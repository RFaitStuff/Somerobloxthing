--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local ClanConfig = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("ClanConfig"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local ClanService = {}
ClanService.__index = ClanService

function ClanService.new(profiles)
    return setmetatable({
        Profiles = profiles,
        Remote = nil,
        Rosters = {},
    }, ClanService)
end

function ClanService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.ClanRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function ClanService:GetClanId(player)
    local clan = self.Profiles:GetClan(player)
    return clan and clan.ClanId or nil
end

function ClanService:GetSnapshot(player)
    local clan = self.Profiles:GetClan(player)
    local roster = clan and self.Rosters[clan.ClanId] or nil
    return {
        Clan = clan,
        Roster = roster or {},
        Config = {
            MaxMembers = ClanConfig.MaxMembers,
            MaxNameLength = ClanConfig.MaxNameLength,
            MaxTagLength = ClanConfig.MaxTagLength,
        },
    }
end

function ClanService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.ClanUpdate):FireClient(player, self:GetSnapshot(player))
end

function ClanService:ReplicateClan(clanId)
    for player in pairs(self.Profiles.Profiles) do
        local clan = self.Profiles:GetClan(player)
        if clan and clan.ClanId == clanId then
            self:Replicate(player)
        end
    end
end

function ClanService:AddRosterMember(player, clanData)
    self.Rosters[clanData.ClanId] = self.Rosters[clanData.ClanId] or {}
    self.Rosters[clanData.ClanId][player.UserId] = {
        UserId = player.UserId,
        Name = player.DisplayName or player.Name,
        Rank = clanData.Rank or "Member",
        Joined = clanData.Joined or os.time(),
    }
end

function ClanService:SyncPlayer(player)
    local clan = self.Profiles:GetClan(player)
    if clan then
        self:AddRosterMember(player, clan)
    end
    self:Replicate(player)
end

function ClanService:Create(player, name, tag)
    if self.Profiles:GetClan(player) then return false, "AlreadyInClan" end
    local clanId = HttpService:GenerateGUID(false)
    local clanData = {
        ClanId = clanId,
        Name = ClanConfig.SanitizeName(name),
        Tag = ClanConfig.SanitizeTag(tag),
        Rank = "Founder",
        Joined = os.time(),
    }
    self.Profiles:SetClan(player, clanData)
    self:AddRosterMember(player, clanData)
    self:Replicate(player)
    return true
end

function ClanService:JoinDev(player)
    if self.Profiles:GetClan(player) then return false, "AlreadyInClan" end
    local clanId = "DEV_CLAN"
    local clanData = {
        ClanId = clanId,
        Name = "Dev Clan",
        Tag = "DEV",
        Rank = "Member",
        Joined = os.time(),
    }
    self.Profiles:SetClan(player, clanData)
    self:AddRosterMember(player, clanData)
    self:ReplicateClan(clanId)
    return true
end

function ClanService:Leave(player)
    local clan = self.Profiles:GetClan(player)
    if not clan then return false, "NotInClan" end
    local clanId = clan.ClanId
    local roster = self.Rosters[clanId]
    if roster then
        roster[player.UserId] = nil
    end
    self.Profiles:SetClan(player, nil)
    self:Replicate(player)
    self:ReplicateClan(clanId)
    return true
end

function ClanService:GetMembers(player)
    local clan = self.Profiles:GetClan(player)
    if not clan then return {} end
    local members = {}
    for userId in pairs(self.Rosters[clan.ClanId] or {}) do
        table.insert(members, userId)
    end
    return members
end

function ClanService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Clan", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "Create" then
        local ok, reason = self:Create(player, payload.Name, payload.Tag)
        if not ok then ValidationAudit.Reject(player, "Clan", reason or "CreateFailed") end
    elseif payload.Action == "JoinDevClan" then
        local ok, reason = self:JoinDev(player)
        if not ok then ValidationAudit.Reject(player, "Clan", reason or "JoinFailed") end
    elseif payload.Action == "Leave" then
        local ok, reason = self:Leave(player)
        if not ok then ValidationAudit.Reject(player, "Clan", reason or "LeaveFailed") end
    else
        ValidationAudit.Reject(player, "Clan", "UnknownAction")
    end
end

return ClanService
