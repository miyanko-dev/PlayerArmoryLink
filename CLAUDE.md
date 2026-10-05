# PlayerArmoryLink

## Target

- WoW Forever 1.60.x only, `## Interface: 16001`. No client branches, no `WOW_PROJECT_*`, no compat layer.
- `main` holds the Forever version. `1.15.x-backup` stays untouched.
- Verify every API against Gethe `wow-ui-source` and Ketho `BlizzardInterfaceResources`, branch `forever`.

## Rules

- Names come only from Blizzard's menu context, `context.name` and `context.surname`, never from `UnitName`. For unit menus `UnitPopupManager:OpenMenu` fills both from `UnitNameUnmodified`.
- A roster name without a surname is split on a space or a hyphen. Keep both: chat links join names with `CHARACTERNAME_LINK_SEPARATOR` (`-`).
- Call `RegionalUniqueNamesEnabled()`, never just test that it exists. When true, the second part is a surname, the display name comes from `NameUtil.GetFullNameWithoutRealm` and the realm from `GetRealmName()`. When false, the second part is the realm, as in Blizzard's menu.
- Read the name inside `pcall`. `canaccessvalue` and `issecretvalue` are `SecretArguments = "AllowedWhenUntainted"`, so they can't guard tainted addon code.
- The dialog copies the game menu chrome of `MainMenuFrameTemplate`: `DialogBorderTemplate`, `DialogHeaderTemplate` and `UIPanelCloseButton`.
- Left out on purpose: `MENU_UNIT_WORLD_STATE_SCORE`, which nothing on Forever opens.

## Checks

- Run `luac -p` on every Lua file after a change. The repo has no test harness.
- Turn on `/console scriptErrors 1` before testing in game.
