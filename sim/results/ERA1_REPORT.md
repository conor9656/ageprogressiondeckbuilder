# Simulation Results — Ancient Era (Era 1)

Date: 2026-09-30 · Code: `sim/era1_sim.py` · N=400 per strategy (seed 42)  
**Note:** Defence later raised to base **500** (Village 500 / Town 750 / Capital 1250) in GDD after this report. Figures below used the **old** base **300**. See `ERA3_REPORT.md` for retuned multi-era results.

Settlements (this run): Village **300** · Town **450** · Capital **750**.

Bots play greedy Assaults (enumerate 1–5 card plays), strategy-biased shop / Science / Civics, pack shops, level-ups. Not a full card-pool sim — subset of Blueprints/Doctrines/Policies.

---

## Headline

| Bot | Era win rate | Village | Town | Capital |
|---|---|---|---|---|
| **S1 Wallbreakers** | 92.0% | 100% | 99.5% | 92.5% |
| **S2 Thin Legion** | **100%** | 100% | 100% | 100% |
| **S3 Battle Line** | 91.5% | 100% | 99.8% | 91.7% |
| **S4 Builder burst** | 93.5% | 100% | 99.5% | 94.0% |
| **S5 Faith snowball** | 88.2% | 100% | 99.8% | 88.5% |
| **S6 Science rush** | 88.2% | 100% | 99.5% | 88.7% |
| **BALANCED** | 89.2% | 100% | 99.5% | 89.7% |
| **CLUMSY** (random plays) | **0%** | 51.8% | ~24% of attempts | **0%** |

Raw JSON: `sim/results/era1_summary.json`, `sim/results/era1_clumsy.json`.

---

## How hard is Ancient?

1. **For a thoughtful/greedy player: easy–moderate.** Village is never the wall; **Capital is the only real filter** (~8–12% losses for most strategies).
2. **For clumsy/random play: very hard.** ~half fail Village; nobody clears the Capital. Skill gap is huge (good), but the floor/ceiling may be too far apart.
3. **Naked greedy Village damage** (no shop): p50 total ≈ **427** vs Defence **300** (clear rate 100%). Design wanted a *mild struggle* at 300 — currently it’s a **stomp**, often in 1–2 Assaults.

---

## Strategy notes

- **S2 Thin Legion** overperformed (100%): disbanding Supports densifies combat hands; high formations appear constantly. Likely strong *and* slightly overtuned in this bot.
- **S5 / S6** slightly weaker on Capital (more investment into econ/Science than raw Might before boss).
- Failures cluster on **walled Capitals** with awkward garrisons when the bot never found Siege Tower / Siege upgrade / enough Siege in hand.

---

## Balance recommendations (for next tuning pass)

| Lever | Suggestion |
|---|---|
| Village Defence | **Applied:** base **500** (Village 500 / Town 750 / Capital 1250) in `GAME_DESIGN.md` |
| Town / Capital | Scale with base ×1.5 / ×2.5 |
| Multi-era | See `ERA3_REPORT.md` — Medieval Capital outpaces damage; consider cutting era‑3 base |
| Formation bases | Alternatively nerf early high shapes slightly (Vanguard/Legion bases) if Defence stays |
| Supports | S2 shows Support-disband is very strong — keep Disband cost meaningful |

Do **not** treat these win rates as final until more Blueprints/Policies and human playtests exist; greedy bots overstate human strength, but the Village stomp is clear even so.

---

## Sim limitations

- Subset of modifier cards; no Wonders; simplified Editions/Promotions.
- Greedy enumeration ≠ human; no animation/time pressure.
- Doctrine/Blueprint AI is heuristic.
- Python twin — port to Godot rules later to avoid drift (`TECH_STACK.md`).
