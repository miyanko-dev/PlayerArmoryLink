# PlayerArmoryLink

Right-click any player and copy their `worldofwarcraft.blizzard.com` armory link.

## Features

- **Armory Link** entry on every player right-click menu: unit frames, party and raid frames, chat names, friends list, guild roster, battleground scoreboard
- Link arrives pre-selected, so one CMD+C or CTRL+C copies it and closes the dialog
- Character, Realm and Link shown in their own boxes
- Zero configuration and nothing saved: realm, region, locale and game version all come from the running client
- Handles camel-case realms like `HydraxianWaterlords` and apostrophes like `Rhok'delar`

## Installation

1. Copy the `PlayerArmoryLink/` folder into your client's `Interface/AddOns/` folder.
2. Restart the game or `/reload`.
3. Enable **Player Armory Link** in the AddOns list.

## Usage

Right-click a player portrait, name or roster row and pick **Armory Link**. The link is already selected — press CMD+C (macOS) or CTRL+C (Windows) and the dialog closes itself.

## Requirements

Classic Era, Anniversary, Classic Progression or Retail. Each client picks its own armory path segment:

| Client | Path segment |
| --- | --- |
| Classic Era | `classic1x` |
| Anniversary | `classicann` |
| Classic Progression | `classic` |
| Retail | `worldsoul` |

## Restrictions

Armory links only resolve for players on your own realm and game version, which is what the right-click menu gives you anyway.
