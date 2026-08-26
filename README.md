# DriftwoodXI Pad Hub

Controller-first Ashita addon for [DriftwoodXI](https://xi.driftwoodgaming.com/) on Steam Deck (and other pads).

Opens a D-pad navigable hub (macro / bind to toggle) that issues the same typed `!` commands the official Driftwood windows use — no server changes required.

## Goals (MVP)

- **Squad** — call / dismiss
- **Jobs** — use presets (then set jobs)
- **Rules** — assign gambit presets
- **Port** — home, list tabs, go
- **Items** — send / fetch / equip (after MVP)

Search fields stay at the **top** of the window so Steam Deck OSK does not cover them. Select can stay on OSK; open the hub from a macro.

## Non-goals

- Real FFXI event menus (`!squad menu` style) — those are server-side
- Full gambit rule editing, parse, report, etc.

## Status

Scaffold only — planning next.

## Install (later)

Copy the addon folder into Ashita `addons/`, enable in your boot script or `/addon load …`.

## Related

- Deck launch helpers: [driftwoodxi-steamdeck](https://github.com/JRustyHaner/driftwoodxi-steamdeck) (if applicable)
- Typed commands: https://xi.driftwoodgaming.com/commands
