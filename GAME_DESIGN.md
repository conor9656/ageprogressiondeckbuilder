# Game Design Document — "Ages" (working title)

> Status: concept locked, all numbers **provisional** (to be tuned by simulation later).
> This document describes the game only — not the technical implementation.
> Design risks to validate in sim: §14. Engine / art / Steam stack: see `TECH_STACK.md`.

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

| Era | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Base Defence | 300 | 800 | 2,000 | 5,000 | 12,000 | 30,000 | 75,000 | 150,000 |

Village = ×1, Town = ×1.5, Capital = ×2.5 of the era base.

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

Provisional stats per tier (I / II / III / IV / V):

| Class | Might | Momentum |
|---|---|---|
| Melee | 5 / 12 / 20 / 32 / 50 | — |
| Ranged | 2 / 4 / 7 / 11 / 16 | +1 / +1 / +2 / +2 / +3 |
| Cavalry | 8 / 16 / 26 / 40 / 60 | — |
| Siege | 3 / 6 / 10 / 16 / 24 | — |

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
| **Gold** | Base reward per settlement won, +1 per unused Assault, interest (+1 per 5 held, max +5), razing, occupied Trade Ports | Shop: units, Blueprints, Wonders, rerolls, disbanding cards |
| **Science** | Small base per victory, occupied Scholar cities, Doctrines, Policies | Fills research bar → **techs** (auto-applied, player chooses which tech to research next) |
| **Culture** | Small base per victory, occupied Artisan cities, Doctrines, Policies | Fills civics bar → **civics** (player chooses which civic next) |
| **Faith** | Small base per victory, occupied Temple cities, Doctrines | Great Prophets, Doctrines, Missionary tier upgrades |

### Techs (Science)
Each tech does one of:
- **Upgrade a class tier** (e.g. *Bronze Working*: all Melee I → II).
- **Level up a formation** (e.g. *Military Tactics*: Battle Line +1 level).
- **Upgrade the Builder tier.**
- **Unlock new cards in the shop.**

Techs available = those of the current era and earlier. Falling behind in Science means outdated units (and losing access to Imperial Guard).

### Civics (Culture)
Each civic does one of:
- **+1 Policy slot** (start 2, max 5).
- **Choose 1 of 3 Policies** to gain.
- **+1 Builder or Missionary slot** (each starts at 2 / 1, max 5 / 4).
- Small rule upgrades (e.g. +1 hand size, +1 Regroup).

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

### Blueprints (examples)

| Blueprint | Rarity | Effect |
|---|---|---|
| Battering Ram | Common | Siege units +10 Might for the rest of this settlement |
| Scaffolding | Common | Next formation ignores walls |
| Supply Lines | Common | Draw 2 cards |
| Barracks | Uncommon | Draw 3 cards |
| Siege Tower | Uncommon | Walls removed for the rest of this settlement |
| Forge | Uncommon | Next formation's units +50% Might |
| Roads | Uncommon | +1 Regroup this settlement |
| Aqueduct | Rare | +1 Assault this settlement |
| Great Works | Rare | Every Builder in this formation triggers an extra Blueprint |

### Doctrines (examples) — pay out only on victory

| Doctrine | Rarity | Reward |
|---|---|---|
| Tithe | Common | +15 Gold |
| Scriptorium | Common | +Science equal to 10% of total damage dealt |
| Pilgrimage | Common | +Faith; if occupied, this city yields double Faith |
| Zeal | Uncommon | All units +15% Might for the next 2 settlements |
| Peaceful Conversion | Uncommon | Occupied city yields double |
| Relic Hunt | Uncommon | Gain a free Great Prophet |
| Missionary Zeal | Rare | Reward grows permanently each time it triggers |
| Holy War | Rare | Every Missionary in the winning formation retriggers all fired Doctrines |

### Great Prophets (examples)

| Prophet | Effect |
|---|---|
| Sow Dissent | Settlement −25% Defence |
| Conversion | Change the settlement's garrison type |
| Holy Revolt | Remove walls |
| Blessing | One chosen card permanently gains ×1.5 Might |
| Revelation | Reveal and reroll the next route choice |

### Policies (examples)

| Policy | Effect |
|---|---|
| Agoge | Melee +4 Might |
| Conscription | First scoring unit in each formation scores twice |
| Professional Army | +1 Momentum per Ranged card in your deck (÷4, rounded down) |
| Chivalry Code | Cavalry +1 Momentum each |
| Siegecraft | Siege units count as any class for formation shapes |
| Levée en Masse | Legion and Vanguard +3 Momentum |
| Mercantilism | +1 interest cap |
| Rationalism | +25% Science from all sources |

---

## 8. Shop

Opens after every conquered settlement. Stock is **random** and restocks each visit.

- **Units** of any class, at the currently researched tier.
- **Blueprints** (Gold) and **Doctrines** (Faith).
- **Great Prophets** (Faith).
- **Disband:** pay Gold to remove a card from the deck.
- **Reroll:** pay Gold (cost rises each reroll per visit).
- **Wonders:** see below.

### Wonders
- **Very rare** in the shop, **very expensive**, and **only one Wonder can be owned per run**.
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
| Terracotta Army | Units in the shop cost 50% less |
| Big Ben | Interest cap doubled |

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
Falling behind Science means **outdated unit tiers** and **loss of Imperial Guard** (requires current-era tier). That double penalty may be fine on Deity but frustrating on Prince.
- **Mitigation to try:** soft floor (shop always sells at least era−1 tiers); Imperial Guard uses “highest tier you own”; Scholar cities / Rationalism strong enough to recover one era behind.
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

- Exact tech and civic trees (names, costs, era gating) — **not required** before Round‑1 combat sim; see `SIMULATION.md` Phase A vs C.
- Final numbers for all stats, costs, rewards and Defence targets (simulation-tuned) — **after** §14 risks have provisional mitigations. Defence should be derived from measured damage percentiles, not guessed first.
- Stub Village reward / Ancient shop costs before Phase B (post-Village → Town) sims.
- Formation positioning/ordering as a future depth layer.
- Unit promotions (individual cards gaining permanent bonuses) — possible future feature.
- Endless Mode scaling formula.
- Art direction, name, and meta-progression (unlocks between runs).
- See `TECH_STACK.md` for engine, art pipeline, and Steam packaging. See `SIMULATION.md` for sim phases.
