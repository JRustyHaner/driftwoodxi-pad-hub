# Opening the hub (Deck binds)

The hub toggles with `/dwhub` (alias `/hub`). Keep **Select** on Steam Deck’s on-screen keyboard; use a **macro** or another face/shoulder bind for the hub.

## Recommended setup

1. **Deck:** Steam **DriftwoodXI** uses the Neptune **Gamepad** layout (installer ships it). **Left back paddle (L4)** sends **F9** → Pad Hub.
2. Ashita bind (in `driftwood-default.txt` after `/addon load dwhub`):

```
/bind F9 /dwhub
```

3. **Select** stays on Steam OSK (not remapped).

Optional macro line (same effect if you prefer in-game macro book):

```
/dwhub
```

Optional Ashita keyboard bind (Desktop / when a key is free):

```
/bind !insert /dwhub
```

## Steam Input

- Controller template: **DriftwoodXI Gamepad** (Neptune passthrough to FFXI Alternate Setup E).
- **L4** (left back paddle) → **F9** → `/dwhub` (via Ashita bind above).
- Do **not** steal Select — keep it on Steam OSK for search fields.

## While the hub is open

`dwhub` best-effort:

- Disables FFXI **gamepad** consumption (`SetDisableGamepad`) so A/B/D-pad do not move the character
- Blocks FFXI **keyboard** consumption (`IKeyboard:SetBlockInput`) so arrows / Enter / Esc drive the hub instead of menus or movement

Closing `/dwhub` restores both previous settings. ImGui still receives those keys for hub nav and top search fields.

**Xbox / XInput:** Hub navigation reads Ashita’s `xinput_state` event (D-pad, A, B). ImGui gamepad keys alone are not enough on desktop. FFXI Setup E with XInput enabled is required.

If input still leaks on your build, say so in an issue (Ashita build + Desktop vs Deck).

## OSK and search

Search fields stay at the **top** of hub windows so the Deck OSK (from the bottom) does not cover them. See [UX.md](./UX.md).
