# Balance hotspots (pre–full-sim qualitative)

Quick read from prior sims (balance v2, average-run trajectory) + current content density.  
**Not a substitute for contribution sims** — those numbers come next (§ below + `SIMULATION.md`).

---

## Suspected too strong (nerf candidates)

| Area | Why it smells strong | What to measure |
|---|---|---|
| **S2 Thin Legion** | E3 clear ~64% vs mean ~39%; thin deck + Conscription / Triple Mom spikes | Clear Δ vs other strats; damage share from promotions vs tiers |
| **Science as a whole** | Tech Literacy + Academy Mom + Research Corps + troop tiers all ride Sci levels; S6 and “any strat that takes sci” may be carried | Ablation: freeze Science level-ups → clear Δ |
| **Academy Momentum (Policy R)** | Mom ×(1+0.1×sci) stacks with always-on Tech Literacy | Ablation: ban this Policy; also Sci-levels-only curve |
| **S2 + promotions** | Thin decks multiply per-card promotions harder than fat decks | Ablation: no promotions / no editions |
| **Scriptoria Spire** (new) | Copy-a-unit every win → deck snowball or thin-deck god rolls | Pickup rate + clear Δ when Wonder present vs absent |
| **Kaleidoscope + Academy Mom** (new) | Flat Mom aura × multipliers | Runs with both equipped vs neither |

## Suspected too weak (buff candidates)

| Area | Why it smells weak | What to measure |
|---|---|---|
| **S5 Faith / Missionaries** | E3 ~24%; Doctrines still mostly *after* win → little in-fight power | Ablation: no Doctrines; also “Doctrine fired rate” and damage with/without Missionary in play |
| **Troop tier reward feel** | Tiers matter, but Policies/Blueprints/Sci Mom may dwarf +2–4 Might on a class | Ablation: freeze troop tiers at I; compare Capital damage share |
| **Builders (S4)** | E3 ~32%; slots + BP fire once/settlement — easy to under-fire | % assaults with Builder; BP fire rate; clear Δ no-Blueprints |
| **Civics / Culture** | Avg-run showed ~1.4 civ levels by E1 Cap — shop/Works lines are new and unproven | Ablation: no Civics; pickup rates for Commerce vs Works vs drafts |
| **Wonders (pre-new batch)** | Guaranteed offer/era but bots often skip if gold-tight; unclear if owned Wonder moves clear rate | Own-rate × clear Δ by Wonder id |
| **Editions as a system** | Court Fashion helps, but edition density was ~0.2 specials early | Ablation: no editions; % packs that rolled editions |

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
