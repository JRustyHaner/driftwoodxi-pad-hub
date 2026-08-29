# Agent guide — DriftwoodXI Pad Hub

This repo ships a **client-only** Ashita addon hub for DriftwoodXI pad play (Steam Deck first). Agents and humans use the same delivery pipeline. Do not skip steps.

## Delivery pipeline (required)

Every change goes through:

**issue → branch → code → test → document → PR → merge**

| Step | What to do |
|------|------------|
| **1. Issue** | Open a GitHub issue first. Capture goal, acceptance criteria, and out-of-scope notes. Work is tracked against that issue. |
| **2. Branch** | Branch from up-to-date `main`. Name: `type/short-desc` (e.g. `feat/hub-toggle`, `fix/port-parse`, `docs/agents-md`). One issue per branch unless the issue explicitly says otherwise. |
| **3. Code** | Implement only what the issue asks for. Prefer small, reviewable diffs. Follow scope in `docs/SCOPE.md`. |
| **4. Test** | Verify before opening a PR. For Lua/addon work: load in Ashita when possible, exercise the acceptance path, note Deck/pad checks. For docs-only: confirm links and that instructions are accurate. Record how you tested in the PR. |
| **5. Document** | Update user-facing or agent-facing docs in the same change (README, `docs/`, addon header comments, install notes). Do not leave “docs later.” |
| **6. PR** | Open a pull request against `main`. Link the issue (`Closes #N` / `Fixes #N`). Include summary, test notes, and any follow-ups. |
| **7. Merge** | Merge only after review (or explicit owner approval). Prefer squash merge unless history matters. Delete the branch after merge. Never commit straight to `main` for feature work. |

### Do not

- Push feature commits directly to `main`
- Open a PR with no linked issue
- Mix unrelated features in one branch/PR
- Expand scope mid-PR without updating the issue

## Product constraints (always)

- **Client-only.** Drive Driftwood via documented typed `!` / `/` surfaces. No server patches in this repo.
- **No packet forgery.** Do not inject fake event-menu or other packets the stock client would not send.
- **No automation that plays unattended.** Hub actions happen because the player chose them.
- **Pad-first UX.** D-pad / A confirm / B back. Search fields at the **top** of windows so Steam Deck OSK does not cover them. Hub opens from a macro/bind; Select may stay on OSK.
- **Safety model.** Same as official dw\* addons: the hub is a renderer over commands the server already accepts and re-validates.

## Repo layout

| Path | Role |
|------|------|
| `addons/dwhub/` | Ashita addon package (install unit) |
| `docs/` | Design and scope notes |
| `AGENTS.md` | This file — agent/human workflow |
| `README.md` | Project overview and install |

## Commands / references

- Driftwood command sheet: https://xi.driftwoodgaming.com/commands
- Allowed addons: https://xi.driftwoodgaming.com/addons
- Deck launch helpers (separate repo): may install or launch FFXI; this repo owns the hub addon only

## Implementation best practices

Follow these when adding or changing hub features. They complement the [product constraints](#product-constraints-always) above and the scope in [docs/SCOPE.md](./docs/SCOPE.md).

### Code structure

- **One screen module per Home category** — target `screens/squad.lua`, `screens/items.lua`, etc. (see [#41](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/41)); avoid a monolithic `screens.lua` as new categories land.
- **Pure logic in testable modules** — command strings in `cmds.lua`, layout math in `layout.lua`, packet/parse logic in `data.lua`; cover with busted where behavior is non-trivial.
- **ImGui drawing stays thin** — window chrome, list viewport, and input routing live in `dwhub.lua`; screen tables return `{ id, title, rows, on_confirm }` data, not large draw blocks.
- **Declare locals before use** — Lua binds locals at compile time; helpers like `action_rows` must appear *above* any function that references them (see [#63](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/63)).

### Data and commands

- **Prefer machine channels** — reads via `!dws`, `!dwj`, `!dwq`, `!dwg`, etc. and `_DW*DATA` senders; scrape human chat only with explicit `*_expecting` flags and [parse fixtures](./spec/fixtures/) ([#42](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/42)).
- **Observe packets; never block official dw\* senders** — dwhub may parse `_DW*DATA` for its own pick lists but must not swallow lines meant for dwbags, dwsquad, dwjobs, etc.
- **Only send registered Driftwood verbs** — unknown `!` commands fall through to **public /say** on this server; match the [command sheet](https://xi.driftwoodgaming.com/commands) and official addon `issue()` strings. When a user-facing alias exists (`!squad send`), prefer it over the machine form (`!dwq send`) for player-visible actions; use machine verbs for silent data refresh.
- **All outbound lines through the throttled queue** — one command per ~1.2s via `queue.lua`; no burst bypass. Duplicates collapse in the queue.

### UX

- **Menu IA** — Home stays at five groups; new addons extend a group screen, never a sixth Home row. See [docs/MENU-IA.md](./docs/MENU-IA.md) ([#38](https://github.com/JRustyHaner/driftwoodxi-pad-hub/pull/60)).
- **Viewport** — list rows render inside a fixed content budget; status/description height included; no clipping below the window footer ([#37](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/37)).
- **Search/filter at the top** — Steam Deck OSK must not cover the field being edited ([docs/UX.md](./docs/UX.md)).
- **Confirm gates** — spend, warp, enter, and buy flows get an explicit Confirm/Cancel step ([#43](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/43)).
- **Pad-first picks** — prefer live pick lists over free typing when roster, presets, or search results already exist; grey locked or unavailable rows (`dim = true`) with a status reason.

### Testing

- **`luacheck` + `busted`** required before opening a PR (`ci` workflow).
- **Parse fixtures** under `spec/fixtures/` for each new `_DW*DATA` verb or record shape you parse.
- **In-game sync** — after merge, `./scripts/sync-to-ashita.sh` (or `DRIFTWOOD_ASHITA=…`) and `/addon reload dwhub`; note Desktop vs Deck in the PR when input or layout changes ([docs/ACCEPTANCE.md](./docs/ACCEPTANCE.md)).

### Versioning and docs

- **Bump `addon.version`** on any user-visible hub change (menu rows, commands, navigation, pad behavior).
- **Update docs in the same PR** — at minimum touch [docs/UX.md](./docs/UX.md) when flows change; [docs/ROADMAP.md](./docs/ROADMAP.md) when shipping or re-scoping; [docs/ACCEPTANCE.md](./docs/ACCEPTANCE.md) when acceptance criteria move.

## PR checklist (copy into PR body)

```markdown
## Summary
-

## Issue
Closes #

## Test plan
- [ ] Acceptance criteria from the issue exercised
- [ ] [MENU-IA](./docs/MENU-IA.md) respected (Home = 5 groups; new work under a group)
- [ ] List viewport: no rows clipped below footer ([#37](./docs/UX.md))
- [ ] Outbound commands registered on Driftwood (no /say leaks)
- [ ] Docs updated (`UX.md`, `ROADMAP.md`, `ACCEPTANCE.md` as needed)
- [ ] `addon.version` bumped if player-visible
- [ ] No unrelated files changed
- [ ] CI green (luacheck + busted)

## Notes
-
```

PRs should stay green on the `ci` workflow (`.github/workflows/ci.yml`). Enable branch protection on `main` to require that check when ready.