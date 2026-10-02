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

## 6. Non-troop Science pool

Fills the 1–2 non-troop slots. Two families:

| Family | Era gating | Notes |
|---|---|---|
| **Formation drills / unlocks** | Current era **and earlier** (can re-roll drills; levels stack) | Military backbone |
| **Progression trees** (Education, Banking, Devotion, Arts, Engineering, Prophecy) | **Current-era node only** — once you leave an era, that era’s node never appears again | Miss it → miss that stack forever |

Rare ahead-of-era: **not** used for progression-tree nodes (keeps the miss-penalty honest). Formation drills may still rare-roll one era ahead at low weight.

### 6.1 Progression stacking rule

Each tree node adds its **own** % (or effect) when taken. Bonuses **stack additively** with other owned nodes of the same tree.

Example — Education:
- Take **Scribal Schools** in Era 1 (+10% Sci) then **Lyceum** in Era 2 (+12% Sci) → **+22% Science** from all sources.
- Skip Schools, take only Lyceum in Era 2 → **+12% only** (no retroactive 10%).

UI should show `Education +22%` on the run sheet.

### 6.2 Currency trees (one node per era)

Increments tuned so a **perfect** 8-node stack is strong but not automatic win (~+90–110% on that resource). Missing early nodes is a real cost.

#### Education — Science % from all sources

| Era | ID | Name | Effect |
|---|---|---|---|
| 1 | EDU1 | Scribal Schools | +10% Science |
| 2 | EDU2 | Lyceum | +12% Science |
| 3 | EDU3 | Cathedral Schools | +12% Science |
| 4 | EDU4 | Colleges | +14% Science |
| 5 | EDU5 | National Academies | +14% Science |
| 6 | EDU6 | Polytechnics | +16% Science |
| 7 | EDU7 | Research Institutes | +16% Science |
| 8 | EDU8 | Global University Network | +18% Science |

Max if all taken: **+112% Science**. Replaces old one-off “Natural Philosophy +10%”.

#### Banking — Gold % from all sources (rewards, interest, city yields, Doctrines that grant Gold)

| Era | ID | Name | Effect |
|---|---|---|---|
| 1 | BANK1 | Open Markets | +8% Gold |
| 2 | BANK2 | Coinage | +10% Gold |
| 3 | BANK3 | Merchant Guilds | +10% Gold |
| 4 | BANK4 | Counting Houses | +12% Gold |
| 5 | BANK5 | Joint-Stock Companies | +12% Gold |
| 6 | BANK6 | Central Banks | +14% Gold |
| 7 | BANK7 | Credit Networks | +14% Gold |
| 8 | BANK8 | Global Markets | +16% Gold |

Max: **+96% Gold**. Slightly leaner than Education (Gold converts directly to shop power).

#### Devotion — Faith % from all sources

| Era | ID | Name | Effect |
|---|---|---|---|
| 1 | DEV1 | Wayside Shrines | +8% Faith |
| 2 | DEV2 | City Temples | +10% Faith |
| 3 | DEV3 | Monasteries | +10% Faith |
| 4 | DEV4 | Great Cathedrals | +12% Faith |
| 5 | DEV5 | Mission Societies | +12% Faith |
| 6 | DEV6 | Great Awakenings | +14% Faith |
| 7 | DEV7 | Ecumenical Councils | +14% Faith |
| 8 | DEV8 | World Faith Network | +16% Faith |

Max: **+96% Faith**.

#### Arts — Culture % from all sources

| Era | ID | Name | Effect |
|---|---|---|---|
| 1 | ART1 | Festival Grounds | +8% Culture |
| 2 | ART2 | Amphitheaters | +10% Culture |
| 3 | ART3 | Patron Guilds | +10% Culture |
| 4 | ART4 | Printing Houses | +12% Culture |
| 5 | ART5 | Opera & Museums | +12% Culture |
| 6 | ART6 | Broadcast Culture | +14% Culture |
| 7 | ART7 | Culture Ministries | +14% Culture |
| 8 | ART8 | Planetary Archive | +16% Culture |

Max: **+96% Culture**.

### 6.3 Engineering Line (Builder progression)

Eight era nodes; **only three** grant +1 Builder slot (Eras **2, 5, 8**). Others are Builder-facing abilities that grow with the ages.

| Era | ID | Name | Effect |
|---|---|---|---|
| 1 | ENG1 | Mason's Apprenticeship | First Builder played each settlement: **draw 1** |
| 2 | ENG2 | Clerk of Works | **+1 Builder (Blueprint) slot** |
| 3 | ENG3 | Siege Engineering | Wall-related Blueprints (Scaffolding, Siege Tower, Battering Ram, etc.) numeric **+50%** |
| 4 | ENG4 | Master Builder's Retinue | Opening hand always includes a **floating Builder** that **does not count** toward hand size |
| 5 | ENG5 | Corps of Engineers | **+1 Builder slot** |
| 6 | ENG6 | Prefabrication | All Blueprint numeric effects **+25%** (stacks with Builder tier / Pyramids) |
| 7 | ENG7 | Workshop Relay | Once per settlement: fire one equipped Blueprint **without** playing a Builder |
| 8 | ENG8 | Planetary Engineering | **+1 Builder slot** (cap still 5 — if maxed, Blueprint numeric +25% instead) |

### 6.4 Prophetic Line (Missionary / Doctrine / Prophet progression)

Mirror of Engineering for Faith supports. Slot bumps on Eras **2, 5, 8**.

| Era | ID | Name | Effect |
|---|---|---|---|
| 1 | PRO1 | Alms Circuit | When a Missionary is played: **+4 Faith** |
| 2 | PRO2 | Ordination | **+1 Doctrine slot** |
| 3 | PRO3 | Illuminated Canon | Doctrine numeric rewards **+20%** |
| 4 | PRO4 | Chaplain's Guard | Opening hand always includes a **floating Missionary** (does not count toward hand size) |
| 5 | PRO5 | Synod Seal | **+1 Doctrine slot** |
| 6 | PRO6 | Prophetic Tradition | Gain a **free Great Prophet** at the start of each era |
| 7 | PRO7 | Evangelists | Once per settlement: a played Missionary **does not consume a formation slot** (Helping Hand for Faith) |
| 8 | PRO8 | World Communion | **+1 Doctrine slot** (if maxed, Doctrine numeric +20% instead) |

### 6.5 Formation drills & misc unlocks (keep / expand)

| ID | Era | Upgrade | Effect |
|---|---|---|---|
| NS01 | 1 | Battle Line Drill | Battle Line +1 level |
| NS02 | 1 | Skirmish Drill | Skirmish & Pair +1 level |
| NS03 | 1 | Combined Arms Primer | Combined Arms +1 level |
| NS04 | 1 | Writing | Uncommon Blueprints can appear in Treasury |
| NS05 | 1 | Surveying | +1 Regroup permanently |
| NS06 | 1 | Fortification Studies | Scaffolding/Siege Tower family +25% |
| NS07 | 2 | Phalanx Drill | Phalanx +1 level |
| NS08 | 2 | Vanguard Primer | Vanguard +1 level |
| NS11 | 3 | Grand Army Drill | Grand Army +1 level |
| NS12 | 3 | Legion Primer | Legion +1 level |
| NS13 | 3 | Imperial Standards | Imperial Guard +1 level |
| NS14 | 3 | Machinery | Rare Blueprint weight ↑ in Treasury |
| NS15 | 4 | General Staff Maps | Pick one formation +2 levels |
| NS16 | 5 | Staff College | All formations +1 level |
| NS17 | 6 | Combined Doctrine Manual | Combined Arms & Grand Army +1 level |
| NS18 | 7 | Rapid Deployment | +1 Regroup permanently |
| NS19 | 8 | Networked Command | +1 hand size |

Old **Natural Philosophy** one-off is retired in favour of the Education tree.

### 6.6 Shop tree — parked (do not implement yet)

Future non-troop Science line ideas (era-gated same way):

| Idea | Example beats |
|---|---|
| Stall Permits → Bazaar Law → Department Stores → … | +1 visible shop offer |
| Tariff Reform / Subsidies | −% cost on Units or Blueprints |
| Faith Concession | −% Synod costs |
| Bulk Contracts | First reroll each visit free |

Keep out of the live pool until shop UX is stable.

### 6.7 Offer weighting (non-troop fill)

When picking non-troop cards for the 1–2 slots:
1. Build candidate list = progression nodes for **this era only** (6 trees → up to 6 cards) + formation/misc unlocks for **era ≤ current** (and not already redundant if one-shot unlock owned).
2. Prefer not offering two nodes from the **same** progression tree in one screen (only one exists per era anyway).
3. Weight currency trees slightly below formation drills early (e.g. drill 1.2×, tree node 1.0×) so military stays visible; bump tree weight if player is resource-starved (optional later).

Duplicate rule: don’t offer the same ID twice in one screen.

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

- Implement shop progression tree (§6.6) when shop UX is ready.
- Exact weights for T=1 vs T=2 troop slots.
- Whether Builders count toward the “troop” min/max (currently **yes**).
- Missionary **class tier** (Faith) vs Prophetic Line (Science) — both can coexist.
- Sim: apply % bonuses to reward helpers; gate progression offers to current era only. **Done** in `sim/era1_sim.py`.
- Fatten civics to ~20+.
- Retune Education/Banking caps if multi-era sims show resource explosion.
