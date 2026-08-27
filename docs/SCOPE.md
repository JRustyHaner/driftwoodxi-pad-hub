# Scope

Client-only Ashita Lua hub for DriftwoodXI pad play (Steam Deck first).

## In scope (MVP)

- ImGui hub with FFXI-style chrome and gamepad navigation (see [UX.md](./UX.md))
- Home categories: **Squad, Jobs, Items, Rules, Port**
- Typed command backends: `!squad`, `!jobs`, `!port`, `!squad rules` / related `!dw*` machine channels as needed
- Full job list for main/sub (locked jobs greyed)
- Pad pick lists for roster, find results, job presets, rule sets, port destinations (type-name fallback)
- Items: find / send / fetch / equip / box / gear / unpin / optimize
- Toggle via `/dwhub` + keyboard bind / Deck macro
- Top-aligned search/filter for Steam Deck OSK clearance
- Throttled outbound `!` command queue (including `!dws` / `!dwq` / `!dwj` / `!dwg` reads)
- CI: luacheck + busted on pure Lua modules

## Out of scope

- Server / native `!… menu` event dialogs
- Packet forgery
- Automating combat or unattended play
- Gambit rule *authoring* (assign presets only)
- Merc, craft, parse, raid, market UIs
