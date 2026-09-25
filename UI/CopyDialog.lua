local _, ns = ...

-- One dialog serves both clients. Every template, font object and texture it touches was confirmed present on Classic Era 1.15.9 and WoW Forever 1.60.1, so there is no per-version UI variant to load.

local DIALOG_TITLE = "Player Armory Link"
local FRAME_NAME = "PlayerArmoryLinkFrame"

-- One 4px unit and its multiples cover every distance in the dialog.
local UNIT = 4
local LAYOUT = {
    FRAME_W = 480,
    BANNER = UNIT * 12, -- clears the dialog-box header
    PAD = UNIT * 4, -- frame inset, gap between boxes, box body padding
    LABEL_INSET = 2, -- box label sits 2px in from the box edge and one UNIT above it
    LINE_LG = 16, -- GameFontHighlightLarge line
    LINE = 12, -- GameFontNormal and GameFontDisable line
    EDIT_H = 20, -- InputBoxTemplate
}

local dialog

local function copyHint()
    return "Press " .. ns.CopyModifierName() .. "+C to copy and close."
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
    label:SetPoint("BOTTOMLEFT", section, "TOPLEFT", LAYOUT.LABEL_INSET, UNIT)
    label:SetText(labelText)
    section.label = label

    local body = CreateFrame("Frame", nil, section)
    body:SetPoint("TOPLEFT", section, "TOPLEFT", LAYOUT.PAD, -LAYOUT.PAD)
    body:SetPoint("BOTTOMRIGHT", section, "BOTTOMRIGHT", -LAYOUT.PAD, LAYOUT.PAD)
    section.body = body

    return section
end

local function buildValueText(section)
    local text = section.body:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    text:SetAllPoints(section.body)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    return text
end

local function buildLinkBox(frame, section)
    local help = section.body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    help:SetPoint("TOPLEFT", section.body, "TOPLEFT", 0, 0)
    help:SetPoint("RIGHT", section.body, "RIGHT", 0, 0)
    help:SetHeight(LAYOUT.LINE)
    help:SetJustifyH("LEFT")
    help:SetWordWrap(false)
    help:SetText(copyHint())

    local link = CreateFrame("EditBox", nil, section.body, "InputBoxTemplate")
    link:SetHeight(LAYOUT.EDIT_H)
    -- NATIVE: InputBoxVisualTemplate anchors its Left border texture 5px outside the frame, shift the left anchor so the art lines up with the body edge.
    link:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 5, -UNIT * 2)
    link:SetPoint("RIGHT", section.body, "RIGHT", 0, 0)
    link:SetAutoFocus(true)
    link:SetFontObject("ChatFontSmall")

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
        if key ~= "C" or not ns.IsCopyModifierDown() then
            return
        end
        -- Deferred so the client finishes the copy before the frame goes away.
        C_Timer.After(0.2, function()
            frame:Hide()
            UIErrorsFrame:AddMessage("Armory link copied", 0.2, 1, 0.2)
        end)
    end)

    return link
end

local function createDialog()
    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
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

    buildTitleHeader(frame, DIALOG_TITLE)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    -- The single content container, every box anchors inside it.
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", LAYOUT.PAD, -LAYOUT.BANNER)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -LAYOUT.PAD, LAYOUT.PAD)

    -- Two half-width boxes side by side.
    local columnWidth = (LAYOUT.FRAME_W - LAYOUT.PAD * 3) / 2
    local VALUE_BOX_H = LAYOUT.PAD * 2 + LAYOUT.LINE_LG

    local nameSection = buildSection(content, "Character")
    nameSection:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    nameSection:SetSize(columnWidth, VALUE_BOX_H)
    frame.nameText = buildValueText(nameSection)

    local realmSection = buildSection(content, "Realm")
    realmSection:SetPoint("TOPLEFT", nameSection, "TOPRIGHT", LAYOUT.PAD, 0)
    realmSection:SetSize(columnWidth, VALUE_BOX_H)
    frame.realmText = buildValueText(realmSection)

    -- Full-width link box below, the PAD gap is exactly one label line plus its UNIT offset.
    local LINK_BOX_H = LAYOUT.PAD * 2 + LAYOUT.LINE + UNIT * 2 + LAYOUT.EDIT_H
    local linkSection = buildSection(content, "Link")
    linkSection:SetPoint("TOPLEFT", nameSection, "BOTTOMLEFT", 0, -LAYOUT.PAD)
    linkSection:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    linkSection:SetHeight(LINK_BOX_H)
    frame.link = buildLinkBox(frame, linkSection)

    -- Frame height = banner clearance + value row + gap + link box + bottom inset.
    frame:SetSize(LAYOUT.FRAME_W, LAYOUT.BANNER + VALUE_BOX_H + LAYOUT.PAD + LINK_BOX_H + LAYOUT.PAD)

    tinsert(UISpecialFrames, FRAME_NAME)

    return frame
end

function ns.ShowCopyDialog(name, realm, url)
    dialog = dialog or createDialog()
    dialog.url = url
    dialog.nameText:SetText(ns.ProperCase(name))
    dialog.realmText:SetText(ns.RealmDisplay(realm))
    dialog.link:SetText(url)
    dialog.link:SetCursorPosition(0)
    dialog:Show()
    dialog.link:SetFocus()
    dialog.link:HighlightText()
end
