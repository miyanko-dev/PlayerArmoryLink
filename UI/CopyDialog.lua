local addonName, ns = ...

local FRAME_NAME = addonName .. "Dialog"
local TITLE = "Player Armory Link"
local COPIED_TEXT = "Armory link copied"
local WIDTH = 448

-- Blizzard's own text roles, so each client draws its native faces and sizes: the name as a gold heading, the realm as white body text, the hint as grey help text.
local NAME_FONT = GameFontNormalLarge
local REALM_FONT = GameFontHighlight
local HINT_FONT = GameFontDisableSmall

-- Both clients' dialog headers hang about 28px into the frame, so content starts a little below them.
local CONTENT_TOP = 40
local PADDING = 20
local NAME_GAP = 2
local LINK_GAP = 8
local HINT_GAP = 4

-- InputBoxTemplate's art is 20px tall, and its left cap sits 5px outside the edit box, so the box shifts right to line the art up with the text column.
local INPUT_HEIGHT = 20
local INPUT_ART_OFFSET = 5

-- Long enough for the client to finish the copy before the edit box goes away.
local CLOSE_DELAY = 0.2

local dialog

local function copyHint()
    local key = IsMacClient() and "CMD" or "CTRL"
    return "Press " .. key .. "+C to copy and close."
end

-- Line heights come from the font objects, so the layout follows each client's own font sizes.
local function fontHeight(font)
    local _, height = font:GetFont()
    return height
end

local function createText(parent, font)
    local text = parent:CreateFontString(nil, "ARTWORK")
    text:SetFontObject(font)
    text:SetHeight(fontHeight(font))
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    return text
end

-- Rows stack down the content column and each one spans to the right padding.
local function stackRow(row, above, gap, indent)
    row:SetPoint("TOPLEFT", above, "BOTTOMLEFT", indent or 0, -gap)
    row:SetPoint("RIGHT", row:GetParent(), "RIGHT", -PADDING, 0)
end

local function isCopyChord(key)
    return key == "C" and (IsControlKeyDown() or IsMetaKeyDown())
end

local function createLinkBox(frame)
    local link = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    link:SetHeight(INPUT_HEIGHT)
    link:SetAutoFocus(false)

    link:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    link:SetScript("OnEnterPressed", link.HighlightText)

    -- Reverts any edit so the link stays intact and fully selected.
    link:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= frame.url then
            self:SetText(frame.url)
            self:HighlightText()
        end
    end)

    link:SetScript("OnKeyDown", function(_, key)
        if not isCopyChord(key) then
            return
        end
        C_Timer.After(CLOSE_DELAY, function()
            frame:Hide()
            UIErrorsFrame:AddMessage(COPIED_TEXT, GREEN_FONT_COLOR:GetRGB())
        end)
    end)

    return link
end

local function createDialog()
    local frame = ns.CreateDialogFrame(FRAME_NAME)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetPoint("CENTER", 0, 140)
    frame:Hide()

    frame.Header:Setup(TITLE)

    frame.name = createText(frame, NAME_FONT)
    frame.name:SetPoint("TOPLEFT", PADDING, -CONTENT_TOP)
    frame.name:SetPoint("RIGHT", -PADDING, 0)

    frame.realm = createText(frame, REALM_FONT)
    stackRow(frame.realm, frame.name, NAME_GAP)

    frame.link = createLinkBox(frame)
    stackRow(frame.link, frame.realm, LINK_GAP, INPUT_ART_OFFSET)

    local hint = createText(frame, HINT_FONT)
    stackRow(hint, frame.link, HINT_GAP, -INPUT_ART_OFFSET)
    hint:SetText(copyHint())

    local height = CONTENT_TOP
        + fontHeight(NAME_FONT) + NAME_GAP
        + fontHeight(REALM_FONT) + LINK_GAP
        + INPUT_HEIGHT + HINT_GAP
        + fontHeight(HINT_FONT) + PADDING
    frame:SetSize(WIDTH, math.ceil(height))

    tinsert(UISpecialFrames, FRAME_NAME)

    return frame
end

function ns.ShowCopyDialog(displayName, realm, url)
    dialog = dialog or createDialog()
    dialog.url = url
    dialog.name:SetText(displayName)
    dialog.realm:SetText(realm)
    dialog.link:SetText(url)
    dialog.link:SetCursorPosition(0)
    dialog:Show()
    dialog.link:SetFocus()
    dialog.link:HighlightText()
end
