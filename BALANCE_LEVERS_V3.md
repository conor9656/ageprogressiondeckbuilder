# Balance levers v3 — design notes (post contribution sim)

Responds to the four levers + your Doctrine fantasy clarification.  
Numbers are proposals; implemented values live in code/docs after this pass.

---

## 1. Faith / Doctrines — keep the “risk a hand for bigger rewards” fantasy

### What the sim was measuring

Contribution Δ ≈ **0% clear** for `no_doctrines` does **not** mean rewards weren’t applied. The sim **does** pay Doctrine victory gold/sci/faith in `apply_doctrine_rewards`.  

It means those payouts were **too small to change who wins fights**:
- Doctrines don’t help the Assault you’re in (by design).
- Extra shop fuel only helps if you **survive** to spend it — S5 often dies at Capitals before the snowball turns.
- So “economy after win ≠ damage” is correct: the fantasy is fine; the **magnitude** and a thin **combat safety layer** were missing.

### Do we want bigger victory buffs?

**Yes — that’s the core fantasy.** Playing a Missionary costs a formation slot (unless Lay Preachers / float / free-use). The payout must feel like “I spent an Assault’s worth of board for a jackpot.”

Proposed payout scale (~**2–2.5×** commons, Capitals pay more):

| Doctrine | Old | New |
|---|---|---|
| Tithe | +15 Gold | **+35 Gold** (+50 on Capital) |
| Scriptorium | 8% dmg Sci cap 40 | **12% dmg Sci cap 70** |
| Pilgrimage | +10 Faith | **+22 Faith** |
| Alms | +8 Culture | **+18 Culture** |
| Zeal | +15% Might ×2 settlements | **+20% Might ×2** (keep combat sticky) |
| Missionary Zeal | scale gold/faith | steeper step |
| **New: Spoils Liturgy** (U) | — | Victory rewards **×1.5** this settlement (the headline “I think I’ll win” card) |
| **New: War Psalm** (U) | — | This settlement: formations **+1 Mom** while Doctrine fired (thin in-fight) |
| **New: Martyr's Guard** (R) | — | If you would lose on last Assault, survive at 1 Defence once (clutch Faith) |

**Assault stuff:** add a **small** combat Doctrine layer (War Psalm, Zeal buff) so Faith isn’t zero for clears, but **don’t** turn Doctrines into Blueprints. Primary identity stays victory spoils.

**More Doctrines?** A few headline ones (Spoils Liturgy, War Psalm) > flooding the pool. Volume was fine; **impact** wasn’t.

---

## 2. Promotions + Editions

### Promotions (scale up a lot)

Contribution: bots **bought** promos heavily, clear Δ ≈ 0 → +2 Might is a gold sink.

| Promo | New effect | Cost |
|---|---|---|
| Master Drill (C) | **+5 Might** (was +2) | 12 Gold (was 10) |
| Skirmish Doctrine (C) | **+2 Mom** (was +1) | 12 |
| Banner Carrier (U) | Formation **+12 Might** while scoring with this card | 22 |
| Heroic (R) | Card Might **×1.75** (was ×1.5) | 40 |
| **New: Shock Drill** (U) | **+3 Might and +1 Mom** | 20 |
| **New: Relentless** (R) | Card scores **twice** each settlement (first two scores) | 40 |

Shop weight: promotion band **20% → ~28%** of Treasury rolls. Stronger → slightly pricier, but still a clear buy.

### Editions (more stamps + higher drop)

Base edition chance **15% → 30%**. Add:

| Edition | Effect |
|---|---|
| **Berserker** | +4 Might |
| **Hawk-Eyed** | +2 Momentum |
| **Savant** | If scored → +20% Science this victory |
| **Zealot** | If scored → +20% Faith this victory |
| **Plated** | +3 Might; ignore half of Archers-garrison penalty on this card |
| Gilded / Scholarly / Devout / Mercantile | keep; bump Gilded to +3 Might |

Wonder idea (below): **Mint of Heroes** — all unit offers this run are Editions.

---

## 3. Wonder funnel + more Wonders

### Funnel (your ask)

- **Every shop visit** while you own **no** Wonder: a **dedicated Wonder slot** is always shown (not buried in the 5-pack RNG).
- **Reroll that Wonder once** per visit for Gold (same reroll cost as Treasury, or 5 Gold).
- Soft-cheaper curve: early Wonders **~55–70**, late **~80–100** (was 70–110 flat).
- Skip still = rival builds it (gone).

### New Wonders (names + niches — equal power, different fantasy)

| Wonder | Niche | Effect |
|---|---|---|
| **Oracle of Delphi** | Science | Sci bar costs **−25%** |
| **Museum of Alexandria** | Science | **+25% Science** from all sources |
| **Angkor Wat** | Faith | **+25% Faith**; Doctrine numeric **+25%** |
| **Hagia Sophia** | Faith/hand | Opening hand: **float Builder + float Missionary** (don’t count to hand size) |
| **Machu Picchu** | Supports | Played Builder/Missionary **never consume formation slots** |
| **Chichen Itza** | Combat | All formations **+2 Mom** |
| **Taj Mahal** | Economy | Victory Gold **+50%** |
| **Eiffel Tower** | Shop | All Treasury units are **Editions**; promotions **−30%** cost |
| **Christ the Redeemer** | Faith clutch | Once/era: if Capital would kill you, set Defence left to 0 (auto-clear, half rewards) |
| **Petra** | Occupy | Occupied city yields **×2** |
| *(existing)* Colosseum, Library, Pyramids, … | keep | retune costs down slightly |

**Hagia Sophia / Machu Picchu** are strong support Wonders — intentional Faith/Builder path answers to “float both.” Power-band with Colosseum (+Assault).

---

## 4. Strategy evening — raise others to S2, don’t nerf S2

S2 E3 ~71% with easy E1–E2 is the **target feel**. Bring S1/S3–S6 up.

| Lever | Helps |
|---|---|
| Doctrine payout + Spoils Liturgy + War Psalm | **S5** |
| Sci offers **4** (was 3), **max 2 troop** | **S6** + everyone (more non-troop / trees) |
| Oracle / Alexandria Wonders + cheaper Sci path | **S6** |
| Siege: free wall-ignore once/settlement for S1 bots / BP weight | **S1** |
| Battle Line drill weight ↑ early | **S3** |
| Blueprint numeric feel via cheaper Forge path already OK | **S4** — Pyramids/Hagia help |
| Guaranteed Wonder funnel | All non-S2 (S2 already owned Wonders) |

### Formations — what’s “best”?

- **S2** wins with **one-class high shapes** (Vanguard/Legion/Triple+Conscription) — not “2 melee + 2 archer.”
- **S3** is the Melee+Ranged Battle Line route — reliable, lower ceiling.
- No need to buff Battle Line to beat Legion; buff **S3’s consistency tools** and **S5/S6 engines** instead.
- Optional later strat **S7 Combined Arms** if we want an explicit 3-class identity.

### Science screen change

When rolling Science: show **4 offers**; troop-like **min 1, max 2** (same as before on max, but one more non-troop slot on average). More room for Education/Banking/Engineering/Prophecy.

---

## Implementation status (this pass) — **wired**

1. ✅ Doctrine payout ×~2 + Spoils Liturgy + War Psalm + Martyr's Guard (`DOCTRINES.md`, `era1_sim.py`)  
2. ✅ Promotion power/cost/weight + new editions + 30% stamp rate + PROMOTIONS table  
3. ✅ Wonder every shop visit + reroll once + 10 new Wonders + cheaper era-scaled costs  
4. ✅ Science **4-offer** (max 2 troop) + S1 free wall-ignore + S3/S5/S6 pick prefs  

**Re-sim done** (`--eras 3 --runs 80 --seed 42`): see `sim/results/CONTRIBUTION_REPORT.md`.  
**8-era follow-up** (`--eras 8 --runs 60 --seed 42`): see `sim/results/CONTRIBUTION_REPORT_E8.md`.

| Lever | Outcome |
|---|---|
| Promos / editions | **Win** — promo E3 Δ −15% (was ~0); still −9% at E4 |
| Doctrine spoils + combat | Partial — Doc −5% mean; S5 −10% |
| Wonder funnel | Own-rate up; effect Δ still −4% |
| Evening to S2 | S5/S6/S1 up a lot; **S2 also +18pp** on shared buffs — need asymmetric next |
| Long horizon | **E4 cliff** — mean clear ~10%; E6–E8 ≈ 0%. Next gate is Medieval HP, not late-game content. |
