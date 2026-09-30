# PlayerArmoryLink

Right-click any player and copy their `worldofwarcraft.blizzard.com` armory link. Built for
WoW Forever 1.60.x.

## Features

- An **Armory Link** entry on every player right-click menu: your own portrait, target and focus frames, party and raid frames, chat names, the friends list, the guild and community rosters, recent allies and the battleground scoreboard
- A native dialog that shows the character's name and realm, with the link already selected. The name includes the surname
- The game's own dialog: the metal-framed border and banner of the game menu, in the game's own fonts
- One keypress copies the link and closes the dialog: CMD+C on macOS, CTRL+C on Windows
- Nothing to configure and nothing saved. Realm, region and locale all come from the running client

## Installation

1. Copy the `PlayerArmoryLink/` folder into the `Interface/AddOns/` folder of your WoW Forever install.
2. Restart the game or `/reload`.
3. Enable **Player Armory Link** in the AddOns list.

## Usage

- Right-click a player portrait, name or roster row, then pick **Armory Link**.
- The link is already selected. Press CMD+C or CTRL+C to copy it, and the dialog closes itself.
- Escape or the close button dismisses the dialog without copying.

## Requirements

WoW Forever 1.60.x (`## Interface: 16001`). The Classic Era 1.15.x version lives on the `1.15.x-backup` branch.

## Restrictions

WoW Forever has no armory pages yet. Until Blizzard publishes Forever characters, links use the
Classic Era armory format (`classic1x`), so they may not resolve.

No entry appears for NPCs. It also stays hidden for players whose name the game
hides from addons inside restricted content, so nothing errors and nothing leaks.

The entry is added through Blizzard's own menu system (`Menu.ModifyMenu`), so the native menu
keeps working and nothing is tainted in combat.
