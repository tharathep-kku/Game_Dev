# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Godot 4.7 2D game built from the "2D Platformer Starter Kit" (see README.md for the original starter-kit feature list), reskinned as a zombie-apocalypse platformer. GDScript only — no C#/GDExtension. There is no test suite and no package manager; "building" means opening the project in the Godot editor.

## Commands

There is no CLI build/lint/test pipeline. Development happens in the Godot editor (Project → Open, select `project.godot`, press F5 to run). For headless verification (no display available), use the Godot editor binary directly:

```
<path-to-godot>/Godot_v4.X-stable_win64_console.exe --headless --path . --import
```

This reimports all assets and surfaces script/scene parse errors without opening the GUI — the fastest way to confirm a change didn't break anything. To smoke-test that scenes actually load and tick without runtime errors, write a throwaway `extends SceneTree` script that `load()`s/`instantiate()`s the scenes in question and run it with `--headless --path . --script <script>.gd`.

### Regenerating the platformer levels

`Level_01.tscn`, `Level_02.tscn`, `level_03.tscn`, `level_04.tscn` are **generated files** — do not hand-edit their tile layout. Edit the layout data in `tools/build_levels.gd` (ground strips, trap/enemy/item placement, backgrounds) and regenerate:

```
<godot-binary> --headless --path . --script tools/build_levels.gd
```

This exists because `TileMapLayer.tile_map_data` is an opaque binary `PackedByteArray` in `.tscn` files — unsafe to write by hand. The script builds each level as a flattened scene via `TileMapLayer.set_cell()` and `PackedScene.pack()`, then saves over the target file. Two things to know if you touch this tool:
- Any node you construct directly (not via `PackedScene.instantiate()`) needs `.owner` set to the packing root or `pack()` silently drops it.
- Signal connections made via script (`.connect(...)`) need the `CONNECT_PERSIST` flag or `pack()` won't save them, even though the connection works fine at runtime in the same process.
- Array-typed `@export` properties (e.g. `Array[Vector2]`) set via `.set()` will silently no-op if the value passed through an untyped `Array`-typed function parameter along the way — type it explicitly end-to-end.

## Architecture

### Two game modes, one active

The game has two separate level-flow implementations sharing the same player/enemy/item scripts:

- **Platformer mode** (currently the default entry point): `Scenes/Levels/base_level.tscn` + `base_level.gd` is the shared template; `Level_01.tscn` → `Level_02.tscn` → `level_03.tscn` → `level_04.tscn` → `game_win.tscn` is a fixed, hand-designed (generated) chain with jump/fall traversal, traps, moving platforms/elevators/portals.
- **Endless mode** (built but currently dormant, not wired as the entry point): `Scenes/Levels/endless_level.tscn` + `endless_level.gd` procedurally builds a flat, ever-longer level each time it loads, driven by `GameManager.stage` (persists across loads, resets on `restart()`). Continuous zombie spawning, a boss every 4th stage, win condition at `stage >= FINAL_STAGE`.

Which mode is active is decided entirely by `GameManager.current_level` (default) and `GameManager.restart()` (what "Start"/"Play Again" load) — both currently point at `Level_01.tscn`. To switch modes, repoint those two.

### Autoloads (`project.godot` `[autoload]`)

- `GameManager` (`game_manager.gd`) — the only real game-state singleton: score, hp, life, stage, combo/multiplier, kill count, persisted high score (`ConfigFile` at `user://highscore.cfg`), save/load (JSON at `user://game.save`), and `damage()`/`death()`. `GameManager.player` is a live reference to the current player instance, set by whichever level script is active. `life` is currently `1` (one-hit run, not the original starter kit's multi-life design).
- `AudioManager` (`audio_manager.tscn`/`.gd`) — one `AudioStreamPlayer` child per sound event, exposed as `@onready var` properties (e.g. `AudioManager.jump_sfx.play()`). Add new SFX by adding a child node + matching `@onready var`, not by loading streams ad hoc.
- `SceneTransition` — wraps `change_scene_to_packed` with a fade animation; call `SceneTransition.load_scene(packed_scene)` instead of `get_tree().change_scene_to_*` directly for player-facing transitions.

### Player script naming is inverted — read carefully before editing

- `Scenes/Actors/player_2.gd` has `class_name Player` and drives `player2.tscn`. **This is the active player script.**
- `Scenes/Actors/player.gd` has `class_name Player2` and drives `player.tscn`. This is unused dead code from the original starter kit — no level references it.

Always edit `player_2.gd`. Grepping for "Player" the class name, not the filename, is the reliable way to find the right file.

### Damage pipeline

Every damage source funnels through two player signals — `hit_enemy(damage: int)` and `hit_trap` — which the active level script (`base_level.gd::_on_player_hit_enemy/_on_player_hit_trap` or `endless_level.gd`'s equivalents) forwards to `GameManager.damage()`. `hit_enemy` carries the colliding enemy's `contact_damage` export (varies per enemy type — see `enemy.gd`), not a hardcoded value.

Any new damage source must respect the player's i-frame/shield state (`player.can_damage`, `player.is_shielded()`) before dealing damage — this has been a repeated source of bugs (pit-fall damage, kill-zone damage, and lava DoT all independently forgot this check at various points). Grep existing trap scripts (`trap_lava.gd`, `_on_collision_body_entered` in `player_2.gd`) for the pattern before adding a new one.

### Enemies

`enemy.gd` (`class_name Enemy`) is the shared AI/HP/death base — patrol-and-chase via three `RayCast2D`s, `take_damage(amount)`/`hp`/`max_hp`, `death_tween()` (which itself calls `GameManager.register_kill()` for scoring/combo — don't also score from the caller, e.g. explosion AoE code, or it double-counts). Concrete enemies are `enemy.tscn` instanced with different `speed`/`max_hp`/`contact_damage`/`score_value` exports and a sprite swap — see `monster_zombie_runner.tscn` / `_tank.tscn` / `_boss.tscn` for the pattern. `monster_zombie_thrower.gd` is the one enemy with genuinely different behavior (extends `Enemy`, adds ranged attacks).

Note: `monster_mushroom1.tscn`/`monster_mushroom2.tscn` are misleadingly named — they're zombie-skinned (from `Assets/Free-Urban-Zombie-Sprite-Sheet-Pixel-Art-Pack/`), not fantasy mushrooms. Every enemy in the game is a zombie regardless of scene filename.

### Physics layers & groups

Layers (`project.godot` `[layer_names]`): 1=wall, 2=player, 3=enemy, 4=item. Groups used for logic (not physics): `"Player"`, `"Enemy"`, `"Traps"`, `"Bullet"` — most collision-response code branches on `body.is_in_group(...)` rather than layer/mask alone.

### Asset organization

`Assets/Kenney/` and `Assets/Backgrounds/Postapocalypse*/` are curated subsets pulled from free Kenney.nl packs and a user-supplied craftpix-style asset pack respectively — see `Assets/Kenney/LICENSE.txt` (CC0). `Assets/Free-Urban-Zombie-Sprite-Sheet-Pixel-Art-Pack/` supplies all zombie enemy sprites. The `new/` directory at the repo root is a scratch staging area for asset drops, not part of the shipped game — treat it as source material to copy *from* into `Assets/`, not a place to reference directly from scene files.
