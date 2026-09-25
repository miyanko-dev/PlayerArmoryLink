local _, ns = ...

local ARMORY_URL = "https://worldofwarcraft.blizzard.com/%s/%s/%s/armory/character/%s/%s"

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

-- Returns nil rather than a malformed URL when the realm cannot be slugged, so callers can drop the menu entry instead of offering a dead link.
function ns.ArmoryUrl(name, realm)
    local realmSlug = ns.RealmSlug(realm)
    if not realmSlug then
        return nil
    end
    local locale = LOCALE_SLUGS[GetLocale()] or "en-us"
    return ARMORY_URL:format(locale, ns.ArmorySegment(), ns.RegionSlug(), realmSlug, name:lower())
end
