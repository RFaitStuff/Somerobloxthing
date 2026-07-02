--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Abilities = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Abilities"))
local Mods = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mods"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local HubServices = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("HubServices"))
local Codex = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Codex"))
local ChatChannels = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("ChatChannels"))
local SettingsSchema = require(Shared:WaitForChild("Data"):WaitForChild("Settings"):WaitForChild("SettingsSchema"))

local HubConsole = {}
HubConsole.__index = HubConsole

local function make(parent, className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

function HubConsole.new(state, input)
    return setmetatable({
        State = state,
        Input = input,
        Gui = nil,
        Tabs = nil,
        Body = nil,
        Detail = nil,
        ActivePanel = "Navigation",
        DragModId = nil,
        ChatChannel = "Server",
        ChatBox = nil,
        Remotes = {},
        Connections = {},
    }, HubConsole)
end

function HubConsole:Start()
    self.Remotes.Hub = Net.GetRemoteEvent(Net.RemoteEvents.HubRequest)
    self.Remotes.Profile = Net.GetRemoteEvent(Net.RemoteEvents.ProfileRequest)
    self.Remotes.Inventory = Net.GetRemoteEvent(Net.RemoteEvents.InventoryRequest)
    self.Remotes.Crafting = Net.GetRemoteEvent(Net.RemoteEvents.CraftingRequest)
    self.Remotes.Mastery = Net.GetRemoteEvent(Net.RemoteEvents.MasteryRequest)
    self.Remotes.World = Net.GetRemoteEvent(Net.RemoteEvents.WorldRequest)
    self.Remotes.Story = Net.GetRemoteEvent(Net.RemoteEvents.StoryRequest)
    self.Remotes.Quest = Net.GetRemoteEvent(Net.RemoteEvents.QuestRequest)
    self.Remotes.Room = Net.GetRemoteEvent(Net.RemoteEvents.RoomRequest)
    self.Remotes.Marketplace = Net.GetRemoteEvent(Net.RemoteEvents.MarketplaceRequest)
    self.Remotes.Npc = Net.GetRemoteEvent(Net.RemoteEvents.NpcRequest)
    self.Remotes.Clan = Net.GetRemoteEvent(Net.RemoteEvents.ClanRequest)
    self.Remotes.Trade = Net.GetRemoteEvent(Net.RemoteEvents.TradeRequest)
    self.Remotes.ResourceNode = Net.GetRemoteEvent(Net.RemoteEvents.ResourceNodeRequest)
    self.Remotes.Training = Net.GetRemoteEvent(Net.RemoteEvents.TrainingRequest)
    self.Remotes.Chat = Net.GetRemoteEvent(Net.RemoteEvents.SocialChatRequest)
    self.Remotes.Settings = Net.GetRemoteFunction(Net.RemoteFunctions.Settings)
    self:Build()

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.H then
            self.Gui.Enabled = not self.Gui.Enabled
            if self.Gui.Enabled then
                self:RequestSnapshots()
                self:Refresh()
            end
        end
    end))

    local function bind(remoteName, apply)
        table.insert(self.Connections, Net.GetRemoteEvent(remoteName).OnClientEvent:Connect(function(payload)
            apply(payload)
            if self.Gui and self.Gui.Enabled then self:Refresh() end
        end))
    end
    bind(Net.RemoteEvents.HubUpdate, function(payload)
        self.State:ApplyHub(payload)
        if typeof(payload) == "table" then
            if payload.Type == "OpenPanel" then
                self.ActivePanel = payload.Panel or self.ActivePanel
                if self.Gui then self.Gui.Enabled = true end
                self:RequestSnapshots()
            elseif payload.Type == "HubRules" and payload.ActivePanel then
                self.ActivePanel = payload.ActivePanel
            elseif payload.ActivePanel then
                self.ActivePanel = payload.ActivePanel
            end
        end
    end)
    bind(Net.RemoteEvents.InventoryUpdate, function(payload) self.State:ApplyInventory(payload) end)
    bind(Net.RemoteEvents.CraftingUpdate, function(payload) self.State:ApplyCrafting(payload) end)
    bind(Net.RemoteEvents.MasteryUpdate, function(payload) self.State:ApplyMastery(payload) end)
    bind(Net.RemoteEvents.WorldUpdate, function(payload) self.State:ApplyWorld(payload) end)
    bind(Net.RemoteEvents.StoryUpdate, function(payload) self.State:ApplyStory(payload) end)
    bind(Net.RemoteEvents.QuestUpdate, function(payload) self.State:ApplyQuest(payload) end)
    bind(Net.RemoteEvents.RoomUpdate, function(payload) self.State:ApplyRoom(payload) end)
    bind(Net.RemoteEvents.MarketplaceUpdate, function(payload) self.State:ApplyMarketplace(payload) end)
    bind(Net.RemoteEvents.NpcUpdate, function(payload)
        self.State:ApplyNpc(payload)
        if payload and payload.Type == "Open" then
            self.ActivePanel = "Npc"
        end
    end)
    bind(Net.RemoteEvents.ClanUpdate, function(payload) self.State:ApplyClan(payload) end)
    bind(Net.RemoteEvents.TradeUpdate, function(payload) self.State:ApplyTrade(payload) end)
    bind(Net.RemoteEvents.ResourceNodeUpdate, function(payload) self.State:ApplyResourceNode(payload) end)
    bind(Net.RemoteEvents.TrainingUpdate, function(payload) self.State:ApplyTraining(payload) end)
    bind(Net.RemoteEvents.SocialChatUpdate, function(payload) self.State:ApplyChat(payload) end)

    self:RequestSnapshots()
end

function HubConsole:RequestSnapshots()
    self.Remotes.Hub:FireServer({ Action = "RequestHub" })
    self.Remotes.Inventory:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Crafting:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Mastery:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.World:FireServer({ Action = "RequestLocations" })
    self.Remotes.Story:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Quest:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Room:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Marketplace:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Clan:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Trade:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.ResourceNode:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Training:FireServer({ Action = "RequestSnapshot" })
    self.Remotes.Chat:FireServer({ Action = "RequestChannels" })
    local ok, settingsPayload = pcall(function()
        return self.Remotes.Settings:InvokeServer("Load")
    end)
    if ok and typeof(settingsPayload) == "table" then
        self.State:ApplySettings(settingsPayload.Settings)
    end
end

function HubConsole:Build()
    local gui = make(Players.LocalPlayer:WaitForChild("PlayerGui"), "ScreenGui", {
        Name = "HubConsole",
        ResetOnSpawn = false,
        Enabled = false,
    })
    self.Gui = gui

    local panel = make(gui, "Frame", {
        Size = UDim2.fromOffset(900, 620),
        Position = UDim2.new(0.5, -450, 0.5, -310),
        BackgroundColor3 = Color3.fromRGB(12, 15, 20),
        BorderSizePixel = 0,
    })
    make(panel, "UICorner", { CornerRadius = UDim.new(0, 8) })

    make(panel, "TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(245, 248, 252),
        Text = "Hub Console (H)",
    })

    self.Tabs = make(panel, "Frame", {
        Size = UDim2.fromOffset(172, 560),
        Position = UDim2.fromOffset(10, 48),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
    })
    make(self.Tabs, "UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    make(self.Tabs, "UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })

    self.Body = make(panel, "ScrollingFrame", {
        Size = UDim2.fromOffset(470, 560),
        Position = UDim2.fromOffset(192, 48),
        BackgroundColor3 = Color3.fromRGB(10, 13, 18),
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    make(self.Body, "UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    make(self.Body, "UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })

    self.Detail = make(panel, "TextLabel", {
        Size = UDim2.fromOffset(218, 560),
        Position = UDim2.fromOffset(672, 48),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Color3.fromRGB(220, 230, 240),
        Text = "",
    })
    make(self.Detail, "UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
    self:Refresh()
end

function HubConsole:Clear(container)
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
end

function HubConsole:Button(parent, text, callback)
    local button = make(parent, "TextButton", {
        Size = UDim2.new(1, -4, 0, 30),
        BackgroundColor3 = Color3.fromRGB(35, 45, 58),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(242, 246, 250),
        Text = text,
    })
    button.MouseButton1Click:Connect(callback)
    return button
end

function HubConsole:Label(text)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -4, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(130, 205, 255),
        Text = text,
    })
end

function HubConsole:Paragraph(text, height)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -4, 0, height or 64),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Color3.fromRGB(220, 230, 240),
        Text = text,
    })
end

function HubConsole:RefreshTabs()
    self:Clear(self.Tabs)
    for _, id in ipairs(HubServices.Order) do
        local service = HubServices.Get(id)
        self:Button(self.Tabs, (service.Panel == self.ActivePanel and "* " or "") .. service.DisplayName, function()
            self.ActivePanel = service.Panel
            self.Remotes.Hub:FireServer({ Action = "OpenPanel", ServiceId = service.Id })
            self:Refresh()
        end)
    end
    self:Button(self.Tabs, (self.ActivePanel == "Chat" and "* " or "") .. "Chat", function()
        self.ActivePanel = "Chat"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Story" and "* " or "") .. "Story", function()
        self.ActivePanel = "Story"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Quest" and "* " or "") .. "Quest", function()
        self.ActivePanel = "Quest"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Clan" and "* " or "") .. "Clan", function()
        self.ActivePanel = "Clan"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Trade" and "* " or "") .. "Trade", function()
        self.ActivePanel = "Trade"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Resources" and "* " or "") .. "Resources", function()
        self.ActivePanel = "Resources"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Npc" and "* " or "") .. "NPC", function()
        self.ActivePanel = "Npc"
        self:Refresh()
    end)
    self:Button(self.Tabs, (self.ActivePanel == "Settings" and "* " or "") .. "Settings", function()
        self.ActivePanel = "Settings"
        self:Refresh()
    end)
end

function HubConsole:Refresh()
    if not self.Body then return end
    self:RefreshTabs()
    self:Clear(self.Body)
    local panel = self.ActivePanel
    self.Detail.Text = self:GetDetailText()
    if panel == "Equipment" then
        self:RenderEquipment()
    elseif panel == "Mods" then
        self:RenderMods()
    elseif panel == "Crafting" then
        self:RenderCrafting()
    elseif panel == "Missions" or panel == "Navigation" then
        self:RenderNavigation()
    elseif panel == "Marketplace" then
        self:RenderMarketplace()
    elseif panel == "Room" then
        self:RenderRoom()
    elseif panel == "Training" then
        self:RenderTraining()
    elseif panel == "Codex" then
        self:RenderCodex()
    elseif panel == "Chat" then
        self:RenderChat()
    elseif panel == "Story" then
        self:RenderStory()
    elseif panel == "Quest" then
        self:RenderQuest()
    elseif panel == "Clan" then
        self:RenderClan()
    elseif panel == "Trade" then
        self:RenderTrade()
    elseif panel == "Resources" then
        self:RenderResources()
    elseif panel == "Npc" then
        self:RenderNpc()
    elseif panel == "Settings" then
        self:RenderSettings()
    end
end

function HubConsole:GetDetailText()
    local profile = self.State.Profile or {}
    local inv = self.State.Inventory or {}
    local mastery = self.State.Mastery or inv.Mastery or {}
    return table.concat({
        "Hub services are safe-zone panels.",
        "Weapons are blocked in hub except training.",
        "",
        string.format("Frame: %s", tostring(profile.SelectedFrameId or "None")),
        string.format("Power: %s", tostring(self.State.Power or 0)),
        string.format("Mastery: %s XP %s", tostring(mastery.Rank or profile.MasteryRank or 0), tostring(mastery.XP or profile.MasteryXP or 0)),
        string.format("Dragging mod: %s", tostring(self.DragModId or "None")),
    }, "\n")
end

function HubConsole:RenderEquipment()
    local profile = self.State.Profile or {}
    self:Label("Frames")
    for frameId, unlocked in pairs(profile.UnlockedFrames or {}) do
        if unlocked then
            local frame = Frames.Get(frameId)
            self:Button(self.Body, string.format("%s%s", profile.SelectedFrameId == frameId and "Selected " or "Select ", frame and frame.DisplayName or frameId), function()
                self.Remotes.Profile:FireServer({ Action = "SelectFrame", FrameId = frameId })
            end)
        end
    end
    local selectedFrame = Frames.Get(profile.SelectedFrameId)
    local frameState = profile.Frames and profile.Frames[profile.SelectedFrameId]
    if selectedFrame and frameState then
        self:Label("Ability Variants")
        for slot, slotData in pairs(selectedFrame.AbilitySlots or {}) do
            for _, abilityId in ipairs(slotData.Variants or {}) do
                local ability = Abilities.Get(abilityId)
                local selected = frameState.SelectedVariants and frameState.SelectedVariants[slot] == abilityId
                local locked = (frameState.Level or 1) < (slotData.UnlockLevel or 1)
                local label = string.format("%s Slot %s: %s%s", selected and "Using" or "Use", tostring(slot), ability and ability.Name or abilityId, locked and (" (L" .. tostring(slotData.UnlockLevel) .. ")") or "")
                self:Button(self.Body, label, function()
                    if not locked then
                        self.Remotes.Profile:FireServer({ Action = "SelectAbility", Slot = slot, AbilityId = abilityId })
                    end
                end)
            end
        end
    end

    self:Label("Weapons")
    local inventory = self.State.Inventory or {}
    for weaponId, state in pairs(inventory.Weapons or {}) do
        local def = Weapons.Get(weaponId)
        if def then
            self:Button(self.Body, string.format("%s L%s [%s]", def.Name or weaponId, tostring(state.Level or 1), def.Kind or ""), function()
                if def.Kind == "Ranged" then
                    Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest):FireServer({ Action = "Equip", Slot = "Active", WeaponId = weaponId })
                else
                    Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest):FireServer({ Action = "Equip", Slot = "Melee", WeaponId = weaponId })
                end
            end)
        end
    end
    self:Label("Armor")
    for uid, item in pairs(inventory.Armor or {}) do
        self:Button(self.Body, string.format("Equip %s (%s)", tostring(item.ArmorId), uid), function()
            self.Remotes.Inventory:FireServer({ Action = "EquipArmor", ItemUid = uid })
        end)
    end
    self:Label("Attachments")
    for uid, item in pairs(inventory.Attachments or {}) do
        self:Button(self.Body, string.format("%s [%s] (%s)", tostring(item.AttachmentId or uid), tostring(item.Slot or "Attachment"), uid), function() end)
    end
end

function HubConsole:RenderMods()
    local inventory = self.State.Inventory or {}
    self:Label("Owned Mods - click to pick up, then drop into slot")
    for modId, owned in pairs(inventory.Mods or {}) do
        local mod = Mods.Get(modId)
        self:Button(self.Body, string.format("%s R%s [%s]", mod and mod.Name or modId, tostring(owned.Rank or 0), mod and mod.Slot or "?"), function()
            self.DragModId = modId
            self:Refresh()
        end)
    end
    self:Label("Drop Targets")
    for _, group in ipairs({ "Frame", "Weapon", "Melee" }) do
        self:Button(self.Body, "Drop into " .. group .. " slot", function()
            if self.DragModId then
                self.Remotes.Inventory:FireServer({ Action = "EquipMod", Group = group, ModId = self.DragModId })
                self.DragModId = nil
            end
        end)
    end
    self:Label("Equipped Mods")
    for group, list in pairs(inventory.EquippedMods or {}) do
        for _, modId in ipairs(list) do
            self:Button(self.Body, string.format("%s: %s (remove)", group, modId), function()
                self.Remotes.Inventory:FireServer({ Action = "UnequipMod", Group = group, ModId = modId })
            end)
        end
    end
end

function HubConsole:RenderCrafting()
    local crafting = self.State.Crafting or {}
    self:Label("Materials")
    local materialLines = {}
    for materialId, amount in pairs(crafting.Materials or {}) do
        table.insert(materialLines, string.format("%s:%s", materialId, tostring(amount)))
    end
    table.sort(materialLines)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -4, 0, 42),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(220, 230, 240),
        Text = #materialLines > 0 and table.concat(materialLines, "  ") or "No materials yet",
    })
    self:Label("Recipes")
    for recipeId, recipe in pairs(crafting.Recipes or {}) do
        self:Button(self.Body, string.format("Start %s (%ss)", recipe.DisplayName or recipeId, tostring(recipe.TimeSeconds or 0)), function()
            self.Remotes.Crafting:FireServer({ Action = "StartRecipe", RecipeId = recipeId })
        end)
    end
    self:Label("Jobs")
    for jobId, job in pairs(crafting.Jobs or {}) do
        local remaining = math.max(0, math.floor((job.FinishAt or 0) - os.clock()))
        self:Button(self.Body, string.format("%s remaining %ss - claim if done", job.DisplayName or job.RecipeId, tostring(remaining)), function()
            self.Remotes.Crafting:FireServer({ Action = "ClaimJob", JobId = jobId })
        end)
    end
end

function HubConsole:RenderNavigation()
    self:Label("Navigation / Mission Board")
    local world = self.State.World or {}
    local visibleLocations = world.Locations or Locations.ById
    for locationId, location in pairs(visibleLocations) do
        self:Label(location.DisplayName or locationId)
        for _, node in ipairs(location.Nodes or {}) do
            local text = string.format("%s [%s P%s]", node.DisplayName or node.Id, node.NodeType or "Node", tostring(node.RecommendedPower or 0))
            self:Button(self.Body, "Solo " .. text, function()
                self.Remotes.World:FireServer({ Action = "StartSolo", LocationId = locationId, NodeId = node.Id })
            end)
            if node.NodeType ~= "PublicEvent" and node.Matchmaking ~= "Solo" then
                self:Button(self.Body, "Queue " .. text, function()
                    self.Remotes.World:FireServer({ Action = "QueueNode", LocationId = locationId, NodeId = node.Id })
                end)
            end
        end
    end
end

function HubConsole:RenderStory()
    local snapshot = self.State.Story or {}
    local story = snapshot.Story or {}
    local progress = snapshot.Progress or {}
    self:Label(story.DisplayName or snapshot.ActiveStoryId or "Story")
    if story.Description then
        make(self.Body, "TextLabel", {
            Size = UDim2.new(1, -4, 0, 48),
            BackgroundColor3 = Color3.fromRGB(17, 22, 30),
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(220, 230, 240),
            Text = story.Description,
        })
    end
    local nextStep = snapshot.NextStep
    if nextStep then
        self:Label("Current Objective: " .. tostring(nextStep.Title or nextStep.Id))
        self:Button(self.Body, "Start Current Story Node", function()
            self.Remotes.Story:FireServer({ Action = "StartNextStep" })
        end)
    else
        self:Label("Story complete for this arc")
    end
    self:Button(self.Body, "Refresh Story", function()
        self.Remotes.Story:FireServer({ Action = "RequestSnapshot" })
    end)
    self:Label("Unlocked Locations")
    local unlocked = {}
    for locationId, value in pairs(snapshot.UnlockedLocations or {}) do
        if value then table.insert(unlocked, locationId) end
    end
    table.sort(unlocked)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(220, 230, 240),
        Text = #unlocked > 0 and table.concat(unlocked, ", ") or "None",
    })
    self:Label("Campaign Steps")
    for _, step in ipairs(snapshot.Steps or {}) do
        local prefix = step.Completed and "[Done] " or (step.IsNext and "[Next] " or "[Locked] ")
        local location = step.LocationId and (" / " .. tostring(step.LocationId)) or ""
        self:Button(self.Body, prefix .. tostring(step.Title or step.Id) .. location, function()
            if step.IsNext then
                self.Remotes.Story:FireServer({ Action = "StartNextStep" })
            else
                self.Remotes.Story:FireServer({ Action = "RequestSnapshot" })
            end
        end)
    end
    self:Label("Studio Debug")
    for _, step in ipairs(snapshot.Steps or {}) do
        if not step.Completed then
            self:Button(self.Body, "Debug complete " .. tostring(step.Id), function()
                self.Remotes.Story:FireServer({ Action = "DebugCompleteStep", StepId = step.Id })
            end)
            break
        end
    end
end

function HubConsole:RenderQuest()
    local snapshot = self.State.Quest or {}
    local quest = snapshot.Quest or {}
    local progress = snapshot.Progress or {}
    local completedSteps = progress.CompletedSteps or {}
    self:Label(quest.DisplayName or snapshot.ActiveQuestId or "Quest")
    if quest.Description then
        make(self.Body, "TextLabel", {
            Size = UDim2.new(1, -4, 0, 52),
            BackgroundColor3 = Color3.fromRGB(17, 22, 30),
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(220, 230, 240),
            Text = quest.Description,
        })
    end
    self:Button(self.Body, "Refresh Quest", function()
        self.Remotes.Quest:FireServer({ Action = "RequestSnapshot" })
    end)
    self:Label("Quest Steps")
    for _, step in ipairs(quest.Steps or {}) do
        local prefix = completedSteps[step.Id] and "[Done] " or "[Open] "
        self:Button(self.Body, prefix .. tostring(step.Title or step.Id) .. " / " .. tostring(step.Type), function() end)
    end
end

function HubConsole:RenderMarketplace()
    local snapshot = self.State.Marketplace or {}
    local catalog = snapshot.Catalog or {}
    local wallet = snapshot.Wallet or {}
    local dallions = wallet.Dallions or {}
    self:Label(string.format("Wallet: %s Coins / %s Dallions", tostring(wallet.Coins or wallet.Credits or 0), tostring((dallions.Starter or 0) + (dallions.Tradeable or 0))))
    self:Label("Vendor Catalog")
    for _, listingId in ipairs(catalog.FeaturedOrder or {}) do
        local listing = catalog.Catalog and catalog.Catalog[listingId]
        if listing then
            local costParts = {}
            for currencyId, amount in pairs(listing.Cost or {}) do
                table.insert(costParts, tostring(amount) .. " " .. currencyId)
            end
            table.sort(costParts)
            self:Button(self.Body, string.format("Buy %s - %s", listing.DisplayName or listingId, table.concat(costParts, ", ")), function()
                self.Remotes.Marketplace:FireServer({ Action = "Buy", ListingId = listingId })
            end)
        end
    end
    self:Label("Later")
    self:Button(self.Body, "Player trading listings need escrow and anti-dupe validation", function() end)
    self:Button(self.Body, "Premium purchases should stay cosmetics/convenience-only", function() end)
end

function HubConsole:RenderRoom()
    local snapshot = self.State.Room or {}
    local room = snapshot.Room or {}
    self:Label((room.Name or "Orbiter Room") .. " / " .. tostring(room.Privacy or "Private"))
    self:Button(self.Body, "Enter / rebuild room preview", function()
        self.Remotes.Room:FireServer({ Action = "EnterRoom" })
    end)
    self:Button(self.Body, "Return to hub rules", function()
        self.Remotes.Hub:FireServer({ Action = "RequestHub" })
    end)
    self:Label("Room Templates")
    local ownedTemplates = snapshot.OwnedTemplates or {}
    local materials = snapshot.Materials or {}
    local mastery = self.State.Mastery or {}
    local rank = mastery.Rank or ((self.State.Profile or {}).MasteryRank) or 0
    local templateIds = {}
    for templateId in pairs(snapshot.Templates or {}) do
        table.insert(templateIds, templateId)
    end
    table.sort(templateIds, function(a, b)
        local ta = snapshot.Templates[a] or {}
        local tb = snapshot.Templates[b] or {}
        if (ta.Tier or 0) ~= (tb.Tier or 0) then
            return (ta.Tier or 0) < (tb.Tier or 0)
        end
        return tostring(ta.DisplayName or a) < tostring(tb.DisplayName or b)
    end)
    for _, templateId in ipairs(templateIds) do
        local template = snapshot.Templates[templateId]
        local owned = ownedTemplates[templateId] == true
        local costParts = {}
        for materialId, amount in pairs(template.Costs or {}) do
            local have = materials[materialId] or 0
            table.insert(costParts, string.format("%s %s/%s", materialId, tostring(have), tostring(amount)))
        end
        table.sort(costParts)
        local unlock = template.Unlock or {}
        local masteryText = unlock.Type == "Mastery" and (" MR" .. tostring(unlock.Rank or 0)) or ""
        local label = string.format("%s%s / slots %s / %s", tostring(template.DisplayName or templateId), masteryText, tostring(template.SlotLimit or 0), #costParts > 0 and table.concat(costParts, ", ") or "default")
        if owned then
            self:Button(self.Body, (room.TemplateId == templateId and "Using " or "Use ") .. label, function()
                self.Remotes.Room:FireServer({ Action = "SetTemplate", TemplateId = templateId })
            end)
        elseif unlock.Type == "Mastery" and rank < (unlock.Rank or 0) then
            self:Button(self.Body, "Locked " .. label, function() end)
        else
            self:Button(self.Body, "Buy " .. label, function()
                self.Remotes.Room:FireServer({ Action = "PurchaseTemplate", TemplateId = templateId })
            end)
        end
    end
    self:Label("Privacy")
    for _, privacy in ipairs({ "Private", "Friends", "Invite", "Clan", "Public" }) do
        self:Button(self.Body, privacy, function()
            self.Remotes.Room:FireServer({ Action = "SetPrivacy", Privacy = privacy })
        end)
    end
    self:Label("Invite Player")
    local inviteBox = make(self.Body, "TextBox", {
        Size = UDim2.new(1, -4, 0, 30),
        BackgroundColor3 = Color3.fromRGB(24, 30, 38),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(245, 248, 250),
        ClearTextOnFocus = false,
        PlaceholderText = "Player name or display name",
        Text = "",
    })
    self:Button(self.Body, "Invite to room", function()
        if inviteBox.Text ~= "" then
            self.Remotes.Room:FireServer({ Action = "InvitePlayer", TargetName = inviteBox.Text })
            inviteBox.Text = ""
        end
    end)
    self:Label("Invites")
    local inviteCount = 0
    for userId in pairs(room.Invites or {}) do
        inviteCount += 1
        self:Button(self.Body, "Revoke invite: " .. tostring(userId), function()
            self.Remotes.Room:FireServer({ Action = "RevokeInvite", TargetUserId = tonumber(userId) })
        end)
    end
    if inviteCount == 0 then
        self:Button(self.Body, "No active room invites", function() end)
    end
    self:Label("Room Directory")
    for _, entry in ipairs(snapshot.Directory or {}) do
        local ownerName = entry.OwnerDisplayName or entry.OwnerName or tostring(entry.OwnerUserId)
        local text = string.format("%s - %s [%s] visitors %s", tostring(ownerName), tostring(entry.RoomName or "Room"), tostring(entry.Privacy or "Private"), tostring(entry.Visitors or 0))
        if entry.CanVisit then
            self:Button(self.Body, "Visit " .. text, function()
                self.Remotes.Room:FireServer({ Action = "VisitRoom", OwnerUserId = entry.OwnerUserId })
            end)
        else
            self:Button(self.Body, "Locked " .. text .. " / " .. tostring(entry.LockReason or "Locked"), function() end)
        end
    end
    self:Label("Current Visitors")
    for _, visitor in ipairs(snapshot.Visitors or {}) do
        self:Button(self.Body, string.format("%s%s", visitor.DisplayName or visitor.Name or visitor.UserId, visitor.IsOwner and " (owner)" or ""), function() end)
    end
    self:Label("Place Decoration")
    local placedCount = 0
    for _ in pairs(room.Placed or {}) do placedCount += 1 end
    for decorationId, count in pairs(snapshot.OwnedDecorations or {}) do
        self:Button(self.Body, string.format("%s x%s", decorationId, tostring(count)), function()
            local x = ((placedCount % 6) - 2.5) * 5
            local z = -10 - math.floor(placedCount / 6) * 5
            self.Remotes.Room:FireServer({ Action = "PlaceDecoration", DecorationId = decorationId, Transform = { Position = Vector3.new(x, 2, z), Rotation = Vector3.zero } })
        end)
    end
    self:Label("Placed")
    for itemId, placed in pairs(room.Placed or {}) do
        self:Button(self.Body, string.format("Remove %s", placed.DecorationId or itemId), function()
            self.Remotes.Room:FireServer({ Action = "RemoveDecoration", ItemId = itemId })
        end)
    end
end

function HubConsole:RenderTraining()
    local snapshot = self.State.Training or {}
    local stats = snapshot.Stats or {}
    self:Label("Training Range")
    self:Button(self.Body, "Enter Shooting Range", function()
        self.Remotes.Hub:FireServer({ Action = "EnterTraining" })
    end)
    self:Button(self.Body, "Return To Hub Safe Zone", function()
        self.Remotes.Hub:FireServer({ Action = "RequestHub" })
    end)
    self:Label(string.format(
        "Damage %s / Hits %s / Kills %s / DPS %s",
        tostring(stats.Damage or 0),
        tostring(stats.Hits or 0),
        tostring(stats.Kills or 0),
        tostring(stats.Dps or 0)
    ))
    if stats.LastTargetId then
        self:Label(string.format("Last hit: %s for %s", tostring(stats.LastTargetId), tostring(stats.LastDamage or 0)))
    end
    self:Button(self.Body, "Reset Training Stats", function()
        self.Remotes.Training:FireServer({ Action = "ResetStats" })
    end)
    self:Button(self.Body, "Reset Targets", function()
        self.Remotes.Training:FireServer({ Action = "ResetTargets" })
    end)
    self:Button(self.Body, "Refresh Training Snapshot", function()
        self.Remotes.Training:FireServer({ Action = "RequestSnapshot" })
    end)
    self:Label("Targets")
    local targets = snapshot.Targets or {}
    for _, targetId in ipairs(snapshot.Order or {}) do
        local def = snapshot.Definitions and snapshot.Definitions[targetId]
        local target = targets[targetId] or {}
        self:Button(self.Body, string.format(
            "%s HP %s/%s SH %s/%s",
            tostring(def and def.DisplayName or targetId),
            tostring(math.floor(tonumber(target.Health) or 0)),
            tostring(target.MaxHealth or (def and def.Health) or "?"),
            tostring(math.floor(tonumber(target.Shield) or 0)),
            tostring(target.MaxShield or (def and def.Shield) or 0)
        ), function() end)
    end
end

function HubConsole:IsCodexEntryUnlocked(entry)
    local storySnapshot = self.State.Story or {}
    local progress = storySnapshot.Progress or (self.State.World and self.State.World.Story and self.State.World.Story.Progress) or {}
    local unlockedLocations = progress.UnlockedLocations or {}
    local completedSteps = progress.CompletedSteps or {}
    local unlock = entry.Unlock
    if not unlock then return true end
    if unlock.LocationId then
        return unlock.LocationId == "Moon" or unlockedLocations[unlock.LocationId] == true
    end
    if unlock.StoryStepId then
        return completedSteps[unlock.StoryStepId] == true
    end
    return true
end

function HubConsole:RenderCodex()
    self:Label("Codex / Archive")
    self:Paragraph("Discovered records from Moonveil, Atlas Shard, enemy origins, factions, and progression systems. Later this can be fed by scans, quests, enemy kills, and mission discoveries.", 52)

    local visibleByCategory = {}
    for _, entryId in ipairs(Codex.Order or {}) do
        local entry = Codex.Get(entryId)
        if entry and self:IsCodexEntryUnlocked(entry) then
            local category = entry.Category or "Story"
            visibleByCategory[category] = visibleByCategory[category] or {}
            table.insert(visibleByCategory[category], entry)
        end
    end

    for categoryId, category in pairs(Codex.Categories or {}) do
        local entries = visibleByCategory[categoryId]
        if entries and #entries > 0 then
            self:Label(category.DisplayName or categoryId)
            for _, entry in ipairs(entries) do
                local related = ""
                if entry.Related and #entry.Related > 0 then
                    related = "\nRelated: " .. table.concat(entry.Related, ", ")
                end
                self:Paragraph(string.format("%s\n%s\n%s%s", tostring(entry.DisplayName or entry.Id), tostring(entry.Summary or ""), tostring(entry.Body or ""), related), 112)
            end
        end
    end

    local lockedCount = 0
    for _, entry in pairs(Codex.Entries or {}) do
        if not self:IsCodexEntryUnlocked(entry) then lockedCount += 1 end
    end
    if lockedCount > 0 then
        self:Label(string.format("%s locked record(s)", tostring(lockedCount)))
    end
end

function HubConsole:RenderChat()
    self:Label("Channels")
    local chat = self.State.Chat or { Channels = {}, Messages = {} }
    local channels = chat.Channels or ChatChannels.ById
    local order = chat.Order or ChatChannels.Order
    for _, channelId in ipairs(order) do
        local channel = channels[channelId] or ChatChannels.Get(channelId)
        if channel and not channel.ReadOnly then
            local available = channel.Available ~= false
            local alias = channel.Alias and (" " .. channel.Alias) or ""
            local prefix = self.ChatChannel == channelId and "* " or ""
            local lock = available and "" or (" locked:" .. tostring(channel.LockReason or "Unavailable"))
            self:Button(self.Body, prefix .. tostring(channel.DisplayName or channelId) .. alias .. lock, function()
                if available then
                    self.ChatChannel = channelId
                    self:Refresh()
                end
            end)
        end
    end
    self:Paragraph("Shortcuts: /s server, /h hub, /sq squad, /c clan, /t trade, /r room, /w player message.", 42)
    local box = make(self.Body, "TextBox", {
        Size = UDim2.new(1, -4, 0, 32),
        BackgroundColor3 = Color3.fromRGB(24, 30, 38),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(245, 248, 250),
        ClearTextOnFocus = false,
        PlaceholderText = "Type message",
        Text = "",
    })
    self.ChatBox = box
    self:Button(self.Body, "Send to " .. self.ChatChannel, function()
        if self.ChatBox and self.ChatBox.Text ~= "" then
            self.Remotes.Chat:FireServer({ Action = "Send", ChannelId = self.ChatChannel, Text = self.ChatBox.Text })
            self.ChatBox.Text = ""
        end
    end)
    self:Label("Messages")
    for index = math.max(1, #chat.Messages - 14), #chat.Messages do
        local msg = chat.Messages[index]
        if msg then
            make(self.Body, "TextLabel", {
                Size = UDim2.new(1, -4, 0, 34),
                BackgroundColor3 = Color3.fromRGB(17, 22, 30),
                BorderSizePixel = 0,
                Font = Enum.Font.Code,
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Color3.fromRGB(220, 230, 240),
                Text = string.format("[%s] %s: %s", tostring(msg.ChannelName or msg.ChannelId), tostring(msg.FromName or "?"), tostring(msg.Text or "")),
            })
        end
    end
end

function HubConsole:RenderClan()
    local snapshot = self.State.Clan or {}
    local clan = snapshot.Clan
    if clan then
        self:Label(string.format("%s [%s] - %s", tostring(clan.Name), tostring(clan.Tag), tostring(clan.Rank)))
        self:Label("Online Roster")
        for _, member in pairs(snapshot.Roster or {}) do
            self:Button(self.Body, string.format("%s - %s", tostring(member.Name), tostring(member.Rank)), function() end)
        end
        self:Button(self.Body, "Leave Clan", function()
            self.Remotes.Clan:FireServer({ Action = "Leave" })
        end)
    else
        self:Label("No Clan")
        self:Button(self.Body, "Create Solo Clan", function()
            self.Remotes.Clan:FireServer({ Action = "Create", Name = "My Clan", Tag = "MY" })
        end)
        self:Button(self.Body, "Join Dev Clan", function()
            self.Remotes.Clan:FireServer({ Action = "JoinDevClan" })
        end)
    end
    self:Label("Clan Chat")
    self.ChatChannel = "Clan"
    self:Button(self.Body, "Open Chat Tab On Clan", function()
        self.ActivePanel = "Chat"
        self:Refresh()
    end)
end

function HubConsole:RenderTrade()
    local snapshot = self.State.Trade or {}
    local inventory = self.State.Inventory or {}
    local wallet = (self.State.Marketplace and self.State.Marketplace.Wallet) or (inventory.Wallet or {})
    local dallions = wallet.Dallions or {}
    self:Label(string.format("Trade Board / Coins: %s / Dallions: %s (%s tradeable)", tostring(wallet.Coins or wallet.Credits or 0), tostring((dallions.Starter or 0) + (dallions.Tradeable or 0)), tostring(dallions.Tradeable or 0)))
    self:Label("Create Listing")
    for materialId, amount in pairs(inventory.Materials or {}) do
        if amount > 0 then
            self:Button(self.Body, string.format("List 5 %s for 50 Coins", materialId), function()
                self.Remotes.Trade:FireServer({ Action = "CreateListing", ItemType = "Material", ItemId = materialId, Quantity = math.min(5, amount), PriceCurrency = "Coins", PriceCoins = 50 })
            end)
        end
    end
    for decorationId, amount in pairs(inventory.Decorations or {}) do
        if amount > 0 then
            self:Button(self.Body, string.format("List 1 %s for 100 Coins", decorationId), function()
                self.Remotes.Trade:FireServer({ Action = "CreateListing", ItemType = "Decoration", ItemId = decorationId, Quantity = 1, PriceCurrency = "Coins", PriceCoins = 100 })
            end)
        end
    end
    for modId in pairs(inventory.Mods or {}) do
        self:Button(self.Body, string.format("List mod %s for 75 Coins", modId), function()
            self.Remotes.Trade:FireServer({ Action = "CreateListing", ItemType = "Mod", ItemId = modId, Quantity = 1, PriceCurrency = "Coins", PriceCoins = 75 })
        end)
    end
    for itemUid, armorState in pairs(inventory.Armor or {}) do
        self:Button(self.Body, string.format("List armor %s for 200 Coins", tostring(armorState.ArmorId or itemUid)), function()
            self.Remotes.Trade:FireServer({ Action = "CreateListing", ItemType = "Armor", ItemId = itemUid, Quantity = 1, PriceCurrency = "Coins", PriceCoins = 200 })
            end)
    end
    for itemUid, attachmentState in pairs(inventory.Attachments or {}) do
        self:Button(self.Body, string.format("List attachment %s for 150 Coins", tostring(attachmentState.AttachmentId or itemUid)), function()
            self.Remotes.Trade:FireServer({ Action = "CreateListing", ItemType = "Attachment", ItemId = itemUid, Quantity = 1, PriceCurrency = "Coins", PriceCoins = 150 })
        end)
    end
    self:Label("Listings")
    for listingId, listing in pairs(snapshot.Listings or {}) do
        local label = string.format("%s x%s %s from %s - %s %s", tostring(listing.ItemId), tostring(listing.Quantity), tostring(listing.ItemType), tostring(listing.SellerName), tostring(listing.PriceAmount or listing.PriceCoins or listing.PriceCredits), tostring(listing.PriceCurrency or "Coins"))
        if listing.SellerUserId == Players.LocalPlayer.UserId then
            self:Button(self.Body, "Cancel " .. label, function()
                self.Remotes.Trade:FireServer({ Action = "CancelListing", ListingId = listingId })
            end)
        else
            self:Button(self.Body, "Buy " .. label, function()
                self.Remotes.Trade:FireServer({ Action = "BuyListing", ListingId = listingId })
            end)
        end
    end
    self:Button(self.Body, "Refresh Trade Board", function()
        self.Remotes.Trade:FireServer({ Action = "RequestSnapshot" })
    end)
end

function HubConsole:RenderResources()
    local snapshot = self.State.ResourceNodes or {}
    local inventory = self.State.Inventory or {}
    self:Label("Resource Nodes")
    if snapshot.Type == "Gathered" then
        self:Label(string.format("Last gathered: %s x%s from %s", tostring(snapshot.MaterialId), tostring(snapshot.Amount), tostring(snapshot.LocationId)))
    end
    self:Label("Current Materials")
    local lines = {}
    for materialId, amount in pairs(inventory.Materials or {}) do
        table.insert(lines, string.format("%s:%s", materialId, tostring(amount)))
    end
    table.sort(lines)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -4, 0, 44),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(220, 230, 240),
        Text = #lines > 0 and table.concat(lines, "  ") or "No materials yet",
    })
    self:Label("Definitions")
    for resourceId, def in pairs(snapshot.Definitions or {}) do
        self:Button(self.Body, string.format("%s -> %s (%s-%s)", def.DisplayName or resourceId, tostring(def.MaterialId), tostring(def.AmountMin or 1), tostring(def.AmountMax or def.AmountMin or 1)), function() end)
    end
    self:Button(self.Body, "Refresh Resource Definitions", function()
        self.Remotes.ResourceNode:FireServer({ Action = "RequestSnapshot" })
    end)
end

function HubConsole:RenderNpc()
    local payload = self.State.Npc or {}
    local npc = payload.Npc or {}
    self:Label(npc.DisplayName or "No NPC selected")
    for _, line in ipairs((npc.Lines and npc.Lines.Default) or {}) do
        make(self.Body, "TextLabel", {
            Size = UDim2.new(1, -4, 0, 46),
            BackgroundColor3 = Color3.fromRGB(17, 22, 30),
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(220, 230, 240),
            Text = line,
        })
    end
    if payload.NextStory then
        self:Label("Next Story: " .. tostring(payload.NextStory.Title or payload.NextStory.Id))
    end
    self:Label("Actions")
    for _, action in ipairs(npc.Actions or {}) do
        self:Button(self.Body, action.Label or action.Id, function()
            self.Remotes.Npc:FireServer({ Action = "RunAction", NpcId = npc.Id, ActionId = action.Id })
        end)
    end
    if payload.Shop and payload.Shop.Definition then
        self:Label(payload.Shop.Definition.DisplayName or "Shop")
        local purchases = (payload.Shop.Ledger and payload.Shop.Ledger.Purchases) or {}
        for listingId, listing in pairs(payload.Shop.Definition.Listings or {}) do
            local bought = purchases[listingId] or 0
            local stock = listing.DailyStock or -1
            local costParts = {}
            for currencyId, amount in pairs(listing.Cost or {}) do
                table.insert(costParts, tostring(amount) .. " " .. currencyId)
            end
            table.sort(costParts)
            self:Button(self.Body, string.format("Buy %s (%s/%s) - %s", tostring(listing.DisplayName or listingId), tostring(bought), tostring(stock), table.concat(costParts, ", ")), function()
                self.Remotes.Npc:FireServer({ Action = "BuyShopItem", NpcId = npc.Id, ListingId = listingId })
            end)
        end
    end
    if payload.Bounties and payload.Bounties.Definition then
        self:Label(payload.Bounties.Definition.DisplayName or "Bounties")
        local accepted = (payload.Bounties.Ledger and payload.Bounties.Ledger.Accepted) or {}
        local active = payload.Bounties.Active or {}
        for bountyId, bounty in pairs(payload.Bounties.Definition.Bounties or {}) do
            local activeBounty = active[bountyId]
            local objective = activeBounty and activeBounty.Objective or bounty.Objective or {}
            local target = objective.Count or 1
            local progress = activeBounty and activeBounty.Progress or 0
            local prefix = "Accept "
            if activeBounty and activeBounty.Completed then
                prefix = "[Done] "
            elseif accepted[bountyId] then
                prefix = string.format("[%s/%s] ", tostring(progress), tostring(target))
            end
            self:Button(self.Body, prefix .. tostring(bounty.DisplayName or bountyId), function()
                self.Remotes.Npc:FireServer({ Action = "AcceptBounty", NpcId = npc.Id, BountyId = bountyId })
            end)
        end
    end
    if not npc.Id then
        self:Button(self.Body, "Talk to a dev NPC prompt in the hub", function() end)
    end
end

function HubConsole:SaveSettings()
    if not self.Remotes.Settings then return end
    local ok, payload = pcall(function()
        return self.Remotes.Settings:InvokeServer("Save", {
            Settings = self.State.Settings,
            Rebinds = self.Input and self.Input:GetSerializedBindings() or {},
        })
    end)
    if ok and typeof(payload) == "table" then
        self.State:ApplySettings(payload.Settings)
    end
end

function HubConsole:SetSetting(key, value)
    self.State.Settings[key] = value
    self:SaveSettings()
    self:Refresh()
end

function HubConsole:RenderSettings()
    self:Label("Settings")
    local settings = SettingsSchema.SanitizeSettings(self.State.Settings)
    local numericOrder = { "MouseSensitivity", "GamepadSensitivity", "CameraFov", "UiScale" }
    for _, key in ipairs(numericOrder) do
        local def = SettingsSchema.Fields[key]
        local value = settings[key]
        self:Label(string.format("%s: %s", key, tostring(value)))
        self:Button(self.Body, "- " .. key, function()
            self:SetSetting(key, math.max(def.Min or value, value - (key == "CameraFov" and 5 or 0.1)))
        end)
        self:Button(self.Body, "+ " .. key, function()
            self:SetSetting(key, math.min(def.Max or value, value + (key == "CameraFov" and 5 or 0.1)))
        end)
    end
    self:Label("Toggles")
    for _, key in ipairs({ "InvertY", "ToggleCrouch", "ChatEnabled", "ShowTradeChat", "ShowDamageNumbers", "ReduceMotion" }) do
        self:Button(self.Body, string.format("%s: %s", key, tostring(settings[key] == true)), function()
            self:SetSetting(key, not (settings[key] == true))
        end)
    end
    self:Button(self.Body, "Reset Settings To Defaults", function()
        self.State.Settings = SettingsSchema.GetDefaults()
        self:SaveSettings()
        self:Refresh()
    end)
end

return HubConsole
