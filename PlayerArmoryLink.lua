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

-- Ordered for the dropdown, keyed by the path segment the armory expects.
local GAME_VERSIONS = {
    {slug = "classic1x", label = "Classic Era"},
    {slug = "classicann", label = "Anniversary"},
    {slug = "classic", label = "Classic Progression"},
    {slug = "worldsoul", label = "Retail"},
}

-- Anniversary realms run the era client under a Fresh season, permanent era realms do not.
local FRESH_SEASONS = {[11] = true, [12] = true}

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

local function defaultVersion()
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        return "worldsoul"
    end
    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
        return "classic"
    end
    local season = C_Seasons and C_Seasons.HasActiveSeason() and C_Seasons.GetActiveSeason()
    if season and FRESH_SEASONS[season] then
        return "classicann"
    end
    return "classic1x"
end

local function selectedVersion()
    return PlayerArmoryLinkDB and PlayerArmoryLinkDB.version or defaultVersion()
end

local function versionLabel(slug)
    for _, version in ipairs(GAME_VERSIONS) do
        if version.slug == slug then
            return version.label
        end
    end
    return slug
end

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

local function buildUrl(name, realm, versionSlug)
    local locale = LOCALE_SLUGS[GetLocale()] or "en-us"
    local region = REGION_SLUGS[GetCurrentRegion()] or "us"
    return ARMORY_URL:format(locale, versionSlug, region, realm, name:lower())
end

local function copyHint()
    if IsMacClient and IsMacClient() then
        return "Press CMD+C to copy and close"
    end
    return "Press CTRL+C to copy and close"
end

local function refreshPopup()
    local frame = popup
    if not frame or not frame.playerName then
        return
    end

    local slug = selectedVersion()
    frame.url = buildUrl(frame.playerName, frame.playerRealm, slug)
    frame.Subtitle:SetText(("%s  %s  %s"):format(frame.playerName, frame.playerRealm, versionLabel(slug)))
    frame.Link:SetText(frame.url)
    frame.Link:SetCursorPosition(0)
    frame.Link:HighlightText()
    frame.Version:GenerateMenu()
end

local function setVersion(slug)
    PlayerArmoryLinkDB.version = slug
    refreshPopup()
    return MenuResponse.CloseAll
end

local function isVersion(slug)
    return selectedVersion() == slug
end

local function createPopup()
    local frame = CreateFrame("Frame", "PlayerArmoryLinkFrame", UIParent)
    frame:SetSize(420, 148)
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
    hint:SetPoint("TOPLEFT", link, "BOTTOMLEFT", 2, -10)
    hint:SetText(copyHint())

    local version = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    version:SetSize(150, 22)
    version:SetPoint("BOTTOMRIGHT", -20, 16)
    version:SetupMenu(function(_, root)
        for _, entry in ipairs(GAME_VERSIONS) do
            root:CreateRadio(entry.label, isVersion, setVersion, entry.slug)
        end
    end)
    frame.Version = version

    tinsert(UISpecialFrames, "PlayerArmoryLinkFrame")

    return frame
end

local function showPopup(name, realm)
    popup = popup or createPopup()
    popup.playerName = name
    popup.playerRealm = realm
    popup:Show()
    refreshPopup()
    popup.Link:SetFocus()
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

local function handleSlash(input)
    local target = input and input:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if target == "" then
        target = UnitName("player")
    end

    local name, realm = target:match("^([^%-]+)%-(.+)$")
    name = name or target
    showPopup(name, realmSlug(realm) or realmSlug(GetRealmName()))
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= "PlayerArmoryLink" then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")

    if type(PlayerArmoryLinkDB) ~= "table" then
        PlayerArmoryLinkDB = {}
    end
    if not PlayerArmoryLinkDB.version then
        PlayerArmoryLinkDB.version = defaultVersion()
    end

    if Menu and Menu.ModifyMenu then
        for _, tag in ipairs(UNIT_MENU_TAGS) do
            Menu.ModifyMenu(tag, appendMenu)
        end
    end

    SLASH_PLAYERARMORYLINK1 = "/armory"
    SLASH_PLAYERARMORYLINK2 = "/pal"
    SlashCmdList.PLAYERARMORYLINK = handleSlash
end)
