# Contribution / ablation report — eras 1–8 (levers v3)

Eras 1–8 · **N=60**/strategy/ablation · seed 42 · all S1–S6  
Defence bases: 500 / 800 / 1400 / **4500** / 12000 / 30000 / 75000 / 150000

Negative Δ = that system was **carrying** clears.  
Companion 3-era report: `CONTRIBUTION_REPORT.md`.

---

## Headline

**The run dies at Classical → Medieval (era 4).**  
Mean clear: easy through E3, then a cliff.

| Era | Mean clear | Defence (Capital ≈ ×2.5) |
|---|---|---|
| E1 | **81%** | 500 |
| E2 | **73%** | 800 |
| E3 | **57%** | 1400 |
| **E4** | **~10%** | **4500** |
| E5 | **~1%** | 12000 |
| E6–E8 | **~0%** | 30k–150k |

Nobody clears era 7–8 at current numbers. S2 is the only strat with a real E4 foothold (~27%); everyone else is single-digit or zero.

---

## Clear curve by strategy

| Strat | E1 | E2 | E3 | **E4** | E5 | E6 | Sci lv | Doc | Wonder none |
|---|---|---|---|---|---|---|---|---|---|
| **S2** | 97% | 97% | 90% | **27%** | 5% | 0% | 8.5 | 1.5 | **2%** |
| S1 | 97% | 92% | 78% | 7% | 0% | 0% | 7.8 | 1.3 | 3% |
| S5 | 77% | 65% | 48% | **12%** | 2% | 0% | 6.5 | **2.2** | 27% |
| S6 | 65% | 57% | 42% | 8% | 2% | 0% | 5.8 | 1.2 | 33% |
| S3 | 72% | 62% | 47% | 3% | 0% | 0% | 6.1 | 1.2 | 27% |
| S4 | 82% | 68% | 38% | **0%** | 0% | 0% | 6.1 | 1.3 | 15% |

**Where they die (top fails)**
- **S2:** E4 town / E4 capital (even split) — overkill E3 (~1.15× HP), underkill E4 (~0.92×)
- **S1:** E4 town / E4 capital — wall-ignore helps early, not the E4 HP jump
- **S5/S6:** mix of early Capitals + E4 town — still soft before Medieval
- **S4:** mostly E3 capital — never reaches the E4 question

---

## Ablation Δ (mean across strategies)

| Ablation | E1 | E2 | E3 | E4 | E5 |
|---|---|---|---|---|---|
| no_science | −0.25 | −0.46 | **−0.52** | −0.11 | −0.02 |
| no_troop_upgrades | −0.12 | −0.20 | −0.28 | −0.09 | −0.02 |
| no_civics | −0.11 | −0.18 | −0.24 | −0.09 | −0.01 |
| no_blueprints | −0.04 | −0.11 | −0.17 | −0.03 | ~0 |
| **no_promotions** | ~0 | −0.06 | **−0.16** | **−0.09** | −0.02 |
| no_policies | −0.06 | −0.07 | −0.16 | −0.06 | −0.01 |
| no_editions | −0.03 | −0.03 | −0.06 | −0.03 | ~0 |
| no_doctrines | ~0 | −0.01 | −0.03 | +0.03 | 0 |
| no_wonders | ~0 | ~0 | ~0 | −0.01 | ~0 |

Past E4, sample size collapses → ablation Δ → 0 (not “systems don’t matter,” just “almost nobody is alive”).

Promotions still matter into E4 (−9%). Doctrines/Wonders still don’t move clears much even when owned.

---

## Power vs HP (S2 p50 damage/HP)

| Era | Ratio | Read |
|---|---|---|
| E1–E3 | ~1.15–1.22 | Comfortable clears |
| **E4** | **~0.92** | Median shortfall — cliff |
| E5 | ~0.75 | Survivors still behind the curve |

Era 4 defence jump (1400 → 4500 base, Capital ~11k) outpaces stack growth from shops/Sci between E3 and E4.

---

## Wonder funnel at long horizon

Own-rate is high when runs live (S2 **98%** own a Wonder; S1 97%).  
S5/S6 still ~27–33% none — die earlier, less shop time.  
Top S2 picks: Hanging Gardens, Christ the Redeemer, Oracle, Taj Mahal.  
Mean Wonder ablation still ~0 → **ownership ≠ power** at the E4 cliff.

---

## What this means for the next pass

1. **E4 is the balance gate** — retune Medieval defence and/or give a power spike into era 4 (tier soft-cap, formation drills, Wonder combat effects).  
2. **Don’t tune E6–E8 yet** — zero clears; fix the E3→E4 gap first.  
3. **S2 still the only E4 contender** — asymmetric S5/S4/S6 buffs still needed if evening is the goal.  
4. **Promotions confirmed** into mid-game; Faith still spoils-not-damage.  
5. Fixed: failed runs now snapshot `sci_level` / `wonder` / util (was missing → false 0% wonder own in first E8 pass).

Raw JSON: `sim/results/CONTRIBUTION_REPORT_E8.json`
