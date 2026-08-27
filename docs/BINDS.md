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

`dwhub` best-effort:

- Disables FFXI **gamepad** consumption (`SetDisableGamepad`) so A/B/D-pad do not move the character
- Blocks FFXI **keyboard** consumption (`IKeyboard:SetBlockInput`) so arrows / Enter / Esc drive the hub instead of menus or movement

Closing `/dwhub` restores both previous settings. ImGui still receives those keys for hub nav and top search fields.

If input still leaks on your build, say so in an issue (Ashita build + Desktop vs Deck).

## OSK and search

Search fields stay at the **top** of hub windows so the Deck OSK (from the bottom) does not cover them. See [UX.md](./UX.md).
