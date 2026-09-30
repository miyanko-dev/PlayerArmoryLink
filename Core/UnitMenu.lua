local _, ns = ...

local ENTRY_TEXT = "Armory Link"

-- Every unit menu that can open on a player. Each tag is "MENU_UNIT_" plus the menu name UnitPopupManager:OpenMenu receives.
local MENU_TAGS = {
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_ENEMY_PLAYER",
    "MENU_UNIT_RAID",
    "MENU_UNIT_FOCUS",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_CHAT_ROSTER",
    "MENU_UNIT_PVP_SCOREBOARD",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_COMMUNITIES_WOW_MEMBER",
    "MENU_UNIT_RECENT_ALLY",
    "MENU_UNIT_RECENT_ALLY_OFFLINE",
}

-- A roster name the menu left joined: "First Surname", or the chat link form "First-Surname".
local function splitFullName(fullName)
    local first, surname = fullName:match("^([^%s%-]+)[%s%-](.+)$")
    if first then
        return first, surname
    end
    return fullName
end

-- UnitPopupManager:OpenMenu fills name and surname from UnitNameUnmodified for unit menus, so unit frames and rosters read the same source.
local function readName(context)
    local unit = context.unit
    if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
        return nil
    end
    local name = context.name
    if not name then
        return nil
    end
    local surname = context.surname
    if surname and surname ~= "" then
        return name, surname
    end
    return splitFullName(name)
end

-- With regional unique names the second part is a surname and every player shares the current realm. Without them it is the player's realm, as Blizzard's own menu treats it.
local function identify(name, suffix)
    if RegionalUniqueNamesEnabled() then
        return NameUtil.GetFullNameWithoutRealm(name, suffix), GetRealmName()
    end
    if suffix and suffix ~= "" then
        return name, suffix
    end
    return name, GetRealmName()
end

local function readPlayer(context)
    local name, suffix = readName(context)
    if type(name) ~= "string" or name == "" or name == UNKNOWN then
        return nil
    end
    local displayName, realm = identify(name, suffix)
    local url = ns.ArmoryUrl(realm, name)
    if not url then
        return nil
    end
    return displayName, realm, url
end

-- A name under identity restriction arrives as a secret value and any string operation on it throws, so the whole read runs in pcall. canaccessvalue cannot guard it: it rejects secrets from tainted callers.
local function appendEntry(_, root, context)
    local ok, displayName, realm, url = pcall(readPlayer, context)
    if not ok or not url then
        return
    end

    root:CreateDivider()

    -- Deferred so the menu tears down before the dialog takes keyboard focus.
    root:CreateButton(ENTRY_TEXT, function()
        C_Timer.After(0, function()
            ns.ShowCopyDialog(displayName, realm, url)
        end)
    end)
end

for _, tag in ipairs(MENU_TAGS) do
    Menu.ModifyMenu(tag, appendEntry)
end
