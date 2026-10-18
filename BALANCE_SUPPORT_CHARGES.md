# Battlefield Support Charges

**Goal:** Make Builders and Missionaries reliable tools — not deck-draw lottery — while keeping early formation-slot tension.

## Design

| Piece | Rule |
|---|---|
| Presence | Always on the battlefield; **not** in the combat deck |
| Starting stock | **1 charge** each per settlement |
| Formation | Still occupies a slot until free-slot (Helping Hand, Corvée / Lay Preachers, Machu Picchu) |
| Cap | **4** charges / settlement |
| Unlock gate | `sci_level >= 2 × current_charges` (upgrade opportunities at Sci 2 / 4 / 6) |
| Science path | ~40% chance the charge-upgrade node appears in a Sci offer when unlocked |
| Gold path | Instant lump buy: **50 / 80 / 120** gold for charges 2 / 3 / 4 |

## Combat AI (sim)

- Enumerate combat-only hand subsets (1–5).
- Optionally attach ephemeral B and/or Y when charges remain and slot rules allow.
- Prefer attach when unused Blueprints / Doctrines are available.
- Spending a charge fires one BP / Doc (same as old hand supports).

## Why

Prior model: supports competed for hand slots and pack RNG → S4/S5 fantasy under-delivered. Charges guarantee availability; Sci/Gold upgrades scale mid-game usage without flooding early battles.

## Sim note

See `sim/results/SUPPORT_CHARGES_S1_5.md`. Usage goal is hit (≈100% of runs use B; strong Y on Faith paths). Clear rates rose vs E5-evening — expect a follow-up retune if preserving the prior S2≈75% E4 curve.
