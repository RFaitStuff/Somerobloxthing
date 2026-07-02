--!nonstrict
local Channels = {}

Channels.ById = {
    Server = { Id = "Server", DisplayName = "Server", Scope = "Server", MaxLength = 180, Alias = "/s" },
    Hub = { Id = "Hub", DisplayName = "Hub", Scope = "Location", LocationId = "Hub", MaxLength = 180, Alias = "/h" },
    Squad = { Id = "Squad", DisplayName = "Squad", Scope = "Party", MaxLength = 180, Alias = "/sq", RequiresContext = "Squad" },
    Clan = { Id = "Clan", DisplayName = "Clan", Scope = "Clan", MaxLength = 180, Alias = "/c", RequiresContext = "Clan" },
    Trade = { Id = "Trade", DisplayName = "Trade", Scope = "Server", TradeOnly = true, Cooldown = 2.5, MaxLength = 220, Alias = "/t" },
    Room = { Id = "Room", DisplayName = "Room", Scope = "Room", MaxLength = 180, Alias = "/r", RequiresContext = "Room" },
    Whisper = { Id = "Whisper", DisplayName = "Whisper", Scope = "Direct", MaxLength = 180, Alias = "/w", RequiresTarget = true },
    System = { Id = "System", DisplayName = "System", Scope = "System", ReadOnly = true, MaxLength = 240 },
}

Channels.Order = { "Server", "Hub", "Squad", "Clan", "Trade", "Room", "Whisper" }

function Channels.Get(id)
    return Channels.ById[id]
end

return Channels
