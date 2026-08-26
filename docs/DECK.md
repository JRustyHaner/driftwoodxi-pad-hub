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

## Pad capture

While the hub is open, dwhub best-effort disables FFXI’s gamepad so A/B/D-pad drive the hub. Closing restores control. If your Ashita build ignores that API, map D-pad → arrows for hub use (see BINDS.md).

## Quick smoke

1. `/dwhub` → Home lists Squad / Jobs / Items / Rules / Port  
2. Squad → Call → status shows queue; chat eventually gets `!squad call`  
3. B back to Home; B closes hub  
4. Character does not walk while hub is focused  

Full checklist: [ACCEPTANCE.md](./ACCEPTANCE.md).
