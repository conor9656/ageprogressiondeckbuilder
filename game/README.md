# Ages — Godot project (`game/`)

Godot **4.7.2** · GDScript

Design: [`../GAME_SNAPSHOT.md`](../GAME_SNAPSHOT.md) · Tracker: [`../BUILD_PROGRESS.md`](../BUILD_PROGRESS.md)

## Play the vertical slice (you)

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (same version as CI).
2. Open this `game/` folder in Godot (Project → Import, or drag `project.godot`).
3. Press **Play (F5)**.
4. Click **Start fight** → Ancient Village greybox.

**Keys:** `A` Assault · `R` Regroup · `Esc` clear selection · `H` hint (AI pick)

Select 1–5 hand cards, optionally tick **Use Builder charge**, then Assault. Drop Defence to 0 before Assaults run out.

## Run tests (headless / agents)

```bash
bash scripts/run_game_tests.sh
```

Expect `AGES_TESTS_OK`.

## Layout

| Path | Role |
|---|---|
| `rules/` | Pure combat / fight loop (no UI) |
| `scenes/boot/` | Main menu |
| `scenes/fight/` | Greybox fight table |
| `content/` | JSON tables |
| `tests/` | Headless suite + fixtures |
