# Simulation Plan — readiness & phases

How we turn provisional numbers into tuned ones. Newest decisions live here; results go in `progress.md`.

---

## Verdict: are we ready?

| Phase | Ready now? | Needs first |
|---|---|---|
| **A — Round 1 combat only** (Ancient Village, starting deck) | **Yes** | A play bot (not pure random) |
| **B — Post-Village rewards → Town** | **Almost** | Stub reward + shop tables (not full trees) |
| **C — Full era / tech / policy variation** | **No** | Minimal Ancient tech/civic list + Policies |

Do **not** wait for complete tech trees before Phase A. Combat math + starting deck are already locked enough.

---

## Method: measure damage, then set Defence

Yes — invert the problem:

1. Fix formation bases + unit stats (already in `GAME_DESIGN.md`).
2. Simulate many Round‑1 fights **with no Defence cap** (or a huge cap).
3. Record **total damage over 4 Assaults** (and per-Assault distribution).
4. Set Village Defence from percentiles of *skilled* play, not from a lucky mean.

**Do not use pure random card plays as the balance target.** Random understates damage badly (plays supports for nothing, splits bad shapes). Use at least:

| Bot | Role |
|---|---|
| **Greedy** | Enumerate legal plays (1–5 cards); pick max expected Might×Momentum; Regroup when no play beats a threshold | **Primary balance target** |
| **Random-legal** | Sanity floor — “how bad can it go?” |
| **Heuristic / “thoughtful”** (later) | Prefer saving Siege for walls, hold for Phalanx, etc. |

Suggested Village tuning (Prince): Defence ≈ **p40–p50** of Greedy total damage → “mild struggle.” Town / Capital multipliers stay ×1.5 / ×2.5 until Phase B says otherwise.

---

## Phase A — Round 1 only (do this first)

**Locked inputs (enough to code):**
- Deck: 6M / 5R / 3C / 2S / 2 Builder / 2 Missionary, all tier I
- Hand 8, 4 Assaults, 3 Regroups, reshuffle on empty
- Formation table + auto highest rank; supports never score
- Tier‑I unit stats; Militia; **no walls**; no Policies / Blueprints / Doctrines equipped
- Formation levels = 0 extras beyond the base table

**Outputs to report:**
- Mean / p25 / p50 / p75 / p90 of **total damage** (4 Assaults)
- Same for **damage per Assault**
- Formation hit rates (how often Pair vs Battle Line vs Phalanx, etc.)
- Share of hands where Greedy Regroups

**Deliberately out of scope:** shop, techs, leaders, garrisons other than Militia, walls.

That answers: “what average (and spread) does Round 1 actually deal?” → then set Village HP. Town HP waits until Village feels right, or use ×1.5 as a placeholder only.

---

## Phase B — after Village, into Town (stubs, not full design)

Still **no** full tech tree. Add **provisional stubs**:

| Stub | Why |
|---|---|
| Base Gold / Science / Culture / Faith for a Village win | Resource inflow |
| +Gold per unused Assault; interest (+1 / 5 Gold, cap +5) | Already designed |
| Raze vs Occupy: one Gold lump vs +yield next fight | Branching |
| Tiny Ancient shop: unit costs, 1–2 common Blueprints, Disband cost | Deck change before Town |
| Town: ×1.5 Defence, optional walls 50%, random garrison | Real second fight |

Simulate: Village → reward → one shop policy (buy best unit / Blueprint / disband / save) → Town fight. Report clear rate and damage vs placeholder Town HP.

**“First boss”** = Ancient **Capital** (settlement 3), not Village. Phase B′ after Town stubs: Capital ×2.5 + one boss rule stub.

---

## Phase C — variation explosion (later)

Only after A/B numbers feel sane:

- Minimal **Ancient** tech list (class tier ups, formation levels, Builder tier)
- Minimal civics → 3–5 Policies
- Doctrine / Faith paths
- Leaders

Here Monte Carlo over *build paths* matters. Until then, path variance is noise we cannot interpret.

---

## What we still must decide before coding Phase A

1. **Bot:** Greedy as balance voice — confirmed?
2. **Supports in Round 1:** dead cards (no Blueprint/Doctrine) — yes, model as slot-eaters only.
3. **Leader:** none (default deck) for baseline.
4. **Sim language:** Python twin for speed is fine for Phase A **if** we delete it once Godot rules exist; prefer one implementation long-term (`TECH_STACK.md`). For a first spike, Python is acceptable to get numbers tomorrow.

Nothing else blocks Phase A.
