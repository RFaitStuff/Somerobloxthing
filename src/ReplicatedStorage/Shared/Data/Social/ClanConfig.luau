--!nonstrict
local ClanConfig = {}

ClanConfig.MaxNameLength = 24
ClanConfig.MaxTagLength = 5
ClanConfig.MaxMembers = 50

ClanConfig.Ranks = {
    Founder = { Id = "Founder", Power = 100 },
    Officer = { Id = "Officer", Power = 60 },
    Member = { Id = "Member", Power = 10 },
}

function ClanConfig.SanitizeName(name)
    name = type(name) == "string" and name or "Dev Clan"
    name = name:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "Dev Clan" end
    return string.sub(name, 1, ClanConfig.MaxNameLength)
end

function ClanConfig.SanitizeTag(tag)
    tag = type(tag) == "string" and tag or "DEV"
    tag = tag:gsub("[^%w]", ""):upper()
    if tag == "" then tag = "DEV" end
    return string.sub(tag, 1, ClanConfig.MaxTagLength)
end

return ClanConfig
