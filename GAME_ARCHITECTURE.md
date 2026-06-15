# ZombieIO - Game Architecture

## 1. Overview

ZombieIO is a 2D top-down Godot game where the player moves, auto-shoots the nearest zombie, collects EXP gems, levels up, and picks upgrades.

Current project structure:
- `scenes/`: Godot scenes
- `scripts/`: gameplay logic

## 2. Main Scenes

- [`scenes/main.tscn`](./scenes/main.tscn)
  - Main game scene
  - Contains the player, zombie spawner, world container, HUD, upgrade menu, and game over menu
- [`scenes/player.tscn`](./scenes/player.tscn)
  - Player scene
- [`scenes/zombie.tscn`](./scenes/zombie.tscn)
  - Zombie scene
- [`scenes/brute_boss.tscn`](./scenes/brute_boss.tscn)
  - Boss scene for Brute Zombie
- [`scenes/bullet.tscn`](./scenes/bullet.tscn)
  - Bullet scene
- [`scenes/exp_gem.tscn`](./scenes/exp_gem.tscn)
  - EXP gem scene
- [`scenes/death_effect.tscn`](./scenes/death_effect.tscn)
  - Zombie death effect

## 3. Script Architecture

### 3.1 [`scripts/main.gd`](./scripts/main.gd)

Role:
- Main gameplay coordinator
- Spawns zombies
- Manages score, EXP, level, and HUD
- Handles upgrade selection and game over flow

Key behavior:
- Spawns zombies around the player at random angles
- Chooses zombie type based on level
- Adds score when zombies die
- Adds EXP when EXP gems or zombies report rewards
- Opens upgrade menu on level up
- Shows game over menu when the player dies

### 3.2 [`scripts/player.gd`](./scripts/player.gd)

Role:
- Player controller
- Auto-shooting unit
- Damage receiver

Player stats:
- `speed`
- `max_hp`
- `damage`
- weapon library with:
  - `shoot_rate`
  - `bullet_speed`
  - `bullet_life_time`
  - `projectile_count`
  - `spread_degrees`

Weapon behavior:
- Default weapon is `pistol`
- Weapons can be equipped with `equip_weapon(...)`
- Weapons can be added with `add_weapon(...)`
- Press `1`, `2`, `3`, `4` to switch between pistol, shotgun, SMG, and rifle

Key behavior:
- Moves with `move_left`, `move_right`, `move_up`, `move_down`
- Auto-fires at the nearest zombie
- Emits `hp_changed`
- Emits `died` instead of reloading the scene directly
- Shows current weapon in the HUD

### 3.3 [`scripts/zombie.gd`](./scripts/zombie.gd)

Role:
- Zombie AI and combat logic

Zombie types:
- `normal`
- `fast`
- `tank`

Each type has its own stats:
- speed
- max HP
- damage
- EXP value
- score value
- knockback strength

Key behavior:
- Chases the player
- Takes bullet damage
- Applies knockback when hit
- Attacks the player when in range
- Drops EXP gem on death
- Adds score and EXP through `Main`

### 3.4 [`scripts/brute_boss.gd`](./scripts/brute_boss.gd)

Role:
- Boss AI and combat logic for Brute Zombie

Key behavior:
- Chases the player
- Uses charge, slam, and summon skills
- Spawns zombie minions during summon
- Gives larger score and EXP rewards
- Notifies `Main` when defeated

### 3.5 [`scripts/bullet.gd`](./scripts/bullet.gd)

Role:
- Player projectile logic

Key behavior:
- Moves in a normalized direction
- Can be configured with `configure(...)`
- Carries bullet speed, damage, and lifetime
- Damages zombies on collision

### 3.6 [`scripts/exp_gem.gd`](./scripts/exp_gem.gd)

Role:
- EXP pickup logic

Key behavior:
- Stores `exp_value`
- Floats visually
- Moves toward the player when close
- Collects on contact or when close enough
- Calls `Main.add_exp(exp_value)`

### 3.7 [`scripts/game_over_menu.gd`](./scripts/game_over_menu.gd)

Role:
- Game over UI

Key behavior:
- Shows final score and level
- Emits `restart_pressed`

### 3.8 [`scripts/upgrade_menu.gd`](./scripts/upgrade_menu.gd)

Role:
- Level-up upgrade UI

Key behavior:
- Displays 3 upgrade choices
- Emits `upgrade_selected`
- Runs while the game is paused

## 4. Gameplay Flow

1. Game starts in `Main`
2. Player spawns
3. Spawn timer creates zombies around the player
4. Zombie types are selected based on level
5. Player auto-shoots the nearest zombie
6. Bullets damage zombies and apply knockback
7. Zombies chase the player and deal damage in range
8. Zombie death triggers:
   - score increase
   - EXP gain
   - EXP gem spawn
   - death effect spawn
9. Boss waves on wave 5 and wave 10 spawn Brute Zombie
10. Boss can charge, slam, and summon minions
11. EXP gems move toward the player when close
12. When EXP reaches the level threshold:
   - game pauses
   - upgrade menu opens
   - player picks one upgrade
13. When player HP reaches 0:
   - player emits `died`
   - `Main` stops spawning
   - game over menu appears

## 5. Current Features

- Player movement
- Auto-target shooting
- Data-driven weapon system with pistol, shotgun, SMG, and rifle
- Bullet damage, speed, spread, projectile count, and lifetime are weapon-based
- Player HP, damage, speed, and firing rate are upgradeable
- Zombie types: normal, fast, tank
- Boss waves: mini boss on wave 5, full boss on wave 10
- Boss skills: charge, slam, summon
- Zombie score and EXP rewards
- Zombie knockback
- Zombie attack cooldown
- EXP gems attract to player
- Level-up upgrade menu
- Game over menu with restart
- HUD laid out in the top-left area

## 6. Input

Configured in `project.godot`:

- `move_up`: `W` or Up Arrow
- `move_down`: `S` or Down Arrow
- `move_left`: `A` or Left Arrow
- `move_right`: `D` or Right Arrow

## 7. Collision Layers

Current 2D physics layers:

- Layer 1: Player
- Layer 2: Zombie
- Layer 3: Bullet
- Layer 4: Item
- Layer 5: EnemyAttack

## 8. Technical Notes

- The project uses placeholder visuals with `Polygon2D`.
- Most gameplay objects use groups like `player` and `zombie`.
- `Main` is the central gameplay coordinator.
- `Player` no longer restarts the scene directly when dying.
- `Main` now owns the restart and game over flow.

## 9. Suggested Next Extensions

- Add more zombie types
- Add more upgrade choices
- Add bullet piercing or critical hits
- Improve HUD styling
- Add audio effects
- Add waves or difficulty scaling over time
