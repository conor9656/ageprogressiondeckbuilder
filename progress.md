# Progress

Concise log of cloud-agent runs. Newest first. Keep entries short — context for the next agent, not a diary.

---

## 2026-09-30 — Science/Civics random level-ups
- Locked: bar fill → pick 1 of 3 random upgrades (no fixed tree).
- Troop offers are Upgrade Melee/Ranged/Cavalry/Siege/Builders; tiers tracked on the run.
- Era soft-cap + rare ahead-of-era; same-class weight recovers next era.
- Science offer mix: min 1 / max 2 troop-like of 3. Details in `SCIENCE_UPGRADES.md`.

## 2026-09-30 — Full Policy / Blueprint / Doctrine pools
- Studied Balatro joker *patterns* only (flat / conditional / ×mult / scaling) — no copied card text.
- Added `CARD_MODES.md`, `POLICIES.md` (40), `BLUEPRINTS.md` (40), `DOCTRINES.md` (40) with modes, caps, OP notes.
- Catalog points at the new files; scaling prefers once-per-settlement or capped growth.

## 2026-09-29 — Shop packs + unit editions/promotions
- Shop redesigned: **Treasury (Gold)** vs **Synod (Faith)** packs — random offers, not an open catalogue.
- 1 reroll per pack per visit; Disband always available; Wonders can appear in either pack.
- Added **Editions** (stamped shop units) and **Promotions** (upgrade a card already in deck), separate from Science class tiers.
- Docs: `GAME_DESIGN.md` §8, `CONTENT_CATALOG.md` §10.

## 2026-09-29 — Content-first before heavy sim
- Locked order: expand joker-like cards/techs → name strategies → rough power budgets → then simulate.
- Naked Round‑1 Monte Carlo deferred (would be voided by new cards).
- Added `CONTENT_CATALOG.md` (strategies S1–S6, Policies/Blueprints/Doctrines/Prophets, Ancient techs/civics, shop stubs, paper clear check).
- Rewrote `SIMULATION.md` around that order + RPU/rarity budgets.

## 2026-09-29 — Simulation readiness
- Round‑1 damage-first method noted; then superseded by content-first decision above.
- See `SIMULATION.md` for current order.

## 2026-09-29 — Design risks + tech stack
- Added §14 design risks to `GAME_DESIGN.md` (run length, Doctrine snowball, Science spiral, deck bloat, formation clarity).
- Added `TECH_STACK.md`: Godot 4 + GDScript recommended; 2D/faux-3D art pipeline; Steam via GodotSteam; no servers.
- PR: https://github.com/conor9656/ageprogressiondeckbuilder/pull/1

## 2026-09-28 — Concept review
- Reviewed `GAME_DESIGN.md` (Ages: Civ-themed Balatro-like deck-builder).
- Verdict: strong concept; flagged the five risks later written into §14.
- No code yet — design-only repo.
