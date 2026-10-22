# Ages — Build Progress

> Living tracker for game development, starting **2026-10-22**.  
> Design truth: `GAME_SNAPSHOT.md` · Stack: `TECH_STACK.md` · Research sim: `sim/`  
> Update this file whenever a workstream moves status. Newest notes at the top of each workstream log.

---

## How to read this

| Status | Meaning |
|---|---|
| `not_started` | Not begun |
| `blocked` | Waiting on a decision, tool, or dependency |
| `in_progress` | Active |
| `done` | Acceptance criteria met |
| `parked` | Intentionally deferred |

---

## Workstream board

| ID | Workstream | Status | Owner | Depends on | Done when |
|---|---|---|---|---|---|
| **W0** | Game snapshot (`GAME_SNAPSHOT.md`) | `done` | — | — | Single source of truth exists |
| **W1** | Godot rules module + tests | `blocked` → ready once Godot is available | Agent | W0; Godot 4 on PATH | Headless tests + parity vs Python golden seeds |
| **W2** | Vertical slice UI (one settlement) | `not_started` | Agent | W1 | Playable greybox fight |
| **W3** | Ancient run loop + shop | `not_started` | Agent | W2 | Full Ancient era greybox |
| **W4** | Content as data (JSON/resources) | `not_started` | Agent | W1 (can overlap W2–3) | Numbers swappable without code edits |
| **W5** | Unify rules (Godot canonical) | `not_started` | Agent | W1 + stable slice | One rules path in CI |
| **W6** | Art pipeline spike | `not_started` | Human+Agent | W2 feel locked | One class in-engine |
| **W7** | Multi-era systems | `not_started` | Agent | W3 | Domination greybox |
| **W8** | Steam smoke export | `not_started` | Agent | W7-ish | Windows build + stub Steam |

---

## Current focus

**W1 — Godot rules module + tests** (next to start).

Blocked only on: **Godot 4.x available to the agent** (not installed in this Cloud environment yet). See [What we need from you](#what-we-need-from-you).

---

## W1 — Godot rules module + tests

### Intent

Port the *pure rules* from `sim/era1_sim.py` into Godot so combat is engine-native, headless-testable, and ready for UI (W2) to call without owning math.

### Approach (how we should do this)

```
sim/era1_sim.py  (oracle — keep for now)
        │
        ▼  port + golden seeds
game/                    ← Godot 4 project root
  project.godot
  rules/                 ← no Node tree; RefCounted / Resource
    card.gd
    formation.gd
    damage.gd
    support_charges.gd
    settlement_fight.gd
    run_state.gd         ← minimal fields needed for damage
  content/               ← JSON stubs first (tiers, FORM_BASE, defence)
  tests/
    test_formations.gd
    test_damage.gd
    test_parity.gd       ← same seeds as Python fixtures
    run_tests.gd         ← entry for --headless
  tools/
    export_python_fixtures.py  (optional) or checked-in JSON fixtures
```

**Principles**

1. **Rules ≠ scenes.** Combat math lives in `rules/*.gd` as plain classes. UI later only calls `evaluate_play()` / `resolve_assault()`.
2. **Deterministic.** Same seed → same shuffle / damage. Required for parity and bug repro.
3. **Thin vertical slice of rules first.** Order of port:
   1. Card kinds + tiers + unit Might/Mom tables  
   2. Formation ranking (all 10 shapes)  
   3. `Might × Momentum` + Tech Literacy / Age Power hooks  
   4. Walls + garrisons  
   5. Battlefield support charges (attach + slot rules)  
   6. One Blueprint + one Doctrine apply path (enough for slice)  
   7. Settlement fight loop (Assault/Regroup counters) — still headless  
4. **Python stays oracle until parity is green.** Do not delete `sim/` in W1.
5. **Tests before UI.** No greybox screen until W1 acceptance passes.

### Acceptance criteria (W1 done)

- [ ] Godot 4 project boots headless (`godot4 --path game --headless --quit`)
- [ ] Formation tests: each rank shape resolves correctly
- [ ] Damage tests: known hand → expected Might/Mom/damage (walls on/off)
- [ ] Support-charge tests: 1 charge, slot cost, free-slot flag
- [ ] **Parity:** ≥10 golden fixtures from Python match Godot output bit-for-bit (or documented float policy)
- [ ] CI-ready script: one command runs the suite and exits non-zero on fail

### How the agent communicates with Godot (efficiently)

Agents are bad at clicking the editor. We will **never** depend on the GUI for W1.

| Channel | Use |
|---|---|
| **CLI / headless** | `godot4 --headless --path game -s res://tests/run_tests.gd` — primary loop |
| **Text files** | `.gd`, `.tscn`, `.tres`, `.json`, `project.godot` — all diffable |
| **stdout JSON** | Tests print `PASS`/`FAIL` lines or a small JSON summary for the agent to parse |
| **Fixtures** | Checked-in JSON under `game/tests/fixtures/` generated from Python once |
| **Editor** | Optional for *you* later (W2 UX eyeballing). Agent does not need it for W1 |

**Not used in W1:** Spine, art import, Steam, C#, visual regression.

### Log

| Date | Note |
|---|---|
| 2026-10-22 | Workstream opened. Plan written. Waiting on Godot 4 in agent env (and/or local confirm). |

---

## What we need from you

Only a few decisions — nothing artistic yet.

### Required to unblock W1

1. **Godot 4 for the Cloud Agent**  
   Approve adding **Godot 4.x** (Linux headless/standard build) to the project environment so agents can run `--headless` tests here.  
   Preferred: **Godot 4.3 or 4.4 stable** (say which if you care; otherwise we pick latest stable 4.x).

2. **Project folder name**  
   Default proposal: repo root `game/` for the Godot project. OK? (Alternative: `ages/`.)

3. **Local Godot (optional but useful from W2)**  
   Install the **same** Godot 4.x on your machine when we reach UI, so you can press Play and feel the slice. Not required for W1 if CI/agent headless works.

### Nice-to-have (can answer later)

| Question | Default if silent |
|---|---|
| Test framework | Custom `--headless` runner first; GUT only if it earns its keep |
| Keep Python sim | **Yes** through W5 as oracle |
| License / display name | Keep working title “Ages” in `project.godot` |
| Git LFS now | **No** until art lands |

### You do *not* need to provide yet

Art bible, Spine license, Steam App ID, leaders, Endless formula, S4/S5 rebalance.

---

## Communication rhythm (agent ↔ you)

| When | What you’ll get |
|---|---|
| Start of a workstream | Status → `in_progress` in this file + short plan |
| During W1 | PR with `game/rules` + failing→passing tests; ask only if blocked |
| End of W1 | Checklist above ticked; paste headless test summary |
| Handoff to W2 | “Open `game/` in Godot locally” + what to click |

If something needs a human choice, it will be a **single explicit question** (version / folder / approve env), not a questionnaire.

---

## Other workstream stubs

### W2 — Vertical slice UI
- Status: `not_started`
- Depends: W1 green
- Done when: greybox Ancient fight playable (see `GAME_SNAPSHOT.md` §11 milestone)

### W3 — Ancient run + shop
- Status: `not_started`
- Depends: W2

### W4–W8
- See board above; detail added when each becomes current focus.

---

## Changelog (build tracker)

| Date | Change |
|---|---|
| 2026-10-22 | Created tracker; W0 done; W1 planned and blocked on Godot install |
