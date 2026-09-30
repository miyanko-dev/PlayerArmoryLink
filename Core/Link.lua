local _, ns = ...

-- classic1x is the confirmed Classic Era armory. It is UNCONFIRMED for 1.60: worldofwarcraft.blizzard.com has no WoW Forever route yet, so Forever links reuse it until launch shows the real one. See MEMORY.md before changing it.
local ARMORY_URL = "https://worldofwarcraft.blizzard.com/%s/classic1x/%s/armory/character/%s/%s"

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

-- Armory realm slugs are lowercase and dash separated, with apostrophes dropped rather than replaced: Rhok'delar is rhokdelar, not rhok-delar.
local function realmSlug(realm)
    return (realm:gsub("'", ""):lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""))
end

-- Returns nil rather than a malformed URL, so the caller drops the menu entry instead of offering a dead link.
function ns.ArmoryUrl(realm, name)
    local slug = realmSlug(realm)
    if slug == "" then
        return nil
    end
    local locale = LOCALE_SLUGS[GetLocale()] or "en-us"
    return ARMORY_URL:format(locale, GetCurrentRegionName():lower(), slug, name:lower())
end
