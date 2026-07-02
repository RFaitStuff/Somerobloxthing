--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Rooms = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Rooms"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local RoomService = {}
RoomService.__index = RoomService

function RoomService.new(profiles, playerState)
    return setmetatable({ Profiles = profiles, PlayerState = playerState, Remote = nil, InstancesFolder = nil }, RoomService)
end

function RoomService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.RoomRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    self.InstancesFolder = Workspace:FindFirstChild("PlayerRooms")
    if not self.InstancesFolder then
        self.InstancesFolder = Instance.new("Folder")
        self.InstancesFolder.Name = "PlayerRooms"
        self.InstancesFolder.Parent = Workspace
    end
end

function RoomService:GetSnapshot(player)
    local profile = self.Profiles:Get(player)
    return {
        Room = profile.Room,
        Templates = Rooms.Templates,
        Decorations = Rooms.Decorations,
        OwnedTemplates = profile.Inventory.RoomTemplates,
        OwnedDecorations = profile.Inventory.Decorations,
        Materials = profile.Inventory.Materials,
        Directory = self:GetRoomDirectory(player),
        Visitors = self:GetVisitors(player),
    }
end

function RoomService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.RoomUpdate):FireClient(player, self:GetSnapshot(player))
end

function RoomService:GetRoomFolder(player)
    local root = self.InstancesFolder or Workspace:FindFirstChild("PlayerRooms")
    if not root then return nil end
    local name = tostring(player.UserId)
    local folder = root:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder:SetAttribute("OwnerUserId", player.UserId)
        folder.Parent = root
    end
    return folder
end

function RoomService:GetTemplateModel(templateId)
    local assets = ServerStorage:FindFirstChild("ServerAssets")
    local rooms = assets and assets:FindFirstChild("Rooms")
    local model = rooms and rooms:FindFirstChild(templateId)
    return model and model:IsA("Model") and model or nil
end

function RoomService:GetDecorationModel(decorationId)
    local assets = ServerStorage:FindFirstChild("ServerAssets")
    local decorations = assets and assets:FindFirstChild("Decorations")
    local model = decorations and decorations:FindFirstChild(decorationId)
    return model and model:IsA("Model") and model or nil
end

local function clearFolder(folder)
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end
end

local function makePart(parent, name, size, cframe, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function RoomService:GetRoomOrigin(player)
    local index = math.max(0, player.UserId % 1000)
    local column = index % 20
    local row = math.floor(index / 20)
    return CFrame.new(1000 + column * 140, 40, row * 140)
end

function RoomService:BuildPlaceholderShell(parent, template, origin)
    local bounds = template.Bounds or Vector3.new(48, 22, 48)
    makePart(parent, "Floor", Vector3.new(bounds.X, 1, bounds.Z), origin * CFrame.new(0, 0, 0), Color3.fromRGB(35, 39, 46))
    makePart(parent, "BackWall", Vector3.new(bounds.X, bounds.Y, 1), origin * CFrame.new(0, bounds.Y / 2, -bounds.Z / 2), Color3.fromRGB(22, 27, 35))
    makePart(parent, "LeftWall", Vector3.new(1, bounds.Y, bounds.Z), origin * CFrame.new(-bounds.X / 2, bounds.Y / 2, 0), Color3.fromRGB(24, 29, 37))
    makePart(parent, "RightWall", Vector3.new(1, bounds.Y, bounds.Z), origin * CFrame.new(bounds.X / 2, bounds.Y / 2, 0), Color3.fromRGB(24, 29, 37))
    local spawn = makePart(parent, "RoomSpawn", Vector3.new(4, 0.25, 4), origin * CFrame.new(0, 1, bounds.Z / 2 - 7), Color3.fromRGB(72, 132, 164))
    spawn.Transparency = 0.35
    spawn.CanCollide = false
    return spawn.CFrame + Vector3.new(0, 3, 0)
end

function RoomService:PlaceRenderedDecoration(parent, origin, placed)
    local decoration = Rooms.GetDecoration(placed.DecorationId)
    if not decoration then return end

    local position = typeof(placed.Position) == "Vector3" and placed.Position or Vector3.zero
    local rotation = typeof(placed.Rotation) == "Vector3" and placed.Rotation or Vector3.zero
    local cframe = origin * CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
    local model = self:GetDecorationModel(placed.DecorationId)
    if model then
        local clone = model:Clone()
        clone.Name = placed.ItemId or placed.DecorationId
        clone:SetAttribute("DecorationId", placed.DecorationId)
        clone:PivotTo(cframe)
        clone.Parent = parent
        return
    end

    local part = makePart(parent, placed.ItemId or placed.DecorationId, decoration.Size or Vector3.new(3, 3, 3), cframe, Color3.fromRGB(90, 115, 135))
    part:SetAttribute("DecorationId", placed.DecorationId)
end

function RoomService:SanitizeTransform(template, transform)
    local bounds = template and template.Bounds or Vector3.new(48, 22, 48)
    local position = typeof(transform) == "table" and transform.Position or Vector3.zero
    local rotation = typeof(transform) == "table" and transform.Rotation or Vector3.zero
    if typeof(position) ~= "Vector3" then position = Vector3.zero end
    if typeof(rotation) ~= "Vector3" then rotation = Vector3.zero end

    local inset = 3
    position = Vector3.new(
        math.clamp(position.X, -bounds.X / 2 + inset, bounds.X / 2 - inset),
        math.clamp(position.Y, 1, math.max(1, bounds.Y - inset)),
        math.clamp(position.Z, -bounds.Z / 2 + inset, bounds.Z / 2 - inset)
    )
    rotation = Vector3.new(0, math.clamp(rotation.Y, -360, 360), 0)
    return position, rotation
end

function RoomService:RenderRoom(player)
    local profile = self.Profiles:Get(player)
    local template = Rooms.GetTemplate(profile.Room.TemplateId) or Rooms.GetTemplate("OrbiterPod")
    if not template then return nil end
    local folder = self:GetRoomFolder(player)
    if not folder then return nil end
    clearFolder(folder)
    folder:SetAttribute("TemplateId", template.Id)
    folder:SetAttribute("RoomName", profile.Room.Name or template.DisplayName)
    folder:SetAttribute("Privacy", profile.Room.Privacy or "Private")

    local origin = self:GetRoomOrigin(player)
    local spawnCFrame
    local templateModel = self:GetTemplateModel(template.Id)
    if templateModel then
        local clone = templateModel:Clone()
        clone.Name = "RoomModel"
        clone:PivotTo(origin)
        clone.Parent = folder
        local spawnPart = clone:FindFirstChild("RoomSpawn", true)
        spawnCFrame = spawnPart and spawnPart:IsA("BasePart") and (spawnPart.CFrame + Vector3.new(0, 3, 0)) or (origin + Vector3.new(0, 4, 0))
    else
        spawnCFrame = self:BuildPlaceholderShell(folder, template, origin)
    end

    local decorationsFolder = Instance.new("Folder")
    decorationsFolder.Name = "Decorations"
    decorationsFolder.Parent = folder
    for _, placed in pairs(profile.Room.Placed or {}) do
        self:PlaceRenderedDecoration(decorationsFolder, origin, placed)
    end
    return spawnCFrame
end

function RoomService:GetVisitors(owner)
    local visitors = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local state = self.PlayerState and self.PlayerState:Get(player)
        if state and state.LocationId == "Room" and state.RoomOwnerUserId == owner.UserId then
            table.insert(visitors, {
                UserId = player.UserId,
                Name = player.Name,
                DisplayName = player.DisplayName,
                IsOwner = player == owner,
            })
        end
    end
    table.sort(visitors, function(a, b)
        return tostring(a.DisplayName or a.Name) < tostring(b.DisplayName or b.Name)
    end)
    return visitors
end

function RoomService:SameClan(player, owner)
    if player == owner then return true end
    if not self.Profiles.GetClan then return false end
    local clan = self.Profiles:GetClan(player)
    local ownerClan = self.Profiles:GetClan(owner)
    return clan and ownerClan and clan.ClanId == ownerClan.ClanId
end

function RoomService:CanVisitRoom(visitor, owner)
    if not visitor or not owner then return false, "InvalidOwner" end
    if visitor == owner then return true end
    local profile = self.Profiles:Get(owner)
    local room = profile.Room or {}
    local privacy = room.Privacy or "Private"
    if privacy == "Public" then return true end
    if privacy == "Clan" then
        return self:SameClan(visitor, owner), "ClanOnly"
    end
    if privacy == "Friends" then
        local ok, isFriend = pcall(function()
            return visitor:IsFriendsWith(owner.UserId)
        end)
        return ok and isFriend == true, "FriendsOnly"
    end
    if privacy == "Invite" then
        return room.Invites and room.Invites[tostring(visitor.UserId)] == true, "InviteOnly"
    end
    return false, "Private"
end

function RoomService:GetRoomDirectory(viewer)
    local entries = {}
    for _, owner in ipairs(Players:GetPlayers()) do
        local profile = self.Profiles:Get(owner)
        local room = profile.Room or {}
        local canVisit, reason = self:CanVisitRoom(viewer, owner)
        table.insert(entries, {
            OwnerUserId = owner.UserId,
            OwnerName = owner.Name,
            OwnerDisplayName = owner.DisplayName,
            RoomName = room.Name or "Orbiter Room",
            TemplateId = room.TemplateId or "OrbiterPod",
            Privacy = room.Privacy or "Private",
            CanVisit = canVisit == true,
            LockReason = canVisit and nil or reason,
            Visitors = #self:GetVisitors(owner),
        })
    end
    table.sort(entries, function(a, b)
        if a.CanVisit ~= b.CanVisit then return a.CanVisit end
        return tostring(a.OwnerDisplayName or a.OwnerName) < tostring(b.OwnerDisplayName or b.OwnerName)
    end)
    return entries
end

function RoomService:FindPlayerByUserId(userId)
    userId = tonumber(userId)
    if not userId then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then return player end
    end
    return nil
end

function RoomService:FindPlayerByName(name)
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

function RoomService:TeleportToRoom(player, owner)
    owner = owner or player
    local canVisit, reason = self:CanVisitRoom(player, owner)
    if not canVisit then return false, reason end
    local spawnCFrame = self:RenderRoom(owner)
    local state = self.PlayerState and self.PlayerState:Get(player)
    if state then
        state.LocationId = "Room"
        state.SafeZone = true
        state.TrainingRange = false
        state.RoomOwnerUserId = owner.UserId
        state.ActiveMission = nil
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if spawnCFrame and root then
        root.CFrame = spawnCFrame
    end
    self:Replicate(player)
    if owner ~= player then self:Replicate(owner) end
    return spawnCFrame ~= nil
end

function RoomService:VisitRoom(player, ownerUserId)
    local owner = self:FindPlayerByUserId(ownerUserId)
    if not owner then return false, "OwnerOffline" end
    return self:TeleportToRoom(player, owner)
end

function RoomService:InvitePlayer(owner, targetName)
    local target = self:FindPlayerByName(targetName)
    if not target or target == owner then return false, "InvalidInviteTarget" end
    local profile = self.Profiles:Get(owner)
    profile.Room.Invites = profile.Room.Invites or {}
    profile.Room.Invites[tostring(target.UserId)] = true
    self.Profiles:Replicate(owner)
    self:Replicate(owner)
    self:Replicate(target)
    return true
end

function RoomService:RevokeInvite(owner, targetUserId)
    local profile = self.Profiles:Get(owner)
    profile.Room.Invites = profile.Room.Invites or {}
    profile.Room.Invites[tostring(targetUserId)] = nil
    self.Profiles:Replicate(owner)
    self:Replicate(owner)
    local target = self:FindPlayerByUserId(targetUserId)
    if target then self:Replicate(target) end
    return true
end

function RoomService:SetTemplate(player, templateId)
    local profile = self.Profiles:Get(player)
    if not Rooms.GetTemplate(templateId) or not profile.Inventory.RoomTemplates[templateId] then return false end
    profile.Room.TemplateId = templateId
    self:RenderRoom(player)
    self.Profiles:Replicate(player)
    self:Replicate(player)
    return true
end

function RoomService:CanUnlockTemplate(player, templateId)
    local template = Rooms.GetTemplate(templateId)
    if not template then return false, "InvalidTemplate" end
    local profile = self.Profiles:Get(player)
    if profile.Inventory.RoomTemplates[templateId] then return false, "AlreadyOwned" end
    local unlock = template.Unlock or {}
    if unlock.Type == "Mastery" and (profile.MasteryRank or 0) < (unlock.Rank or 0) then
        return false, "MasteryTooLow"
    end
    local canSpend, missing = self.Profiles:CanSpendMaterials(player, template.Costs or {})
    if not canSpend then return false, "MissingMaterial:" .. tostring(missing) end
    return true
end

function RoomService:PurchaseTemplate(player, templateId)
    local ok, reason = self:CanUnlockTemplate(player, templateId)
    if not ok then return false, reason end
    local template = Rooms.GetTemplate(templateId)
    local spent, missing = self.Profiles:SpendMaterials(player, template.Costs or {})
    if not spent then return false, "MissingMaterial:" .. tostring(missing) end
    if not self.Profiles:GrantCraftedOutput(player, "RoomTemplate", templateId, 1) then
        for materialId, amount in pairs(template.Costs or {}) do
            self.Profiles:GrantMaterial(player, materialId, amount)
        end
        return false, "GrantFailed"
    end
    self:Replicate(player)
    return true
end

function RoomService:SetPrivacy(player, privacy)
    local allowed = false
    for _, value in ipairs(Rooms.Privacy) do
        if value == privacy then allowed = true break end
    end
    if not allowed then return false end
    self.Profiles:Get(player).Room.Privacy = privacy
    self:RenderRoom(player)
    self.Profiles:Replicate(player)
    self:Replicate(player)
    return true
end

function RoomService:PlaceDecoration(player, decorationId, transform)
    local profile = self.Profiles:Get(player)
    local decoration = Rooms.GetDecoration(decorationId)
    if not decoration then return false end
    if (profile.Inventory.Decorations[decorationId] or 0) <= 0 then return false end
    local template = Rooms.GetTemplate(profile.Room.TemplateId)
    local placedCount = 0
    for _ in pairs(profile.Room.Placed or {}) do placedCount += 1 end
    if template and placedCount >= (template.SlotLimit or 35) then return false end

    profile.Inventory.Decorations[decorationId] -= 1
    local itemId = HttpService:GenerateGUID(false)
    local position, rotation = self:SanitizeTransform(template, transform)
    profile.Room.Placed[itemId] = {
        ItemId = itemId,
        DecorationId = decorationId,
        Position = position,
        Rotation = rotation,
    }
    self:RenderRoom(player)
    self.Profiles:Replicate(player)
    self:Replicate(player)
    return true
end

function RoomService:RemoveDecoration(player, itemId)
    local profile = self.Profiles:Get(player)
    local placed = profile.Room.Placed and profile.Room.Placed[itemId]
    if not placed then return false end
    profile.Room.Placed[itemId] = nil
    profile.Inventory.Decorations[placed.DecorationId] = (profile.Inventory.Decorations[placed.DecorationId] or 0) + 1
    self:RenderRoom(player)
    self.Profiles:Replicate(player)
    self:Replicate(player)
    return true
end

function RoomService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Room", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "EnterRoom" then
        local ok, reason = self:TeleportToRoom(player)
        if not ok then ValidationAudit.Reject(player, "Room", reason or "EnterFailed") end
    elseif payload.Action == "VisitRoom" then
        local ok, reason = self:VisitRoom(player, payload.OwnerUserId)
        if not ok then ValidationAudit.Reject(player, "Room", reason or "VisitFailed") end
    elseif payload.Action == "InvitePlayer" then
        local ok, reason = self:InvitePlayer(player, payload.TargetName)
        if not ok then ValidationAudit.Reject(player, "Room", reason or "InviteFailed") end
    elseif payload.Action == "RevokeInvite" then
        local ok, reason = self:RevokeInvite(player, payload.TargetUserId)
        if not ok then ValidationAudit.Reject(player, "Room", reason or "RevokeFailed") end
    elseif payload.Action == "SetTemplate" then
        if not self:SetTemplate(player, payload.TemplateId) then ValidationAudit.Reject(player, "Room", "InvalidTemplate") end
    elseif payload.Action == "PurchaseTemplate" then
        local ok, reason = self:PurchaseTemplate(player, payload.TemplateId)
        if not ok then ValidationAudit.Reject(player, "Room", reason or "PurchaseTemplateFailed") end
    elseif payload.Action == "SetPrivacy" then
        if not self:SetPrivacy(player, payload.Privacy) then ValidationAudit.Reject(player, "Room", "InvalidPrivacy") end
    elseif payload.Action == "PlaceDecoration" then
        if not self:PlaceDecoration(player, payload.DecorationId, payload.Transform) then ValidationAudit.Reject(player, "Room", "InvalidPlacement") end
    elseif payload.Action == "RemoveDecoration" then
        if not self:RemoveDecoration(player, payload.ItemId) then ValidationAudit.Reject(player, "Room", "InvalidRemove") end
    else
        ValidationAudit.Reject(player, "Room", "UnknownAction")
    end
end

return RoomService
