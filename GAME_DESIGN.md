# Game Design Document — "Ages" (working title)

> Status: concept locked, all numbers **provisional** (to be tuned by simulation later).
> This document describes the game only — not the technical implementation.
> Design risks: §14. Stack: `TECH_STACK.md`. Modes: `CARD_MODES.md`. Pools: `POLICIES.md`, `BLUEPRINTS.md`, `DOCTRINES.md`. Science/Civics offers: `SCIENCE_UPGRADES.md`. Sim: `SIMULATION.md`.

---

## 1. Pitch

A single-player **roguelike deck-builder** in the style of *Balatro*, themed on *Civilization*.

- **The fixed game** is a card game: each round you play formations of unit cards to conquer an enemy settlement. The rules of a round never change across a run.
- **The civilization layer** is how you get stronger: Gold, Science, Culture and Faith upgrade your deck, your units and your rules as you advance through eight historical eras.
- **The feel we want:** early settlements need ~300 damage and are a mild struggle; by the late game the *same formations* deal tens of thousands of damage because of stacked upgrades. Winning requires planning, not luck.

---

## 2. Core Loop

```
Choose next settlement  →  Fight (card round)  →  Win: Raze or Occupy
        ↑                                                   ↓
   Advance era  ←  Research / civics progress  ←  Shop (spend Gold / Faith)
```

A run is lost the first time you fail to conquer a settlement.

---

## 3. Run Structure

- **8 eras:** Ancient, Classical, Medieval, Renaissance, Industrial, Modern, Atomic, Information.
- **3 settlements per era:** Village → Town → Rival Capital (boss).
- **Route choice:** before a Village or Town, the player picks 1 of 2–3 visible settlements (different yields, garrisons, difficulty). The Capital is fixed.
- **Victory:** conquer the Information-era Capital (Domination Victory). Then optionally continue in **Endless Mode** with exponentially rising targets.

### Defence targets (provisional)

Tuned after Ancient-era Monte Carlo (`sim/results/ERA1_REPORT.md`) and balance‑v2 multi-era pass (`sim/results/BALANCE_V2_REPORT.md`).

| Era | 1 Ancient | 2 Classical | 3 Medieval | 4 Renaissance | 5 Industrial | 6 Modern | 7 Atomic | 8 Information |
|---|---|---|---|---|---|---|---|---|
| Base Defence | **500** | **800** | **1,400** | 4,500 | 12,000 | 30,000 | 75,000 | 150,000 |

Village = ×1, Town = ×1.5, Capital = ×2.5 of the era base.

| Era 1 (Ancient) | Village | Town | Capital |
|---|---|---|---|
| Defence | 500 | 750 | 1,250 |

| Era 3 (Medieval) | Village | Town | Capital |
|---|---|---|---|
| Defence | 1,400 | 2,100 | 3,500 |

Prior era‑1 base was 300; prior era‑3 base was 2,000 (Cap 5,000) which outpaced multipliers before balance v2.

---

## 4. The Round (Conquering a Settlement)

### Rules
- Deck is shuffled at the start of each settlement. Draw a hand of **8 cards**.
- You have **4 Assaults** and **3 Regroups** per settlement.
- **Assault:** play 1–5 cards as a formation. It deals damage to the settlement's **Defence**. Draw back up to 8.
- **Regroup:** discard 1–5 cards and draw replacements. No damage.
- If the draw pile empties, reshuffle the discard pile into it.
- Reduce Defence to 0 before Assaults run out → settlement conquered. Otherwise → run over.

### Damage formula

```
Damage = Might × Momentum   (then apply settlement modifiers, e.g. walls)
```

- **Might** = formation's base Might + the Might of each **scoring** unit (+ bonuses).
- **Momentum** = formation's base Momentum + Momentum from scoring units (+ bonuses, multipliers).
- The game automatically selects the **highest-ranking formation** the played cards make. Only the units that form it are **scoring**; other combat units played contribute nothing.
- Modifiers resolve in a fixed order: units → Blueprints → Policies (left to right by slot) → Wonders → settlement modifiers.

**Tech Literacy (balance v2):** all formations gain Momentum ×(1 + 0.04 × Science levels taken this run). Stacks with Policy/Blueprint scalers such as Academy Momentum (Mom ×(1 + 0.1 × sci levels)).

### Formations

Formations only care about the **mix of combat classes** (Melee, Ranged, Cavalry, Siege). Support units (Builder, Missionary) occupy a slot but never count toward a formation.

| Rank | Formation | Shape | Base Might × Momentum |
|---|---|---|---|
| 1 | Skirmish | 1 unit | 5 × 1 |
| 2 | Pair | 2 of the same class | 10 × 2 |
| 3 | Triple | 3 of the same class | 20 × 3 |
| 4 | Battle Line | 2 + 2 of two classes | 30 × 3 |
| 5 | Combined Arms | 3 different classes | 35 × 3 |
| 6 | Phalanx | 3 + 2 of two classes | 45 × 4 |
| 7 | Grand Army | 1 of each of the 4 combat classes | 60 × 4 |
| 8 | Vanguard | 4 of the same class | 60 × 6 |
| 9 | Imperial Guard | 5 combat units, all of the current era's tier | 70 × 6 |
| 10 | Legion | 5 of the same class | 80 × 8 |

Formations have **levels** (raised by techs). Each level adds formation-specific Might and Momentum.

### Walls
Towns and Capitals may have **walls**: formations containing **no Siege unit** deal **×0.5** damage.

### Garrisons (class modifiers)
Each settlement has a garrison that weakens one class:

| Garrison | Effect |
|---|---|
| Pikemen | Cavalry add 0 Might |
| Archers | Melee Might halved |
| Horsemen | Ranged add 0 Momentum |
| Militia | No modifier (Villages mostly) |

---

## 5. Units (the Deck)

### Combat classes

All units simply contribute numbers to formations. There is no positioning and no unit is ever killed or wounded.

| Class | Profile | Upgrade line (tiers I → V) |
|---|---|---|
| Melee | Steady high Might | Warrior → Swordsman → Man-at-Arms → Musketman → Infantry |
| Ranged | Low Might, adds Momentum | Slinger → Archer → Crossbowman → Field Cannon → Machine Gun |
| Cavalry | Highest Might | Horseman → Knight → Cuirassier → Cavalry → Tank |
| Siege | Low Might, required to beat walls | Catapult → Trebuchet → Bombard → Artillery → Rocket Artillery |

Provisional stats per tier (I / II / III / IV / V) — **balance v2** early-weighted buff:

| Class | Might | Momentum |
|---|---|---|
| Melee | 7 / 15 / 24 / 36 / 55 | — |
| Ranged | 3 / 5 / 8 / 12 / 18 | +1 / +2 / +2 / +3 / +3 |
| Cavalry | 11 / 20 / 30 / 44 / 65 | — |
| Siege | 4 / 8 / 12 / 18 / 26 | — |

**Tier upgrades apply to the whole class**, including cards bought later (see Science).

### Support units

| Unit | In a formation | Powered by | Upgrade line |
|---|---|---|---|
| **Builder** | Triggers one equipped **Blueprint** (immediate effect this fight) | Blueprints bought with Gold; tier upgraded by Science | Builder → Engineer → Military Engineer |
| **Missionary** | Triggers one equipped **Doctrine** (reward paid **only if you win** this settlement) | Doctrines bought with Faith; tier upgraded by Faith | Missionary → Apostle → Inquisitor |

- Support units contribute **no Might or Momentum** and take up a formation slot — a deliberate trade-off.
- When played, the player picks one equipped Blueprint/Doctrine that **hasn't fired yet this settlement**. Each fires at most **once per settlement**. If none are available, the card does nothing.
- Blueprints and Doctrines are **permanent**; they sit in slots and can be swapped between fights (like Balatro jokers).
- Upgrading the Builder/Missionary tier **scales the strength** of every Blueprint/Doctrine (e.g. Battering Ram +10 → +25 → +50).

### Starting deck (default)
6 Melee, 5 Ranged, 3 Cavalry, 2 Siege, 2 Builders, 2 Missionaries (20 cards, all tier I).

---

## 6. Resources

| Resource | Earned from | Spent on / effect |
|---|---|---|
| **Gold** | Base **~38** per settlement won, +1 per unused Assault, interest (+1 per 5 held, max +5 / Wonder can raise), razing (~28), occupied Trade Ports | Shop: units, Blueprints, Wonders, rerolls, disbanding cards |
| **Science** | Base **~16** per victory, occupied Scholar cities, Doctrines, Policies | Fills research bar → **Science level-up** (pick 1 of 3 random offers) |
| **Culture** | Base **~16** per victory, occupied Artisan cities, Doctrines, Policies | Fills civics bar → **Civic level-up** (pick 1 of 3 random offers) |
| **Faith** | Base **~12** per victory, occupied Temple cities, Doctrines | Great Prophets, Doctrines, Missionary tier upgrades |

### Science level-ups (random offer of 3)

There is **no fixed tech tree to click through**. When the Science bar fills, the player is shown **3 random upgrades** and picks one. Full offer rules + non-troop pool: `SCIENCE_UPGRADES.md`.

**Troop upgrades (class tiers)** — simple and tracked:
- Offers are named **Upgrade Melee / Ranged / Cavalry / Siege / Builders** (not “Bronze Working”).
- The run stores `MeleeTier`, `RangedTier`, `CavalryTier`, `SiegeTier`, `BuilderTier` (start at **I**).
- Taking “Upgrade Melee” does `MeleeTier += 1` for **all** Melee cards (owned and future shop units).

**Era soft-cap vs rare ahead-of-era:**
- Each era has a **soft-cap** on class tier (e.g. Ancient soft-caps at II). Offers at or below soft-cap are normal weight.
- A class **already at the soft-cap** can still appear as the *next* tier at **low** weight (rare Science spike — e.g. Melee III while still Ancient).
- When the run **enters a new era**, soft-cap rises and **same-class upgrade weight resets upward**, so catching the next Melee bump becomes realistic again.

**Composition of the 3 Science offers (hard rule):**
- **Minimum 1** troop upgrade (Melee/Ranged/Cavalry/Siege — Builders count as troop-like for this quota).
- **Maximum 2** troop upgrades.
- Therefore **1–2** of the three are class/Builder tier bumps; the rest are **other Science upgrades** (formation levels, shop unlocks, rule bumps — pool still expanding).

Falling behind Science still means outdated tiers (and Imperial Guard needs current-era soft-cap tier).

### Civics level-ups (random offer of 3)

Same presentation: bar fills → **3 random civic upgrades** → pick one. No troop mix rule (Culture doesn’t upgrade unit tiers).

Each civic does one of:
- **+1 Policy slot** (start 2, max 5).
- **Gain a Policy** (often itself a nested 1-of-3 Policy draft).
- **+1 Builder or Missionary slot** (start 2 / 1, max 5 / 4).
- Small rule upgrades (e.g. +1 hand size, +1 Regroup).

Era-weighting for civics mirrors Science (current-era pool + rare ahead-of-era). Details expand with the civic pool later.

---

## 7. Modifier Systems

Four systems, distinguished by **timing**:

| System | Timing | Source | Balatro equivalent |
|---|---|---|---|
| **Policies** | Always on | Culture (civics) | Jokers |
| **Blueprints** | *Now* — power in this fight, via Builders | Gold (shop) | Joker-like, card-triggered |
| **Doctrines** | *Later* — rewards if you win, via Missionaries | Faith | Joker-like, delayed payoff |
| **Great Prophets** | One-use, any time during a fight or before it | Faith | Spectral / Tarot cards |

Rarities: Common, Uncommon, Rare.

**Full pools (flat + scaling + OP notes):** `POLICIES.md`, `BLUEPRINTS.md`, `DOCTRINES.md`. Pattern primer: `CARD_MODES.md`.

Include both **flat** cards (same bonus all run / fight) and **scaling** cards (grow with use — always capped; show `Currently: X` in UI).

### Great Prophets (examples — short list; expand later)

| Prophet | Effect |
|---|---|
| Sow Dissent | Settlement −25% Defence |
| Conversion | Change the settlement's garrison type |
| Holy Revolt | Remove walls |
| Blessing | One chosen card permanently gains ×1.5 Might |
| Revelation | Reveal and reroll the next route choice |

---

## 8. Shop

Opens after every conquered settlement. The shop is **not** an open catalogue — stock is random and split into two **packs** so spending always involves luck (Balatro-pack feel), not perfect free will.

### Two packs

| Pack | Currency | Typical stock | Reroll |
|---|---|---|---|
| **Treasury (Gold pack)** | Gold | Units (incl. **Editions**), **Promotions**, Blueprints | 1× per visit, costs Gold |
| **Synod (Faith pack)** | Faith | Doctrines, Great Prophets | 1× per visit, costs Faith |

- Each pack shows a small random row (**5 offers**). Buy what you want from the row; unbought offers vanish when you leave.
- **You cannot buy a named Great Prophet / Blueprint à la carte from a fixed price list.** You buy (or skip) whatever the pack rolled.
- **Disband** sits outside both packs: pay Gold to remove a card from the deck (always available).
- **Reroll:** each pack can be rerolled **once per shop visit** (once per settlement). Gold rerolls Treasury; Faith rerolls Synod. No second reroll that visit.
- **Wonders:** **one guaranteed Wonder offer per era** (random which Wonder), plus a **low chance (~4%)** to appear as a normal Treasury slot. Same Wonder rules as below (one per run; skip → rival builds it).

Provisional pack costs (pay to *refresh into view* is wrong — the visit is free; you pay per item). Optional later: small fee to open a second packed row — not required for v1.

### Units in the Treasury

Buying a unit **adds that card to your deck** at the current researched **class tier** (Science).

On top of base units, Treasury can roll:

1. **Editions** — the unit card already has a baked-in bonus (like Balatro editions).
2. **Promotions** — offers that apply an upgrade to a unit **already in your deck** (not a new card).

Science **class tier ups** (all Melee I → II) remain global. **Promotions / Editions** are the per-card axis.

### Editions (unit variants in shop)

When a unit offer appears, it may be stamped:

| Edition | Rarity weight | Effect (provisional) |
|---|---|---|---|
| **Standard** | Common | No extra — base unit at current tier |
| **Gilded** | Uncommon | This card +2 Might permanently (or +1 Momentum for Ranged) |
| **Scholarly** | Uncommon | If this card **scored** at least once this settlement, +10% Science from this victory |
| **Devout** | Uncommon | If scored at least once, +10% Faith from this victory |
| **Mercantile** | Uncommon | If scored at least once, +5 Gold on victory |
| **Veteran** | Rare | This card scores twice the first time it scores each settlement |
| **Relic** | Rare | This card +1 Momentum and counts as any class for **formation shape** only |

Edition units cost more than Standard (roughly +50% / +100% for U / R stamps).

### Promotions (upgrade a card you already own)

Separate Treasury offers: pick one unit in your deck and apply a promotion. A card may hold a limited number of promotions (provisional: **1**, or **2** if a civic allows).

| Promotion | Rarity | Effect (provisional) |
|---|---|---|
| Master Drill | C | +2 Might on this card |
| Skirmish Doctrine | C | +1 Momentum on this card |
| Thinking Soldier | U | If this card scored this settlement → +10% Science on victory |
| Tithe Sergeant | U | If scored → +8 Gold on victory |
| Zealot's Mark | U | If scored → +8 Faith on victory |
| Banner Carrier | U | While this card is in the scoring formation, formation +5 Might |
| Wallbreaker Bit | U | If this card is Siege and scores, ignore walls this Assault |
| Heroic | R | This card permanently ×1.5 Might |
| Mentor | R | When this card scores, a random other scoring unit gains +1 Might permanently |

End-of-fight bonuses on Editions/Promotions are **on-score economy**, distinct from Doctrines (which need a Missionary play and a Doctrine slot). Doctrines stay the big Faith-engine; Scholarly/Thinking Soldier are thin sticky rewards for using that body.

### Wonders

- **Very rare** in either pack, **very expensive**, and **only one Wonder can be owned per run**.
- **If a Wonder is skipped, a rival builds it — it never appears again this run.** (It may later be used against you by that rival's Capital.)
- Creates the key dilemma: buy the Colosseum now, or hold out for the Great Library?

| Wonder | Effect |
|---|---|
| Great Library | Free tech at the start of each era |
| Colosseum | +1 Assault per settlement |
| Pyramids | +1 Builder slot; Blueprints +50% stronger |
| Hanging Gardens | +1 hand size |
| Stonehenge | Free Great Prophet each era |
| Forbidden Palace | +1 Policy slot |
| Terracotta Army | After each victory, replace one combat unit in your deck with a random combat unit at current class tier; **25%** chance it is an Edition (Gilded/Scholarly/Devout/Mercantile/etc.) |
| Big Ben | Interest cap doubled |
| Grand Bazaar | *(parking)* Unit offers in Treasury cost 50% less — former Terracotta effect |

---

## 9. Settlements

Each settlement has:
- **Defence** (the damage target).
- **Type** — decides what it yields if occupied: **Scholar** (Science), **Artisan** (Culture), **Temple** (Faith), **Trade Port** (Gold).
- **Garrison** (class modifier, see §4).
- **Walls** (Towns and Capitals only, optional).

After conquering, choose:
- **Raze:** large one-time Gold payout.
- **Occupy:** the city joins your empire and yields its resource **after every future settlement**.

### Rival Capitals (bosses)
Each era ends with a Capital that has a boss rule, e.g.:

| Capital | Boss rule |
|---|---|
| The Great Wall | Walls cannot be removed; non-Siege formations deal ×0.25 |
| Horse Lords | Formations without Cavalry deal ×0.5 |
| Holy City | Great Prophets and Missionaries have no effect |
| Republic of Merchants | Each Regroup costs 5 Gold |
| Industrial Powerhouse | Regains 10% Defence after each Assault |
| Imperial Court | Your leftmost Policy is disabled |

---

## 10. Leaders (starting options)

| Leader | Bonus | Drawback / start |
|---|---|---|
| Warlord | Cavalry ×1.5 Might | Extra Cavalry, fewer Missionaries |
| Scholar-King | +50% Science | Weaker starting army |
| High Priest | Faith ×2, starts with 2 Great Prophets | Fewer combat units |
| Merchant Prince | +5 starting Gold, +1 interest cap | — |
| Master Builder | +1 Builder slot, starts with a Blueprint | — |
| Philosopher | +50% Culture, +1 Policy slot | Lower starting Gold |

---

## 11. Difficulty Levels

| Level | Changes |
|---|---|
| Settler | Defence ×0.75, no garrison modifiers in Villages |
| Prince | Standard |
| Emperor | Defence ×1.25, stronger boss rules |
| Deity | Defence ×1.5, all settlements have garrisons, walls more common |

Design target: a thoughtful player should win on Prince regularly; careless play should lose.

---

## 12. Example Scaling

**Ancient Village (Defence 300).** Play Battle Line: Warrior, Warrior, Slinger, Slinger.
Might = 30 + 5 + 5 + 2 + 2 = 44. Momentum = 3 + 1 + 1 = 5. **220 damage.**

**Modern Capital (Defence 75,000).** Same Battle Line shape: Infantry, Infantry, Machine Gun, Machine Gun, with Battle Line at level 6, Agoge, Conscription, Forge, and Zeal active. **~30,000 per Assault.** Same game, vastly stronger civilization.

---

## 13. Glossary

| Term | Meaning |
|---|---|
| Assault | Playing a formation (Balatro: hand) |
| Regroup | Discarding and redrawing (Balatro: discard) |
| Formation | The combination of combat classes played (Balatro: poker hand) |
| Might × Momentum | Damage formula (Balatro: chips × mult) |
| Defence | Settlement's HP / score target (Balatro: blind) |
| Scoring unit | A unit that is part of the selected formation |
| Blueprint | Permanent Builder ability, fires once per settlement |
| Doctrine | Permanent Missionary ability, pays out on victory |
| Great Prophet | One-use Faith consumable |
| Policy | Permanent passive modifier from Culture |
| Wonder | Unique, rare, one-per-run super-modifier |
| Treasury / Synod | Gold pack / Faith pack in the shop |
| Edition | Baked-in bonus on a unit bought from Treasury |
| Promotion | Shop upgrade applied to a unit already in the deck |

---

## 14. Design Risks (to validate before / during simulation)

These are known tension points from the concept review. Do not treat them as bugs — they are the first things the balance sim and early prototypes should stress-test.

### 14.1 Run length (~24 settlements)
A full run is **8 eras × 3 settlements = 24 fights**, roughly 3× a typical Balatro run. If each fight takes too long, the mid-run will drag even when the power curve feels good.
- **Mitigation to try:** keep Assault/Regroup resolution snappy; allow fast-forward / skip animations; consider shorter early eras or optional skip of weak Villages once overpowered.
- **Validate:** time-to-clear for a Prince run; quit rate after era 3–4 in playtests.

### 14.2 Doctrine / Missionary snowball
Missionaries cost a formation slot and Doctrines pay out **only on victory**. When you are behind, you cannot afford to play them; when you are ahead, they print free resources. Faith builds can feel like victory-lap engines rather than catch-up tools.
- **Mitigation to try:** a weak always-on Faith drip; at least one Doctrine (or Prophet) that helps *during* the fight; Missionary tier bonuses that add a small in-fight effect.
- **Validate:** Faith income curves for winning vs struggling runs; win rate of High Priest vs Warlord on Prince.

### 14.3 Science death spiral
Falling behind Science means **outdated unit tiers** and **loss of Imperial Guard** (requires units at the **current era soft-cap** tier). That double penalty may be fine on Deity but frustrating on Prince.
- **Mitigation to try:** soft floor (shop always sells at least soft-cap−1); Imperial Guard uses “highest tier you own”; Scholar cities / Rationalism strong enough to recover one era behind; ahead-of-era rare troop offers as a catch-up lottery.
- **Validate:** win rate when deliberately delaying Science by one era; frequency of Imperial Guard availability on Prince clears.

### 14.4 Deck bloat vs formation consistency
Starting deck is 20 cards with hand size 8. Buying units freely dilutes class density and makes high-rank formations (Vanguard, Legion, Grand Army) unreliable. Disband exists but may be underused if priced wrong.
- **Mitigation to try:** make Disband cheap early; shop sometimes offers “upgrade in place” instead of adding a card; Policies that reward thin decks or specific class counts.
- **Validate:** deck size and formation-hit rate by era for winning runs; Gold spent on Disband vs unit buys.

### 14.5 Formation auto-pick clarity
The game auto-selects the **highest-ranking** formation; non-scoring combat units contribute nothing. Correct for clarity, but easy to misread (“I thought that Cavalry counted”).
- **Mitigation to try:** hard UI teaching — highlight scoring vs dead cards before confirm; preview Might × Momentum live; optional “lock formation rank” toggle later if needed.
- **Validate:** misplay rate in first 3 settlements; whether players understand scoring after the Ancient Capital.

---

## 15. Open Questions / Parking Lot

- Classical → Information **non-troop** Science + civic pool fattening (`SCIENCE_UPGRADES.md`).
- Exact tech/civic **bar costs** and troop offer weights (T=1 vs T=2).
- Final numbers for all stats, costs, rewards and Defence targets — after catalogs + strategy paper checks; Defence from measured damage later, not before content.
- Stub Village reward / Ancient shop costs — provisional stubs now in `CONTENT_CATALOG.md` §9.
- Expand Policies / Blueprints / Doctrines toward fuller pools (catalog §11) — draft 40s exist; trim weak commons.
- Unit **Promotions / Editions** — now in §8; still need full pool size, stack rules (1 vs 2 promotions), and rarity weights.
- Exact pack row size (3?), Wonder appearance rate per pack, reroll costs.
- Formation positioning/ordering as a future depth layer.
- Endless Mode scaling formula.
- Art direction, name, and meta-progression (unlocks between runs).
- See `TECH_STACK.md` for engine, art pipeline, and Steam packaging. See `SIMULATION.md` for sim phases.
