local _, ns = ...

-- Every Classic Era 1.15.x and WoW Forever 1.60.x difference lives in this file. RegionalUniqueNamesEnabled exists only on 1.60, where characters carry a first name and a surname instead of belonging to a realm.
local HAS_SURNAMES = RegionalUniqueNamesEnabled ~= nil

-- The dialog skin follows the art the client loaded, not its name rules: ClassicDialogHeaderTemplate loads only for the classic family, and 1.60's Blizzard_SharedXML.toc gates it out.
local CLASSIC_SKIN = C_XMLUtil.GetTemplateInfo("ClassicDialogHeaderTemplate") ~= nil

-- Each client's CreateChannelPopup, a small dialog with the same border, pins UIPanelCloseButton at this corner offset.
local CLOSE_X = -2
local CLOSE_Y = CLASSIC_SKIN and -3 or -2

-- 1.15's GameMenuFrame pairs the classic UI-DialogBox backdrop with ClassicDialogHeaderTemplate. The backdrop sits on the frame itself, as 1.15's CreateChannelPopup carries it, so it draws below the frame's text.
local function createClassicFrame(name)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetBackdrop(BACKDROP_DIALOG_32_32)
    frame.Header = CreateFrame("Frame", nil, frame, "ClassicDialogHeaderTemplate")
    return frame
end

-- 1.60's GameMenuFrame and CreateChannelPopup use the DiamondMetal border and header.
local function createMainlineFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame.Border = CreateFrame("Frame", nil, frame, "DialogBorderTemplate")
    frame.Header = CreateFrame("Frame", nil, frame, "DialogHeaderTemplate")
    return frame
end

-- A dialog in the running client's own chrome: border, frame.Header and a close button.
function ns.CreateDialogFrame(name)
    local frame = CLASSIC_SKIN and createClassicFrame(name) or createMainlineFrame(name)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", CLOSE_X, CLOSE_Y)
    return frame
end

-- UnitPopupManager:OpenMenu stores the second name part as `surname` on 1.60 and as `server` on 1.15.
function ns.ContextSuffix(context)
    if HAS_SURNAMES then
        return context.surname
    end
    return context.server
end

-- Lowercase connectors that realm names keep lowercase, and that 1.15 UnitName glues onto the neighbouring word.
local CONNECTORS = {"of", "der", "des", "die", "das", "dem", "von"}

-- Restores word breaks in a realm from 1.15 UnitName, which strips spaces: "ChamberofAspects" becomes "Chamber of Aspects".
local function splitRealmWords(realm)
    realm = realm:gsub("(%l)(%u)", "%1 %2")
    for _, word in ipairs(CONNECTORS) do
        realm = realm:gsub("(%l)(" .. word .. ") (%u)", "%1 %2 %3")
    end
    return realm
end

-- Turns a name and its second part into the name to show and the realm it lives on. 1.60 is realmless, so every player shares the current realm.
function ns.Identify(name, suffix)
    if HAS_SURNAMES then
        return NameUtil.GetFullNameWithoutRealm(name, suffix), GetRealmName()
    end
    if suffix and suffix ~= "" then
        return name, splitRealmWords(suffix)
    end
    return name, GetRealmName()
end
