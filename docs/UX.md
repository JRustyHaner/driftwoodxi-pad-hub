# Pad Hub UX

Controller-first Ashita overlay for DriftwoodXI. Chrome reference: [mockups/ffxi-hub-chrome.html](./mockups/ffxi-hub-chrome.html).

## Interaction

| Control | Action |
|---------|--------|
| D-pad / stick | Move focus |
| A | Confirm / enter |
| B | Back / close hub from Home |
| Macro / bind | Toggle `/dwhub` (Select stays on Steam Deck OSK) |

- Target frame: **1280×720**
- Search / filter fields at the **top** of the active window (OSK rises from the bottom)
- **Pick lists** for characters, find results, presets, rule sets, and port destinations (live from Driftwood machine / list replies). **Type name…** is a fallback only.
- Footer hint: `A Confirm  B Back` (Home: `B Close`)
- Focused row: yellow text + white hand cursor; description panel explains the row
- Vertical lists only (pad-friendly); mock’s horizontal FFXI bar is chrome inspiration, not primary nav

## Hot reload

After copying updated Lua into Ashita `addons/dwhub/`:

```
/addon reload dwhub
```

Or `/addon unload dwhub` then `/addon load dwhub`. No client restart.

## Home

1. Squad  
2. Jobs  
3. Items  
4. Rules  
5. Port  

---

## 1. Squad

| Row | Command / flow |
|-----|----------------|
| Call | `!squad call` |
| Dismiss | `!squad dismiss` |
| List | Show `!squad list` (read-only) |
| Set slot… | Slot 1–5 → **roster list** → `!squad set N Name` |
| Clear slot… | Slot 1–5 → `!squad clear N` |
| Engage | `!squad engage` |
| Disengage | `!squad disengage` |
| Come | `!squad come` |
| Rest | `!squad rest` |
| Behavior… | Aggressive / Defensive / Passive / Off → `!squad behavior <profile>` |

---

## 2. Jobs

| Row | Flow |
|-----|------|
| Change jobs… | **Roster** → Main (full list) → Sub (full list or None) → `!jobs set <char> <main> [sub\|none]` |
| Use preset… | **Preset list** (`!dwj`) → `!jobs use <name>` |
| Save preset… | Name (top field / OSK) → `!jobs save <name>` |
| Delete preset… | **Preset list** → `!jobs delete <name>` |

**Job list** (always show; grey locked):

`WAR MNK WHM BLM RDM THF PLD DRK BST BRD RNG SAM NIN DRG SMN BLU COR PUP DNC SCH GEO RUN`

---

## 3. Items

| Row | Flow |
|-----|------|
| Who | `!squad who` (+ roster refresh) |
| Find… | Top filter → Search (`!dwq find`) → **result list** → Send / Fetch |
| Send… | **Roster** → Find results → `!dwq send` (id) |
| Fetch… | **Roster** → Find results → `!dwq fetch` (id) |
| In transit… | `!squad box` |
| Gear… | **Roster** → `!squad gear` |
| Equip… | **Roster** → slot → auto / none / find / type → `!dwq equip` |
| Unpin all… | **Roster** → `!squad unpin` |
| Optimize me | `!optimizegear` (preview when easy) |

**Equip slots:** `main sub ranged ammo head body hands legs feet neck waist ear1 ear2 ring1 ring2 back`

Qty default `1`.

---

## 4. Rules (assign only)

| Row | Flow |
|-----|------|
| What’s running | `!squad rules` (read-only) |
| Assign set… | **Roster** (`me` / chars / `all`) → **set/preset list** → `!squad rules use` |
| Assign when job… | Member → set → job → `!squad rules use … when <job>` |
| Behavior… | Same four profiles as Squad |

Sets = shipped (`!dwg presets`) + account (`!dwg list`). No rule editing in hub.

---

## 5. Port

| Row | Flow |
|-----|------|
| Home nation | `!port home` / `!home` |
| Home points… | `!port list hp` → **destination list** → `!port go hp …` |
| Survival guides… | `!port list sg` → Go |
| Outposts… | `!port list op` → Go |
| Teleport spells… | `!port list sp` → Go |
| Search… | Field at **top**; unambiguous `!port <name>` |

Unusable destinations dimmed; cannot Go.
