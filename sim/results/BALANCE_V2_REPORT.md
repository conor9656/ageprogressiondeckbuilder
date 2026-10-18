# Balance v2 — levers + 3-era results

Date: 2026-10-01 · `sim/era1_sim.py` · N=250 / strategy · seed 42

Goal: raise overall clear rates through Ancient→Medieval using the four player levers (not strategy-evening yet).

---

## Levers applied

| Lever | Change |
|---|---|
| **1. Troop base damage** | Early-weighted buff (~+30–40% tier I). Melee 5→**7**, Cavalry 8→**11**, Ranged 2→**3** (+ tier‑II Mom 1→**2**). High tiers rise less. |
| **2. Resource / level-up density** | Rewards **38G / 16 Sci / 16 Cul / 12 Faith** (was 25/8/8/5). City yield **7**. Science/Civic bar costs lowered (first levels 8/12/16…). |
| **3. Shop** | Pack size **3→5**. Slightly higher edition rate. |
| **4. Scaling / exponential cards** | **Tech Literacy** (always-on): Mom ×(1 + 0.04×sci_levels). Policies: `research_corps` (C) Might×(1+0.05×sci), `academy_momentum` (R) Mom×(1+0.1×sci), `workshop_network`, `liturgical_fire`. Blueprint `observatory` = next Mom×(1+0.1×sci). |
| **5. Wonders** | **One guaranteed Wonder offer per era** + **4%** chance per Treasury slot. Effects: Colosseum +Assault, Great Library free sci pick, Pyramids builder, etc. |
| **HP curve** | Era‑3 base **2000→1400** (Capital **3500**) so scalers can land near 1.0 damage/HP without needing broken early power. Era 1–2 Defence unchanged (500 / 800). |

---

## Clear-through rates (vs balance v1)

| Strategy | E1 v1→v2 | E2 v1→v2 | E3 v1→v2 |
|---|---|---|---|
| S1 Wallbreakers | 33%→**85%** | 7%→**72%** | 0%→**29%** |
| S2 Thin Legion | 86%→**100%** | 39%→**94%** | 0%→**64%** |
| S3 Battle Line | 34%→**83%** | 11%→**72%** | 0%→**42%** |
| S4 Builder | 43%→**82%** | 7%→**68%** | 0%→**32%** |
| S5 Faith | 22%→**76%** | 2%→**58%** | 0%→**24%** |
| S6 Science | 32%→**84%** | 7%→**67%** | 0%→**37%** |
| BALANCED | 31%→**85%** | 7%→**75%** | 0%→**44%** |

**Mean across strategies:** E1 **~85%** · E2 **~73%** · E3 **~39%**.

---

## Capital damage / HP (v2)

| Era | Cap HP | Typical ratio (S3) | S2 | S5 |
|---|---|---|---|---|
| 1 | 1250 | **1.15** | 1.21 | 1.11 |
| 2 | 2000 | **1.15** | 1.20 | 1.14 |
| 3 | 3500 | **1.04** | 1.06 | 0.96 |

Multipliers now roughly track HP through Medieval for mid/strong builds.

---

## Still uneven (later pass)

- **S2** still dominates (64% E3 vs S5 24%).
- **S5 Faith** matures late — needs earlier in-fight Faith payoffs (already flagged in GDD §14.2).
- Strategy evening is **out of scope** for this pass per request.

---

## Recommended provisional locks for GDD

- Unit tier‑I table → v2 numbers  
- Pack size 5; rewards 38/16/16/12  
- Tech Literacy + Academy Momentum pattern  
- Era Wonder offer + rare shop Wonder  
- Era‑3 base Defence **1400** (Cap 3500)

Raw JSON: `sim/results/era3_summary.json` (overwritten with v2).
