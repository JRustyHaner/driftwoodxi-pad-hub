# Pad Hub roadmap

Client-only pad overlay over typed Driftwood `!` commands. Issues track work on GitHub.

## Shipped / in progress

| Area | Status |
|------|--------|
| Home + 5 categories | Done |
| Live lists (roster, bags, find, port) | Done |
| Viewport lists + ←/→ paging | Done |
| Optional filter (Up to highlight) | Done |
| Squad cast / cast all (#35) | Done |
| Items send/fetch/equip fix (#34) | Done |
| Locked jobs greyed | Done |
| Send/fetch qty picker | Done |
| Port Go blocked when locked | Done |
| Optimize preview | Done |
| In-hub squad roster | Done |

## Next (recommended order)

### Cast phase 2 ([#35](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/35) follow-ups)

- Job abilities + weapon skills (`!whm abilities`, `!war provoke`)
- Per-member field orders (`!pld engage`, `!whm rest`)
- SMN pet verbs (summon / dismiss / avatar)
- Tune spell chat parser against live `!whm spells` output on Deck

### Items depth

- In-transit box as pick list (parse `!squad box`)
- Gear plan summary in hub (from `!squad gear`)
- `!squad tidy` / `!squad stack`
- `!squad use` (scrolls / food / heal)

### Jobs & rules polish

- Show current main/sub on character pick
- Preset preview before `!jobs use`
- Label shipped vs custom rule sets in pick list

### Port & data reliability

- Auto-fetch port list pages 2+
- Harden chat scrapers (port, spells) with fixture tests

### Deck / ops

- Mirror desktop Ashita addons + config to Deck (rsync)
- Acceptance checklist on hardware ([ACCEPTANCE.md](./ACCEPTANCE.md))

## Out of scope (unless product changes)

- Gambit rule **authoring** (assign only — use `/gambits`)
- Merc, craft, market, raid, parse UIs
- Server menu packet growth
- Unattended automation

## Issues

| # | Topic |
|---|--------|
| [#34](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/34) | Items send/fetch/equip |
| [#35](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/35) | Squad spell cast |

| [#36](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/36) | MVP polish (locked jobs, qty, roster, port, optimize) |
