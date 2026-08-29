# Pad Hub UX

Controller-first Ashita overlay for DriftwoodXI. Chrome reference: [mockups/ffxi-hub-chrome.html](./mockups/ffxi-hub-chrome.html).

## Interaction

| Control | Action |
|---------|--------|
| D-pad / stick | Move focus |
| A | Confirm / enter |
| B | Back / close hub from Home |
| Macro / bind | Toggle `/dwhub` (Select stays on Steam Deck OSK) |

- Design frame: **1280×720** — font, padding, and window size scale up/down with your game resolution (4K ≈ 3×, 1080p ≈ 1.5×)
- Search fields at the **top** of the active window (OSK rises from the bottom)
- **List viewport:** every menu/list draws inside a fixed box; only the current page of rows is shown
- **Paging:** **← / →** (or D-pad left/right) turns pages; **↑ / ↓** moves focus (auto-advances page at edges)
- **Optional filter:** press **Up** on the first row of page 1 to highlight the filter field; **Down** or **B** returns to the list
- Footer hint: `← → pages   Up: filter   A Confirm   B Back` (Home: `B Close`)
- Focused row: yellow text + white hand cursor; description panel explains the row
- Vertical lists only (pad-friendly); mock’s horizontal FFXI bar is chrome inspiration, not primary nav

## Home

Fixed **five group rows** — Home never grows. Full map: [MENU-IA.md](./MENU-IA.md).

| # | Group | Categories inside |
|---|--------|-------------------|
| 1 | **Party and Travel** | Squad, Jobs, Rules, Port |
| 2 | **Inventory and Trade** | Items (+ Storage, Market, Merc when shipped) |
| 3 | **Quests and Crafts** | Quests, Drift, Fish (+ Craft later) |
| 4 | **Instances** | Raid, Arena |
| 5 | **Field** | Scan, Engage |

Confirm a group → pick a category → existing screen flows below.

---

## 1. Squad

| Row | Command / flow |
|-----|----------------|
| Call | `!squad call` |
| Dismiss | `!squad dismiss` |
| List | Show `!squad list` (read-only) |
| Set slot… | Slot 1–5 → character → `!squad set N Name` |
| Clear slot… | Slot 1–5 → `!squad clear N` |
| Engage | `!squad engage` |
| Disengage | `!squad disengage` |
| Come | `!squad come` |
| Rest | `!squad rest` |
| Roster | Read-only slots 1–5 in hub (Refresh) |
| Cast… | Job tag → spell → target → `!whm cure3 me` |
| Cast all… | Job → spell → target → `!allwhm curaga me` |
| Behavior… | Aggressive / Defensive / Passive / Off → `!squad behavior <profile>` |
| Hints (me) | `!squad hints me` |
| Hints… | Character → `!squad hints <name>` |

---

## 2. Jobs

| Row | Flow |
|-----|------|
| Change jobs… | Character → Main (full list) → Sub (full list or None) → `!jobs set <char> <main> [sub\|none]` |
| Use preset… | `!jobs list` → `!jobs use <name>` |
| Save preset… | Name (top field / OSK) → `!jobs save <name>` |
| Delete preset… | Pick → `!jobs delete <name>` |

**Job list** (always show; grey locked):

`WAR MNK WHM BLM RDM THF PLD DRK BST BRD RNG SAM NIN DRG SMN BLU COR PUP DNC SCH GEO RUN`

---

## 3. Items

| Row | Flow |
|-----|------|
| Who | `!squad who` |
| Find… | Search at **top** → Send / Fetch on row |
| Browse bags… | Character → bag page → Send / Fetch |
| Send… | Target → item → qty → `!squad send` |
| Fetch… | Source → item → qty → `!squad fetch` |
| In transit… | `!squad box` |
| Gear… | Character → `!squad gear` |
| Equip… | Character → slot → item / Auto / Empty → `!squad equip` |
| Unpin all… | Character → `!squad unpin` |
| Optimize… | Apply `!optimizegear` or preview in chat |

Unusable port destinations are dimmed and cannot Go.

**Equip slots:** `main sub ranged ammo head body hands legs feet neck waist ear1 ear2 ring1 ring2 back`

Qty default `1`.

---

## 4. Rules (assign only)

| Row | Flow |
|-----|------|
| What’s running | `!squad rules` (read-only) |
| Assign set… | Member or `all` → set → `!squad rules use <member> <set>` |
| Assign when job… | Member → set → job → `!squad rules use … when <job>` |
| Behavior… | Same four profiles as Squad |

Sets = shipped (`!squad rules presets`) + account (`!squad rules list`). No rule editing in hub.

---

## 5. Port

| Row | Flow |
|-----|------|
| Home nation | `!port home` / `!home` |
| Home points… | `!port list hp` → `!port go hp …` |
| Survival guides… | `!port list sg` → Go |
| Outposts… | `!port list op` → Go |
| Teleport spells… | `!port list sp` → Go |
| Search… | Field at **top**; filter / unambiguous `!port <name>` |

Unusable destinations dimmed; cannot Go.
