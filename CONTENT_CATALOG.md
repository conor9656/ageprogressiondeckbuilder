# Content Catalog — cards, techs, strategies

Provisional ideas + rough numbers for the joker-like layer and early techs.  
Fantasy first; numbers follow the power budget in `SIMULATION.md`. All values **estimate-tier** — coherent, not final.

Rarities: **C** Common · **U** Uncommon · **R** Rare  
Slots: Policies start 2 (max 5). Blueprints start 2 (max 5). Doctrines start 1 (max 4).

---

## 1. Expected strategies (design against these)

| ID | Name | Core loop | Early buys | Mid payoff |
|---|---|---|---|---|
| S1 | **Wallbreakers** | Siege density + wall ignore | Siege units, Battering Ram / Siege Tower, Siegecraft | Towns/Capitals with walls become free damage |
| S2 | **Thin Legion** | Disband junk → 5-of-class | Disband supports, buy one class, Vanguard/Legion techs | Huge single-class formations |
| S3 | **Battle Line engine** | 2+2 reliability + formation levels | Battle Line tech, Agoge / ranged Momentum, Conscription | Steady every-Assault damage |
| S4 | **Builder burst** | Blueprints every fight | Blueprint slots, Forge, Aqueduct, Builder tier techs | Extra Assaults / Might spikes |
| S5 | **Faith snowball** | Doctrines + occupy Temples | Missionary slot, Tithe→Zeal→Missionary Zeal | Economy then Zeal Might into later eras |
| S6 | **Science rush** | Tier ups before era rolls | Scholar cities, Rationalism, Scriptorium | Imperial Guard + tier V classes on time |

A card is “good” if it clearly serves ≥1 strategy and isn’t mandatory for all six.

---

## 2. Unit tier progression (relationship lock)

Whole-class upgrades via Science. Stats already in GDD; this table states the **design intent** of each bump.

| Tier | Name examples (Melee) | Might vs prior | Intent |
|---|---|---|---|
| I | Warrior | baseline | Ancient naked deck |
| II | Swordsman | ~2.0–2.4× Might | First big spike; Town/Capital of era 1–2 feel fair if researched |
| III | Man-at-Arms | ~1.6–1.7× | Keeps pace with era Defence ×~2 |
| IV | Musketman | ~1.5–1.6× | Industrial step |
| V | Infantry | ~1.5–1.6× | Late ceiling |

Same ratios apply across classes (Cavalry stays highest Might; Ranged stays Momentum carrier; Siege stays wall key + low Might).

**Spot-check formula (paper):**  
`Assault ≈ (formation_base_Might + Σ scoring unit Might) × (formation_base_Mom + Σ Mom)`  
then × Policy/Blueprint modifiers.  
Class tier up only changes the unit Might/Mom terms — so a Melee-heavy Battle Line jumps harder from Bronze Working than a Cavalry-light Combined Arms.

---

## 3. Formation levels (tech)

Each +1 level on a formation (provisional):

| Formation | Per level |
|---|---|
| Skirmish–Triple | +3 Might, +0 Momentum |
| Battle Line–Combined Arms | +5 Might, +0 Momentum |
| Phalanx–Grand Army | +5 Might, +1 Momentum |
| Vanguard–Imperial Guard–Legion | +8 Might, +1 Momentum |

Stacking 3–4 levels on your main shape ≈ one solid Policy; shouldn’t alone replace a class tier up.

---

## 4. Policies (Culture — always on)

Expand from GDD examples. Shop/civic reward: pick 1 of 3.

| Policy | Rarity | Effect (provisional) | Serves |
|---|---|---|---|
| Agoge | C | Melee +4 Might | S3 |
| Drill Manual | C | Ranged +1 Momentum | S3 |
| Horse Breeding | C | Cavalry +5 Might | S2 |
| Camp Followers | C | +1 Gold interest step (every 4 Gold instead of 5) | econ |
| Conscription | U | First scoring unit in each formation scores twice | S2 S3 |
| Professional Army | U | +1 Momentum per 4 Ranged cards in deck (⌊n/4⌋) | S3 |
| Chivalry Code | U | Cavalry +1 Momentum each | S2 |
| Siegecraft | U | Siege counts as any class for **shape** (Might still Siege) | S1 |
| Logistics | U | +1 hand size | all |
| Levée en Masse | R | Legion & Vanguard +3 Momentum | S2 |
| Mercantilism | R | Interest cap +1 (or +2) | econ |
| Rationalism | R | +25% Science from all sources | S6 |
| Patronage | R | +25% Culture from all sources | slots |
| Total War | R | +10% Might on Capitals | bosses |
| Militia Act | C | Skirmish and Pair +5 Might | early |
| Combined Doctrine | U | Combined Arms & Grand Army +2 Momentum | S3 |
| Corps of Engineers | U | Blueprints numeric effects +25% | S4 |
| State Religion | U | Doctrines numeric rewards +25% | S5 |

---

## 5. Blueprints (Gold — Builder, once per settlement)

| Blueprint | Rarity | Effect (provisional) | Serves |
|---|---|---|---|
| Battering Ram | C | Siege +10 Might rest of settlement | S1 |
| Scaffolding | C | Next formation ignores walls | S1 |
| Supply Lines | C | Draw 2 | all |
| Watchtower | C | Next formation +10 Might | all |
| Barracks | U | Draw 3 | all |
| Siege Tower | U | Remove walls for rest of settlement | S1 |
| Forge | U | Next formation’s **unit** Might +50% | S4 |
| Roads | U | +1 Regroup this settlement | all |
| Magazine | U | Next formation +2 Momentum | S3 |
| Aqueduct | R | +1 Assault this settlement | S4 |
| Great Works | R | Each Builder in this formation triggers an extra Blueprint | S4 |
| Arsenal | R | All combat units in next formation +25% Might | S4 |
| Field Hospital | C | Discard up to 3, draw that many | all |
| Ballista Yard | U | Siege +1 Momentum rest of settlement | S1 |

Builder tiers multiply numeric Blueprint fields (e.g. Ram +10 → +25 → +50) per GDD.

---

## 6. Doctrines (Faith — Missionary, pay on victory)

| Doctrine | Rarity | Reward (provisional) | Serves |
|---|---|---|---|
| Tithe | C | +15 Gold | S5 |
| Scriptorium | C | +Science = 10% of damage dealt this settlement | S6 |
| Pilgrimage | C | +10 Faith; if Occupy, this city Faith yield ×2 | S5 |
| Alms | C | +8 Culture | slots |
| Zeal | U | All units +15% Might for next **2** settlements | S5 |
| Peaceful Conversion | U | Occupied city yields ×2 (all resources) | S5 |
| Relic Hunt | U | Gain 1 free Great Prophet | S5 |
| Census | U | +Gold equal to cards in deck | econ |
| Missionary Zeal | R | This Doctrine’s Gold/Faith reward +5 permanently each trigger | S5 |
| Holy War | R | Each Missionary in winning formation retriggers fired Doctrines | S5 |
| Indulgence | R | +1 Missionary slot | S5 |
| Crusade Charter | U | Next Capital: +20% Might | bosses |

---

## 7. Great Prophets (Faith — one-use)

| Prophet | Effect (provisional) |
|---|---|
| Sow Dissent | Settlement Defence −25% |
| Conversion | Change garrison type |
| Holy Revolt | Remove walls |
| Blessing | One card permanently ×1.5 Might |
| Revelation | Reroll next route choices |
| Martyrdom | Discard hand; draw 8; +1 Regroup |
| Synod | Gain a random Common Doctrine (or upgrade choice) |
| Jubilee | +20 Gold now |

---

## 8. Ancient techs (Science) — first pass list

Player picks next research; costs provisional (Science points). Era-gated: Ancient list available in era 1+.

| Tech | Cost | Effect | Notes |
|---|---|---|---|
| Bronze Working | 15 | Melee → tier II | Classic first spike |
| Archery | 15 | Ranged → tier II | |
| Horseback Riding | 20 | Cavalry → tier II | |
| Masonry | 15 | Siege → tier II | |
| Military Tactics | 20 | Battle Line +1 level | S3 |
| Construction | 25 | Builder → Engineer (tier II) | Scales Blueprints |
| Writing | 20 | Unlock Uncommon Blueprints in shop | |
| Iron Working | 40 | Melee → tier III *(Classical gate — park if era-strict)* | move to Classical if needed |

Keep Classical+ trees to a later pass; Ancient alone must support strategies through era‑1 Capital.

---

## 9. Ancient civics (Culture) — first pass

| Civic | Cost | Effect |
|---|---|---|
| Code of Laws | 15 | +1 Policy slot |
| Craftsmanship | 15 | Choose 1 of 3 Policies |
| Early Empire | 20 | +1 Builder slot |
| Theology | 20 | +1 Missionary slot |
| Military Training | 15 | +1 Regroup permanently |
| Literacy | 25 | Choose 1 of 3 Policies (better uncommon weight) |

---

## 10. Shop cost stubs (Gold / Faith)

| Item | Cost idea |
|---|---|
| Unit (current tier) | 8 / 12 / 18 / 28 / 40 by tier |
| Blueprint C / U / R | 10 / 22 / 45 Gold |
| Doctrine C / U / R | 8 / 18 / 35 Faith |
| Great Prophet | 12 Faith |
| Disband | 5 Gold (rises +1 each disband in run?) |
| Reroll | 2 Gold, +1 per reroll this visit |
| Wonder | 80–120 Gold, appears rarely |

Village win stub: **+25 Gold, +8 Science, +8 Culture, +5 Faith**, +1 Gold per unused Assault, then interest.

---

## 11. Paper clear check (era 1 Capital)

Defence target: **750** (300 × 2.5).

Example **S3 Battle Line engine** after Village+Town shops (illustrative, not sim):
- Battle Line lvl 1, Agoge, one Forge used, Melee II + Ranged II on a 2+2  
- Might ≈ 30+5 + 12+12 + 4+4 = 67; Mom ≈ 3+1+1 = 5 → **335** before Forge  
- Forge +50% unit Might → rough **~450–500** one Assault; ×4 Assaults with one Aqueduct rare → clear with margin  

Example **naked deck** only: often **below** 750 total — Capital should require *some* upgrades (design intent).

Use checks like these while adding cards; full Monte Carlo later.

---

## 12. Still to fill (next content passes)

- Classical → Information tech/civic names and costs  
- More Policies toward ~25–30 (Balatro-like breadth)  
- Blueprint/Doctrine pools toward ~20 each  
- Wonder rival-boss rules when skipped  
- Leader starting loadouts tied to S1–S6  
- Exact Science/Culture bar sizes per era  

When those feel dense, implement strategy bots and simulate.
