# Steam Deck install

## Prerequisites

- Working DriftwoodXI client on Deck (see [driftwoodxi-steamdeck](https://github.com/JRustyHaner/driftwoodxi-steamdeck) helpers if needed)
- Ashita with the Driftwood addon set
- Controller template **Gamepad** + FFXI Setup E / XInput

## Install dwhub

1. Copy this repo’s `addons/dwhub/` folder into Ashita:

   `…/Ashita/addons/dwhub/` (must contain `dwhub.lua`)

2. Load once in chat:

   ```
   /addon load dwhub
   ```

3. Persist: add `/addon load dwhub` to your boot script (e.g. `scripts/driftwood-default.txt`).

4. Toggle: `/dwhub` or `/hub`

## Opening on Deck without a keyboard

Keep **Select** on the Steam OSK. Put `/dwhub` on a macro book slot or Steam Input → key → `/bind`. Details: [BINDS.md](./BINDS.md).

## OSK and search

Any hub screen with a text field draws it at the **top** of the window so the Deck on-screen keyboard does not cover it. Prefer D-pad flows (job list, behavior, slots) when you can avoid typing.

## Pad / keyboard capture

While the hub is open, dwhub best-effort:

- Disables FFXI’s gamepad (`SetDisableGamepad`) so A/B/D-pad drive the hub
- Blocks FFXI’s keyboard (`SetBlockInput`) so arrows / Enter / Esc do not open menus or move the character

Closing restores both. If your Ashita build ignores an API, say so in acceptance notes.

## Quick smoke

1. `/dwhub` → Home lists five groups (Party and Travel, … Field)
2. Party and Travel → Squad → Call → status shows queue
3. B back to group, B to Home, B closes hub
4. Character does not walk while hub is focused

Full checklist: [ACCEPTANCE.md](./ACCEPTANCE.md).

## Parse fixtures (CI)

`_DW*DATA` and chat-scraper parsers are covered by committed lines in `spec/fixtures/`. CI runs them on every PR via `busted`.

**Capture from live Driftwood (Desktop or Deck):**

1. Trigger the verb in game (e.g. Items → Who, or `/dwhub` → Jobs).
2. Log machine lines from `data.handle_machine` during dev, or copy from an official dw\* addon’s parse debug if available.
3. Redact real character names → placeholders (`Alice`, `Bob`).
4. Update the matching `spec/fixtures/<name>.lines` file; run `busted spec/data_spec.lua`.
5. Commit fixture + any parser fix in the same PR.

Details: [spec/README.md](../spec/README.md).
