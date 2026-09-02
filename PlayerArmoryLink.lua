local ADDON_TITLE = "Player Armory Link"

local ARMORY_URL = "https://worldofwarcraft.blizzard.com/%s/%s/%s/armory/character/%s/%s"

local REGION_SLUGS = {"us", "kr", "eu", "tw", "cn"}

local LOCALE_SLUGS = {
    enUS = "en-us",
    enGB = "en-gb",
    deDE = "de-de",
    esES = "es-es",
    esMX = "es-mx",
    frFR = "fr-fr",
    itIT = "it-it",
    koKR = "ko-kr",
    ptBR = "pt-br",
    ruRU = "ru-ru",
    zhCN = "zh-cn",
    zhTW = "zh-tw",
}

-- Keyed by WOW_PROJECT_ID, whose constants are not all defined on every client.
local PROJECT_VERSIONS = {
    [1] = "worldsoul", -- Mainline
    [2] = "classic1x", -- Classic, the permanent and fresh era realms
    [5] = "classicann", -- Burning Crusade Classic, the Anniversary realms
    [19] = "classic", -- Mists Classic, the progression realms
}

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

local popup

-- Armory realm slugs are lowercase and dash separated, and UnitName returns realms without spaces.
local function realmSlug(realm)
    if type(realm) ~= "string" or realm == "" then
        return nil
    end
    realm = realm:gsub("'", "")
    if not realm:find("%s") then
        realm = realm:gsub("(%l)(%u)", "%1 %2")
    end
    realm = realm:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    return realm ~= "" and realm or nil
end

local function buildUrl(name, realm)
    local locale = LOCALE_SLUGS[GetLocale()] or "en-us"
    local version = PROJECT_VERSIONS[WOW_PROJECT_ID] or "classic"
    local region = REGION_SLUGS[GetCurrentRegion()] or "us"
    return ARMORY_URL:format(locale, version, region, realm, name:lower())
end

local function copyHint()
    if IsMacClient and IsMacClient() then
        return "Press CMD+C to copy and close"
    end
    return "Press CTRL+C to copy and close"
end

local function createPopup()
    local frame = CreateFrame("Frame", "PlayerArmoryLinkFrame", UIParent)
    frame:SetSize(420, 118)
    frame:SetPoint("CENTER", 0, 140)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local border = CreateFrame("Frame", nil, frame, "DialogBorderTemplate")
    border:SetAllPoints(frame)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 3, 3)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", 0, -18)
    title:SetText(ADDON_TITLE)

    local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
    frame.Subtitle = subtitle

    local link = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    link:SetSize(356, 20)
    link:SetPoint("TOP", subtitle, "BOTTOM", 4, -14)
    link:SetAutoFocus(true)
    link:SetFontObject("ChatFontSmall")
    frame.Link = link

    link:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    link:SetScript("OnEnterPressed", function(self)
        self:HighlightText()
    end)

    -- Revert edits so the link stays intact and fully selected.
    link:SetScript("OnTextChanged", function(self, userInput)
        if userInput and frame.url and self:GetText() ~= frame.url then
            self:SetText(frame.url)
            self:HighlightText()
        end
    end)

    link:SetScript("OnKeyDown", function(_, key)
        if key ~= "C" then
            return
        end
        if not (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then
            return
        end
        -- Deferred so the client finishes the copy before the frame goes away.
        C_Timer.After(0.2, function()
            frame:Hide()
            UIErrorsFrame:AddMessage("Armory link copied", 0.2, 1, 0.2)
        end)
    end)

    local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOP", link, "BOTTOM", -4, -10)
    hint:SetText(copyHint())

    tinsert(UISpecialFrames, "PlayerArmoryLinkFrame")

    return frame
end

local function showPopup(name, realm)
    popup = popup or createPopup()
    popup.url = buildUrl(name, realm)
    popup.Subtitle:SetText(("%s  %s"):format(name, realm))
    popup.Link:SetText(popup.url)
    popup.Link:SetCursorPosition(0)
    popup:Show()
    popup.Link:SetFocus()
    popup.Link:HighlightText()
end

-- Menu context carries a name for roster entries and a unit for frames, never both reliably.
local function resolvePlayer(context)
    local name, realm = context.name, context.server

    if context.unit then
        if not UnitIsPlayer(context.unit) then
            return nil
        end
        local unitName, unitRealm = UnitName(context.unit)
        name = unitName or name
        realm = unitRealm or realm
    end

    if type(name) ~= "string" or name == "" or name == UNKNOWN then
        return nil
    end

    local basename, suffix = name:match("^([^%-]+)%-(.+)$")
    if basename then
        name, realm = basename, realm or suffix
    end

    return name, realmSlug(realm) or realmSlug(GetRealmName())
end

local function appendMenu(_, root, context)
    if not context then
        return
    end
    local name, realm = resolvePlayer(context)
    if not name or not realm then
        return
    end

    root:CreateDivider()
    -- Deferred so the menu tears down before the popup takes keyboard focus.
    root:CreateButton("Armory Link", function()
        C_Timer.After(0, function()
            showPopup(name, realm)
        end)
    end)
end

if Menu and Menu.ModifyMenu then
    for _, tag in ipairs(UNIT_MENU_TAGS) do
        Menu.ModifyMenu(tag, appendMenu)
    end
end
