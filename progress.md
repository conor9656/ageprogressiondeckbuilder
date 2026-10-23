# Progress

Concise log of cloud-agent runs. Newest first. Keep entries short — context for the next agent, not a diary.

---

## 2026-10-23 — W1 core combat in Godot (parity green)
- Ported formations + Might×Mom + walls/garrisons + Tech Literacy/Age Power + support charges into `game/rules/`.
- 16 golden fixtures from Python → all match. `bash scripts/run_game_tests.sh` → `AGES_TESTS_OK`.
- Next for W1: headless Assault/Regroup fight loop + one BP/Doc path.

## 2026-10-23 — W1 unblocked: Godot 4.7.2 + `game/` scaffold
- Locked **Godot 4.7.2** + project folder **`game/`**. Headless smoke test green (`AGES_TESTS_OK`).
- Scripts: `scripts/install_godot.sh`, `scripts/run_game_tests.sh`. Local editor = human @ W2 only.

## 2026-10-22 — Build progress tracker + W1 plan
- Added `BUILD_PROGRESS.md`: workstream board from W0→W8; W1 (Godot rules + tests) approach, acceptance, agent↔Godot CLI plan.
- W1 blocked only on Godot 4 in the agent environment. Next: user approves Godot install + `game/` folder name.

## 2026-10-22 — Game snapshot source of truth
- Added `GAME_SNAPSHOT.md`: single frozen picture of Ages (rules, supports, defence, sim curve, tech, build order).
- Pointed `GAME_DESIGN.md` / `TECH_STACK.md` at it. Next milestone: Godot rules module + Ancient Capital vertical slice.

## 2026-10-22 — Ease eras 6–8 defence (~−35%)
- Rebased E6–E8 onto post–E5 curve: **18300 / 49000 / 98000** (same −35% cut as E5; kept old growth multiples).
- N=40 S1–S5 eras 1–8: E1–E5 means held; late mean **E6 46% / E7 31% / E8 24%** (was ~0%). S2 E8 55%.
- Design: `BALANCE_E6_E8_EASE.md`. Report: `sim/results/ERAS_6_8_EASE.md`.

## 2026-10-20 — HP curve eras 1–5 (mean 95/88/78/68/61)
- After support charges, retuned `ERA_BASE_DEFENCE` → **665 / 1200 / 1790 / 3450 / 7180**.
- N=40 S1–S5: mean clear **95.0 / 89.0 / 77.5 / 69.0 / 61.0** (MAE 0.025). Design: `BALANCE_HP_CURVE_E1_5.md`.
- E1–E3 HP up; E4–E5 eased vs post-charge power. E6–E8 unchanged.

## 2026-10-18 — Battlefield support charges (B/Y not deck RNG)
- Design: `BALANCE_SUPPORT_CHARGES.md`. Wired in `era1_sim.py`: always-on B/Y with 1 charge/settlement; slot cost until free-slot; Sci chance (~40%) or Gold (50/80/120) upgrades every 2 Sci levels (cap 4).
- Sim N=40 S1–S5 eras 1–5: **100% runs use Builder**; Y strong esp. S5 (11.5 mean uses). B/settlement ~0.8–1.25.
- Clears rose vs E5-evening (S2 E5 60→80, S1 28→62, S4 2→15). Report: `sim/results/SUPPORT_CHARGES_S1_5.md`.
- Next: if keeping S2 E4≈75% target, retune after this power bump.

## 2026-10-18 — E5 evening first-pass (no HP edits)
- Design: `BALANCE_E5_EVENING.md`. Wired: +1 Assault @ E5, Line Mom (BL/CA/Phalanx), Industrial Toolkit.
- Quick N=40: **S2 E4 held 75%**; mean E5 **14%→22%**; S1 E5 10%→28%; S5 8%→15%; S2 E5 42%→60%.
- S4 still dies pre-toolkit. Report: `sim/results/E5_EVENING_QUICK.md`. Ready to promote to GDD if desired.

## 2026-10-14 — E4+ escalation pack (growth into the curve)
- Design: `BALANCE_E4_ESCALATION.md`. Wired in `era1_sim.py`.
- Retuned for **S2 E4 ≈ 75%**: def E4 **4100** / E5 11000 / E6 28000; Age Power 0.015; Literacy 0.05; income ×1.55; bar −15%; Breakthrough Sci+Civ only.
- Quick baseline N=40: **S2 E4 75%**, mean E4 **40%**, E5 **14%**. S5/S4 still soft. Report: `E4_ESCALATION_QUICK.md`.

## 2026-10-12 — 8-era contribution sim (levers v3)
- Runner: `python3 sim/contribution_sim.py --eras 8 --runs 60 --seed 42` → `CONTRIBUTION_REPORT_E8.*`
- **Cliff at E4:** mean clear E1 81% · E2 73% · E3 57% · **E4 ~10%** · E5 ~1% · E6–E8 ~0%.
- S2 only real E4 foothold (27%); S5 12%; S4 0%. Capitals/towns at Medieval kill the field.
- Ablations past E4 → 0 (nobody alive). Promos still −16% E3 / −9% E4. Doc/Wonder still weak for clears.
- Bugfix: fail-path now snapshots wonder/sci/civ/util. Next: retune E4 defence or mid-game power spike — don’t tune E7–E8 yet.

## 2026-10-10 — Contribution sim after levers v3
- Runner: `python3 sim/contribution_sim.py --eras 3 --runs 80 --seed 42`
- Baseline mean clear **E1 82% / E2 72% / E3 56%** (was 80/68/38).
- **Promotions fixed:** E3 Δ **−15%** (was ~0). Editions −4%, Doctrines −5%.
- Science still #1 (−48%). Wonder own-rate up; mean Wonder Δ still −4%.
- Evening: S5 28→42, S6 20→45, S1 26→65; **S2 also rose 71→89** (ate promo buffs). Gap 51→44pp.
- Report: `sim/results/CONTRIBUTION_REPORT.md`. Next: asymmetric S4/S5 buffs, not more global combat.

## 2026-10-10 — Balance levers v3 implemented (pre re-sim)
- Design notes: `BALANCE_LEVERS_V3.md`. Wired into `era1_sim.py` + `DOCTRINES.md` / `GAME_DESIGN.md` / `CONTENT_CATALOG.md`.
- **Faith:** Tithe/Scriptorium/etc. ×~2; Spoils Liturgy (×1.5 victory); War Psalm (+1 Mom); Martyr's Guard; Zeal +20%; steeper Missionary Zeal.
- **Promos/Editions:** Master Drill +5 / Skirmish +2 Mom / Shock / Banner +12 / Heroic ×1.75 / Relentless; edition chance 30%; Berserker, Hawk-Eyed, Savant, Zealot, Plated; promo band ~28%.
- **Wonders:** dedicated shop slot **every visit** + 1 Gold reroll; Oracle/Alexandria/Angkor/Hagia/Machu/Chichen/Taj/Eiffel/Christ/Petra; cheaper era-scaled costs.
- **Evening:** Science **4-offers** (max 2 troop); S1 free wall-ignore once/settlement; S3 Battle Line preference; no S2 nerf.
- **Next:** re-run contribution sim and compare Doc/Promo/Wonder ablations + S5/S6 clears vs S2 target.

## 2026-10-10 — Full contribution sim (eras 1–3, N=80)
- Runner: `sim/contribution_sim.py --eras 3 --runs 80 --seed 42`
- **Science carries** (E3 clear Δ −37%; E2 −53%). Troop upgrades real (−28%). Civics (−18%), Blueprints (−14%), Policies (−10%).
- **Near-zero:** Doctrines, Promotions, Editions. Wonders weak (−4%) and under-owned.
- S2 still king (E3 71% vs S6 20%). Report: `sim/results/CONTRIBUTION_REPORT.md`. Hotspots updated.

## 2026-10-09 — Contribution/ablation plan for next full sim
- Qualitative hotspots: `BALANCE_HOTSPOTS.md` (S2/Science strong; S5/Builders/Civics/Wonders weak suspects).
- Next sim must measure **system contribution**, not only strategy clears: ablations for science/civics/troops/BP/Doc/wonders/promos/editions/policies + offer/take util.
- Scaffold: `sim/contribution_sim.py` + ablation flags on `RunState`. Docs in `SIMULATION.md`.

## 2026-10-09 — Idea intake batch (Wonders / BP / Policies / Doctrine / Civic)
- Assessed spoken bonuses in `CARD_ASSESSMENT_IDEAS.md` (placement + tuned numbers).
- **Skipped** per-class +Mom (dupe of Science tiers / class Policies). Shop Commerce already live.
- Added: Wonders Parade Grounds / Theater of War / Scriptoria Spire / Safe Conduct; Blueprints Court Mime / Investment Bond / Kaleidoscope Orders; Policies Steady Advance / Court Fashion; Doctrine Prophetic Succession; Civic Treasury Windfall.
- Wired into `era1_sim.py`. Content dense enough for first full multi-era sim.

## 2026-10-09 — Works/Ministry Builder & Missionary upgrades
- Shared support ladder (Science + Civics): **free slot → float → free use → ×2**, plus **+slots** on eras 2/4/6.
- Missionary civics: Lay Preachers (E1 free slot), Chaplain's Escort (E2 float), Silent Benediction (E3 free use), Parish/Synodal/Cathedral +slots, Apostolic Double (E6 ×2).
- Builder mirrors: Corvée Exemption, Clerk's Retinue, Standing Order of Works, Works/Public Works/Atelier +slots, Masterwork Code ×2.
- Science also offers Masterwork Code / Apostolic Double as era-6 drills. No double-dip if already owned via the other track.
- Docs §6.4b + §7.5; sim wired.

## 2026-10-03 — Shop civics (Commerce line)
- Civics clarified: **era-weighted random 1-of-3**, not a fixed tree (current-era bias + rare ahead; one-shots drop once owned).
- Added Commerce shop civics to Civics (not Science): **Stall Permits** (+1 pack size, C), **Pedlar's Writ** (free reroll/era, U), **Royal Boon** (free item/era, U), plus Fairground Toll, Merchant Guild Charter, Tithe Rebate, Courier Privilege, Double Stall, Auction House, Edition Edict, Letter of Credit, Promotion Subsidy, World Fair, Disband Amnesty, Open Borders Market.
- Wired into `era1_sim.py` (era charges, pack size, discounts, debt). Science §6.6 shop tree superseded → Civics §7.2–7.3.

## 2026-10-02 — Science progression trees (non-troop pool)
- Designed era-gated stacking trees in `SCIENCE_UPGRADES.md` §6: **Education / Banking / Devotion / Arts** (currency %), **Engineering** (Builder line), **Prophecy** (Missionary line).
- Rule: current-era node only; miss = gone forever; stacks additively across eras. Shop Science tree parked (§6.6).
- Natural Philosophy one-off retired → Education tree.
- Sim (`era1_sim.py`): PROG_* tables, reward/city/interest/doctrine % scaling, era-gated offers, eng/pro combat flags (float Builder/Missionary, draw-on-Builder, faith-on-Missionary, wall BP +50%, Workshop Relay, Evangelists free slot, free Prophet proxy).
- Catalog §8 updated. Strategy evening still deferred; shop tree still parked.

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
