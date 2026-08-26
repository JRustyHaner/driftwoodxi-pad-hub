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

## PR checklist (copy into PR body)

```markdown
## Summary
-

## Issue
Closes #

## Test plan
- [ ] Acceptance criteria from the issue exercised
- [ ] Docs updated
- [ ] No unrelated files changed

## Notes
-
```
