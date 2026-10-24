# Ages — Playtest notes (2026-10-24)

Answers + gaps from Domination greybox play. Track fixes here.

---

## Your questions

### 1. Is Corvée Exemption irrelevant now?

**No — still relevant.** Builders are battlefield charges (not deck cards), but they still **cost a formation slot** when you attach them to an Assault (same as Missionaries), unless you have a free-slot source.

Free-slot sources (design): Helping Hand (Blueprint), **Corvée Exemption** / Lay Preachers (Civics), Machu Picchu (Wonder).

**Fixed:** fight code now honours `eng_flags.builder_free_slot` / `pro_flags.missionary_free_slot` (not only Helping Hand).

### 2. What does “Upgrade Builder” mean?

Design: Science **Builder tier** scales **Blueprint numbers** (Might bonuses, wall help strength, etc.):

| Tier | Scale |
|---|---|
| I | ×1.0 |
| II | ×1.5 |
| III | ×2.0 |
| IV | ×2.5 (cap) |

It is **not** “+1 Builder charge” (that’s the separate `support_charge_B` / Gold charge path).

**Wired:** `builder_scale` updates on `upgrade_B` and is shown in fight + shop income panel. Full numeric BP effects still stubby for most Blueprints (scaffolding / siege_tower wall help work).

### 3. Classical Village HP < Ancient Capital?

Yes — with the current table that’s intentional math, not a bug:

| | Formula | E1 | E2 |
|---|---|---|---|
| Village | era_base × 1 | **665** | **1200** |
| Capital | era_base × 2.5 | **1662** | 3000 |

So **Ancient Capital (1662) > Classical Village (1200)**. Same pattern can recur at other era seams.

**Issue flagged:** feels wrong in human play (“next era’s opener weaker than last boss”). Options later: raise E2+ village floor, change mults, or “no Defence regression” vs previous Capital. **Don’t retune mid-playtest without a deliberate pass.**

---

## Economy (flag only — don’t retune yet)

| Issue | Notes |
|---|---|
| **Gold piles up** | Starting rewards + occupy + weak sinks; shop packs cheap; disband/Wonder underused |
| **Faith piles up** | Synod thin; Doctrine slots start at **1**; prophets weak; few Faith sinks |

Needs a dedicated economy pass after shop/Wonder/loadout are visible.

---

## Shop / meta — what’s in the docs vs greybox

| Design (GAME_SNAPSHOT) | Greybox after this pass | Status |
|---|---|---|
| Treasury (units / BP / promos / Wonder spill) | Units/BP/promos; Wonder is dedicated row | OK for greybox |
| Synod (Doctrines / Prophets / spill) | Expanded prophet catalog (8 ids) | Improved |
| **Dedicated Wonder row** (1 Wonder / run, reroll) | **Added** (+ cheap Wonder reroll) | Done |
| See / swap equipped BP & Docs | Loadout + Unequip | Done |
| See deck + promotions | Deck panel in shop | Done |
| Occupy yield readout | Income breakdown panel | Done |
| Gold charge upgrades (50/80/120) | Missing | Noted |
| Disband (rising Gold) | Missing | Noted |
| Editions on units | Missing | Noted |
| Rival skips Wonder | Missing | Noted |
| Policy board visibility | Listed in loadout | Partial |
| Per-card promotion attach | Tracked as owned list only | Greybox |

---

## Fight UX

| Need | Notes |
|---|---|
| Builder as clickable support | Toggle + Blueprint picker + scale/slot strip |
| Preview with/without Builder + chosen BP | Δ damage vs Builder off |
| See equipped Blueprints | Shown on Builder strip |
| Missionary / Doctrine arm | Still thin — next pass |

---

## UI blocker (Medieval shop)

Leave shop → march scrolled off-screen when packs/lists grew. **Fixed:** shop content scrolls; march / reroll stay in a sticky footer.

---

## Still missing / next

1. Economy pass (Gold/Faith sinks: richer Synod effects, disband, charge gold buys, Wonder costs vs income)
2. Defence seam (E_n Village vs E_{n-1} Capital)
3. Real Blueprint/Doctrine numeric effects × Builder tier
4. Missionary arm + Doctrine on-win payout UI
5. Disband / Editions / Wonder spill in pack RNG
6. Art (W6) only once the loop feels fair

---

## Suggested priority after this fix pack

1. Play again with loadout / deck / Builder UX / Wonder visible  
2. Economy pass  
3. Defence seam discussion  
4. Real BP/Doc numbers  
5. Art  
