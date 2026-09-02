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

-- Spacing scale shared with QuestieGuide, ChatScan and GatherMate2NodeAlert.
local SPACING = {
    XS = 4,
    SM = 8,
    MD = 16,
    LG = 24,
}

-- Frame and widget dimensions, PAD_TOP clears the dialog-box-header banner and SECTION_PAD clears the tooltip-border art.
local LAYOUT = {
    FRAME_W = 480,
    PAD_TOP = 48,
    SECTION_PAD = 12,
    LABEL_H = 12, -- one GameFontNormal label line.
    NAME_H = 16, -- GameFontHighlightLarge character name line.
    REALM_H = 14, -- GameFontHighlightMedium realm line.
    EDIT_H = 20, -- link edit box.
}

-- Lowercase connectors that realm names keep lowercase, and that UnitName glues onto the neighbouring word.
local CONNECTORS = {"of", "der", "des", "die", "das", "dem", "von"}
local LEADING_ARTICLES = {"Der", "Die", "Das"}

local popup

-- Restores word breaks in a realm from UnitName, which strips spaces: "ChamberofAspects" becomes "Chamber of Aspects".
local function splitRealmWords(realm)
    if realm:find("%s") then
        return realm
    end
    realm = realm:gsub("(%l)(%u)", "%1 %2")
    for _, word in ipairs(CONNECTORS) do
        realm = realm:gsub("(%l)(" .. word .. ") (%u)", "%1 %2 %3")
    end
    for _, article in ipairs(LEADING_ARTICLES) do
        realm = realm:gsub("^(" .. article .. ")(%l)", "%1 %2")
    end
    return realm
end

-- Armory realm slugs are lowercase and dash separated.
local function realmSlug(realm)
    if type(realm) ~= "string" or realm == "" then
        return nil
    end
    realm = splitRealmWords(realm:gsub("'", ""))
    realm = realm:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    return realm ~= "" and realm or nil
end

-- Capitalizes each word and keeps connectors lowercase unless they lead.
local function properCase(text)
    local index = 0
    return (text:gsub("(%S+)", function(word)
        index = index + 1
        if index > 1 and tContains(CONNECTORS, word:lower()) then
            return word:lower()
        end
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

local function realmDisplay(realm)
    return properCase(splitRealmWords(realm))
end

local function buildUrl(name, realm)
    local locale = LOCALE_SLUGS[GetLocale()] or "en-us"
    local version = PROJECT_VERSIONS[WOW_PROJECT_ID] or "classic"
    local region = REGION_SLUGS[GetCurrentRegion()] or "us"
    return ARMORY_URL:format(locale, version, region, realmSlug(realm), name:lower())
end

-- Modifier resolved from the running client, IsMacClient is false on Windows and Linux.
local function copyHint()
    if IsMacClient and IsMacClient() then
        return "Press CMD+C to copy and close."
    end
    return "Press CTRL+C to copy and close."
end

local function applyPanelBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8},
    })
end

-- NATIVE: Blizzard dialog-box header banner composed as three texture pieces, every pixel value is proportioned to the texture art.
local function buildTitleHeader(parent, text)
    local HEADER_TEXTURE = "Interface\\DialogFrame\\UI-DialogBox-Header"

    local mid = parent:CreateTexture(nil, "OVERLAY")
    mid:SetTexture(HEADER_TEXTURE)
    mid:SetTexCoord(0.31, 0.67, 0, 0.63)
    mid:SetPoint("TOP", parent, "TOP", 0, 12)
    mid:SetHeight(40)

    local left = parent:CreateTexture(nil, "OVERLAY")
    left:SetTexture(HEADER_TEXTURE)
    left:SetTexCoord(0.21, 0.31, 0, 0.63)
    left:SetPoint("RIGHT", mid, "LEFT")
    left:SetWidth(30)
    left:SetHeight(40)

    local right = parent:CreateTexture(nil, "OVERLAY")
    right:SetTexture(HEADER_TEXTURE)
    right:SetTexCoord(0.67, 0.77, 0, 0.63)
    right:SetPoint("LEFT", mid, "RIGHT")
    right:SetWidth(30)
    right:SetHeight(40)

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mid, "TOP", 0, -14)
    title:SetText(text)

    mid:SetWidth((title:GetStringWidth() or 0) + 10)

    return mid
end

-- Boxed subcontainer: dark bg plus tooltip border with a floating yellow label above and an inner body frame.
local function buildSection(parent, labelText)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 3, right = 3, top = 5, bottom = 3},
    })
    section:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    section:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", section, "TOPLEFT", LAYOUT.SECTION_PAD, SPACING.SM)
    label:SetText(labelText)
    section.label = label

    local body = CreateFrame("Frame", nil, section)
    body:SetPoint("TOPLEFT", section, "TOPLEFT", LAYOUT.SECTION_PAD, -LAYOUT.SECTION_PAD)
    body:SetPoint("BOTTOMRIGHT", section, "BOTTOMRIGHT", -LAYOUT.SECTION_PAD, LAYOUT.SECTION_PAD)
    section.body = body

    return section
end

-- Plain labeled group, GameFontNormal instead of the reference's 10px GameFontNormalSmall to keep every line at 12px or more.
local function buildGroup(parent, labelText)
    local group = CreateFrame("Frame", nil, parent)
    local label = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", group, "TOPLEFT", 0, 0)
    label:SetText(labelText)
    group.label = label
    local body = CreateFrame("Frame", nil, group)
    body:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -(LAYOUT.LABEL_H + SPACING.XS))
    body:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", 0, 0)
    group.body = body
    return group
end

-- Sizes a group to its label row plus the given body height so layout math can trust GetHeight.
local function sizeGroup(group, bodyHeight)
    group:SetHeight(LAYOUT.LABEL_H + SPACING.XS + bodyHeight)
end

local function createPopup()
    local frame = CreateFrame("Frame", "PlayerArmoryLinkFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    applyPanelBackdrop(frame)
    frame:SetPoint("CENTER", 0, 140)
    frame:Hide()

    buildTitleHeader(frame, ADDON_TITLE)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    -- The single content container, every section anchors inside it.
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", SPACING.MD, -LAYOUT.PAD_TOP)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -SPACING.MD, SPACING.MD)

    local section = buildSection(content, "Armory")
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    section:SetPoint("RIGHT", content, "RIGHT", 0, 0)

    -- 1) Character group: name on top at 16px, realm below at 14px, both white for legibility.
    local CHARACTER_BODY = LAYOUT.NAME_H + SPACING.XS + LAYOUT.REALM_H
    local characterGroup = buildGroup(section.body, "Character")
    characterGroup:SetPoint("TOPLEFT", section.body, "TOPLEFT", 0, 0)
    characterGroup:SetPoint("RIGHT", section.body, "RIGHT", 0, 0)
    sizeGroup(characterGroup, CHARACTER_BODY)

    local nameText = characterGroup.body:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    nameText:SetPoint("TOPLEFT", characterGroup.body, "TOPLEFT", 0, 0)
    nameText:SetPoint("RIGHT", characterGroup.body, "RIGHT", 0, 0)
    nameText:SetHeight(LAYOUT.NAME_H)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    frame.nameText = nameText

    local realmText = characterGroup.body:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    realmText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -SPACING.XS)
    realmText:SetPoint("RIGHT", characterGroup.body, "RIGHT", 0, 0)
    realmText:SetHeight(LAYOUT.REALM_H)
    realmText:SetJustifyH("LEFT")
    realmText:SetWordWrap(false)
    frame.realmText = realmText

    -- 2) Link group: help line pinned to one label row above the pre-selected edit box.
    local LINK_BODY = LAYOUT.LABEL_H + SPACING.SM + LAYOUT.EDIT_H
    local linkGroup = buildGroup(section.body, "Link")
    linkGroup:SetPoint("TOPLEFT", characterGroup, "BOTTOMLEFT", 0, -SPACING.MD)
    linkGroup:SetPoint("RIGHT", section.body, "RIGHT", 0, 0)
    sizeGroup(linkGroup, LINK_BODY)

    local linkHelp = linkGroup.body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    linkHelp:SetPoint("TOPLEFT", linkGroup.body, "TOPLEFT", 0, 0)
    linkHelp:SetPoint("RIGHT", linkGroup.body, "RIGHT", 0, 0)
    linkHelp:SetHeight(LAYOUT.LABEL_H)
    linkHelp:SetJustifyH("LEFT")
    linkHelp:SetWordWrap(false)
    linkHelp:SetText(copyHint())

    local link = CreateFrame("EditBox", nil, linkGroup.body, "InputBoxTemplate")
    link:SetHeight(LAYOUT.EDIT_H)
    -- NATIVE: InputBoxVisualTemplate anchors its Left border texture 5px outside the frame, shift the left anchor so the art lines up with the body edge.
    link:SetPoint("TOPLEFT", linkHelp, "BOTTOMLEFT", 5, -SPACING.SM)
    link:SetPoint("RIGHT", linkGroup.body, "RIGHT", 0, 0)
    link:SetAutoFocus(true)
    link:SetFontObject("ChatFontSmall")
    frame.link = link

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

    -- Section height = padding + both groups + the gap between them, frame height adds the banner clearance and bottom inset.
    local sectionHeight = LAYOUT.SECTION_PAD * 2 + characterGroup:GetHeight() + SPACING.MD + linkGroup:GetHeight()
    section:SetHeight(sectionHeight)
    frame:SetSize(LAYOUT.FRAME_W, LAYOUT.PAD_TOP + sectionHeight + SPACING.MD)

    tinsert(UISpecialFrames, "PlayerArmoryLinkFrame")

    return frame
end

local function showPopup(name, realm)
    popup = popup or createPopup()
    popup.url = buildUrl(name, realm)
    popup.nameText:SetText(properCase(name))
    popup.realmText:SetText(realmDisplay(realm))
    popup.link:SetText(popup.url)
    popup.link:SetCursorPosition(0)
    popup:Show()
    popup.link:SetFocus()
    popup.link:HighlightText()
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

    if type(realm) ~= "string" or realm == "" then
        realm = GetRealmName()
    end
    if not realmSlug(realm) then
        return nil
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
