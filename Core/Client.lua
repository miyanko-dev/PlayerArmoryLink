local _, ns = ...

-- Every place Classic Era 1.15.x and WoW Forever 1.60.x differ lives here, so a new build is checked against one file. Differences are detected by feature or by build number, never by a hardcoded flavor list.

-- 1.60 hands unit names out as secret values under identity restrictions; 1.15.9 ships the same function and never issues secrets, so one guard serves both. The argument is documented non-nilable, so nil is screened out before the call rather than passed through.
local canAccessValue = canaccessvalue

function ns.IsReadable(value)
    if value == nil then
        return false
    end
    if canAccessValue then
        return canAccessValue(value)
    end
    return true
end

-- Armory path segments, each one confirmed routable under worldofwarcraft.blizzard.com.
local ARMORY_ERA = "classic1x"
local ARMORY_ANNIVERSARY = "classicann"
local ARMORY_PROGRESSION = "classic"
local ARMORY_RETAIL = "worldsoul"

-- WoW Forever has no armory segment of its own yet, so it rides the Vanilla lineage's. Change this one line if launch adds a dedicated segment.
local ARMORY_FOREVER = ARMORY_ERA

-- Keyed by WOW_PROJECT_ID. Only 1 and 2 are declared on every client; the higher ids are reported by their own client only.
local PROJECT_SEGMENTS = {
    [1] = ARMORY_RETAIL,
    [2] = ARMORY_ERA,
    [5] = ARMORY_ANNIVERSARY,
    [19] = ARMORY_PROGRESSION,
}

-- Last resort for a client whose WOW_PROJECT_ID is unmapped, keyed by interface band.
local INTERFACE_SEGMENTS = {
    {below = 20000, segment = ARMORY_ERA},
    {below = 30000, segment = ARMORY_ANNIVERSARY},
    {below = 60000, segment = ARMORY_PROGRESSION},
}

local FOREVER_INTERFACE_MIN = 16000
local FOREVER_INTERFACE_MAX = 16999

local function interfaceVersion()
    return select(4, GetBuildInfo()) or 0
end

-- WoW Forever runs the retail engine and reports WOW_PROJECT_MAINLINE, so the project id alone would send 1.60 to the retail armory. Its interface band is checked first and settles it, the same way Questie's Forever port detects the client.
local function isForeverClient()
    local version = interfaceVersion()
    return version >= FOREVER_INTERFACE_MIN and version <= FOREVER_INTERFACE_MAX
end

function ns.ArmorySegment()
    if isForeverClient() then
        return ARMORY_FOREVER
    end

    local mapped = PROJECT_SEGMENTS[WOW_PROJECT_ID]
    if mapped then
        return mapped
    end

    local version = interfaceVersion()
    for _, band in ipairs(INTERFACE_SEGMENTS) do
        if version < band.below then
            return band.segment
        end
    end
    return ARMORY_RETAIL
end

-- GetCurrentRegionName is the stable spelling and needs no index table; the numeric form stays as a fallback in case a client only ships that one.
local REGION_BY_INDEX = {"us", "kr", "eu", "tw", "cn"}

function ns.RegionSlug()
    if GetCurrentRegionName then
        local name = GetCurrentRegionName()
        if type(name) == "string" and name ~= "" then
            return name:lower()
        end
    end
    if GetCurrentRegion then
        return REGION_BY_INDEX[GetCurrentRegion()] or "us"
    end
    return "us"
end

-- Era menus carry the realm as `server`; the 1.60 menu code splits "Name-Realm" into `name` and `surname`. Both spellings are set by UnitPopupManager:OpenMenu on their own build.
function ns.ContextRealm(context)
    return context.server or context.surname
end

-- Resolved from the running client, IsMacClient is false on Windows and Linux.
function ns.CopyModifierName()
    if IsMacClient and IsMacClient() then
        return "CMD"
    end
    return "CTRL"
end

function ns.IsCopyModifierDown()
    if IsControlKeyDown() then
        return true
    end
    return IsMetaKeyDown ~= nil and IsMetaKeyDown()
end
