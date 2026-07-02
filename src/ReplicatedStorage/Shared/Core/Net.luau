--!nonstrict
local Config = require(script.Parent:WaitForChild("Config"))

local Net = {}

Net.RemotesFolderName = Config.Networking.RemotesFolderName

Net.RemoteEvents = {
    ActionRequest = "ActionRequest",
    MeleeRequest = "MeleeRequest",
    StateUpdate = "StateUpdate",
    StatusUpdate = "StatusUpdate",
    Correction = "Correction",
    HitboxDebug = "HitboxDebug",
    ProfileRequest = "ProfileRequest",
    ProfileUpdate = "ProfileUpdate",
    AbilityRequest = "AbilityRequest",
    AbilityUpdate = "AbilityUpdate",
    WeaponRequest = "WeaponRequest",
    WeaponUpdate = "WeaponUpdate",
    CombatFeedback = "CombatFeedback",
    EnemyRequest = "EnemyRequest",
    EnemyUpdate = "EnemyUpdate",
    RewardUpdate = "RewardUpdate",
    MissionRequest = "MissionRequest",
    MissionUpdate = "MissionUpdate",
    TuningRequest = "TuningRequest",
    TuningUpdate = "TuningUpdate",
    ValidationUpdate = "ValidationUpdate",
    WorldRequest = "WorldRequest",
    WorldUpdate = "WorldUpdate",
    StoryRequest = "StoryRequest",
    StoryUpdate = "StoryUpdate",
    QuestRequest = "QuestRequest",
    QuestUpdate = "QuestUpdate",
    HubRequest = "HubRequest",
    HubUpdate = "HubUpdate",
    InventoryRequest = "InventoryRequest",
    InventoryUpdate = "InventoryUpdate",
    CraftingRequest = "CraftingRequest",
    CraftingUpdate = "CraftingUpdate",
    MasteryRequest = "MasteryRequest",
    MasteryUpdate = "MasteryUpdate",
    RoomRequest = "RoomRequest",
    RoomUpdate = "RoomUpdate",
    MarketplaceRequest = "MarketplaceRequest",
    MarketplaceUpdate = "MarketplaceUpdate",
    NpcRequest = "NpcRequest",
    NpcUpdate = "NpcUpdate",
    ClanRequest = "ClanRequest",
    ClanUpdate = "ClanUpdate",
    TradeRequest = "TradeRequest",
    TradeUpdate = "TradeUpdate",
    ResourceNodeRequest = "ResourceNodeRequest",
    ResourceNodeUpdate = "ResourceNodeUpdate",
    TrainingRequest = "TrainingRequest",
    TrainingUpdate = "TrainingUpdate",
    SocialChatRequest = "SocialChatRequest",
    SocialChatUpdate = "SocialChatUpdate",
}

Net.RemoteFunctions = {
    Settings = "Settings",
    Rebind = "Rebind",
}

function Net.GetRemotesFolder()
    return game:GetService("ReplicatedStorage"):WaitForChild(Net.RemotesFolderName)
end

function Net.GetRemoteEvent(name)
    return Net.GetRemotesFolder():WaitForChild(name)
end

function Net.GetRemoteFunction(name)
    return Net.GetRemotesFolder():WaitForChild(name)
end

return Net
