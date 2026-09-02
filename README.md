# PlayerArmoryLink

Right-click any player and copy their `worldofwarcraft.blizzard.com` armory link. Works on
every armory-supported flavor: Classic Era, Anniversary, Classic Progression and Retail.

## Features

- "Armory Link" entry on every player right-click menu: unit frames, party and raid frames, chat names, friends list, guild roster, battleground scoreboard
- Pre-selected link in a native dialog, so CMD+C (macOS) or CTRL+C (Windows) copies and closes it in one keypress
- Game version auto-detected from the running client, switchable from the dropdown and remembered
- Realm and region slugs built from the live client, including camel-case realms like `HydraxianWaterlords`

## Installation

1. Copy the `PlayerArmoryLink/` folder into:
   `World of Warcraft/_classic_era_/Interface/AddOns/`
2. Restart the game or `/reload`.
3. Enable **Player Armory Link** in the AddOns list.

## Usage

- Right-click a player portrait, name or roster row, then pick **Armory Link**.
- The link is already selected. Press CMD+C or CTRL+C to copy it, the dialog closes itself.
- The dropdown in the bottom-right switches game version. The choice is stored in
  `PlayerArmoryLinkDB` per account.

## URL format

```
https://worldofwarcraft.blizzard.com/<locale>/<version>/<region>/armory/character/<realm>/<name>
```

| Version | Path segment |
| --- | --- |
| Classic Era | `classic1x` |
| Anniversary | `classicann` |
| Classic Progression | `classic` |
| Retail | `worldsoul` |

Version detection: Retail reports `WOW_PROJECT_MAINLINE`, the vanilla client reports
`WOW_PROJECT_CLASSIC` and is split by `C_Seasons.GetActiveSeason()` (Fresh seasons 11 and 12
are Anniversary realms, everything else is Classic Era), and every other project ID falls back
to Classic Progression.

## Notes

The addon adds a menu entry rather than replacing the portrait right-click, so the native
menu keeps working. Blizzard's own menu system (`Menu.ModifyMenu`) is used, so no dropdown
is tainted and combat is unaffected.
