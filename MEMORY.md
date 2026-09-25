# PlayerArmoryLink — Development Memory

The single persistent note for this addon. Read it before touching the code instead of re-deriving anything. Consolidated on 2026-09-19 from `NEXT-STEPS.md` (merged in and deleted) plus the compatibility parts of `README.md`.

**Verified against:** `forever` @ `70ef1b2` (1.60.1.69913), 2026-09-21.

**Shared 1.60 client facts are not in this file.** They live in one place: `Cortex/WoW/Forever Client Facts.md` in the Obsidian vault (`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/`). Read that first — this note records only what is specific to this addon, and never restates a fact about the client. Companions there: `Two-Version Addon Architecture.md` (layout), `UI Compatibility Analysis.md` (templates and widgets). Run `../check-client-facts.sh` to see whether any of it has gone stale.

---

## 1. Status on 2026-09-19

| Item | State |
|---|---|
| Version | 1.2.0 (was 1.1.0), **uncommitted** on top of HEAD `9e00a53` |
| Repo | `github.com/miyanko-dev/PlayerArmoryLink`, branch `main`. No `.pkgmeta`, no CI |
| Working tree | ` D PlayerArmoryLink.lua`, ` M PlayerArmoryLink.toc`, ` M README.md`, `?? Core/`, `?? UI/`, `?? MEMORY.md` |
| Restructure | one 399-line `PlayerArmoryLink.lua` split into five files across `Core/` and `UI/` |
| Targets | Classic Era 1.15.x (11508/11509), WoW Forever 1.60.1 build 69913 (game type camelot, 16001), plus Anniversary 20506, Mists 50504, Retail 120100 in the toc |
| Sources verified | `Gethe/wow-ui-source` `forever` @ `70ef1b2` (1.60.1, 69913), `classic_era` @ `33e177d` (1.15.9, 69722); live armory routes probed 2026-09-19 |
| Installed clients | Forever beta only (`_classic_beta_`). No character has logged in. No 1.15.x client on this Mac |
| Verdict | Compatible with both after the fixes in section 3. Two real bugs found, one broke the addon's purpose on 1.60 |
| Offline checks | `luac -p` clean on all five files; load-order check; stub harness run in a session scratchpad (not in the repo, lost) |
| In-game checks | **None** |

---

## 2. How to resume

1. `git status`: expect the tree above.
2. Seam check: `grep -rE 'GetBuildInfo|WOW_PROJECT|11509|16001' Core UI` must hit nothing outside `Core/Client.lua` (clean on 2026-09-19).
3. `luac -p Core/*.lua UI/*.lua`.
4. Highest-value unknowns: whether Forever characters appear on the armory at all and under which segment (section 6, question 1), and the live interface number (question 2).

---

## 3. Layout

One codebase serves every flavor. `Core/Client.lua` is the only file that knows the clients differ.

```
PlayerArmoryLink.toc   ## Interface: 11508, 11509, 16001, 20506, 50504, 120100
Core/Client.lua        game version, region, copy modifier, secret-value guard, menu context shape
Core/Realm.lua         realm word splitting, armory slug, display casing
Core/Link.lua          armory URL assembly
UI/CopyDialog.lua      the copy dialog
Core/UnitMenu.lua      unit menu entry and player resolution (loads last, registers callbacks at end of load)
```

The UI is not split per version. Every template, font object and texture the dialog touches (`BackdropTemplate`, `InputBoxTemplate`, `UIPanelCloseButton`, `GameFontNormal`, `GameFontHighlightLarge`, `GameFontDisable`, `ChatFontSmall`, the `UI-DialogBox-*` art) was confirmed present on both 1.15.9 and 1.60.1. No slash commands, no saved variables, nothing configurable.

### URL format and detection

```
https://worldofwarcraft.blizzard.com/<locale>/<version>/<region>/armory/character/<realm>/<name>
```

| Signal | Client | Segment |
|---|---|---|
| interface 16000–16999 (checked first) | WoW Forever 1.60 | `classic1x` (placeholder, `ARMORY_FOREVER` in `Core/Client.lua`) |
| `WOW_PROJECT_ID` 1 | Mainline 12.1.0 | `worldsoul` |
| `WOW_PROJECT_ID` 2 | Classic Era 1.15.x | `classic1x` |
| `WOW_PROJECT_ID` 5 | Anniversary 2.5.6 | `classicann` |
| `WOW_PROJECT_ID` 19 | Classic Progression 5.5.4 | `classic` |
| unmapped, interface < 20000 | Vanilla lineage | `classic1x` |

WoW Forever must be caught before the project id because it runs the retail engine and reports `WOW_PROJECT_MAINLINE`. Anniversary realms progress through expansions, so their project id moves; adding a new id to `PROJECT_SEGMENTS` in `Core/Client.lua` is one line.

Region: `GetCurrentRegionName()` lowercased, falling back to the `REGION_SLUGS[GetCurrentRegion()]` index table. Copy modifier: `IsMacClient()` → CMD, else CTRL. The dialog pre-selects the link; `OnKeyDown` on the EditBox with `key == "C"` while CTRL or CMD is held closes the dialog ~0.2 s later and prints a green "Armory link copied" in `UIErrorsFrame`.

---

## 4. Fixes applied on 2026-09-19

| # | Severity | Where | Problem | Fix |
|---|---|---|---|---|
| F1 | breaking on 1.60 | `projectVersionSlug` in the old single file | `PROJECT_VERSIONS[WOW_PROJECT_ID]` consulted first; Forever reports `WOW_PROJECT_MAINLINE` (1), so every 1.60 link used the retail `worldsoul` segment and the interface fallback was dead code | `Core/Client.lua` checks the 16000–16999 band first, then project id, then interface bands |
| F2 | error on both | `resolvePlayer` | `canaccessvalue(name)` reached before `type(name) ~= "string"`; nil passed to an argument documented `Nilable = false` | `ns.IsReadable` screens nil before calling `canaccessvalue`. **Superseded 2026-09-21: the whole guard is unsound, see section 9** |
| F3 | wrong slug | `splitRealmWords` | `LEADING_ARTICLES` rewrote `^Der/Die/Das` + lowercase, which only fires on single-word realms the camel-case split left alone: "Derwisch" → "Der wisch", slug `der-wisch` | Pass removed. No realm reaches `splitRealmWords` with a space; camel-case splitting handles every real `Der Rat von Dalaran` style name |
| F4 | robustness | region lookup | `REGION_SLUGS[GetCurrentRegion()]` depends on an undocumented index order | `GetCurrentRegionName()` preferred; index table kept as fallback |
| F5 | robustness | URL assembly | `realmSlug(realm)` could return nil into `string.format("%s")` | `ns.ArmoryUrl` returns nil; `Core/UnitMenu.lua` drops the menu entry rather than offering a dead link |
| F6 | robustness | `resolvePlayer` | A realm returned as a 1.60 secret value was never guarded, only the name | Realm screened with `ns.IsReadable` too, falls back to `GetRealmName()` |
| F7 | docs | `README.md` | Claimed `DialogBorderTemplate`; the dialog applies a manual `UI-DialogBox-*` backdrop. Install path named `_classic_era_` only | Corrected; Layout section and detection table added |

The author's uncommitted 1.1.0 edits (16001 in the toc, the `surname` menu field, the `canaccessvalue` guard) were correct in intent and are kept, folded into the new layout.

---

## 5. Confirmed findings

### 5.1 Everything the addon touches exists on both builds

| Symbol | 1.15.9 | 1.60.1 | Where |
|---|---|---|---|
| `Menu.ModifyMenu(tag, callback)` | yes | yes | `Blizzard_Menu/Menu.lua`, byte-identical bodies. `Blizzard_Menu` is `LoadFirst: 1`, `AllowLoad: Both`, exists before any addon runs |
| `root:CreateButton(text, callback, data)`, `root:CreateDivider()` | yes | yes | `Blizzard_Menu/MenuUtil.lua` `MenuUtilPrivate.Inserters` |
| All 19 `MENU_UNIT_*` tags used | yes | yes | `Blizzard_UnitPopupShared/UnitPopupSharedMenus.lua`, `RegisterMenu("SELF")` through `RegisterMenu("RECENT_ALLY_OFFLINE")`. 1.60 adds `DISCORD_USER*`, drops nothing used |
| `canaccessvalue(value)` | present | present | **Present but unusable from addon code — see the canonical note, *How to guard*. `ns.IsReadable` in `Core/Client.lua` is built on it and is therefore broken. Tracked in section 9.** |
| `GetCurrentRegionName()`, `GetCurrentRegion()` | yes | yes | used in FrameXML on both; `GetCurrentRegion` documented as returning a number |
| `GetBuildInfo()` 4th return | yes | yes | `interfaceVersion` at position 4 on both |
| `IsMacClient()`, `IsMetaKeyDown()`, `IsControlKeyDown()` | yes | yes | FrameXML use on both |
| `UnitName`, `UnitIsPlayer`, `GetRealmName`, `GetLocale`, `tContains`, `C_Timer.After`, `UIErrorsFrame` | yes | yes | |
| `UISpecialFrames` | yes | yes | `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua`, iterated by the ESC handler |
| `BackdropTemplate`, `InputBoxTemplate`, `UIPanelCloseButton` | yes | yes | |
| `GameFontNormal`, `GameFontHighlightLarge`, `GameFontDisable`, `ChatFontSmall` | yes | yes | `Blizzard_Fonts_Shared/Shared/Fonts.xml`, same line on both |
| `OnKeyDown` script on an EditBox | yes | yes | `UI.xsd` `ScriptsType`, shared by every frame type |

### 5.2 The menu context field differs; the 1.1.0 edit was right

`UnitPopupManager:OpenMenu`:

- 1.15.9 (`UnitPopupShared.lua:33-48`): `name, server = UnitNameUnmodified(unit)`; for roster entries `strmatch(name, "^([^-]+)-(.*)")` into `contextData.name` and `contextData.server`.
- 1.60.1 (`UnitPopupShared.lua:33-52`): the same fields are `name` and **`surname`**, and the split only runs `if name and not RegionalUniqueNamesEnabled()`.

So `ns.ContextRealm` in `Core/Client.lua` reads `context.server or context.surname`, and `Core/UnitMenu.lua` still splits a joined `Name-Realm` itself, because with regionally unique names enabled Blizzard leaves it joined. `RegionalUniqueNamesEnabled` exists only on `forever` (13 files); the addon does not call it.

### 5.3 Secret values on 1.60

- `UnitName` is `SecretWhenUnitNameIdentityRestricted`: "regular unit identity secrecy rules, except in PvP when the queried unit is a player."
- `SecretWhenUnitIdentityRestricted` (on `UnitNameUnmodified`): "Guarded APIs and events produce secret values when the unit isn't player-controlled or in the party/raid."
- `UnitName` is therefore the better call because of the extra player exception. `Core/UnitMenu.lua` uses it deliberately.
- 1.15.9 has `canaccessvalue` and `issecretvalue` but no `Secret*` annotation on any unit function, so the guard is a no-op there.
- Caveat from ChatScan's audit: on `forever`, `canaccessvalue` is declared `SecretArguments = "AllowedWhenUntainted"`, so handing it a genuine secret from tainted addon code may raise instead of returning false. Unverified in game; see `../ChatScan/MEMORY.md` open question 2. The nil screen (F2) is unaffected.

### 5.4 WoW Forever cannot be detected by project id

- `forever` defines only `WOW_PROJECT_MAINLINE = 1` and `WOW_PROJECT_CLASSIC = 2` (`Blizzard_ProjectConstants/ProjectConstants.lua`). No Camelot constant.
- `WOW_PROJECT_ID` is set by the C client and assigned nowhere in FrameXML except the Plunderstorm override, so its 1.60 value cannot be read from source. Two beta reports say it is 1.
- `C_GameRules.GetActiveGameMode()` is no discriminator: `Enum.GameMode` is `Standard`, `Plunderstorm`, `WoWHack`, `Foo` on both branches, no Camelot value.
- That leaves the interface number, which Questie's Forever port also uses (draft PR Questie/Questie#7847 detects the client by a `GetBuildInfo` prefix of "16").

### 5.5 Armory routes, probed live 2026-09-19 against `worldofwarcraft.blizzard.com`

| Path | Status |
|---|---|
| `/en-us/classic1x/us/armory/` | 200 |
| `/en-us/classicann/us/armory/` | 200 |
| `/en-us/classic/us/armory/` | 200 |
| `/en-us/worldsoul/us/armory/` | 200 |
| `/en-us/nonsenseversion/us/armory/...` | 404 |
| `/en-gb/classic1x/eu/armory/character` | 200 |
| `/en-gb/classic1x/eu/armory/notaroute` | 500 |
| `/en-gb/classic1x/eu/armory/character/firemaw` | 404, the name segment is required |
| `/en-gb/{forever,camelot,classicforever,wowforever,classicera,era,anniversary}/...` | 404 |

All four segments the addon can emit are real routes; the `armory/character/<realm>/<name>` shape is structurally confirmed. No Forever-specific segment exists yet, expected because launch is 2026-11-04 and no beta character is on the armory.

---

## 6. Assumptions (inferred, not proven)

1. **Interface 16001 is the live number on 1.60.1.** Derived as `major*10000 + minor*100 + patch`. The detection band 16000–16999 survives 1.60.2 and 1.60.9 but not a renumbering.
3. **Forever characters will appear on the armory under `classic1x`.** They may get their own segment at launch or not be published at all. The single most likely thing to need changing.
4. **A comma-separated `## Interface` list is accepted by the 1.60 client.** Every Forever-aware addon installed locally relies on it; none has run. The beta binary holds `camelot` and `wow_camelot` strings but no toc suffix literal.
5. **`UI-DialogBox-Header`, `UI-DialogBox-Background`, `UI-DialogBox-Border`, `ChatFrameBackground` and `UI-Tooltip-Border` are in 1.60 client data.** On the `forever` tree `UI-DialogBox-Header` is referenced only from Classic-gated files (`Blizzard_QuestTimer/Classic/`, `Blizzard_ColorPickerFrame/Classic/`) that do not load on camelot. Almost certainly ships anyway; a missing texture renders as a green or black block, a visual check not a crash risk.
6. **`OnKeyDown` fires on a focused EditBox while CTRL or CMD is held with `key == "C"`.** Pre-existing design and the only thing between the copy and the auto-close. If it does not fire the link is still copyable; the dialog just stays open.
7. **Party and raid member names are readable on 1.60.** Normal unit-identity declassification. A wrong guess is harmless: the menu entry is omitted.

### Unresolved questions, by impact

1. What armory segment, if any, Forever characters are published under.
2. Live interface number on 1.60.1.
3. Whether `Menu.ModifyMenu` entries appear on the 1.60 unit menus on every one of the 19 tags.
4. Whether `UnitName` returns a secret for an enemy player in a 1.60 battleground, and for a random world player outside the group.
5. Whether the CMD+C / CTRL+C auto-close fires on both clients.
6. Whether the dialog art renders correctly on 1.60 given its Camelot nine-slice overrides.
7. Whether a comma-separated `## Interface` list loads on 1.60, or a `_Camelot.toc` suffix is required.

---

## 7. Verification done without a client

- `luac -p` clean on all five files.
- Load order: every `ns.*` a file reads at call time is defined by an earlier toc entry. `Core/UnitMenu.lua` registers its callbacks at the end of load and only calls `ns.*` from inside them.
- A stub harness (session scratchpad, **not shipped and since lost**; no `Tools/` exists in this repo) loaded the toc order under six client shapes and asserted `canaccessvalue` is never called with nil:

| Profile | Segment | Region | Modifier |
|---|---|---|---|
| Classic Era 1.15.9 | `classic1x` | eu | CMD |
| WoW Forever 1.60.1 | `classic1x` | eu | CMD |
| Forever with a secret unit name | entry omitted | | |
| Retail 12.1.0 | `worldsoul` | us | CTRL |
| Anniversary 2.5.6 | `classicann` | us | CTRL |
| Mists progression 5.5.4 | `classic` | us | CTRL |

Context cases, identical on every profile: roster entry on own realm, roster entry with `server`, roster entry with a 1.60 `surname`, a joined `Name-Realm`, an apostrophe realm, a unit frame, and correct refusal for nil name, `UNKNOWN`, a secret name and a non-player unit. Sample output `https://worldofwarcraft.blizzard.com/en-us/classic1x/eu/armory/character/chamber-of-aspects/bumblefoot`. Realm handling: `KultderVerdammten` → "Kult der Verdammten", `HydraxianWaterlords` → "Hydraxian Waterlords", `Rhok'delar` → slug `rhokdelar`, `Derwisch` → slug `derwisch` (F3).

What the harness could not prove: the widget stub auto-created any method asked for, so a misspelled widget method would pass. Anchoring, texture loading, focus, key delivery and the real menu system are untested. If a harness is wanted again, model it on `../SuperSocial/Tools/harness.lua` and commit it.

---

## 8. Testing checklist

`/console scriptErrors 1` first. Record results in section 10.

### 8.1 Both clients

- [ ] Log in; **Player Armory Link** enabled, no Lua error. `/reload`, no error.
- [ ] Right-click own portrait: a divider and an **Armory Link** entry at the bottom of the menu.
- [ ] Pick it: dialog centred and above middle, header banner drawn, three boxed sections, Character and Realm filled, link selected, hint reads CMD+C on macOS.
- [ ] Press CMD+C (or CTRL+C): dialog closes within ~0.2 s, green "Armory link copied" in the error area. Paste into a browser; the character page loads. Answers questions 1 and 5.
- [ ] Reopen, Escape closes. Reopen, type into the link box: text snaps back and stays selected. Reopen, drag by the body: it moves.
- [ ] Walk the tags: party member frame, raid frame row, chat name, friends-list row, guild-roster row, battleground scoreboard row, target, focus frame. Entry on all. Answers question 3.
- [ ] Right-click an NPC and a critter: **no** entry.
- [ ] Right-click a cross-realm player: their realm in the Realm box, not yours.
- [ ] German client: players on `Die Aldor`, `Der Mithrilorden`, `Kult der Verdammten`: Realm box spaced correctly, slug dashed correctly.

### 8.2 1.60 only

- [ ] `/dump select(4, GetBuildInfo())`: a number in 16000–16999. Otherwise change `FOREVER_INTERFACE_MIN`/`MAX` in `Core/Client.lua` and the toc. Answers question 2.
- [ ] `/dump WOW_PROJECT_ID`: record it. If not 1, note it in section 10; the interface check makes it moot.
- [ ] `/dump GetCurrentRegionName()`: `EU` or `US`, not nil.
- [ ] Inspect the header banner and box borders closely. Camelot re-tunes nine-slice corner offsets; green or black blocks mean absent texture. Answers assumption 4 and question 6.
- [ ] Battleground: right-click an enemy player's nameplate or unit frame. Absent entry means `UnitName` came back secret, which is correct behaviour. Answers question 4.
- [ ] Dungeon or raid: right-click a party member, then a non-group player if one is around. Record both.
- [ ] Macro `print(issecretvalue(UnitName("target")))` on a stranger in the open world: records where the secrecy line falls.
- [ ] `/dump C_GameRules.GetActiveGameMode()`: `0` or `Enum.GameMode.Standard`. Confirms it is not a Forever discriminator.

### 8.3 1.15.x

Requires reinstalling `_classic_era_`. Run 8.1 in full. Expected: every menu entry present, no secret values ever, `RegionalUniqueNamesEnabled` nil.

---

## 9. Next development steps

Steps 1 and 2 need no beta access.

1. **Remove `ns.IsReadable` (`Core/Client.lua:6-8`), which is unsound.** It wraps `canaccessvalue`, and that function is `SecretArguments = "AllowedWhenUntainted"` while addon execution is tainted, so handing it a secret raises the very error it was written to catch — see *How to guard* in `Cortex/WoW/Forever Client Facts.md`. Replace with a no-argument state predicate, or `pcall` the string work. `SocialShortcuts` commit `990d6cc` is a worked example. Discovered 2026-09-21; three addons here share the defect.
2. **Review the diff and commit.** Old 399-line `PlayerArmoryLink.lua` deleted, `Core/`, `UI/`, `MEMORY.md` added. Decide whether the 1.1.0 author edits and the audit fixes ship as one 1.2.0 commit or two. Use `git add -A` so the deletion is staged.
3. **Get beta access, log in, run 8.2.** Write results into section 10.
4. **Settle the Forever armory segment.** After launch on 2026-11-04 look up a Forever character on the armory and read the URL. If not `classic1x`, change `ARMORY_FOREVER` in `Core/Client.lua`. The only line involved.
5. **Confirm 16001 and fix the toc if needed.**
6. **Act on the secret-value result.** Enemy players in PvP readable: nothing changes. Group members secret: the addon is much less useful on 1.60 and the entry should fall back to `context.name` from the roster rather than the unit.
7. **Act on the copy result.** If `OnKeyDown` never fires, drop the auto-close and leave the dialog open with the link selected.
8. **Re-verify on every new 1.60.x build.** Diff `Blizzard_UnitPopupShared/UnitPopupShared.lua`, `UnitPopupSharedMenus.lua` and `Blizzard_Menu/Menu.lua` against the previous `forever` commit before each release. Beta ends 2026-10-21, launch 2026-11-04.
9. **Optional simplification, only after the art is verified in game.** `DialogHeaderTemplate` exists in `Blizzard_SharedXML/Shared/Dialog/DialogTemplates.xml` on both branches and would replace the hand-composed three-texture header. It draws `UI-Frame-DiamondMetal-Header-*` atlases, a different look and unverified on 1.15.9, so a deliberate change, not a cleanup.

---

## 10. Test results

Empty. Fill in per checklist item with date, build, character, zone and observed output.

---

## 11. Sources

Local: `/Applications/World of Warcraft/_classic_beta_/` (1.60.1 beta, the only client installed); `PlayerArmoryLink/` working tree at `9e00a53` plus uncommitted changes.

Gethe/wow-ui-source `forever` @ `70ef1b2` (1.60.1, 69913):
- `Interface/AddOns/Blizzard_UnitPopupShared/UnitPopupShared.lua:22-58`, `UnitPopupSharedMenus.lua` (38 `RegisterMenu` calls), `Blizzard_UnitPopupShared.toc`
- `Interface/AddOns/Blizzard_Menu/Menu.lua:2724-2745`, `MenuUtil.lua:209-285`, `Blizzard_Menu.toc`
- `Interface/AddOns/Blizzard_ProjectConstants/ProjectConstants.lua`, `Blizzard_ProjectConstants.toc`
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:2489-2540`, `SecretPredicatesDocumentation.lua:125-133`, `FrameScriptDocumentation.lua:65-79`, `BuildDocumentation.lua:10-22`, `LocaleDocumentation.lua:40-47`, `GameRulesDocumentation.lua`
- `Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:21`
- `Interface/AddOns/Blizzard_SharedXML/Shared/Dialog/DialogTemplates.xml:11-69`, `UI.xsd:440-443`
- `Interface/AddOns/Blizzard_Fonts_Shared/Shared/Fonts.xml:1369`

Gethe/wow-ui-source `classic_era` @ `33e177d` (1.15.9, 69722):
- `Interface/AddOns/Blizzard_UnitPopupShared/UnitPopupShared.lua:22-49`, `UnitPopupSharedMenus.lua` (36 `RegisterMenu` calls), `Blizzard_UnitPopupShared_Classic.toc`
- `Interface/AddOns/Blizzard_Menu/Menu.lua:2615-2636`, `MenuUtil.lua:209-273`, `Blizzard_Menu.toc`
- `Interface/AddOns/Blizzard_SharedXML/ProjectConstants.lua`, `UI.xsd:362-365`, `Shared/Dialog/DialogTemplates.xml:11-69`
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:1441-1468`, `FrameScriptDocumentation.lua:62-75`, `LocaleDocumentation.lua:38-45`
- `Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:20`

Live web, 2026-09-19: `worldofwarcraft.blizzard.com` armory route status codes (5.5).
