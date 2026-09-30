# PlayerArmoryLink — Memory

Updated 2026-09-30 after the Forever-only audit. The owner's decision now is WoW Forever 1.60.x only: `main` drops everything that exists only for Classic, and `1.15.x-backup` keeps the Classic version. This supersedes the 2026-09-25 decision that every addon supports both clients with each client's own look. The audit verified against Gethe `forever` @ `966519cf` (1.60.1.70124) and Ketho `forever` @ `4149af64` (1.60.1.70009). The installed client is 1.60.1.70009. Nothing has run in a client yet.

## Current state

Adds **Armory Link** to player right-click menus and opens a copy dialog with the worldofwarcraft.blizzard.com armory URL.

| Item | State |
|---|---|
| Version | 3.0.0, Forever only: `## Interface: 16001`, `## Category: Social` |
| Author | `miyanko` everywhere, including the backup branch |
| Git | `main` holds 3.0.0 (committed 2026-09-30, not pushed). `1.15.x-backup` = `b665cf4` on GitHub: a merge whose tree is the dual-client 2.1.0 (`7043e86`, the last commit that supports 1.15.x), with the older six-client 1.2.0 snapshot `825e468` kept as its first parent |
| Files | `Core/Link.lua`, `Core/UnitMenu.lua`, `UI/CopyDialog.lua` |

How names are read on Forever:

- Every menu reads `context.name` and `context.surname`. For unit menus, `UnitPopupManager:OpenMenu` fills both from `UnitNameUnmodified` (`UnitPopupShared.lua:36-39`), so unit frames and rosters share one source. A roster name with no surname is split on a space or hyphen ("First Surname" or the link form "First-Surname").
- `RegionalUniqueNamesEnabled()` is called, not just tested for existence. When true, the second part is a surname, the display name is `NameUtil.GetFullNameWithoutRealm`, and the realm is `GetRealmName()`. When false, the second part is the realm, as Blizzard's menu treats it.
- The dialog is Forever's GameMenuFrame chrome (`MainMenuFrameTemplate`): `DialogBorderTemplate` as `.Border`, `DialogHeaderTemplate` as `.Header` (default anchor TOP +11), and a `UIPanelCloseButton` at (-2, -2). Strata DIALOG, toplevel, clamped, movable, Escape via `UISpecialFrames`.

The rest is shared and verified on Forever:

- Blizzard font objects, `InputBoxTemplate` and `UIPanelCloseButton`
- `DialogHeaderMixin:Setup` (`Blizzard_SharedXML/Shared/Dialog/DialogTemplates.lua:10`)
- `Menu.ModifyMenu` with `MENU_UNIT_<which>` tags (`UnitPopupShared.lua:110`)
- The name read inside `pcall`. `canaccessvalue` and `issecretvalue` are both `SecretArguments = "AllowedWhenUntainted"`, so an addon can't guard with them

## Forever-only rework (done 2026-09-30)

- PAL-2: `## Interface: 16001` only, version 3.0.0, `## Category: Social`.
- PAL-3: `Core/Compat.lua` is deleted. The Classic skin, the `server` context branch and the 1.15 realm re-spacing (`splitRealmWords`) are gone. The dialog builder moved into `UI/CopyDialog.lua`, and name handling into `Core/UnitMenu.lua`.
- PAL-4: `RegionalUniqueNamesEnabled()` is called.
- PAL-5: unit menus read Blizzard's own `context.name`/`context.surname` (from `UnitNameUnmodified`) instead of `UnitName(unit)`. This removes the ambiguity about `UnitName`'s return shape. Trade-off: in content where only `UnitNameUnmodified` is secret (`SecretWhenUnitIdentityRestricted`), the entry now hides rather than showing.
- PAL-6: `MENU_UNIT_WORLD_STATE_SCORE` is dropped; nothing on Forever opens it.
- PAL-7: the fallback split keeps both separators, because chat links use `CHARACTERNAME_LINK_SEPARATOR` "-". Only its comment changed.
- PAL-9: the README is Forever only.

Still open:

- PAL-1 (High, external): no Forever armory route is known, so links use the Era `classic1x` segment.
- PAL-8 (Low): realm slugs strip non-ASCII characters. Revisit once the Forever URL format is known.

Nothing to do:

- The copy dialog's behaviour: select all, snap-back, copy chord, Escape through `UISpecialFrames`.
- `Menu.ModifyMenu` integration, with no taint.
- No saved variables.

Branches: `1.15.x-backup` (`b665cf4`) merges the old side snapshot `825e468` with `7043e86`, and its tree is the dual-client 2.1.0. `main` continues from `7043e86` with the Forever-only 3.0.0. No work is lost.

## Blockers, issues, challenges

1. Blocker for 1.60: no Forever armory URL is known (PAL-1).
2. What `GetRealmName()` returns on realmless 1.60 is unverified. An empty value hides the entry.
3. Where 1.60 identity secrecy applies is unverified. The `pcall` should hide the entry cleanly.
4. The name forms on Forever are unverified; the addon now uses exactly the values Blizzard's own menu uses.

## Next steps

1. Review and push `main` (3.0.0).
2. After Forever launch, read a real Forever armory URL and fix `Core/Link.lua` (PAL-1, PAL-8).
3. Run `/console scriptErrors 1` first in game.

Forever checks:

- [ ] **Armory Link** appears after a divider on your own portrait, target, focus, party, raid, chat names, friends, guild and community rosters. It never appears on NPCs.
- [ ] CMD+C / CTRL+C closes the dialog after about 0.2 s and shows a green "Armory link copied". Escape and X close it, and edits snap back.
- [ ] The dialog shows the DiamondMetal border and banner, and the name includes the surname.
- [ ] `/dump RegionalUniqueNamesEnabled(), GetRealmName(), UnitNameUnmodified("target")` on a player target. This settles issue 2 and confirms the name source.
- [ ] Recent allies and the PvP scoreboard menus show the entry. Right-clicking a stranger in a dungeon either shows the entry or hides it, with no Lua error.
- [ ] Open the generated link and record the status. This feeds issue 1.
