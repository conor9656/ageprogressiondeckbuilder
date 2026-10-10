# Contribution / ablation report (full)

Eras 1–3 · **N=80**/strategy/ablation · seed 42 · all S1–S6

Negative Δ = that system was **carrying** clears (removing it hurts).

---

## Headline

| Rank | System | Mean E3 clear Δ | Verdict |
|---|---|---|---|
| 1 | **Science level-ups** | **−37%** (E2 **−53%**) | Dominant carrier — nerf Sci Mom stack / diversify power |
| 2 | **Troop upgrades** | **−28%** | Real reward; keep, but less of total Sci screen |
| 3 | **Civics** | **−18%** | Meaningful mid-game; Commerce/Works landing |
| 4 | **Blueprints** | **−14%** | Matter (esp. S4); not carrying other strats |
| 5 | **Policies** | **−10%** | Moderate; Academy Mom inside this bucket |
| 6 | **Wonders** | **−4%** | Weak mean impact; **~59–80% of runs own none** |
| 7 | **Doctrines** | **~0%** | Faith payoffs not moving clears — buff in-fight |
| 8 | **Promotions / Editions** | **~0% / +noise** | Underperforming as systems (bots buy promos but Δ≈0) |

Baseline mean clear: **E1 80% · E2 68% · E3 38%**

---

## Mean clear-through Δ vs baseline

| Ablation | E1 | E2 | E3 |
|---|---|---|---|
| no_science | −0.294 | −0.531 | −0.371 |
| no_troop_upgrades | −0.146 | −0.302 | −0.277 |
| no_civics | −0.091 | −0.171 | −0.177 |
| no_blueprints | −0.123 | −0.196 | −0.137 |
| no_policies | −0.025 | −0.104 | −0.100 |
| no_wonders | −0.008 | −0.044 | −0.038 |
| no_doctrines | +0.046 | −0.002 | −0.003 |
| no_promotions | +0.006 | −0.012 | +0.056 |
| no_editions | +0.015 | −0.034 | +0.002 |

---

## Baseline by strategy

| Strat | E1 | E2 | E3 | mean Sci lv | Civ lv | BP | Doc | Wonder own |
|---|---|---|---|---|---|---|---|---|
| S1 | 78% | 66% | 26% | 2.0 | 2.0 | 2.6 | 1.1 | 26% |
| **S2** | **100%** | **96%** | **71%** | **5.5** | **5.1** | 2.3 | 1.3 | **71%** |
| S3 | 80% | 68% | 42% | 3.2 | 3.1 | 2.1 | 1.2 | 41% |
| S4 | 80% | 69% | 38% | 2.8 | 2.7 | **3.4** | 1.1 | 36% |
| S5 | 70% | 54% | 28% | 2.1 | 1.9 | 1.7 | **2.0** | 28% |
| S6 | 72% | 54% | 20% | 1.5 | 1.6 | 1.7 | 1.2 | 20% |

S2 still dominates and also **survives longest → takes most Sci/Civ levels and buys most Wonders**. Part of “Science carries” is “winners get more Science.”

---

## Utilization notes (S3 sample)

- **Science picks:** heavily `upgrade_M/R/C`; Education/Banking trees rare (single digits).
- **Civics:** Craftsmanship, Stall Permits, Corvée Exemption, Windfall show up — Commerce/Works are live.
- **Shop:** many promotions bought (286) but ablation says promotions don’t move clears — **promos are gold sinks with weak payoff**.
- **Doctrines:** bought (tithe/scriptorium) but ablation ~0 — **economy after win ≠ damage**.

---

## Recommended balance levers (next pass)

1. **Nerf Science stack:** Tech Literacy and/or Academy Mom; or soft-cap Sci levels’ Mom multiplier.  
2. **Buff Faith in-fight:** Doctrine combat auras / Missionary-on-assault payoffs (not just victory gold).  
3. **Make promotions matter:** +Mom or on-score combat, not only +2 Might — or cut cost/weight.  
4. **Wonder funnel:** cheaper early Wonder or stronger guaranteed-era effect — own-rate is too low outside S2.  
5. **Strategy evening:** S2 E3 71% vs S6 20% / S5 28% — still the open gap.

Raw JSON: `sim/results/CONTRIBUTION_REPORT.json`
