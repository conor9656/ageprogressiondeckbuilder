# Ages — Godot project (`game/`)

Godot **4.7.2** · GDScript

Design: [`../GAME_SNAPSHOT.md`](../GAME_SNAPSHOT.md) · Tracker: [`../BUILD_PROGRESS.md`](../BUILD_PROGRESS.md)

## Play the Domination greybox (you)

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Open this `game/` folder in Godot.
3. Press **Play (F5)**.
4. **Start Domination run** → 8 eras × Village → Town → Capital.

Between fights: **Occupy / Raze** → Science/Civics → shop → march.  
Era starts: **Breakthrough** free picks from Renaissance; **Industrial Toolkit** at Industrial.

**Keys in fight:** `A` Assault · `R` Regroup (discards **selected** cards only) · `Esc` clear · `H` hint

Solo fight (no run meta) is still available from the menu for quick combat checks.

## Run tests (headless / agents / CI)

```bash
bash scripts/ci_rules.sh          # canonical CI entry
# or:
bash scripts/run_game_tests.sh
```

Expect `AGES_TESTS_OK` (and `AGES_RULES_CANONICAL` from `ci_rules.sh`).

See [`RULES.md`](RULES.md) — Godot is the rules source of truth; `../sim/` is research-only.

## Layout

| Path | Role |
|---|---|
| `rules/` | Pure combat + Domination run meta (no UI) |
| `scenes/boot/` | Main menu |
| `scenes/run/` | Domination hub / fight / post / shop / era hooks |
| `scenes/fight/` | Solo settlement fight (debug) |
| `content/combat_tables.json` | Unit/formation numbers, Defence, walls, Line Mom |
| `content/ancient_run.json` | Rewards, era income, Sci/Civ/shop catalogs, Toolkit |
| `tests/` | Headless suite + fixtures |

Balance knobs live in those JSON files — change a number, re-run tests / Play; no GDScript edit needed for catalogs.
