# ZombieIO Architecture

## 1. Goals

ZombieIO is structured as a scene-driven Godot game with a clear separation of responsibilities:
- Gameplay entities live in their own scenes.
- Core orchestration lives in `Main`.
- Spawning, waves, VFX, upgrades, and audio are handled by managers.
- Balance data is kept in dedicated database scripts.

The V5 refactor aims to:
- Make the game easier to extend with new enemies, weapons, drops, and effects.
- Reduce coupling between gameplay, UI, VFX, and data.
- Keep content additions mostly data-driven.

## 2. Current Folder Layout

```text
scenes/
  main.tscn
  player/
    player.tscn
  enemies/
    zombie.tscn
    brute_boss.tscn
  projectiles/
    bullet.tscn
  items/
    exp_gem.tscn
    weapon_drop.tscn
    rare_drop.tscn
  effects/
    damage_number.tscn
    death_effect.tscn
    death_burst.tscn
    hit_flash.tscn
  ui/
    hud.tscn
    upgrade_menu.tscn
    game_over_menu.tscn

scripts/
  core/
    main.gd
    game_state.gd
    save_manager.gd
  managers/
    wave_manager.gd
    spawn_manager.gd
    upgrade_manager.gd
    audio_manager.gd
    vfx_manager.gd
  player/
    player.gd
    weapon_controller.gd
  enemies/
    zombie.gd
    brute_boss.gd
    enemy_stats.gd
  projectiles/
    bullet.gd
  items/
    exp_gem.gd
    weapon_drop.gd
    rare_drop.gd
  effects/
    damage_number.gd
    death_effect.gd
    death_burst.gd
    hit_flash.gd
  ui/
    hud.gd
    upgrade_menu.gd
    game_over_menu.gd
  data/
    weapon_database.gd
    enemy_database.gd
    wave_database.gd
    upgrade_database.gd

resources/
  weapons/
  enemies/
  waves/
  upgrades/
```

## 3. Runtime Flow

1. `scenes/main.tscn` is loaded.
2. `Main` wires up player, managers, HUD, and menus.
3. `WaveManager` starts the first wave.
4. `WaveManager` emits spawn requests for zombies or bosses.
5. `Main` instantiates scenes and places them into the world container.
6. Player auto-targets the nearest zombie and shoots.
7. Bullet hit triggers damage number, hit flash, knockback, and death effects.
8. Zombie or boss death awards score, EXP, and drops.
9. Level-up opens the upgrade menu.
10. Player death opens the game over menu.

## 4. Scene Tree

`scenes/main.tscn` is the root scene for the game. It contains:
- `Main` as the top-level controller.
- `Player`
- `WaveManager`
- `SpawnManager`
- `VFXManager`
- `UpgradeManager`
- `AudioManager`
- `ZombieContainer`
- `CanvasLayer`
  - `HUD`
  - `UpgradeMenu`
  - `GameOverMenu`

The player scene includes a `Camera2D` so `Main` can apply camera shake on heavy events such as boss death.

## 5. Core Responsibilities

### 5.1 `scripts/core/main.gd`

`Main` is the orchestration layer.

Responsibilities:
- Connect player, wave, UI, and manager signals.
- Spawn zombies, bosses, and VFX through helper methods.
- Track score, EXP, level, and upgrade points.
- Handle restart and game over flow.
- Apply camera shake.

`Main` should not own combat AI or entity-specific behavior. It only routes events and coordinates systems.

### 5.2 `scripts/managers/wave_manager.gd`

`WaveManager` controls the wave loop.

Responsibilities:
- Decide how many enemies spawn per wave.
- Pick enemy types using weighted tables.
- Emit zombie or boss spawn requests.
- Track alive enemies and wave completion.

Wave definitions are provided by `scripts/data/wave_database.gd`, which keeps wave tuning separate from logic.

### 5.3 `scripts/player/player.gd`

The player scene handles movement, targeting, shooting, HP, and weapon switching.

Responsibilities:
- Move with top-down input.
- Auto-fire at the nearest zombie.
- Maintain current weapon data.
- Emit `hp_changed`, `died`, and `weapon_changed`.

Weapon data is sourced from `scripts/data/weapon_database.gd`.

### 5.4 `scripts/projectiles/bullet.gd`

Bullets are simple damage projectiles.

Responsibilities:
- Travel in a configured direction.
- Deal damage on hit.
- Spawn damage numbers on impact.
- Self-destruct after a short lifetime.

### 5.5 `scripts/enemies/zombie.gd`

Zombie is the standard melee enemy with multiple variants.

Current enemy types:
- `normal`
- `fast`
- `tank`
- `exploder`
- `mini_boss`
- `boss`

Responsibilities:
- Chase the player.
- Attack when in range.
- Take damage and apply knockback.
- Spawn hit flash, death effect, burst, EXP gem, and weapon drop.
- Notify `Main` and `WaveManager` when killed.

The stats for each variant are pulled from `scripts/data/enemy_database.gd`.

### 5.6 `scripts/enemies/brute_boss.gd`

Brute Boss is a stronger AI-driven enemy with a simple state machine.

States:
- `chase`
- `charge`
- `slam_windup`
- `recover`

Responsibilities:
- Chase the player.
- Charge or slam depending on range.
- Summon minions.
- Apply stronger death effects.
- Spawn rare drops for boss kills.

### 5.7 `scripts/items/exp_gem.gd`

EXP gems are pickups that float and move toward the player when close.

Responsibilities:
- Attract to the player within a range.
- Collect on contact or proximity.
- Call `Main.add_exp(exp_value)`.

### 5.8 `scripts/items/weapon_drop.gd`

Weapon drops are normal loot pickups.

Responsibilities:
- Float visually.
- Give the player a weapon when collected.

### 5.9 `scripts/items/rare_drop.gd`

Rare drops are boss reward items.

Responsibilities:
- Act like a special pickup.
- Give a high-value or rare weapon reward.

### 5.10 `scripts/effects/damage_number.gd`

Damage numbers are short-lived UI effects.

Responsibilities:
- Show damage as floating text.
- Support critical hits.
- Move slightly upward and fade out.

### 5.11 `scripts/effects/death_effect.gd`

Death effect is the main enemy death burst shape.

Responsibilities:
- Show a short fade-out burst.
- Use a stronger variant for bosses.

### 5.12 `scripts/effects/death_burst.gd`

Death burst is the particle-like burst effect used on death.

Responsibilities:
- Create a small burst around the death position.
- Use different intensity for normal enemies, bosses, and exploders.

### 5.13 `scripts/effects/hit_flash.gd`

Hit flash is a very short hit feedback effect.

Responsibilities:
- Flash white or orange on impact.
- Help make hits feel stronger.

### 5.14 `scripts/managers/vfx_manager.gd`

`VFXManager` centralizes effect spawning.

Responsibilities:
- Spawn damage numbers.
- Spawn hit flash.
- Spawn death effects and death bursts.
- Spawn rare drops.

This keeps entity scripts from manually handling every effect instantiation path.

### 5.15 `scripts/managers/upgrade_manager.gd`

`UpgradeManager` applies level-up effects to the player.

Responsibilities:
- Increase damage, speed, fire rate, HP, or other stats.
- Keep upgrade application logic out of the UI.

### 5.16 `scripts/ui/upgrade_menu.gd`

Upgrade menu is shown on level-up.

Responsibilities:
- Display a small list of upgrade choices.
- Emit `upgrade_selected`.

### 5.17 `scripts/ui/game_over_menu.gd`

Game over menu appears when the player dies.

Responsibilities:
- Show final score and level.
- Emit `restart_pressed`.

## 6. Data Layer

### 6.1 `scripts/data/weapon_database.gd`

Stores weapon balance data such as:
- shoot rate
- bullet speed
- bullet damage
- projectile count
- spread

### 6.2 `scripts/data/enemy_database.gd`

Stores enemy balance data such as:
- speed
- HP
- damage
- EXP value
- score value
- knockback
- drop chance
- boss skills

### 6.3 `scripts/data/wave_database.gd`

Provides wave configs such as:
- total enemies
- spawn interval
- weighted enemy tables
- boss wave markers

### 6.4 `scripts/data/upgrade_database.gd`

Stores the level-up upgrade options shown by the UI.

## 7. Gameplay Flow

### 7.1 Spawn Flow

1. `WaveManager` picks the next enemy type.
2. `WaveManager` emits a spawn request.
3. `Main` spawns the scene and adds it to `ZombieContainer`.
4. `WaveManager` updates alive counts.

### 7.2 Combat Flow

1. Player finds the nearest zombie.
2. Player fires a bullet.
3. Bullet hits the enemy.
4. Enemy takes damage and gets knockback.
5. VFX plays.
6. Enemy dies if HP reaches zero.

### 7.3 Death Flow

1. Enemy spawns death effect and burst.
2. `Main` gets score and EXP updates.
3. EXP gem and drops may spawn.
4. `WaveManager` is notified that one enemy died.

### 7.4 Boss Death Flow

1. Boss dies.
2. Bigger death effect and burst spawn.
3. Camera shake is applied.
4. Rare drop may spawn.
5. Large score and EXP rewards are granted.

### 7.5 Level Up Flow

1. Player gains EXP.
2. When the threshold is reached, `Main.level_up()` runs.
3. Upgrade points increase.
4. Upgrade menu updates.
5. Player chooses one upgrade.

### 7.6 Game Over Flow

1. Player HP reaches zero.
2. `Main` shows the game over menu.
3. The game pauses.
4. Restart reloads the current scene.

## 8. Technical Notes

- Placeholder visuals use `Polygon2D` so the game can be iterated without final art.
- Entity identification relies on groups such as `player` and `zombie`.
- Scene instantiation uses `PackedScene`.
- Most interactions are event-driven through signals.
- `Main` remains the central coordinator, not the owner of all gameplay logic.

## 9. Collision Layers

Current gameplay layers are organized as:
- Player
- Zombie
- Bullet
- Item
- EnemyAttack

## 10. Input

Configured movement actions:
- `move_up`: `W` or Up Arrow
- `move_down`: `S` or Down Arrow
- `move_left`: `A` or Left Arrow
- `move_right`: `D` or Right Arrow

## 11. Extension Strategy

This architecture is meant to scale with content additions:
- Add a zombie type by extending `enemy_database.gd` and the zombie scene logic.
- Add a boss by creating a new scene and config entry.
- Add a weapon by updating `weapon_database.gd`.
- Add a wave pattern by changing `wave_database.gd`.
- Add a new UI or VFX effect by adding a scene and exposing it in a manager.

The main rule is: put content data in data scripts, keep orchestration in managers, and keep entity behavior inside the entity scene.

## 12. Summary

V5 turns ZombieIO into a cleaner, more expandable game:
- `Main` orchestrates.
- `WaveManager` controls pacing.
- `SpawnManager` creates enemies.
- `VFXManager` owns effects.
- `Player`, `Zombie`, `Boss`, `Bullet`, and pickups own their own behavior.
- UI listens and displays state.

That keeps the codebase small enough to work on quickly, but structured enough to add new content without rewriting the core loop.
