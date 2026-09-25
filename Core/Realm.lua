local _, ns = ...

-- Lowercase connectors that realm names keep lowercase, and that UnitName glues onto the neighbouring word.
local CONNECTORS = {"of", "der", "des", "die", "das", "dem", "von"}

-- Restores word breaks in a realm from UnitName, which strips spaces: "ChamberofAspects" becomes "Chamber of Aspects". GetRealmName already returns spaces, so a name that has one is left alone.
local function splitRealmWords(realm)
    if realm:find("%s") then
        return realm
    end
    realm = realm:gsub("(%l)(%u)", "%1 %2")
    for _, word in ipairs(CONNECTORS) do
        realm = realm:gsub("(%l)(" .. word .. ") (%u)", "%1 %2 %3")
    end
    return realm
end

-- Capitalizes each word and keeps connectors lowercase unless they lead.
function ns.ProperCase(text)
    local index = 0
    return (text:gsub("(%S+)", function(word)
        index = index + 1
        if index > 1 and tContains(CONNECTORS, word:lower()) then
            return word:lower()
        end
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

-- Armory realm slugs are lowercase and dash separated, with apostrophes dropped rather than replaced: Rhok'delar is rhokdelar, not rhok-delar.
function ns.RealmSlug(realm)
    if type(realm) ~= "string" or realm == "" then
        return nil
    end
    realm = splitRealmWords(realm:gsub("'", ""))
    realm = realm:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    return realm ~= "" and realm or nil
end

function ns.RealmDisplay(realm)
    return ns.ProperCase(splitRealmWords(realm))
end
