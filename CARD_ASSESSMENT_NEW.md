# New card assessment — Helping Hand, Last Stand, Mercenaries, Three Musketeers, Terracotta Army

Assessed against balance‑v2 (Might × Momentum, Rare ×Mom gated, Doctrine snowballs capped).  
Numbers provisional; rarities locked below.

---

## Summary

| Card | System | Tier | Verdict |
|---|---|---|---|
| **Helping Hand** | Blueprint | **Rare** | Strong, fair for Rare — removes Support slot tax once per settlement |
| **Last Stand** | Policy | **Rare** | Very strong clutch tool; **+15 Mom is hot** — ship Rare, watch for nerf to +8–10 |
| **Mercenaries** | Doctrine | **Rare** | As written (+1 Might **per gold** / Assault) is **broken**; lock a nerfed formula |
| **Three Musketeers** | Policy | **Rare** | Strong Triple build‑around; ×3 Mom belongs at Rare (use ×2 if ever Uncommon) |
| **Terracotta Army** | Wonder | **Wonder** | Healthy Wonder power; replaces old “shop discount” fantasy |

---

## 1. Helping Hand — Blueprint **Rare**

**Effect (locked):** Once per settlement, when you play a Builder, it **does not consume a formation card slot** (you may still include 5 combat units + this Builder). Still fires one Blueprint as usual. Occupies a Blueprint slot.

**Why not Common/Uncommon:** The whole point of Supports is the slot tax. Ignoring it once per fight is a full Rare payoff — same band as Aqueduct / Great Works, different fantasy.

**OP check:** With Forge/Observatory, you get max formation *and* a spike. Once/settlement + slot opportunity cost keeps it in line. If stacked with Great Works later, revisit.

**Serves:** S4 Builder burst primarily; any Blueprint build.

---

## 2. Last Stand — Policy **Rare**

**Effect (locked):** On your **last Assault** of a settlement, if you have **0 Regroups remaining**, that formation gains **+15 Momentum**.

**Why Rare:** +Mom is the dangerous lever. +15 on a Might‑100 line is +1500 damage on that Assault alone, or roughly **×(oldMom+15)/oldMom** (e.g. Mom 5→20 = **×4** clutch). Gates (last Assault + no Regroups) add skill and prevent every-fight spam.

**OP risk:** High. If Prince clears become too consistent on Assault 4, tune to **+8 or +10 Mom** before touching rarity.

**Serves:** All; rewards disciplined Regroup spend.

---

## 3. Mercenaries — Doctrine **Rare** (formula nerfed)

**Player fantasy:** Spend Faith to weaponize your treasury.

**As written (+1 Might per current Gold, each Assault):** With post‑v2 gold (~40–120 mid‑run) this is **+40–120 Might per Assault**. At Mom 6 that is thousands of extra damage per fight — **run‑breaking**, stronger than most Wonders.

**Locked effect (balanced):** When fired this settlement, each Assault gains **+⌊Gold/5⌋ Might** (snapshot Gold when the Doctrine fires), **cap +40 Might**. Pays out as a combat Doctrine for the rest of **this** settlement (Missionary still must play it; victory not required for the buff — buff is in‑fight). *If we must keep pure Doctrine‑on‑victory timing, instead:* on victory gain nothing economic; the combat buff applies to **the next** settlement only at ⌊Gold/5⌋ capped 40.

Sim / GDD use: **in‑fight rest of settlement, ⌊Gold/5⌋, cap 40**, Rare, Faith cost ~35.

**Serves:** Gold‑heavy / Merchant / S4–econ hybrids.

---

## 4. Three Musketeers — Policy **Rare**

**Effect (locked):** When the scored formation is a **Triple** (3 of a class), formation Momentum is multiplied by **×3** (after flat Mom adds, before settlement wall mods).

**Why Rare:** Triple is easy to hit in dense decks. ×3 Mom turns a modest Triple into a primary win condition (S2 Thin Legion loves this). Compare Levée (+3 Mom on Legion/Vanguard, Rare) — ×3 on a common shape is at least that strong.

**If Uncommon:** use **×2 Momentum** instead.

**Serves:** S2; also any mono‑class draft.

---

## 5. Terracotta Army — Wonder (replaces prior shop‑discount effect)

**Old effect:** Units in shop cost 50% less → moved to design parking as possible **Grand Bazaar** Wonder later.

**New effect (locked):** After each victory, choose or auto‑replace **one combat unit** in your deck with a **random combat unit** of a random class at your current class tier. **25%** chance the replacement is an **Edition** (Gilded / Scholarly / Devout / Mercantile / Thinking‑line promotion stamp).

**Why Wonder‑tier:** Permanent every‑victory deck mutation + edition printer. Randomness can brick (replace key Siege), which is the Wonder tax. Not a rarity card — unique, one per run.

**OP check:** Healthy. If editions print too fast, drop to 15% edition chance.

---

## Implementation pointers

| Card | Doc file | Sim hook |
|---|---|---|
| Helping Hand | `BLUEPRINTS.md` | Blueprint `helping_hand` — Builder play ignores slot cap once |
| Last Stand | `POLICIES.md` | Policy check on last Assault + regroups==0 |
| Mercenaries | `DOCTRINES.md` | Doctrine in‑fight Might bonus |
| Three Musketeers | `POLICIES.md` | If form==triple: mom×3 |
| Terracotta Army | `GAME_DESIGN.md` Wonder table | On victory replace 1 combat card |
