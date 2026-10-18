# Battlefield Support Charges — S1–S5 eras 1–5

N=40/strategy · seed 42 · eras 1–5 · 156.5s

**Change:** Builders & Missionaries are always-on battlefield entities (not deck RNG).
Start **1 charge/settlement**; still take a formation slot until free-slot abilities;
every 2 Sci levels unlock a charge upgrade via **Science (chance)** or **Gold (instant)**.

## Clear rates vs E5-evening baseline

| Strat | Prior E4 | **Now E4** | Prior E5 | **Now E5** |
|---|---|---|---|---|
| S1 | 48% | **72%** | 28% | **62%** |
| S2 | 75% | **87%** | 60% | **80%** |
| S3 | 30% | **65%** | 15% | **40%** |
| S4 | 8% | **40%** | 2% | **15%** |
| S5 | 30% | **55%** | 15% | **47%** |

## Full clear curve

| Strat | E1 | E2 | E3 | E4 | E5 |
|---|---|---|---|---|---|
| S1 | 100% | 100% | 100% | 72% | 62% |
| S2 | 100% | 100% | 100% | 87% | 80% |
| S3 | 100% | 100% | 95% | 65% | 40% |
| S4 | 100% | 100% | 90% | 40% | 15% |
| S5 | 100% | 100% | 90% | 55% | 47% |

## Support usage (goal: not pot-luck)

| Strat | Mean B uses | Mean Y uses | B/settlement | Y/settlement | % runs used B | % runs used Y | Mean B max | Mean Y max | % Bmax≥2 | % Ymax≥2 |
|---|---|---|---|---|---|---|---|---|---|---|
| S1 | 16.8 | 6.1 | 1.191 | 0.433 | 100% | 100% | 3.85 | 3.67 | 100% | 100% |
| S2 | 14.65 | 8.72 | 1.002 | 0.597 | 100% | 100% | 3.95 | 3.75 | 100% | 97% |
| S3 | 14.03 | 5.42 | 1.026 | 0.397 | 100% | 95% | 3.58 | 3.2 | 97% | 95% |
| S4 | 15.88 | 5.17 | 1.252 | 0.408 | 100% | 100% | 3.92 | 3.73 | 100% | 100% |
| S5 | 10.9 | 11.45 | 0.826 | 0.867 | 100% | 100% | 3.58 | 3.85 | 97% | 100% |

## Charge upgrades (Science chance vs Gold instant)

| Strat | B↑ Sci | B↑ Gold | Y↑ Sci | Y↑ Gold | Sci offers B | Sci picks B | Sci offers Y | Sci picks Y |
|---|---|---|---|---|---|---|---|---|
| S1 | 12 | 102 | 0 | 107 | 18 | 11 | 14 | 0 |
| S2 | 4 | 114 | 0 | 110 | 13 | 4 | 18 | 0 |
| S3 | 9 | 94 | 0 | 88 | 24 | 9 | 23 | 0 |
| S4 | 20 | 97 | 0 | 109 | 16 | 16 | 16 | 0 |
| S5 | 0 | 103 | 18 | 96 | 22 | 0 | 18 | 18 |

## Verdict

- **Usage goal hit:** nearly every run uses Builders; Missionaries fire consistently (esp. S5).
- Per-settlement attach rates ~0.8–1.25 B and ~0.4–0.87 Y — no longer hand-draw lottery.
- Charge caps climb to ~3.5–4 by late game via Sci chance + Gold lump purchases.
- Side effect: clear rates rose vs E5-evening (more BP/Doc fire). May need retune if preserving prior curve.

## Rules (sim)

| Rule | Value |
|---|---|
| Starting charges | 1 Builder + 1 Missionary per settlement |
| Cap | 4 charges each |
| Formation slot | Counts unless free-slot flag / Helping Hand / Machu Picchu |
| Sci unlock | `sci_level >= 2 × current_charges` (gates at 2 / 4 / 6) |
| Sci offer chance | 40% when unlocked |
| Gold cost (instant) | 50 / 80 / 120 for charges 2 / 3 / 4 |

