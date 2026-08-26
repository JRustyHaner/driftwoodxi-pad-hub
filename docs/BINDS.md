# Opening the hub (Deck binds)

The hub toggles with `/dwhub` (alias `/hub`). Keep **Select** on Steam Deck’s on-screen keyboard; use a **macro** or another face/shoulder bind for the hub.

## Recommended setup

1. Pick a free FFXI macro book slot (or a Steam Input button that presses a keyboard key).
2. Macro line example:

```
/dwhub
```

3. Optional Ashita keyboard bind (Desktop / when a key is free):

```
/bind !insert /dwhub
```

(`!insert` = Alt+Insert — choose whatever does not fight Setup E.)

## Steam Input

- Controller template: **Gamepad** (already typical for Driftwood on Deck).
- Map one unused button (e.g. **L4** / **R4** / long-press **Y**) to a keyboard key that your macro or `/bind` fires.
- Do **not** steal Select if you want OSK for search fields at the top of hub windows.

## While the hub is open

`dwhub` best-effort disables FFXI gamepad consumption (`SetDisableGamepad`) so A/B/D-pad do not move the character. Closing `/dwhub` restores the previous setting.

If pad input still leaks on your build, drive the hub with **arrow keys / Enter / Esc** (Steam Input can mirror D-pad → arrows for the hub chord only).

## OSK and search

Search fields stay at the **top** of hub windows so the Deck OSK (from the bottom) does not cover them. See [UX.md](./UX.md).
