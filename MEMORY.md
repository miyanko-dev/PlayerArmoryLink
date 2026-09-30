# PlayerArmoryLink — Memory

Updated 2026-09-25 after the dual-client port with native UI (decision: every addon in the folder supports both clients, with each client's own look). Verified against Gethe `forever` @ `bd2470a` (1.60.1.70009), Gethe `classic_era` @ `33e177d` (1.15.9.69722) and the matching Ketho dumps. Nothing has run in a client.

## Current state

Adds **Armory Link** to player right-click menus and opens a copy dialog with the worldofwarcraft.blizzard.com armory URL.

| Item | State |
|---|---|
| Version | 2.1.0, both clients from one toc, `## Interface: 11509, 16001` |
| Author | `miyanko` everywhere, including the backup branch |
| Git | Committed and pushed on 2026-09-25: `main` = `origin/main`. GitHub's README restructure (`04a9a91`) was merged with the local README and toc kept. `1.15.x-backup` = `825e468` (six-client 1.2.0) is pushed too |
| Files | `Core/Compat.lua` (the only client switch), `Core/Link.lua`, `Core/UnitMenu.lua`, `UI/CopyDialog.lua` |

Everything client-specific lives in `Core/Compat.lua`:

| | 1.15.9 | 1.60.1 |
|---|---|---|
| Name switch | `RegionalUniqueNamesEnabled` absent | present |
| Menu context second part | `contextData.server` | `contextData.surname` |
| Name shown | `Name` | `NameUtil.GetFullNameWithoutRealm` |
| Realm | re-spaced `UnitName` realm, else `GetRealmName()` | always `GetRealmName()` |
| Dialog skin (`C_XMLUtil.GetTemplateInfo("ClassicDialogHeaderTemplate")`) | `BackdropTemplate` + `BACKDROP_DIALOG_32_32` + `ClassicDialogHeaderTemplate`, like Era's GameMenuFrame | `DialogBorderTemplate` + `DialogHeaderTemplate`, like Forever's GameMenuFrame |
| Close button offset | (-2,-3) | (-2,-2) |

The rest is shared:

- Fonts are Blizzard font objects (`GameFontNormalLarge`, `GameFontHighlight`, `GameFontDisableSmall`).
- `InputBoxTemplate` and `UIPanelCloseButton`.
- `Menu.ModifyMenu` on both clients.
- The name read runs inside `pcall`.

## Blockers, issues, challenges

1. Blocker for 1.60: no Forever armory URL is known. `Link.lua` uses the Era segment `classic1x` as a placeholder, so 1.60 links probably don't resolve.
2. What `GetRealmName()` returns on realmless 1.60 is unverified. An empty value hides the entry.
3. Where 1.60 identity secrecy applies is unverified. The `pcall` should hide the entry cleanly.
4. Realm slugs strip non-ASCII characters, so links are wrong or empty on ruRU, koKR, zhCN and zhTW realms.
5. There's no `_classic_era_` install. The installed beta is 69913, the source is 70009.

## Next steps

1. After Forever launch, read a real Forever armory URL and fix `Core/Link.lua`.
2. Run `/console scriptErrors 1` first.

Both clients:

- [ ] **Armory Link** appears after a divider on your own portrait, target, focus, party, raid, chat names, friends, guild and community rosters. It never appears on NPCs.
- [ ] CMD+C / CTRL+C closes the dialog after about 0.2 s and shows a green "Armory link copied". Escape and X close it, and edits snap back.

Era:

- [ ] The dialog shows the classic stone border and plaque header. A cross-realm player's realm shows with spaces restored ("Chamber of Aspects").

Forever:

- [ ] The dialog shows the DiamondMetal border and banner, and the name includes the surname.
- [ ] `/dump RegionalUniqueNamesEnabled ~= nil, GetRealmName()` prints `true` and a non-empty realm. This settles issue 2.
- [ ] Recent allies and the PvP scoreboard menus show the entry. Right-clicking a stranger in a dungeon either shows the entry or hides it, with no Lua error.
- [ ] Open the generated link and record the status. This feeds issue 1.
