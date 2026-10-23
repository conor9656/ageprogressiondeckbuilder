# Ages — Godot project (`game/`)

Godot **4.7.2** · GDScript · rules-first (W1).

Design: [`../GAME_SNAPSHOT.md`](../GAME_SNAPSHOT.md) · Tracker: [`../BUILD_PROGRESS.md`](../BUILD_PROGRESS.md)

## Run tests (headless)

```bash
godot4 --headless --path game -s res://tests/run_tests.gd
```

Expect `AGES_TESTS_OK` and exit code 0.

## Layout

| Path | Role |
|---|---|
| `rules/` | Pure combat / run math (no UI nodes) |
| `content/` | JSON tables (tiers, defence, formations) — filled in W1 |
| `tests/` | Headless suite + fixtures |
| `scenes/` | UI (W2+) — empty until vertical slice |

## Local editor (you, from W2)

Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (same patch as CI/agents), open this `game/` folder, press Play. Not required for W1.
