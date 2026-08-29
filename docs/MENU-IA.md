# Pad Hub — menu information architecture

Controller-first navigation for Steam Deck. **Home never grows:** exactly five group rows. Every feature lives one level down.

Design frame: **1280×720**. See [UX.md](./UX.md) for input and viewport rules.

## Home (fixed — 5 rows only)

| # | Group | Opens |
|---|--------|--------|
| 1 | **Party and Travel** | Squad, Jobs, Rules, Port |
| 2 | **Inventory and Trade** | Items (+ Storage, Market, Merc when shipped) |
| 3 | **Quests and Crafts** | Quests, Drift, Fish (+ Craft when shipped) |
| 4 | **Instances** | Raid, Arena |
| 5 | **Field** | Scan, Engage (+ Signet / Mog House later if added) |

**B** on Home closes the hub. **B** on any group screen returns to Home.

Do **not** add sixth Home rows for new addons — extend the appropriate group instead.

---

## 1. Party and Travel

Squad control, jobs, combat rules, and teleport.

| Screen | Status | Notes |
|--------|--------|-------|
| Squad | Shipped | Call, dismiss, slots, cast, behavior, hints |
| Jobs | Shipped | Change jobs, presets |
| Rules | Shipped | Assign gambit sets (not authoring — use `/gambits`) |
| Port | Shipped | Home, HP/SG/OP/SP lists, search |

---

## 2. Inventory and Trade

Account bags, gear, and economy.

| Screen | Status | Notes |
|--------|--------|-------|
| Items | Shipped | Find, send, fetch, equip, box, gear, optimize |
| Storage | Planned (#53–#54) | `!warehouse` / dwwarehouse |
| Market | Planned (#56–#57) | `!market` / dwah |
| Merc | Planned (#55) | `!merc` / dwmerc |

---

## 3. Quests and Crafts

Journal, contracts, and skilling.

| Screen | Status | Notes |
|--------|--------|-------|
| Quests | Planned (#50) | `/tracker` / dwtracker |
| Drift | Planned (#51–#52) | Drift Board / dwquest |
| Fish | Shipped (#47) | `!fish`, `!fish next`, `!fish rank`, `!fish route` |
| Craft | Future | `!craft` / dwcraft — full UI out of scope until requested |

---

## 4. Instances

Enter/leave instanced content from anywhere.

| Screen | Status | Notes |
|--------|--------|-------|
| Raid | Shipped (#49) | `!raid`, `!raid enter`, `!raid leave`, `!raid marks` |
| Arena | Shipped (#48) | `!arena`, `!arena enter`, `!arena leave` |

---

## 5. Field

Target info and client engage helpers.

| Screen | Status | Notes |
|--------|--------|-------|
| Scan | Shipped (#46) | `!scan`, `!scan 0 N` |
| Engage | Shipped (#45) | `/dwengage on\|off`, `!trustengage` |

---

## Navigation rules

1. **Home cap:** 5 group rows — no paging on Home, no “More…”, no favorites row on v1.
2. **Group cap:** Prefer ≤7 rows per group; use viewport paging inside a screen, not extra Home tiers.
3. **Read vs act:** Journal/status rows may dump to chat in v1; warp/spend/enter rows use [#43 confirm flow](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/43) when implemented.
4. **Naming:** Use group names above in UI titles (e.g. hub screen title “Party and Travel”, not “Core”).
5. **Implementation:** Group screen → category screen → existing pick flows. **Shipped in v0.4.0** (`screens.HOME_GROUPS`, `screens.group`). Further categories track in [#44](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/44).

## Issue map

| Group | GitHub |
|-------|--------|
| IA / this doc | [#38](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/38) |
| Epic | [#44](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/44) |
| Party and Travel polish | #39 hints; #32–#36 MVP |
| Inventory and Trade | #53–#57 |
| Quests and Crafts | #47, #50–#52 |
| Instances | #48–#49, #58 |
| Field | #45–#46 |
