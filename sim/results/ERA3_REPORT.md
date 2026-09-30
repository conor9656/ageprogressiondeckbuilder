# Simulation Results — Eras 1–3 (Ancient → Medieval)

Date: 2026-09-30 · Code: `sim/era1_sim.py --eras 3` · N=250 per strategy  
Defence bases (updated): **500 / 800 / 2000** → Capitals **1250 / 2000 / 5000**.

---

## Was a 3-era sim worth it?

**Yes.** Era‑1 alone hid the real problem: **unit/policy multipliers do not keep up with the HP curve into Classical/Medieval** under current stubs. By era‑3 Capital (5000), even survivors deal ~0.4–0.6× required damage.

---

## Clear-through rates (reach and beat that era’s Capital)

| Strategy | Through Era 1 | Through Era 2 | Through Era 3 |
|---|---|---|---|
| S1 Wallbreakers | 32.8% | 7.2% | **0%** |
| S2 Thin Legion | **85.6%** | **38.8%** | **0%** |
| S3 Battle Line | 34.4% | 10.8% | **0%** |
| S4 Builder | 43.2% | 6.8% | **0%** |
| S5 Faith | 22.4% | 2.0% | **0%** |
| S6 Science | 32.0% | 6.8% | **0%** |
| BALANCED | 30.8% | 6.8% | **0%** |

Failures pile up on **Capitals** first, then mid-era Towns once underpowered.

---

## Power vs HP (Capital damage ÷ Capital Defence)

Median damage among bots that *reached* that Capital (wins + losses):

| Era | Capital HP | S2 ratio | S3 ratio | S5 ratio | Read |
|---|---|---|---|---|---|
| 1 Ancient | 1,250 | **1.12** | 0.92 | 0.82 | Borderline–OK for strong builds |
| 2 Classical | 2,000 | **0.98** | 0.87 | 0.69 | Tight; many fail |
| 3 Medieval | 5,000 | **0.55** | 0.56 | — | **Damage cliff** |

HP jumps **×1.6** then **×2.5** across capitals (1250→2000→5000). Typical tier/policy growth in the sim does **not** match that second jump.

---

## Era‑1 retune check (base 500 vs old 300)

Raising Ancient base from 300→500 worked as intended for “not free”:
- Old sim: ~88–100% era‑1 clear for strategy bots.
- New: ~22–43% for most; **S2 still 86%** (thin-deck still dominant).

Prince target (“thoughtful wins regularly”) may want era‑1 clear nearer **60–75%** for non-S2 — either slight Defence ease (base ~450) or more early Blueprint/Policy power in the bot’s available pool.

---

## Implications for multipliers / content

1. **Medieval base 2000 (Cap 5000) is too high** relative to tier III + current modifier density — lower era‑3 base, or ensure Science reliably delivers multiple tier-ups + formation levels + a Rare Blueprint by then.
2. **Scaling cards matter more than we simulated** — full Doctrine snowballs / Policy ×Mom / Aqueduct frequency could close the gap; worth a follow-up with denser packs before cutting HP only.
3. **S2 dominance** continues — Disband + mono-class remains the clearest path; other strategies need earlier payoffs.
4. **Faith/Science paths** fall behind on raw damage before their engines mature — matches the Doctrine snowball risk in GDD §14.

---

## Suggested next balance levers

| Lever | Idea |
|---|---|
| Era 3 base | Try **1,400–1,600** (Cap ~3500–4000) until modifiers fatten |
| Era 2 base | Mild cut **800 → 700** if era‑2 clear stays &lt;15% for non-S2 |
| Era 1 base | Hold **500** or ease to **450** after human feel |
| Growth | More non-troop Science levels; guarantee ~1 uncommon Blueprint by Town 2 |
| Anti-S2 | Disband cost steeper, or mono-class formations get soft diminishing returns |

Raw JSON: `sim/results/era3_summary.json`.
