# Idea intake — placement & numbers

Spoken ideas assessed for **where** they live, **when** they spike, and **tuned numbers**.  
Duplicates of existing Policies / Blueprints / Science tiers are called out and skipped.

| # | Idea (raw) | Placement | Timing | Tuned effect | Dupes? |
|---|---|---|---|---|---|
| 1 | Every unit type gives +Mom when played | **Skip as new system** | — | Already covered: Science class tiers + Policies (Agoge, Drill Manual, Chivalry, Sappers, Ballista Yard BP). Fill remaining gaps via those pools only. | **Yes** — troop upgrades / class Policies |
| 2 | Mom scales with how often you’ve used that army type | **Wonder: Parade Grounds** | Mid–late (costly) | Track scoring-class plays all run. When scoring, +**0.05 Mom per prior play** of each scoring class in the formation (*combined*, **cap +3.0 Mom** from this Wonder). | No |
| 3 | Lump gold card by era | **Civic U: Treasury Windfall** | Any (stronger later) | One-shot: gain **Gold = 22 + 14×(era−1)** (E1≈22 · E3≈50 · E5≈78). Weight via U rarity; not Science. | Soft overlap War Bonds / Tithe — OK as burst civic |
| 4 | Mime completes best formation | **Blueprint R: Court Mime** | Mid–late | Once/settlement when fired: treat play as if it had a **phantom** combat unit of the class that **maximises damage** (Might/Mom of current soft-cap tier). Phantom is not a real card. | No |
| 5 | Shop power via Science/Civics | **Already shipped** | — | Commerce civics §7.2–7.3 (Stall Permits, Pedlar’s Writ, Royal Boon, discounts…). No new shop line this pass. | Done |
| 6 | Cards *act as* another class for formations | **Wonder: Theater of War** | Mid | On buy: pick **Source → Target** class (e.g. Melee→Ranged). Source units keep their Might/Mom identity but **count as Target for formation shape** while Wonder owned. | No |
| 7 | Slot diamond that accrues gold, cash on sell | **Blueprint U: Investment Bond** | Early–mid | Occupies a Blueprint slot. After each victory while equipped: bank **+5 Gold** (*cap bank 80*). **Disband / cash-out** pays the bank and removes the Blueprint. No combat fire effect. | No |
| 8 | Duplicate a deck card after each win | **Wonder: Scriptoria Spire** | Late (expensive) | After each victory: duplicate **one combat unit** you choose (sim: preferred class). Deck soft-cap **30**. | Soft vs Terracotta — different (copy vs replace) |
| 9 | +Mom for unused Regroups | **Policy U: Steady Advance** | Any | At settlement start, snapshot unused Regroups; all formations this settlement **+1 Mom per unused Regroup** (*cap +3*). Opposite fantasy of Last Stand. | Complements Last Stand |
| 10 | Doctrine → free Great Prophet on win | **Doctrine U: Prophetic Succession** | Mid | On victory (if fired): gain **1 random Great Prophet** (sim: +12 Faith +8 Gold proxy). Distinct from Relic Hunt (immediate). | Soft vs Relic Hunt — OK |
| 11 | Wonder does nothing until discarded → skip fight | **Wonder: Safe Conduct** | Early–mid | While held: no effect. **Once:** discard/sell Wonder → **skip the next settlement** (auto-clear, **half** normal rewards, no shop). Then Wonder gone. | No |
| 12 | Different formations consecutively grow Mom | **Blueprint R: Kaleidoscope Orders** | Mid–late | When fired: enable streak. Each Assault whose formation **≠ previous** this run: permanent **+0.5 Mom** to a run aura (*cap +4*). Same formation as previous → **reset aura to 0**. Persists across settlements until reset. | Soft vs Grand Strategy / Empty Quiver — different trigger |
| 13 | +Mom per special/Edition in deck | **Policy U: Court Fashion** | Mid | Formations **+1 Mom per Edition unit** in deck (*cap +4*). Culture identity for Edition shop path. | Soft vs Liturgical Fire — counts Editions not Doctrines |

## Summary map

| System | New this pass |
|---|---|
| **Wonder** | Parade Grounds · Theater of War · Scriptoria Spire · Safe Conduct |
| **Blueprint** | Court Mime (R) · Investment Bond (U) · Kaleidoscope Orders (R) |
| **Policy** | Steady Advance (U) · Court Fashion (U) |
| **Doctrine** | Prophetic Succession (U) |
| **Civic** | Treasury Windfall (U) |
| **Skipped** | Per-class +Mom (duplicate) · extra shop tree (already live) |

## Full-sim readiness

With these wired into `era1_sim.py` + existing Science/Civics/Commerce/Works lines, the content pool is dense enough for a **first multi-era full simulation** (strategies S1–S6, eras 1–3 or 1–8). Watch: Scriptoria Spire deck bloat, Kaleidoscope + Academy Mom stacking, Safe Conduct reward skip feel.
