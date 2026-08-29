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

- Menu trees: **[docs/UX.md](./docs/UX.md)**
- Chrome mock: **[docs/mockups/ffxi-hub-chrome.html](./docs/mockups/ffxi-hub-chrome.html)**
- Deck binds: **[docs/BINDS.md](./docs/BINDS.md)**
- Deck install: **[docs/DECK.md](./docs/DECK.md)**
- Acceptance: **[docs/ACCEPTANCE.md](./docs/ACCEPTANCE.md)**

## Non-goals

- Real FFXI event menus (`!squad menu` style) — those are server-side
- Full gambit rule editing, merc, craft, parse, report, etc.

## Status

**MVP feature-complete** (v1.0.0): Home categories wired to Squad / Jobs / Items / Rules / Port. Validate on Deck with [ACCEPTANCE.md](./docs/ACCEPTANCE.md).

## Contributing / agent workflow

All work follows **issue → branch → code → test → document → PR → merge**. See [AGENTS.md](./AGENTS.md). PRs should stay CI-green (`luacheck` + `busted`).

## Install

1. Copy [`addons/dwhub/`](./addons/dwhub/) into your Ashita `addons/dwhub/` folder.
2. `/addon load dwhub` (or add that line to your boot script).
3. Toggle with `/dwhub` or `/hub`.

Deck-oriented steps: [docs/DECK.md](./docs/DECK.md). Addon readme: [addons/dwhub/README.md](./addons/dwhub/README.md).

## Local test loop (Desktop)

After merging hub changes, sync into your Ashita tree and reload in game:

```bash
chmod +x scripts/sync-to-ashita.sh
./scripts/sync-to-ashita.sh
# or: DRIFTWOOD_ASHITA=~/Downloads/driftwoodxi-installer/Ashita ./scripts/sync-to-ashita.sh
```

In game: `/addon reload dwhub` then `/dwhub`.

Auto-detect order: `$DRIFTWOOD_ASHITA` → `~/ffxi/Ashita` → `~/Downloads/driftwoodxi-installer/Ashita`.

## Related

- Deck launch helpers: [driftwoodxi-steamdeck](https://github.com/JRustyHaner/driftwoodxi-steamdeck)
- Typed commands: https://xi.driftwoodgaming.com/commands
- Allowed addons: https://xi.driftwoodgaming.com/addons
