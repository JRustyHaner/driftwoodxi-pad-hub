# Pad Hub — Deck / pad acceptance checklist

Manual verification (CI cannot boot FFXI). Run on Steam Deck Game Mode or Desktop with Gamepad template.

## Setup

- [ ] `dwhub` loads (`/addon load dwhub`)
- [ ] Macro or bind toggles `/dwhub` without stealing Select/OSK (Deck: **L4** → F9)
- [ ] Window readable at **1280×720**

## Navigation

- [ ] Home shows **five groups** only: Party and Travel, Inventory and Trade, Quests and Crafts, Instances, Field
- [ ] Group → category → screen (e.g. Party and Travel → Squad → Call)
- [ ] Planned categories appear dimmed; confirming shows status, does not crash
- [ ] D-pad / arrows move focus; yellow selection + description panel update
- [ ] A / Enter confirms; B / Esc backs; B on Home closes
- [ ] While open, character does not move / stock menu does not eat A/B / arrows / Enter / Esc (gamepad + keyboard block)
- [ ] Closing restores normal pad and keyboard control

## Squad

- [ ] Call / Dismiss enqueue and reach chat as `!squad …`
- [ ] Roster shows slots 1–5 (read-only) with Refresh
- [ ] Set slot → character pick works
- [ ] Cast… queues `!{tag} {spell} [target]`
- [ ] Behavior submenu applies a profile

## Jobs

- [ ] Change jobs greys locked jobs for the selected character
- [ ] Main + sub (or none) queues `!jobs set …`

## Items

- [ ] Send / Fetch prompt for quantity (1 / 5 / 10 / 99 / custom)
- [ ] Optimize → Apply or Preview only

## Rules

- [ ] Assign set / assign when job enqueue `!squad rules use …`
- [ ] No rule-editor UI present (assign only)

## Port

- [ ] Home nation queues `!port home`
- [ ] HP/SG/OP/SP list + Go; locked rows cannot Go
- [ ] Search queues `!port <name>`

## Blockers

Record failures here (Ashita build, Deck OS, bind conflicts). Fix only true blockers in follow-up issues.

_No Deck hardware in CI — this checklist is the acceptance gate._
