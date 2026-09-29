# Tech Stack — "Ages" (working title)

> Goal: single-player PC game (Steam), **2D with depth / faux-3D animation** (not a true 3D sim).
> Constraint: the stack must be something **AI coding agents** (Cursor, Claude, OpenAI Codex-style agents) can read, edit, build, and test without proprietary GUIs as a hard dependency.
> Numbers and content still live in `GAME_DESIGN.md`; this file is implementation only.

---

## 1. Recommendation (summary)

| Layer | Choice | Why |
|---|---|---|
| **Game engine** | **Godot 4** (GDScript + typed dictionaries / classes) | Best agent fit: text scenes, strong 2D, free, CLI export, Steam-ready |
| **Language** | GDScript first; C# only if a library forces it | Agents are fluent; fast iteration; no compile tax for card logic |
| **Card / sim core** | Pure data + logic modules (no scene tree required) | Headless balance sims and unit tests without booting UI |
| **Art stills** | AI image gen → human cleanup in **Aseprite** or **Krita** | Gen for ideation / base plates; authoring tool owns the final asset |
| **Animation** | **Spine** (2D skeletal) *or* Godot `AnimationPlayer` + spritesheets for MVP | Spine = premium “alive” 2D; spritesheets = cheapest path to first vertical slice |
| **Audio** | Godot AudioServer + sourced/commissioned SFX/music; FMOD later if needed | Overkill to start with middleware |
| **PC / Steam** | Godot export (Windows first) + **GodotSteam** / Steamworks | Achievements, Cloud saves, overlay — no game server |
| **Repo / CI** | Git + **Git LFS** (art) + headless Godot in CI | Agents and humans share one pipeline |
| **Balance sim** | Same rules code, run headless (Godot `--headless` or a thin Python mirror) | Required before locking Defence / reward numbers |

**Not recommended as primary:** Unity (heavier for agents, license/seat friction), Unreal (3D-first, wrong weight), pure web/Electron (Steam possible but feels like a wrapper, worse native feel), raw Love2D/Defold (smaller ecosystem / fewer agent examples).

---

## 2. Why Godot for this game + AI agents

1. **Text-native projects.** Scenes (`.tscn`), resources (`.tres`), and scripts are plain text → agents can diff, search, and patch them reliably.
2. **2D is first-class.** Parallax, Y-sort, canvas shaders, AnimationPlayer — enough to sell “2D that reads as dimensional” without a full 3D pipeline.
3. **CLI / headless.** `godot --headless --script …` and export presets let agents run tests and builds in CI without clicking the editor.
4. **MIT license, no runtime fee.** Fine for Steam commercial.
5. **Deck-builder logic is data-heavy.** Formations, modifiers, shops, and techs are tables + functions — GDScript (or a small shared JSON schema) fits that better than a cinematic 3D engine.

**Fallback:** If hiring or a specific middleware later demands it, **Unity (C#)** is the industry alternate. Keep the **rules layer portable** (pure data + pure functions) so a port is possible; do not scatter combat math inside buttons and particles.

---

## 3. Visual approach: “2D that looks 3D”

Interpret this as **stylized 2D with depth cues**, not a 3D mesh game:

| Technique | Use |
|---|---|
| Multi-layer parallax backgrounds (era maps, settlement vistas) | Depth without 3D cameras |
| Y-sorted units / soft shadows / ground decals | Reads as a diorama |
| CanvasItem shaders (rim light, FOW vignette, heat haze in later eras) | Atmosphere |
| Skeletal 2D (Spine) or well-authored frame anims | Units and UI flourish feel “animated,” not flat swaps |
| Optional: orthographic 3D stage with flat sprite cards (true 2.5D) | Only if art direction demands it; keep cards themselves 2D |

**MVP art bar:** readable unit class silhouettes + clear formation preview. Premium Spine polish can land after the rules loop is fun.

---

## 4. Art & animation pipeline

Your guess (generator → animator) is directionally right; the durable pipeline is:

```
Prompt / concept (Flux, Midjourney, SD, etc.)
        ↓
Cleanup & game-ready still (Aseprite for pixel / graphic; Krita or Photoshop for painted)
        ↓
Rig & animate (Spine  →  export runtime for Godot)
   or
Frame animate in Aseprite → spritesheet + .json atlas
        ↓
Import into Godot (textures, AtlasTexture, SpineSprite, or AnimatedSprite2D)
```

| Role | Tool | Notes |
|---|---|---|
| Concept / base plate | Image generator of choice | Do **not** ship raw gens; they will drift in style |
| Pixel / UI / icons | **Aseprite** | Excellent for cards, icons, VFX flakes; agent-friendly file formats via export |
| Painted key art | **Krita** (free) or Photoshop | Leaders, wonders, era splash |
| Character / unit animation | **Spine** (Essential/Pro) | Industry standard for premium 2D; Godot runtime available |
| MVP / low-cost animation | Aseprite frames or Godot AnimationPlayer | Prefer this until combat feel is locked |
| Video-style AI animators (Runway, etc.) | **Reference only** | Poor fit for loopable, atlas-packed game sprites |

**Style lock early:** one limited palette, one line weight, one unit turnaround sheet. Generators amplify inconsistency; a short art bible beats more prompts.

---

## 5. Game architecture (engine-agnostic shape)

Keep these layers separate so agents (and the balance sim) can work without the full UI:

```
┌─────────────────────────────────────────┐
│  Presentation (Godot scenes, anim, UI)  │
├─────────────────────────────────────────┤
│  Controllers (input, shop flow, route)  │
├─────────────────────────────────────────┤
│  Rules / sim (formations, damage, run)  │  ← pure, testable, headless
├─────────────────────────────────────────┤
│  Content data (JSON/CSV: units, techs… )│
└─────────────────────────────────────────┘
```

- **Content as data:** units, formations, blueprints, doctrines, policies, wonders, settlements → JSON or Godot custom resources checked into git.
- **Deterministic combat:** same seed → same reshuffles / shop rolls (needed for sims and bug repro).
- **Save games:** local only (JSON or binary resource); Steam Cloud via Steamworks later.

---

## 6. Steam / PC shipping extras

| Need | Approach |
|---|---|
| Store build | Godot export templates: Windows (primary), then Linux / macOS |
| Steamworks | GodotSteam (or official Steamworks via GDExtension) — achievements, Cloud, Rich Presence |
| Input | Keyboard/mouse first; controller via Godot InputMap |
| Settings | Display, audio buses, accessibility (reduce motion, colorblind-safe class icons) |
| Crash / logs | Local log file; optional third-party later (e.g. Sentry) — not day one |
| DRM | Steam itself; no custom always-online check |
| Servers | **None** for gameplay. Optional later: leaderboard-only via Steam, not a game backend |

---

## 7. Tooling agents actually need

| Tool | Purpose |
|---|---|
| **Godot 4.x** on PATH | Edit, run, export, headless tests |
| **Git + Git LFS** | Code + large art binaries |
| **EditorConfig / formatter** | Consistent GDScript style for multi-agent edits |
| **Automated tests** | GUT (Godot Unit Test) or custom `--headless` scripts for formation math |
| **Balance harness** | Batch-simulate thousands of Ancient→Information runs; write CSV summaries |
| **CI** (GitHub Actions) | On PR: run unit tests + optionally export a smoke build |
| **Design docs in repo** | `GAME_DESIGN.md`, this file — agents should treat them as source of truth |

Agents struggle when: assets are only editable inside a closed GUI, logic lives only in binary scenes, or “run the game” requires a clicked Play button with no CLI. This stack avoids that.

---

## 8. What we do **not** need (for v1)

- Backend / accounts / matchmaking
- Real-time networking
- Full 3D modeling pipeline (Blender as primary) — optional for marketing renders only
- Custom engine
- FMOD / Wwise on day one
- LiveOps economy servers

---

## 9. Suggested build order (tech, not content)

1. **Rules module + unit tests** — damage formula, formation ranking, walls/garrisons.
2. **Headless sim** — stress §14 risks in `GAME_DESIGN.md` (run length, Doctrine snowball, Science spiral, deck bloat).
3. **Godot vertical slice UI** — one settlement fight, draw/Assault/Regroup, damage numbers.
4. **Shop + one era of content data** — prove the loop, still greybox art.
5. **Art pipeline spike** — one unit class through gen → cleanup → animate → in-engine.
6. **Steam smoke export** — windowed build + placeholder achievements wiring.

---

## 10. Open tech decisions (parked)

- Spine license now vs spritesheet MVP (cost vs polish).
- GDScript-only vs mixed C# (prefer GDScript-only until forced).
- Whether the balance sim shares Godot code or a Python twin (prefer **one** rules implementation — Godot headless — to avoid drift).
- Pixel-art vs painted-2D art bible (affects Aseprite vs Krita weight).
- Controller support for Steam Deck (recommended before launch, not before first playable).
