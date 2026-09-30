# Science & Civics level-ups

Random **pick 1 of 3** when the Science or Culture bar fills.  
Replaces a fixed clickable tech/civic tree. Numbers provisional.

---

## 1. Does this make sense? (design lock)

**Yes.** It matches the shop’s luck-with-choice feel:
- Player always has agency (pick 1 of 3).
- Can’t perfectly path “Melee every time.”
- Troop identity stays simple: **Upgrade Melee**, not named era techs.
- Rare ahead-of-era troop bumps create exciting spikes without making Ancient→tier V common.
- Entering a new era **re-opens** same-class upgrades at healthier odds.

---

## 2. Tracked troop tiers

| Track | Start | Max | Offer label |
|---|---|---|---|
| MeleeTier | I | V | Upgrade Melee |
| RangedTier | I | V | Upgrade Ranged |
| CavalryTier | I | V | Upgrade Cavalry |
| SiegeTier | I | V | Upgrade Siege |
| BuilderTier | I | III | Upgrade Builders |

Taking an offer increments that track by 1. Shop units spawn at the current class tier. Imperial Guard requires combat units at the **current era’s soft-cap tier** (or higher).

Missionary tier stays Faith-side (not Science) unless we later add a rare Science bridge.

---

## 3. Era soft-caps (class tiers)

| Era | Soft-cap class tier | Notes |
|---|---|---|
| 1 Ancient | II | First bump is the normal Ancient spike |
| 2 Classical | III | |
| 3 Medieval | III | Extra Science goes to non-troop / catching lagging classes |
| 4 Renaissance | IV | |
| 5 Industrial | IV | |
| 6 Modern | V | |
| 7 Atomic | V | |
| 8 Information | V | |

**At or below soft-cap:** normal offer weight.  
**One tier above soft-cap:** rare weight.  
**Two+ above soft-cap:** do not offer (hard stop).

Builder soft-cap: Era 1 → II, Era 3+ → III (provisional).

---

## 4. Science offer composition (hard rule)

When rolling 3 Science choices:

| Slot rule | Value |
|---|---|
| Troop-like offers (Melee/Ranged/Cavalry/Siege/**Builders**) | **min 1, max 2** of the three |
| Other Science upgrades | the remaining **1–2** |

Procedure (provisional):
1. Roll `T = 1 or 2` with weights e.g. 60% → 1 troop, 40% → 2 troops.
2. Roll `T` distinct troop-like upgrades using §5 weights (skip maxed tracks).
3. Fill remaining slots from **non-troop** pool (§6), current era + rare ahead.
4. If not enough legal cards, relax: allow duplicate *categories* only if necessary (prefer never duplicate the same troop class in one screen).

Player picks **one**; the other two are gone (no hold).

---

## 5. Troop offer weights

Let `gap = softCap - currentTier` for that class.

| Situation | Relative weight |
|---|---|
| `gap ≥ 1` (behind or at room under soft-cap) | **High** (e.g. 10) |
| `gap = 0` and next tier would be softCap+1 (ahead-of-era) | **Low** (e.g. 1) |
| Same class was taken on the **previous** Science level-up | Multiply weight by **0.35** (anti-streak), unless a new era just started |
| **New era just began** (first Science level-up of the era) | Clear anti-streak; if `gap ≥ 1`, weight **High+** (e.g. 14) |
| Tier already V | Weight 0 |

So: first settlement Melee→II is common; a second Melee→III in the same Ancient era is possible but uncommon; Classical makes Melee→III (or II if missed) likely again.

---

## 6. Non-troop Science pool (expand later)

These fill the 1–2 non-troop slots. Era-tagged; rare ahead-of-era allowed at low weight.

| ID | Era | Upgrade | Effect (provisional) |
|---|---|---|---|
| NS01 | 1 | Battle Line Drill | Battle Line +1 level |
| NS02 | 1 | Skirmish Drill | Skirmish & Pair +1 level |
| NS03 | 1 | Combined Arms Primer | Combined Arms +1 level |
| NS04 | 1 | Writing | Uncommon Blueprints can appear in Treasury |
| NS05 | 1 | Surveying | +1 Regroup permanently |
| NS06 | 1 | Fortification Studies | Scaffolding/Siege Tower numeric +25% (Blueprint family) |
| NS07 | 2 | Phalanx Drill | Phalanx +1 level |
| NS08 | 2 | Vanguard Primer | Vanguard +1 level |
| NS09 | 2 | Engineering Corps | Builder slot +1 **or** Builder tier +1 if slot maxed (prefer tier if under soft-cap) — *park; may be too flexible* |
| NS10 | 2 | Natural Philosophy | +10% Science from all sources (small, stacks diminishing) |
| NS11 | 3 | Grand Army Drill | Grand Army +1 level |
| NS12 | 3 | Legion Primer | Legion +1 level |
| NS13 | 3 | Imperial Standards | Imperial Guard +1 level |
| NS14 | 3 | Machinery | Rare Blueprints weight ↑ in Treasury |
| NS15 | 4+ | General Staff Maps | All formations +1 level **or** pick one formation +2 — TBD |

**Need many more** non-troop Science upgrades before sim — flagged in parking lot. Formation-level ups and shop unlocks are the backbone.

Duplicate rule: don’t offer the same NS id twice in one screen; formation drills can reappear across level-ups (levels stack).

---

## 7. Civics level-ups

Culture bar fills → **3 random civics** → pick one.

No troop quota. Weights by era tag + rare ahead-of-era.

### Starter civic pool (expand later)

| ID | Era | Civic | Effect |
|---|---|---|---|
| CV01 | 1 | Code of Laws | +1 Policy slot (if &lt; max) |
| CV02 | 1 | Craftsmanship | Draft 1 of 3 Policies |
| CV03 | 1 | Early Empire | +1 Builder slot |
| CV04 | 1 | Theology | +1 Missionary slot |
| CV05 | 1 | Military Training | +1 Regroup permanently |
| CV06 | 1 | Literacy | Draft 1 of 3 Policies (Uncommon+ weight ↑) |
| CV07 | 2 | Citizenship | +1 Policy slot |
| CV08 | 2 | Patron Games | Draft 1 of 3 Policies |
| CV09 | 2 | Civil Service | +1 hand size |
| CV10 | 2 | State Church | Doctrine numeric +15% or +1 Doctrine slot if under max — TBD |

If a civic is illegal (slots maxed), reroll that offer.

---

## 8. Bar fill costs (stub)

| Science level-up # in run | Cost to fill bar | Civic level-up # | Cost |
|---|---|---|---|
| 1 | 12 | 1 | 12 |
| 2 | 18 | 2 | 18 |
| 3 | 25 | 3 | 25 |
| 4 | 35 | 4 | 35 |
| 5+ | +12 each | 5+ | +12 each |

Tune so Ancient expects ~2–3 Science level-ups before Capital if player Occupies / Doctrine-Sciences lightly.

---

## 9. UI / clarity

- Show current tiers on the Science screen (Melee II · Ranged I · …).
- Ahead-of-era troop offers get a **rare** badge (“Ahead of era”).
- Non-troop cards show era chip.
- After pick, brief banner: `Melee I → II` / `Battle Line level 2`.

---

## 10. Open follow-ups

- Fatten non-troop Science list to ~25–30 across eras.
- Fatten civics to ~20+.
- Exact weights for T=1 vs T=2 troop slots.
- Whether Builders count toward the “troop” min/max (currently **yes**).
- Missionary tier: stay Faith-only vs rare Science offer.
