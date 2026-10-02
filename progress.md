# Progress

Concise log of cloud-agent runs. Newest first. Keep entries short — context for the next agent, not a diary.

---

## 2026-10-02 — New cards assessed + added
- Helping Hand (Blueprint **Rare**), Last Stand (Policy **Rare**, +15 Mom clutch), Mercenaries (Doctrine **Rare**, nerfed to ⌊Gold/5⌋ Might cap 40), Three Musketeers (Policy **Rare**, Triple Mom×3), Terracotta Army Wonder (replace troop post-victory, 25% edition).
- Raw +1 Might/Gold rejected as broken. Assessment: `CARD_ASSESSMENT_NEW.md`. Wired into pools + sim.

## 2026-10-01 — Balance v2 (stack denser + scalers + wonders)
- Applied: early unit buffs, rewards 38/16/16/12, pack size 5, Tech Literacy + Academy-style Mom scalers, era Wonder offer, Medieval base 1400.
- 3-era clear (mean): E1 ~85% · E2 ~73% · E3 ~39% (was 0%). Report: `BALANCE_V2_REPORT.md`.
- Strategy evening deferred (S2 still strongest, S5 weakest).

## 2026-10-01 — Average-run trajectory report
- Instrumented post-fight snapshots (gold/faith/sci/civ/tiers/BP/Doc/Pol/editions/promos).
- `sim/avg_run_report.py` + `AVERAGE_RUN_REPORT.md`: after E1 Capital, typical stack is ~1.4 sci levels, ~1.4 BP, &lt;1 Doctrine/Policy, ~0.2 specials.
- Confirms need to increase Science/Faith/Builder/troop upgrade density before era 3.

## 2026-09-30 — Defence retune + 3-era sim
- Applied era‑1 Defence base **500** (V500/T750/C1250) in `GAME_DESIGN.md`.
- Extended sim to eras 1–3 (`--eras 3`). **Nobody cleared Medieval**; Capital damage/HP ~0.5 by era 3.
- Era‑1 clear dropped to ~22–43% (S2 86%). Report: `sim/results/ERA3_REPORT.md`.

## 2026-09-30 — First Ancient-era simulation
- Added `sim/era1_sim.py`: Village→Town→Capital, greedy combat, packs, Science/Civics, strategy bots.
- N=400/strategy: thoughtful era win ~88–100%; Village 100% clear; Capital is the filter.
- Clumsy/random bot: era win 0%, Village ~52%.
- Naked greedy Village p50 damage ~427 vs Defence 300 → first fight too easy.
- Report: `sim/results/ERA1_REPORT.md` (recommend raising early Defence).

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
