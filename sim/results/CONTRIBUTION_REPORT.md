# Contribution / ablation report (levers v3)

Eras 1–3 · **N=80**/strategy/ablation · seed 42 · all S1–S6  
Compared to prior full sim (pre–levers v3, same seed/N).

Negative Δ = that system was **carrying** clears (removing it hurts).

---

## Headline vs prior sim

| System | Prior E3 Δ | **v3 E3 Δ** | Verdict |
|---|---|---|---|
| **Science level-ups** | −37% | **−48%** | Still dominant (higher baseline power amplifies Sci gap) |
| **Troop upgrades** | −28% | **−30%** | Still a real reward |
| **Civics** | −18% | **−23%** | Healthy / slightly up |
| **Blueprints** | −14% | **−19%** | Healthy |
| **Promotions** | ~0% / noise | **−15%** | **Fixed — now a real system** |
| **Policies** | −10% | **−14%** | Moderate |
| **Doctrines** | ~0% | **−5%** | Moved; still weak for clears (spoils ≠ damage) |
| **Editions** | ~0% | **−4%** | Small but real |
| **Wonders** | −4% | **−4%** | Mean impact flat; **own-rate up a lot** |

Baseline mean clear: **E1 82% · E2 72% · E3 56%** (was **80 / 68 / 38**)

---

## Mean clear-through Δ vs baseline

| Ablation | E1 | E2 | E3 |
|---|---|---|---|
| no_science | −0.246 | −0.432 | −0.481 |
| no_troop_upgrades | −0.090 | −0.205 | −0.304 |
| no_civics | −0.084 | −0.148 | −0.225 |
| no_blueprints | −0.102 | −0.155 | −0.189 |
| no_promotions | −0.009 | −0.050 | −0.150 |
| no_policies | −0.023 | −0.113 | −0.139 |
| no_doctrines | −0.017 | −0.013 | −0.048 |
| no_editions | +0.014 | −0.013 | −0.041 |
| no_wonders | +0.006 | +0.004 | −0.035 |

---

## Baseline by strategy (evening check)

| Strat | Prior E3 | **v3 E3** | Δ | Sci lv | Doc | Wonder none |
|---|---|---|---|---|---|---|
| **S2** | **71%** | **89%** | +18 | 6.8 | 1.4 | **14%** |
| S1 | 26% | **65%** | **+39** | 5.0 | 1.2 | 35% |
| S3 | 42% | **55%** | +13 | 4.3 | 1.2 | 48% |
| S6 | 20% | **45%** | **+25** | 3.5 | 1.2 | 57% |
| S5 | 28% | **42%** | **+14** | 3.2 | **2.1** | 57% |
| S4 | 38% | **38%** | 0 | 2.9 | 1.2 | 62% |

| Strat | E1 | E2 | E3 |
|---|---|---|---|
| S1 | 84% | 78% | 65% |
| S2 | 99% | 99% | 89% |
| S3 | 78% | 68% | 55% |
| S4 | 80% | 68% | 38% |
| S5 | 74% | 55% | 42% |
| S6 | 75% | 62% | 45% |

**Evening:** S5/S6/S1 rose hard toward the “easy E1–E2” feel. S2 also ate the promo/edition buffs (promo ablation on S2 = **−23%** E3), so the **gap narrowed only slightly** (S2−S6 was 51pp → **44pp**). Target was raise others *to* S2 without lifting S2 further — next pass should prefer levers that help S4/S5/S6 more than Thin Legion.

---

## Per-strategy E3 ablation (where levers landed)

| Strat | Sci | Troop | Promo | Doc | Wonder |
|---|---|---|---|---|---|
| S1 | −62% | −38% | **−15%** | −1% | +10%* |
| S2 | −64% | −33% | **−23%** | +4% | +3% |
| S3 | −47% | −31% | −16% | **−15%** | **−21%** |
| S4 | −36% | −24% | +7% | −7% | −4% |
| S5 | −38% | −25% | **−23%** | **−10%** | −7% |
| S6 | −41% | −33% | **−21%** | +1% | −1% |

\*S1 wonder +10% is noise / path dependency at N=80 — wonder mean still slightly negative.

Faith: **S5 Doc −10%**, **S3 Doc −15%** — Spoils/War Psalm matter on some paths; mean still small because most strats don’t lean Missionary.

---

## Wonder funnel

Prior: most non-S2 runs owned **none** (~59–80%).  
v3 `(none)` rates: S2 **14%**, S1 35%, S3 48%, S5/S6 57%, S4 62%.  
Funnel worked for ownership; **effect power** still modest (−4% mean). Next: stronger early Wonder effects or S5/S6-preferring Wonder weights.

---

## What worked / what’s next

**Worked**
1. Promotions are a real system (−15% mean; −21–23% on S2/S5/S6).  
2. Overall clear curve up (E3 mean 38% → 56%) — closer to “easy early eras.”  
3. S1/S5/S6 absolute clears up a lot; Wonder own-rate up.  
4. Doctrines/Editions no longer zero.

**Still open**
1. **S2 still king** and rose with the promo buff — evening needs *asymmetric* buffs (Faith/Builder/Sci path) or Soft-nerf Thin Legion’s promo efficiency, not another global combat buff.  
2. **Doctrines** still spoils-primary (−5% mean) — if we want Faith to carry clears, need more War Psalm–class combat or earlier Doctrine slots for S5.  
3. **Science** still the #1 carrier — Tech Literacy / Academy Mom still the knobs if we want less Sci-centrality.  
4. **S4 flat** at 38% E3 — Builder path didn’t ride these levers.

Raw JSON: `sim/results/CONTRIBUTION_REPORT.json` (also `CONTRIBUTION_REPORT_V3.json`).
