# Pad Hub — Deck / pad acceptance checklist

Manual verification (CI cannot boot FFXI). Run on Steam Deck Game Mode or Desktop with Gamepad template.

## Setup

- [ ] `dwhub` loads (`/addon load dwhub`)
- [ ] Macro or bind toggles `/dwhub` without stealing Select/OSK
- [ ] Window readable at **1280×720**

## Navigation

- [ ] D-pad / arrows move focus; yellow selection + description panel update
- [ ] A / Enter confirms; B / Esc backs; B on Home closes
- [ ] Character / item / preset picks are **lists** (Refresh works); Type name… only as fallback
- [ ] While open, character does not move / stock menu does not eat A/B (best-effort)
- [ ] Closing restores normal pad control
- [ ] `/addon reload dwhub` picks up Lua copies without restart

## Squad

- [ ] Call / Dismiss enqueue and reach chat as `!squad …`
- [ ] Set slot → name (top field + OSK) works
- [ ] Behavior submenu applies a profile

## Jobs

- [ ] Change jobs shows full job list (WAR … RUN)
- [ ] Main + sub (or none) queues `!jobs set …`
- [ ] Use / save / delete preset via top text field

## Items

- [ ] Find search field is at the **top** (visible with OSK up)
- [ ] Send / Fetch / Equip enqueue correct `!squad` lines
- [ ] Optimize me queues `!optimizegear`

## Rules

- [ ] Assign set / assign when job enqueue `!squad rules use …`
- [ ] No rule-editor UI present (assign only)

## Port

- [ ] Home nation queues `!port home`
- [ ] HP/SG/OP/SP list + Go use top destination field
- [ ] Search queues `!port <name>`

## Blockers

Record failures here (Ashita build, Deck OS, bind conflicts). Fix only true blockers in follow-up issues.

_No Deck hardware in CI — this checklist is the acceptance gate._
