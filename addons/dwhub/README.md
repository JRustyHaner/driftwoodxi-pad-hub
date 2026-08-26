# dwhub

Ashita 4 addon: controller-first DriftwoodXI hub.

## Install

1. Copy this folder to your Ashita `addons/dwhub/` directory (so `addons/dwhub/dwhub.lua` exists).
2. Load it:
   - In chat: `/addon load dwhub`
   - Or add `/addon load dwhub` to your boot script (e.g. `driftwood-default.txt`).
3. Toggle: `/dwhub` or `/hub`

## Controls

| Input | Action |
|-------|--------|
| D-pad / arrow keys | Move focus |
| A / Enter | Confirm |
| B / Esc | Back (closes hub on Home) |
| `/dwhub` | Toggle |

## Commands

| Command | Effect |
|---------|--------|
| `/dwhub` / `/hub` | Toggle window |
| `/dwhub open` | Open |
| `/dwhub close` | Close |

## Status

Nav shell with Home categories (Squad, Jobs, Items, Rules, Port). Category screens are placeholders until feature PRs. See [docs/UX.md](../../docs/UX.md).
