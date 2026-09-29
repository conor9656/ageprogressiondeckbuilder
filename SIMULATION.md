# Simulation Plan

How we tune numbers. Results of actual runs go in `progress.md`.

---

## Current order of work (locked 2026-09-29)

**Content → strategies → rough power estimates → then simulation.**

Heavy Monte Carlo on the naked starting deck is **deferred**. Adding Blueprints / Policies / techs later would void those medians. Fill the joker-like catalogs and expected builds first; sim against those builds.

| Step | What | Status |
|---|---|---|
| **0** | Formation bases + unit tier table (already in GDD) | Done (provisional) |
| **1** | Expand Policies, Blueprints, Doctrines, Prophets, Ancient techs/civics | **Now** — see `CONTENT_CATALOG.md` |
| **2** | Name expected player strategies / archetypes | **Now** (catalog) |
| **3** | Assign provisional numbers via a shared **power budget** (rarity + era) | **Now** (estimates OK if coherent, not perfect) |
| **4** | Spot-check: does Strategy X clear Era N Capital on paper? | Next |
| **5** | Code sim against those strategies (not pure random) | After catalogs feel dense enough |

Phase A “Round‑1 greedy damage → set Village HP” remains valid as a *later* calibration tool, not the gate before content.

---

## Why estimates before sim still matter

When you add *Bronze Working* (Melee I → II), that is not a free vibe number. It has to sit in a **relationship**:

- Tier bumps multiply the unit contribution inside Might × Momentum.
- Formation level bumps add flat Might/Momentum to shapes players actually hit.
- Policies/Blueprints are the Balatro jokers — they dominate late damage more than base unit stats.
- Defence per era should track an **expected onboard power** for a competent build, not the naked deck.

So: design the cards with a budget; use light spreadsheet / formula checks; full Monte Carlo only once the card pool and 4–6 strategies exist.

---

## Power budget (working model)

Target: a **thoughtful Prince build** clears the era Capital with ~1 Assault of margin; a careless build fails Town or Capital.

Use **Relative Power Units (RPU)** — rough, for designers/agents, not shown to players.

| Era | Naked starting-deck RPU (reference) | Target onboard RPU to clear Capital | Defence (GDD provisional) |
|---|---|---|---|
| 1 Ancient | ~1.0 | ~2–2.5× naked | Cap 750 |
| 2 Classical | — | ~2× Ancient clear | Cap 2,000 |
| 3 Medieval | — | ~2× prior | Cap 5,000 |
| … | … | keep ~2× per era Capital | … |

**Rarity budgets** (fight-local Blueprint / permanent Policy guidance):

| Rarity | Typical fight impact | Example shapes |
|---|---|---|
| Common | +10–20% to one Assault or small economy | +flat Might to one class; draw 2; +15 Gold on win |
| Uncommon | +25–40% to a fight or sticky economy | +50% next formation Might; +1 Regroup; double city yield |
| Rare | +50%+ fight swing or run-defining | +1 Assault; retrigger; permanent scaling Doctrine |

**Tech: class tier up** (whole class): aim ~**+1.5–2×** that class’s contribution when it scores — not +1.5× total damage (deck is mixed).  
**Tech: formation +1 level**: small flat (e.g. +5 Might / +1 Momentum on that shape) so stacking levels matters but doesn’t outrun tier ups alone.  
**Builder/Missionary tier**: scales Blueprint/Doctrine numeric fields ~**+50–100%** per tier step (as in GDD Battering Ram example).

These are **estimates to stay near** while drafting cards. Simulation later moves the decimals; it should not invent the fantasy of each card.

---

## What blocks a useful sim (still)

Without: a denser card pool, rarity costs, and 4–6 named strategies with “what they buy first,” path variation is noise.  
With those: sim compares builds to Defence targets and answers “is Rare X broken?” instead of “what’s average random damage?”

---

## Old Phase A/B/C notes

Kept for later calibration only:

- **A:** Round‑1 combat distribution (Greedy bot) → refine Village HP  
- **B:** Stub rewards/shop → Town  
- **C:** Full path Monte Carlo over techs/policies  

Do not start A until Step 1–3 in the table above are “good enough,” unless we explicitly want a naked-deck sanity check.
