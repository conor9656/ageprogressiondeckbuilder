# Ages — Game Snapshot (source of truth)

> **Frozen snapshot:** 2026-10-22  
> **Working title:** Ages (Civ × Balatro roguelike deck-builder)  
> **Purpose:** One document to point at during the build. When design docs disagree, **this file wins** until it is deliberately revised. Detail pools still live in linked catalogs; this captures the *current intended game*.

| Companion | Role |
|---|---|
| `BUILD_PROGRESS.md` | **Living build tracker** — workstream status from W0 onward |
| `TECH_STACK.md` | Engine / art / Steam / agent tooling |
| `GAME_DESIGN.md` | Living design notes (may lag this snapshot) |
| `SCIENCE_UPGRADES.md`, `POLICIES.md`, `BLUEPRINTS.md`, `DOCTRINES.md` | Offer pools & card lists |
| `CONTENT_CATALOG.md` | Draft IDs / paper checks |
| `sim/era1_sim.py` | Executable rules twin (Python) |
| `sim/results/ERAS_6_8_EASE.md` | Latest full-curve balance evidence |

---

## 0. Status of the project

| Layer | Status |
|---|---|
| Concept / pillars | **Locked** |
| Core combat rules | **Locked enough to build** |
| Content pools (Policies / BP / Docs) | Drafted; numbers provisional |
| Balance (Defence, rewards, growth) | **Sim-backed through era 8** — good enough to start the game; fine-tune later |
| Game client (Godot) | **Not started** |
| Art / audio / Steam | Not started |

**Verdict:** Design + Monte Carlo have done their job for a first vertical slice. Smaller balance tweaks can wait until something is playable. **Next major work is game code**, after this snapshot.

---

## 1. Pitch & pillars

A single-player **roguelike deck-builder**: each settlement is a Balatro-like card fight; between fights a Civilization layer (Gold, Science, Culture, Faith) upgrades your deck, units, and rules across **eight historical eras**.

1. **Fixed round rules** — play formations of combat cards to chip settlement Defence. The round rules do not change mid-run.
2. **Civilization progression** — resources fund shops, Science/Civics level-ups, occupy yields.
3. **Four modifier timings** — Policies (always), Blueprints (now, via Builder), Doctrines (on win, via Missionary), Prophets (one-use).
4. **Growth fantasy** — early fights need hundreds of damage; late fights the *same shapes* deal tens of thousands via tiers, formation levels, jokers, and Science scalers.

---

## 2. Run structure

- **8 eras:** Ancient → Classical → Medieval → Renaissance → Industrial → Modern → Atomic → Information.
- **3 settlements / era:** Village → Town → Rival Capital (boss) → **24 fights** to Domination Victory.
- **Route choice:** before Village/Town, pick 1 of 2–3 visible (yields, garrison, difficulty). Capital is fixed.
- **Win:** clear the Information Capital. Optional Endless Mode afterward (exponential targets — formula TBD).
- **Lose:** first failed conquest ends the run.
- **Post-win:** **Raze** (~28 Gold) or **Occupy** (sticky city yield every future settlement: Scholar / Artisan / Temple / Trade).

**Difficulty modifiers (design):** Settler ×0.75 Def · Prince standard · Emperor ×1.25 · Deity ×1.5 + denser walls/garrisons.

**Leaders (start options, design):** Warlord, Scholar-King, High Priest, Merchant Prince, Master Builder, Philosopher — each with a bonus/drawback. Not required for vertical slice.

---

## 3. The combat round

| Rule | Value |
|---|---|
| Hand size | **8** |
| Assaults / settlement | **4** base (+1 from Industrial era onward in sim) |
| Regroups / settlement | **3** base |
| Assault | Play **1–5** combat cards as a formation → deal damage → draw to hand size |
| Regroup | Discard 1–5, redraw; no damage |
| Empty draw pile | Reshuffle discard |
| Clear | Defence ≤ 0 before Assaults run out |

### Damage

```
Damage = Might × Momentum
         → then walls / garrison / boss mods
```

- Auto-select the **highest-ranking formation** the played combat cards make.
- Only **scoring** units in that formation contribute Might/Momentum; extras are dead weight.
- Resolve order: units → Blueprints → Policies (slot order) → Wonders → settlement.

**Always-on Science scalers (live in sim):**

| Name | Effect |
|---|---|
| **Tech Literacy** | Momentum ×(1 + **0.05** × Science levels taken) |
| **Age Power** (era ≥ 4) | Might ×(1 + **0.015** × Science levels) |

### Formations

Formations care only about **combat class mix** (Melee / Ranged / Cavalry / Siege). Supports never count toward shape.

| Rank | Formation | Shape | Base Might × Momentum |
|---|---|---|---|
| 1 | Skirmish | 1 | 5 × 1 |
| 2 | Pair | 2 same | 10 × 2 |
| 3 | Triple | 3 same | 20 × 3 |
| 4 | Battle Line | 2 + 2 | 30 × 3 |
| 5 | Combined Arms | 3 different classes | 35 × 3 |
| 6 | Phalanx | 3 + 2 | 45 × 4 |
| 7 | Grand Army | 1 of each combat class | 60 × 4 |
| 8 | Vanguard | 4 same | 60 × 6 |
| 9 | Imperial Guard | 5 at current soft-cap tier | 70 × 6 |
| 10 | Legion | 5 same | 80 × 8 |

Formation **levels** (Science drills) add shape-specific Might / Momentum (low shapes +3M; mid +5M; high +5M+1Mom or +8M+1Mom).

### Walls & garrisons

- **Walls** (Town/Capital chance): formation with **no Siege** → damage **×0.5**.
- **Garrisons:** Pikemen (Cavalry Might 0) · Archers (Melee Might ×0.5) · Horsemen (Ranged Momentum 0) · Militia (none).

---

## 4. The deck

### Combat classes

| Class | Role | Example line | Might I→VI (sim) | Mom |
|---|---|---|---|---|
| Melee | Steady Might | Warrior → Infantry | 7 / 15 / 24 / 36 / 55 / **85** | — |
| Ranged | Momentum | Slinger → Machine Gun | 3 / 5 / 8 / 12 / 18 / **28** | +1 / 2 / 2 / 3 / 3 / **+4** |
| Cavalry | Peak Might | Horseman → Tank | 11 / 20 / 30 / 44 / 65 / **100** | (VI: +1) |
| Siege | Walls | Catapult → Rocket | 4 / 8 / 12 / 18 / 26 / **40** | — |

- Science **Upgrade Melee/Ranged/Cavalry/Siege** raises the whole class tier (owned + future shop buys).
- Soft-caps by era: E1 **II**, E2 **III**, E3 **IV**, E4–5 **V**, E6–8 **VI**. Hard max combat **VI**, Builder **IV**.

### Starting deck

**6 Melee · 5 Ranged · 3 Cavalry · 2 Siege** (16 combat cards, all tier I)  
**+ battlefield Builder & Missionary** at **1 charge** each (not in the draw deck).

### Battlefield supports (Builders / Missionaries)

Not hand RNG — always available as **charges** (`BALANCE_SUPPORT_CHARGES.md`).

| | Builder | Missionary |
|---|---|---|
| Effect | Fire one equipped **Blueprint** (this fight) | Fire one equipped **Doctrine** (pays **on win**) |
| Formation slot | Costs a slot until free-slot ability | Same |
| Start | 1 charge / settlement | 1 charge / settlement |
| Cap | 4 | 4 |
| Unlock next charge | `sci_level ≥ 2 × current_charges` | Same |
| Science path | ~40% chance offer when unlocked | Same |
| Gold path | Instant **50 / 80 / 120** for charges 2 / 3 / 4 | Same |
| Tier scale | Science Builder tier scales Blueprint numbers | Faith Missionary tier scales Doctrine numbers |
| Fire limit | Each Blueprint / Doctrine **once per settlement** | Same |

Free-slot sources include Helping Hand, Corvée Exemption / Lay Preachers, Machu Picchu.

### Strategy archetypes (sim bots)

| ID | Fantasy |
|---|---|
| S1 | Wallbreakers / Siege |
| S2 | Thin Legion (Melee density) |
| S3 | Battle Line / mid shapes |
| S4 | Builder / Blueprint burst |
| S5 | Faith / Doctrine snowball |
| S6 | Science rush |

---

## 5. Modifier systems

| System | Timing | Currency | Slots (start → max) |
|---|---|---|---|
| **Policies** | Always on | Culture (civics) | 2 → 5 |
| **Blueprints** | Fight-now via Builder | Gold (Treasury) | 2 → 5 |
| **Doctrines** | Win-pay via Missionary | Faith (Synod) | 1 → 4 |
| **Great Prophets** | One-use | Faith | — |
| **Wonders** | Unique run rule | Gold; **1 / run** | — |

Rarities: Common / Uncommon / Rare. Full lists: `POLICIES.md` (~48), `BLUEPRINTS.md` (~44), `DOCTRINES.md` (~45).

### Illustrative examples (not exhaustive)

**Blueprints:** Scaffolding / Siege Tower (walls) · Forge (+50% next unit Might) · Magazine (+2 Mom) · Aqueduct (+1 Assault) · Helping Hand (free Builder slot once) · Court Mime · Investment Bond.

**Doctrines:** Tithe · Spoils Liturgy (victory rewards ×1.5) · Zeal · Missionary Zeal · War Psalm (+1 Mom this fight) · Martyr's Guard (clutch clear) · Scriptorium (damage→Science) · Holy War.

**Policies:** Agoge · Conscription · Research Corps · Academy Momentum · Martial Law · Last Stand · Three Musketeers · Grand Strategy.

**Prophets:** Sow Dissent (−25% Def) · Blessing · Conversion · Holy Revolt · Revelation…

**Wonders (highlights):** Colosseum (+1 Assault) · Pyramids (+Blueprint slot & strength) · Machu Picchu (supports free slots) · Hagia Sophia · Oracle · Alexandria · Parade Grounds · Theater of War · Christ the Redeemer · Terracotta Army · Safe Conduct…

Shop: dedicated Wonder offer each visit while unequipped + low pack spill chance; one cheap Wonder reroll.

---

## 6. Resources, shops, level-ups

### Rewards (per victory, base)

| Resource | Base | Notes |
|---|---|---|
| Gold | **~38** | +1 / unused Assault; interest (+1 per 5 held, cap +5); raze ~28 |
| Science | **~16** | + occupy Scholar, Docs, Policies |
| Culture | **~16** | + occupy Artisan… |
| Faith | **~12** | Synod currency |

**Era income multipliers (sim):** Sci/Cul `1.00 / 1.15 / 1.30 / 1.55 / 1.95 / 2.50 / 3.20 / 4.00`. Gold/Faith milder (`1.00 → 2.60` by E8).

### Science level-ups (**1 of 4** offers — live rule)

- Hard: **min 1, max 2** troop-like offers (Upgrade M/R/C/S/B).
- Rest: formation drills, progression trees (Education / Banking / Devotion / Arts / Engineering / Prophecy — current-era node only), support-charge upgrades, misc rule bumps.
- Soft-cap weighting + rare ahead-of-era; same-class streak dampened.
- Midgame (era ≥ 4): Sci/Civ bar costs **−15%**.
- Era ≥ 4 start: **Breakthrough** — free Sci + free Civ pick (no free tier).

*(Older GDD text saying “1 of 3” is obsolete.)*

### Civics level-ups (1 of 3)

Slots, Policy drafts, hand/Regroup bumps, Commerce (pack size, free rerolls, discounts), Works/Ministry support ladders. No troop quota.

### Shop packs

| Pack | Size | Mix (approx) |
|---|---|---|
| **Treasury** (Gold) | 5 (+ pack bonuses) | Units ~36% · Blueprints ~28% · Promotions ~28% · Wonder spill ~4% + dedicated Wonder row |
| **Synod** (Faith) | 5 | Doctrines ~55% · Prophets ~40% · Wonder spill |

Reroll once per visit (small Gold/Faith). Disband available (rising Gold cost).

### Editions & Promotions (per-card axis)

- Edition stamp chance ~**30%** (Gilded, Scholarly, Devout, Mercantile, Berserker, Hawk-Eyed, Plated, Savant, Zealot…).
- Promotions ~**28%** of Treasury band; roughly one promo/card. Master Drill, Shock, Banner Carrier, Heroic (×1.75 Might), Relentless, etc.
- On-score economy from Editions/Promos is separate from Doctrine win-pay.

---

## 7. Era growth systems (live in sim)

These are part of the intended game, not temporary debug knobs:

1. Soft-caps + tier **VI** headroom  
2. Era-scaled Sci/Cul (and milder Gold/Faith) income  
3. Midgame Sci/Civ bar discount (−15% from era 4)  
4. Renaissance+ **Breakthrough** (free Sci + Civ)  
5. Tech Literacy + Age Power  
6. **Industrial evening:** +1 Assault; Line Mom on Battle Line / Combined Arms / Phalanx; one **Industrial Toolkit** pick (strat-biased)  
7. Battlefield support charges + Sci/Gold charge upgrades  
8. Defence table below  

---

## 8. Defence table & balance evidence

Village = ×1 · Town = ×1.5 · Capital = ×2.5 of era base.

| Era | Name | Base Defence | Capital HP |
|---|---|---|---|
| 1 | Ancient | **665** | 1,662 |
| 2 | Classical | **1,200** | 3,000 |
| 3 | Medieval | **1,790** | 4,475 |
| 4 | Renaissance | **3,450** | 8,625 |
| 5 | Industrial | **7,180** | 17,950 |
| 6 | Modern | **18,300** | 45,750 |
| 7 | Atomic | **49,000** | 122,500 |
| 8 | Information | **98,000** | 245,000 |

### Design mean clear targets (S1–S5), eras 1–5

**95% / 88% / 78% / 68% / 61%**

### Achieved (N=40, seed 42, S1–S5) — `ERAS_6_8_EASE.md`

| Strat | E1 | E2 | E3 | E4 | E5 | E6 | E7 | E8 |
|---|---|---|---|---|---|---|---|---|
| S1 | 100 | 92 | 88 | 82 | 82 | 62 | 40 | 28 |
| S2 | 95 | 95 | 92 | 90 | 85 | 72 | 60 | **55** |
| S3 | 92 | 85 | 80 | 78 | 68 | 50 | 35 | 25 |
| S4 | 92 | 78 | 50 | 32 | 18 | 10 | 2 | **0** |
| S5 | 95 | 95 | 78 | 62 | 52 | 32 | 15 | 12 |
| **Mean** | **95** | **89** | **78** | **69** | **61** | **46** | **30** | **24** |

E1–E5 means match targets within ~1pp. Late game is playable (was ~0% on the old 28k/75k/150k table).

---

## 9. Known risks (park for post-slice)

| Risk | Notes |
|---|---|
| **S4 underpowered** | E8 0% in latest sim — Builder fantasy needs love later |
| **S5 soft late** | E8 12% — Doctrine combat still trails Legion |
| **S2 dominant** | E8 55% — acceptable for now; watch when evening |
| Run length | ~24 settlements — pacing/UI must stay snappy |
| Doctrine when behind | Spoils fantasy needs fight tools (partly addressed) |
| Deck bloat | High-rank formations hate dilution |
| Auto-formation clarity | Players must understand scoring vs dead cards |
| Doc drift | Older markdown still says Science “1 of 3”, starting deck “20 cards”, obsolete Cap HP — **ignore in favor of this snapshot** |

---

## 10. Tech stack (summary)

Full detail: `TECH_STACK.md`.

| Layer | Choice |
|---|---|
| Engine | **Godot 4** + GDScript |
| Rules | Pure modules (no scene tree) — headless-testable |
| Content | JSON / Godot resources in git |
| Art | Gen → Aseprite/Krita cleanup → Spine *or* spritesheet MVP |
| Ship | Windows Steam via GodotSteam; no game servers |
| Balance | Prefer **one** rules implementation long-term (Godot headless). Python twin (`sim/`) is the current research harness |

Architecture:

```
Presentation (scenes, anim, UI)
        ↑
Controllers (input, shop flow, route)
        ↑
Rules / sim  ← pure, deterministic, seedable
        ↑
Content data (units, formations, packs, wonders…)
```

---

## 11. What to build first (recommended order)

Aligned with `TECH_STACK.md` §9, updated for where we are now:

| # | Workstream | Why first | Done when |
|---|---|---|---|
| **0** | **This snapshot** | One source of truth for agents & humans | ✅ You are here |
| **1** | **Godot project + rules module** | Port combat math from `sim/era1_sim.py`: formations, Might×Mom, walls, garrisons, support charges | Headless unit tests match Python on golden seeds |
| **2** | **Vertical slice UI** | One settlement: draw → Assault/Regroup → damage numbers → win/lose | Playable greybox fight without shop |
| **3** | **Run loop + shop (era 1)** | Rewards, occupy/raze, Treasury/Synod packs, Science/Civics 1-of-N | Full Ancient era playable greybox |
| **4** | **Content data import** | JSON/resources for units, formations, BP/Doc/Policy stubs | Swap numbers without code changes |
| **5** | **Retire or dual-run Python sim** | Avoid rules drift — either call Godot headless from CI or keep Python as oracle with parity tests | One canonical rules path |
| **6** | **Art pipeline spike** | One unit class: silhouette → animate → in-engine | Style locked enough to expand |
| **7** | **Multi-era + meta** | Eras 2–8 systems already designed; wire Breakthrough, Toolkit, Wonders | Full Domination run greybox |
| **8** | **Steam smoke** | Export + placeholder achievements / Cloud | Store-page-ready binary later |

### Explicitly **not** first

- Full art pass / Spine license decision  
- Endless Mode formula  
- Deity tuning / leader kit polish  
- S4/S5 evening passes (do after the loop feels good in human hands)  
- Backend, accounts, networking  

### Suggested first milestone (vertical slice)

> **“Conquer an Ancient Capital with greybox cards.”**  
> Includes: starting deck, battlefield supports (1 charge), walls/garrisons, one Blueprint + one Doctrine equipped, Assault/Regroup UX, damage readout. Shop can be stubbed or minimal.

---

## 12. How to use this document

1. **Building features** — implement against §§3–7; link PRs to section numbers.  
2. **Changing design** — edit this snapshot in the same PR as the code/sim change; leave a one-line note in `progress.md`.  
3. **Catalogs** — still the place for long card lists; if a catalog contradicts §1–8 here, fix the catalog.  
4. **Balance** — new Monte Carlos update §8 tables; do not silently change Defence in code only.

---

## 13. Snapshot checklist (what “Ages” is today)

- [x] 8-era Domination run, 3 settlements/era  
- [x] Might × Momentum formations (10 ranks)  
- [x] Four combat classes + battlefield Builder/Missionary charges  
- [x] Policies / Blueprints / Doctrines / Prophets / Wonders  
- [x] Gold / Science / Culture / Faith economy  
- [x] Science 4-offers + Civics 3-offers + shop packs  
- [x] Editions / Promotions  
- [x] E4+ growth (Literacy, Age Power, Breakthrough, income, bar discount)  
- [x] E5 Industrial evening (Assault, Line Mom, Toolkit)  
- [x] Defence curve sim-backed through Information  
- [ ] Godot client  
- [ ] Ship art / audio / Steam  

**Ready to start game development.**
