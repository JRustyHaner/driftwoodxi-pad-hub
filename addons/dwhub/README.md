# dwhub

Ashita 4 addon: controller-first DriftwoodXI hub (**v1.1.0**).

## Install

1. Copy this folder to your Ashita `addons/dwhub/` directory (so `addons/dwhub/dwhub.lua` exists).
2. Load it:
   - In chat: `/addon load dwhub`
   - Or add `/addon load dwhub` to your boot script (e.g. `driftwood-default.txt`).
3. Toggle: `/dwhub` or `/hub`
4. After updates: `/addon reload dwhub` (no client restart).

Steam Deck: see [docs/DECK.md](../../docs/DECK.md) and [docs/BINDS.md](../../docs/BINDS.md).

## Controls

| Input | Action |
|-------|--------|
| D-pad / arrow keys | Move focus |
| A / Enter | Confirm |
| B / Esc | Back (closes hub on Home) |
| `/dwhub` | Toggle |

Character, item find results, presets, rule sets, and port destinations are **lists** (filter at top). Use **Type name…** only when the list is missing an entry.

## Home categories

Squad · Jobs · Items · Rules · Port — see [docs/UX.md](../../docs/UX.md).

## Commands

| Command | Effect |
|---------|--------|
| `/dwhub` / `/hub` | Toggle window |
| `/dwhub open` | Open |
| `/dwhub close` | Close |
