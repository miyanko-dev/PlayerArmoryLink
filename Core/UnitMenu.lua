local _, ns = ...

local ENTRY_TEXT = "Armory Link"

-- Every unit menu either client can open on a player, each traced to its UnitPopup_OpenMenu caller. WORLD_STATE_SCORE is the 1.15 battleground scoreboard, PVP_SCOREBOARD and the RECENT_ALLY pair exist only on 1.60; a tag the running client never opens stays inert.
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
    "MENU_UNIT_WORLD_STATE_SCORE",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_COMMUNITIES_WOW_MEMBER",
    "MENU_UNIT_RECENT_ALLY",
    "MENU_UNIT_RECENT_ALLY_OFFLINE",
}

-- A name the menu left joined: "First Surname" or "First-Surname" on 1.60, "Name-Realm" on 1.15.
local function splitFullName(fullName)
    local first, surname = fullName:match("^([^%s%-]+)[%s%-](.+)$")
    if first then
        return first, surname
    end
    return fullName
end

-- Unit frames carry a unit, rosters only a name. UnitName beats the context's UnitNameUnmodified because its 1.60 secrecy rule exempts players in PvP. Its second return is a realm on 1.15 and a surname on 1.60.
local function readName(context)
    local unit = context.unit
    if unit and UnitExists(unit) then
        if not UnitIsPlayer(unit) then
            return nil
        end
        return UnitName(unit)
    end
    if not context.name then
        return nil
    end
    local suffix = ns.ContextSuffix(context)
    if suffix then
        return context.name, suffix
    end
    return splitFullName(context.name)
end

local function readPlayer(context)
    local name, suffix = readName(context)
    if type(name) ~= "string" or name == "" or name == UNKNOWN then
        return nil
    end
    local displayName, realm = ns.Identify(name, suffix)
    local url = ns.ArmoryUrl(realm, name)
    if not url then
        return nil
    end
    return displayName, realm, url
end

-- On 1.60 a name under identity restriction arrives as a secret value and any string operation on it throws, so the whole read runs in pcall. canaccessvalue cannot guard it: it rejects secrets from tainted callers. 1.15 never issues secrets, so the pcall costs nothing there.
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
