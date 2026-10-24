# `sim/` — research balance twin (not CI)

Python Monte Carlo used to shape Defence curves, rewards, and era growth **before** the Godot client existed.

## Role after W5

| Path | Role |
|---|---|
| **`game/` (Godot 4.7.2)** | **Canonical rules** — what the player runs; what CI tests |
| **`sim/era1_sim.py`** | **Research oracle** — optional experiments, historical balance evidence |

CI does **not** run this folder. The gate is:

```bash
bash scripts/ci_rules.sh
# → godot4 --headless --path game -s res://tests/run_tests.gd
```

## If you change balance

1. Prefer editing `game/content/*.json` and re-running the Godot suite.  
2. Use Python only for large batch sims; if a Python experiment should become “live”, port numbers into JSON / Godot fixtures in the same PR.  
3. Do not treat Python as the source of truth for combat math anymore.

Golden combat fixtures live in `game/tests/fixtures/` and are asserted by Godot.
