local _, ns = ...

local MENU_ENTRY_TEXT = "Armory Link"

-- Every tag is registered by UnitPopupManager on both builds, so one list serves both. A tag no client registers is inert, Menu.ModifyMenu only asserts that it is a string.
local UNIT_MENU_TAGS = {
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_ENEMY_PLAYER",
    "MENU_UNIT_FOCUS",
    "MENU_UNIT_ARENAENEMY",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_GUILD",
    "MENU_UNIT_GUILD_OFFLINE",
    "MENU_UNIT_CHAT_ROSTER",
    "MENU_UNIT_PVP_SCOREBOARD",
    "MENU_UNIT_WORLD_STATE_SCORE",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_COMMUNITIES_WOW_MEMBER",
    "MENU_UNIT_RECENT_ALLY",
    "MENU_UNIT_RECENT_ALLY_OFFLINE",
}

-- Menu context carries a name for roster entries and a unit for frames, never both reliably.
local function resolvePlayer(context)
    local name, realm = context.name, ns.ContextRealm(context)

    if context.unit then
        if not UnitIsPlayer(context.unit) then
            return nil
        end
        -- UnitName is preferred over UnitNameUnmodified because 1.60 grants it an extra exception from unit-identity secrecy for player units.
        local unitName, unitRealm = UnitName(context.unit)
        if unitName ~= nil then
            name, realm = unitName, unitRealm or realm
        end
    end

    -- Screens out 1.60 secret values before any string operation touches them, and nil and UNKNOWN in the same pass.
    if not ns.IsReadable(name) or type(name) ~= "string" or name == "" or name == UNKNOWN then
        return nil
    end
    if realm ~= nil and (not ns.IsReadable(realm) or type(realm) ~= "string") then
        realm = nil
    end

    -- A 1.60 client with regionally unique names leaves "Name-Realm" joined in the context, so the suffix is split off here.
    local basename, suffix = name:match("^([^%-]+)%-(.+)$")
    if basename then
        name, realm = basename, realm or suffix
    end

    if realm == nil or realm == "" then
        realm = GetRealmName()
    end

    return name, realm
end

local function appendMenu(_, root, context)
    if not context then
        return
    end
    local name, realm = resolvePlayer(context)
    if not name then
        return
    end
    local url = ns.ArmoryUrl(name, realm)
    if not url then
        return
    end

    root:CreateDivider()
    -- Deferred so the menu tears down before the dialog takes keyboard focus.
    root:CreateButton(MENU_ENTRY_TEXT, function()
        C_Timer.After(0, function()
            ns.ShowCopyDialog(name, realm, url)
        end)
    end)
end

if Menu and Menu.ModifyMenu then
    for _, tag in ipairs(UNIT_MENU_TAGS) do
        Menu.ModifyMenu(tag, appendMenu)
    end
end
