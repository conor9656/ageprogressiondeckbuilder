# Ages — Build Progress

> Living tracker for game development, starting **2026-10-22**.  
> Design truth: `GAME_SNAPSHOT.md` · Stack: `TECH_STACK.md` · Research sim: `sim/` · Client: `game/`  
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

## Decisions locked (2026-10-23)

| Decision | Choice |
|---|---|
| Engine version | **Godot 4.7.2** stable (latest stable as of lock; avoid 4.8 beta) |
| Project folder | **`game/`** |
| Agent ↔ engine | **Headless CLI only** for W1 (`godot4 --headless --path game -s …`) |
| Local editor | **Optional — your machine, from W2** (same 4.7.2). Not needed for W1 |

Install helper for agents/CI: `scripts/install_godot.sh`.

---

## Workstream board

| ID | Workstream | Status | Owner | Depends on | Done when |
|---|---|---|---|---|---|
| **W0** | Game snapshot (`GAME_SNAPSHOT.md`) | `done` | — | — | Single source of truth exists |
| **W1** | Godot rules module + tests | `in_progress` (core combat green) | Agent | W0; Godot 4.7.2 | Headless tests + parity vs Python golden seeds |
| **W2** | Vertical slice UI (one settlement) | `not_started` | Agent | W1 | Playable greybox fight |
| **W3** | Ancient run loop + shop | `not_started` | Agent | W2 | Full Ancient era greybox |
| **W4** | Content as data (JSON/resources) | `not_started` | Agent | W1 (can overlap W2–3) | Numbers swappable without code edits |
| **W5** | Unify rules (Godot canonical) | `not_started` | Agent | W1 + stable slice | One rules path in CI |
| **W6** | Art pipeline spike | `not_started` | Human+Agent | W2 feel locked | One class in-engine |
| **W7** | Multi-era systems | `not_started` | Agent | W3 | Domination greybox |
| **W8** | Steam smoke export | `not_started` | Agent | W7-ish | Windows build + stub Steam |

---

## Current focus

**W1 — Godot rules module + tests** (`in_progress` — core combat done).

Core rules ported + **16 Python golden fixtures** matching bit-for-bit.  
`bash scripts/run_game_tests.sh` → `AGES_TESTS_OK failed=0`.  
Still open for full W1: fight loop (Assault/Regroup), one BP/Doc apply path, more fixtures.

---

## W1 — Godot rules module + tests

### Intent

Port the *pure rules* from `sim/era1_sim.py` into Godot so combat is engine-native, headless-testable, and ready for UI (W2) to call without owning math.

### Approach (yes — this is the efficient path forward)

```
sim/era1_sim.py  (oracle — keep for now)
        │
        ▼  port + golden seeds
game/                    ← Godot 4.7.2 project root
  project.godot
  rules/                 ← no Node tree; RefCounted
  content/               ← JSON tables
  tests/                 ← headless suite
```

**Why this stays efficient for later workstreams**

1. **Rules ≠ scenes** — W2 UI only calls into `rules/`; no math in buttons.  
2. **CLI / headless** — agents iterate without the editor; same command in CI.  
3. **Python oracle** — parity fixtures catch drift until Godot is canonical (W5).  
4. **Text-first** — `.gd` / JSON / `project.godot` diff cleanly in PRs.  
5. **Same Godot patch everywhere** — agent, CI, and your local editor all on **4.7.2**.

**Port order**

1. Card kinds + tiers + unit Might/Mom tables  
2. Formation ranking (all 10 shapes)  
3. `Might × Momentum` + Tech Literacy / Age Power hooks  
4. Walls + garrisons  
5. Battlefield support charges  
6. One Blueprint + one Doctrine apply path  
7. Settlement fight loop (Assault/Regroup) — still headless  

### Acceptance criteria (W1 done)

- [x] Godot 4 project boots headless
- [x] Smoke test runner exits 0 (`AGES_TESTS_OK`)
- [x] Formation tests: all 10 ranks covered in fixtures
- [x] Damage tests: walls / garrisons / Tech Literacy / Age Power
- [x] Support-charge tests: spend, refill, upgrade gate, slot attach
- [x] **Parity:** 16 golden fixtures from Python match Godot
- [x] CI-ready one-command suite (`scripts/run_game_tests.sh`)
- [ ] Settlement fight loop (Assault/Regroup counters) headless
- [ ] One Blueprint + one Doctrine apply path

### How the agent talks to Godot

```bash
godot4 --headless --path game -s res://tests/run_tests.gd
```

| Channel | Use |
|---|---|
| **CLI / headless** | Primary loop — never depend on clicking Play for W1 |
| **Text files** | `.gd`, `.tscn`, `.json`, `project.godot` |
| **stdout** | `PASS` / `FAIL` / `AGES_TESTS_OK` |
| **Fixtures** | `game/tests/fixtures/` from Python |
| **Editor** | **You**, from W2 — open `game/` in Godot 4.7.2 to feel UX |

### Log

| Date | Note |
|---|---|
| 2026-10-23 | Core combat port: formations, Might×Mom, walls, garrisons, literacy, Age Power, support charges. 16/16 fixtures vs Python. |
| 2026-10-23 | Locked Godot **4.7.2** + folder **`game/`**. Scaffold + smoke test green. |
| 2026-10-22 | Workstream opened. Plan written. Waiting on Godot / folder confirm. |

---

## What we need from you

### Resolved

1. ~~Godot version~~ → **4.7.2**  
2. ~~Folder name~~ → **`game/`**  
3. **Local Godot** → **Yes, that’s for you** — but **only when we start W2** (greybox UI). For W1, agents/CI use headless `godot4`; you don’t need to install anything yet. When W2 lands, install [4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) and open `game/`.

### Still optional later

Art bible, Spine, Steam App ID, balance evening — not needed now.

---

## Communication rhythm (agent ↔ you)

| When | What you’ll get |
|---|---|
| Start of a workstream | Status → `in_progress` here + short plan |
| During W1 | PRs with rules + tests; ask only if blocked |
| End of W1 | Checklist ticked + headless summary |
| Handoff to W2 | “Install Godot 4.7.2 → open `game/` → Play” |

---

## Other workstream stubs

### W2 — Vertical slice UI
- Status: `not_started`
- Depends: W1 green
- Your part: local Godot 4.7.2 to playtest greybox

### W3–W8
- See board; detail when each becomes current.

---

## Changelog (build tracker)

| Date | Change |
|---|---|
| 2026-10-23 | Locked 4.7.2 + `game/`; scaffold; W1 in progress; clarified local install = you @ W2 |
| 2026-10-22 | Created tracker; W0 done; W1 planned |
