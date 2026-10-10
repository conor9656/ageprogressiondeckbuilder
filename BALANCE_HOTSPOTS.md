# Balance hotspots (pre–full-sim qualitative)

Quick read from prior sims (balance v2, average-run trajectory) + current content density.  
**Not a substitute for contribution sims** — those numbers come next (§ below + `SIMULATION.md`).

---

## Confirmed by full contribution sim (2026-10-10)

N=80 · eras 1–3 · seed 42 · `sim/results/CONTRIBUTION_REPORT.md`

| Area | E3 mean clear Δ | Status |
|---|---|---|
| **Science level-ups** | **−37%** (E2 −53%) | **Confirmed too central** — nerf Sci Mom stack |
| **Troop upgrades** | **−28%** | **Confirmed valuable** — keep; good reward for Sci picks |
| **Civics** | **−18%** | Healthy contributor |
| **Blueprints** | **−14%** | OK; S4 hurts more (−30%) |
| **Policies** | **−10%** | Moderate |
| **Wonders** | **−4%** | **Too weak / under-owned** (most runs: none) |
| **Doctrines** | **~0%** | **Confirmed too weak** for clears |
| **Promotions / Editions** | **~0%** | **Confirmed underpowered** despite high promo buy rate |
| **S2 vs field** | E3 **71%** vs S6 **20%** / S5 **28%** | **Confirmed too strong** |

## Prior suspects (updated)

| Area | Note |
|---|---|
| Academy Mom + Tech Literacy | Inside Science carry — primary nerf knobs |
| S2 + long survival | S2 also takes 5.5 Sci levels / 71% Wonder own — feedback loop |
| Faith in-fight | Doctrines bought but don’t move clears — need combat auras |
| Promotions | Gold sink; +2 Might not enough — retune or cut weight |

## “Probably fine / watch”

- Formation drills — steady, not flashy; check if ever chosen vs currency trees.  
- Banking/Education % trees — new; watch Gold/Sci explosion era 4+.  
- Safe Conduct — skip feels strong but costs Wonder slot + half rewards; measure use rate.

## Special cards — do we need more?

**Not more volume yet** — pools are fat (40+ each + new idea batch). Next sim should answer **utilization**, not count:
- Offer rate vs take rate vs “equipped but never fired”
- Outlier cards that appear in top 10% damage runs vs bottom 10%

Add specials only where contribution sim shows a **hole** (e.g. Faith still dead after Buffs, or no mid-game Builder identity).

---

## What the next full sim must answer (locked)

Not only “which strategy wins,” but **which systems carry**:

1. **Strategy clear curves** — S1–S6, eras 1→N  
2. **Ablation deltas** — turn one system off, measure clear % and Capital damage/HP  
3. **Utilization** — offer / take / fire rates for Science picks, Civics, BP, Doc, Wonders, Promotions, Editions  
4. **Outliers** — runs where one card/Wonder correlates with huge overkill or with never being taken when offered  

See `SIMULATION.md` § Contribution & ablation and `sim/contribution_sim.py`.
