# E4+ escalation — grow into the curve

Post 8-era sim: early clears are fine; **Renaissance (E4) is a cliff** (mean ~10%, S2 ~27%).  
Defence jumps 1400→4500 (~3.2× Capital HP) while stacks are still mostly tier III / ~8 Sci levels.

Goal: **slightly ease E4 HP**, and more importantly give **exponential growth** so a well-played run’s damage can track later eras.

---

## Diagnosis

| Bottleneck | Effect |
|---|---|
| Soft-cap E3 = III, E4 = IV | Enter E4 still on tier III for first fights |
| Hard tier max V | No headroom past Modern for exponential unit growth |
| Flat Sci/Cul rewards (16) | Income doesn’t scale with era HP |
| Linear Sci/Civ bar costs | Mid-game levels get scarce exactly when you need them |
| Tech Literacy 4%/level | Nice early; too weak vs 3× HP jumps |
| No era-entry spike | Era change is only harder enemies, not a power moment |

---

## Idea menu (exponential / compounding)

### A. Remove / raise tier ceilings *(implement)*
- Soft-caps: E3 **IV**, E4–E5 **V**, E6–E8 **VI**
- Hard max **VI** with new stats (~×1.55 tier V)
- Builder soft-cap → IV from E4 (more BP scale)

### B. Era-scaled Science / Culture income *(implement)*
Victory + city yields grow with era (geometric-ish):

| Era | Income mult |
|---|---|
| 1–2 | 1.0 / 1.15 |
| 3 | 1.35 |
| **4** | **1.75** |
| 5 | 2.2 |
| 6 | 2.8 |
| 7–8 | 3.5 / 4.3 |

Gold/Faith milder (×0.7 of that bump) so shop doesn’t explode alone.

### C. Cheaper mid-game bars *(implement)*
From era ≥ 4: Sci/Civ level-up costs **−20%**. Extend cost table so level 15+ still exists. More levels → more compound (Tech Literacy, Research Corps, trees).

### D. Renaissance Breakthrough *(implement)*
On entering era **≥ 4**: free **1 Science level-up** + **1 Civic level-up** (pick via normal chooser). Feels like an Age transition; rewards players who survived E3.

### E. Age Power — compound combat *(implement)*
- Tech Literacy: **0.04 → 0.055** Mom per Sci level (global)
- From era ≥ 4: **Might × (1 + 0.025 × sci_levels)** baseline (“Age of Reason”) — stacks with Research Corps if owned
- Together, a 12-Sci run at E4 gets ~Mom ×1.66 and Might ×1.30 before formations — toward the 3× HP gap when combined with tier ups

### F. Soften E4–E6 defence *(implement, slight)*
| Era | Old | New |
|---|---|---|
| 4 | 4500 | **3600** |
| 5 | 12000 | **10000** |
| 6 | 30000 | **26000** |
| 7–8 | keep | keep (don’t tune until E5–E6 clears exist) |

### G. Parked ideas (next pass if still short)
- **Mastery ranks** past soft-cap: +8% class Might per extra level (infinite soft growth)
- **Wonder Awakening** at E4: owned Wonder gains a second combat effect
- **Industrial Conscription**: E5+ free +1 Assault
- **Faith compound**: Doctrine spoils ×(1.15^(era-3)) — S5 path
- **Formation Prestige**: each form level past 3 also +5% Mom (exponential drill path)

---

## Target feel after this pack

| Era | Mean clear (aim) | Quick sim N=40 |
|---|---|---|
| E1–E2 | ~80–90% | 84% / 77% ✓ |
| E3 | ~55–70% | **68%** ✓ |
| **E4** | **~25–40%** | **~55%** (hot — cliff fixed; can tighten later) |
| E5 | ~10–20% | **~32%** (new soft gate) |
| E6+ | rising from 0 | not measured this pass |

S2 still leads (E4 92%) but S1/S6/S3 now have real E4 footholds. S5/S4 still lag.

Quick report: `sim/results/E4_ESCALATION_QUICK.md`.

---

## Implementation checklist

1. ✅ Defence table soften E4–E6  
2. ✅ Soft-caps + tier VI unit stats + hard max 6  
3. ✅ Era income mult on Sci/Cul/(mild Gold/Faith) + city yields  
4. ✅ Era ≥4 Sci/Civ cost −20%; longer cost tables  
5. ✅ Era ≥4 breakthrough free Sci + Civ + preferred tier  
6. ✅ Tech Literacy 0.055 + Age Power Might scaler  
7. ✅ Docs: GDD defence, SCIENCE soft-caps, progress  
8. ✅ Quick sim eras 1–5 N=40
