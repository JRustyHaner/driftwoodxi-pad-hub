# DriftwoodXI Pad Hub

Controller-first Ashita addon for [DriftwoodXI](https://xi.driftwoodgaming.com/) on Steam Deck (and other pads).

Opens a D-pad navigable hub (macro / bind to toggle) that issues the same typed `!` commands the official Driftwood windows use — no server changes required.

## Goals (MVP)

- **Squad** — call / dismiss / set / field orders / behavior
- **Jobs** — full job list for main/sub + presets
- **Items** — find / send / fetch / equip
- **Rules** — assign gambit presets
- **Port** — home, list tabs, go

Search fields stay at the **top** of the window so Steam Deck OSK does not cover them. Select can stay on OSK; open the hub from a macro.

Menu trees and pad rules: **[docs/UX.md](./docs/UX.md)**. Chrome mock: **[docs/mockups/ffxi-hub-chrome.html](./docs/mockups/ffxi-hub-chrome.html)**.

## Non-goals

- Real FFXI event menus (`!squad menu` style) — those are server-side
- Full gambit rule editing, merc, craft, parse, report, etc.

## Status

Scaffolding in progress (docs → addon → CI → nav → features).

## Contributing / agent workflow

All work follows **issue → branch → code → test → document → PR → merge**. See [AGENTS.md](./AGENTS.md).

## Install

1. Copy [`addons/dwhub/`](./addons/dwhub/) into your Ashita `addons/dwhub/` folder.
2. `/addon load dwhub` (or add that line to your boot script).
3. Toggle with `/dwhub` or `/hub`.

Details: [addons/dwhub/README.md](./addons/dwhub/README.md).

## Related

- Deck launch helpers: [driftwoodxi-steamdeck](https://github.com/JRustyHaner/driftwoodxi-steamdeck) (if applicable)
- Typed commands: https://xi.driftwoodgaming.com/commands
- Allowed addons: https://xi.driftwoodgaming.com/addons
