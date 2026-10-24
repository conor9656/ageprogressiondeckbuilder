# Ages — canonical rules (Godot)

**Source of truth for combat and Ancient run rules:** this `game/` project.

| Piece | Path |
|---|---|
| Combat / run code | `rules/*.gd` |
| Tunable numbers & catalogs | `content/*.json` |
| Headless suite | `tests/run_tests.gd` |
| One-command CI | `../scripts/ci_rules.sh` |

Python under `../sim/` is a **research twin** only — not used by the game client or Rules CI.

```bash
bash scripts/ci_rules.sh
```

Expect `AGES_TESTS_OK` and `AGES_RULES_CANONICAL`.
