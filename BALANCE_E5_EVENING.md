# E5 evening — first pass (no HP edits)

Goal: lift **all strategies** into Industrial (E5) without changing settlement defence, and without another global Sci×Might buff that breaks S2’s E4 ~75% target.

## Wired in sim (`era1_sim.py`)

### 1. +1 Assault from E5 (global)
`base_assaults += 1` once when entering era 5. Turns ~0.72× shortfalls into clears for marginal runs.

### 2. Line Doctrine Mom (E5+, non-Legion)
For **Battle Line / Combined Arms / Phalanx** only:
- **+2 Mom** flat
- **+1 Mom per form level** (cap +3)

Does **not** buff Vanguard / Legion — S3/S6/mixed paths evening.

### 3. Industrial Toolkit (once at E5 start)
Strategy auto-picks (sim):

| Strat | Pick | Effect |
|---|---|---|
| S3 / S2 | **Drill Sergeant** | +2 form levels on preferred shape |
| S1 / S4 | **Foundry Contract** | Blueprint numeric **×1.5**; S1 also era≥5 wall-ignore ease |
| S5 | **Revival Tent** | Formations **+2 Mom** (Faith combat floor) |
| S6 | **Seminar** | Free Sci level preferring Education / non-troop |

## Success criteria (quick sim)
- S2 E4 stays ~**70–80%** (don’t blow past 75% target much)
- Mean E5 and P(E5\|E4) up for S1/S3/S5/S6/S4
- S3 should move most from Line Mom + Drill

## Not in this pass
- Faith % Might per Doctrine (Zealot Era)
- Soften E5 Town HP
- Age Power / Tech Literacy bumps
