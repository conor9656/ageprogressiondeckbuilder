# Ages — Godot project (`game/`)

Godot **4.7.2** · GDScript

Design: [`../GAME_SNAPSHOT.md`](../GAME_SNAPSHOT.md) · Tracker: [`../BUILD_PROGRESS.md`](../BUILD_PROGRESS.md)

## Play the Ancient greybox (you)

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Open this `game/` folder in Godot.
3. Press **Play (F5)**.
4. **Start Ancient run** → hub → fight Village → Town → Capital.

Between fights: **Occupy / Raze** → Science 1-of-4 / Civics 1-of-3 (when you can afford) → **Treasury / Synod** shop → march on.

**Keys in fight:** `A` Assault · `R` Regroup (discards **selected** cards only) · `Esc` clear · `H` hint

Solo fight (no run meta) is still available from the menu for quick combat checks.

## Run tests (headless / agents)

```bash
bash scripts/run_game_tests.sh
```

Expect `AGES_TESTS_OK`.

## Layout

| Path | Role |
|---|---|
| `rules/` | Pure combat + Ancient run meta (no UI) |
| `scenes/boot/` | Main menu |
| `scenes/run/` | Ancient era hub / fight / post / shop |
| `scenes/fight/` | Solo settlement fight (debug) |
| `content/combat_tables.json` | Unit/formation numbers, Defence, walls, garrisons |
| `content/ancient_run.json` | Rewards, Sci/Civ catalogs, shop packs, starter deck |
| `tests/` | Headless suite + fixtures |

Balance knobs live in those JSON files — change a number, re-run tests / Play; no GDScript edit needed for catalogs.
