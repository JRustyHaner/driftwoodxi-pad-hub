# Scope

Client-only Ashita Lua hub for DriftwoodXI pad play (Steam Deck first).

## In scope (MVP)

- ImGui hub with FFXI-style chrome and gamepad navigation (see [UX.md](./UX.md), [MENU-IA.md](./MENU-IA.md))
- **Home:** five fixed groups — Party and Travel, Inventory and Trade, Quests and Crafts, Instances, Field (Home never grows)
- **Party and Travel:** Squad, Jobs, Rules, Port
- **Inventory and Trade:** Items (Storage, Market, Merc planned)
- Typed command backends: `!squad`, `!jobs`, `!port`, `!squad rules` / related `!dw*` machine channels as needed
- Full job list for main/sub (locked jobs greyed)
- Items: find / send / fetch / equip / box / gear / unpin / optimize
- Toggle via `/dwhub` + keyboard bind / Deck macro
- Top-aligned search for Steam Deck OSK clearance
- Throttled outbound `!` command queue
- CI: luacheck + busted on pure Lua modules

## Out of scope

- Server / native `!… menu` event dialogs
- Packet forgery
- Automating combat or unattended play
- Full gambit rule *authoring* (assign presets only)
- Full craft/fame/parse/leaderboard UIs (group rows may link to chat/`!` only until built)
