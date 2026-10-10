# Balance hotspots (post levers-v3 sim)

Quick read from contribution sims.  
Latest: **levers v3** · N=80 · eras 1–3 · seed 42 · `sim/results/CONTRIBUTION_REPORT.md`

---

## Confirmed by levers-v3 contribution sim (2026-10-10)

| Area | E3 mean clear Δ | Status |
|---|---|---|
| **Science level-ups** | **−48%** | Still too central |
| **Troop upgrades** | **−30%** | Healthy reward |
| **Civics** | **−23%** | Healthy |
| **Blueprints** | **−19%** | OK; S4 −30% |
| **Promotions** | **−15%** | **Fixed** (was ~0%) |
| **Policies** | **−14%** | Moderate |
| **Doctrines** | **−5%** | Moved; still weak for clears |
| **Editions** | **−4%** | Small but real |
| **Wonders** | **−4%** | Own-rate up; effect still soft |
| **S2 vs field** | E3 **89%** vs S6 **45%** / S5 **42%** | Gap narrowed (51→44pp) but S2 also rose |

Baseline mean clear: **E1 82% · E2 72% · E3 56%** (was 80 / 68 / 38).

## What the levers did

| Lever | Result |
|---|---|
| Promo scale + editions 30% | **Success** — promotions carry; S2/S5/S6 promo ablation −21–23% |
| Doctrine spoils ×2 + Spoils/War Psalm | Partial — mean −5%; S5 −10%, S3 −15% |
| Wonder every shop + reroll | Own-rate up (S2 none 14%; others ~35–62%); mean Δ still −4% |
| Science 4-offer + S1 wall ignore | S1 E3 26%→65%; S6 20%→45% |
| Don’t nerf S2 | S2 rose 71%→89% on shared combat buffs |

## Next levers (asymmetric evening)

Prefer buffs S4/S5/S6 can eat that S2 cannot:

1. **Faith combat / earlier Doctrine slots** — S5 still dies before spoils snowball; War Psalm–class density or free Missionary slot earlier.  
2. **Builder / S4** — flat at 38% E3; BP path needs more mid-game damage or cheaper Aqueduct density.  
3. **Wonder effect power** (not just funnel) — Oracle/Alexandria/Angkor weight toward S5/S6 shop prefs.  
4. Optional: **Thin Legion promo soft-cap** (1 strong promo vs stacking) so global promo buffs don’t lift S2 as hard.  
5. Science Mom stack still the #1 “everything is Sci” knob if we want less centrality.

## What the next full sim must answer

1. Strategy clears after *asymmetric* evening (S4/S5 vs S2)  
2. Ablations: Doc / Wonder should move more if Faith/Wonder effect buffs land  
3. Utilization: Spoils Liturgy fire rate, Wonder id take rates, promo type mix  

See `SIMULATION.md` and `sim/contribution_sim.py`.
