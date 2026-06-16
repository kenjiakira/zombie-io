# ZombieIO Architecture

## 1. Mục tiêu kiến trúc

ZombieIO được tổ chức theo kiểu scene-driven của Godot:
- Mỗi thực thể gameplay là một scene riêng.
- Logic chia theo trách nhiệm rõ ràng: điều phối, AI, đạn, vật phẩm, UI.
- Giao tiếp giữa các phần chủ yếu qua signal và method công khai.

Thiết kế hiện tại ưu tiên:
- Dễ mở rộng thêm zombie, boss, weapon, upgrade, hiệu ứng.
- Tách UI khỏi logic gameplay.
- Giữ `Main` làm trung tâm điều phối, còn entity tự xử lý hành vi của mình.

## 2. Cấu trúc thư mục

- `scenes/`: scene Godot cho player, zombie, boss, bullet, gem, effect, drop.
- `scripts/`: gameplay logic và UI logic.
- `project.godot`: input, physics layers, project settings.

## 3. Tổng quan runtime

Luồng chạy chính:
1. `main.tscn` được load.
2. `Main` khởi tạo player, wave manager và UI.
3. `WaveManager` bắt đầu wave đầu tiên.
4. `WaveManager` yêu cầu spawn zombie hoặc boss.
5. `Main` tạo entity từ PackedScene và gắn vào world.
6. Player tự động tìm mục tiêu gần nhất và bắn.
7. Bullet trúng zombie, hiện damage number và hit flash.
8. Zombie/Boss bị knockback, nhận sát thương, chết hoặc kích hoạt explode.
9. Khi có EXP đủ ngưỡng, game tạm dừng và mở upgrade menu.
10. Khi player chết, game over menu xuất hiện.

## 4. Scene tree chính

`scenes/main.tscn` là root scene của game. Cấu trúc hiện tại:
- `Main` `Node2D`
  - `Player`
  - `WaveManager`
  - `ZombieContainer`
  - `CanvasLayer`
    - `HPBar`
    - `HPText`
    - `WeaponLabel`
    - `WaveLabel`
    - `TimeLabel`
    - `EnemiesLabel`
    - `ScoreLabel`
    - `LevelLabel`
    - `UpgradeMenu`
    - `GameOverPanel`

Player scene hiện có `Camera2D` gắn kèm để hỗ trợ shake khi boss chết.

## 5. Các lớp trách nhiệm

### 5.1 `scripts/main.gd`

Vai trò:
- Điều phối gameplay cấp cao.
- Tạo zombie/boss theo yêu cầu của `WaveManager`.
- Quản lý score, EXP, level, upgrade points.
- Đồng bộ UI.
- Xử lý game over, restart và camera shake.

Điểm đáng chú ý:
- `Main` không xử lý AI hay combat chi tiết.
- `Main` chỉ kết nối và truyền sự kiện giữa các subsystem.
- `Main` có `shake_camera(strength, duration)` để boss death tạo rung nhẹ.

### 5.2 `scripts/wave_manager.gd`

Vai trò:
- Điều khiển nhịp wave.
- Quyết định số lượng enemy, tốc độ spawn, tỷ lệ loại zombie.
- Phát tín hiệu yêu cầu spawn zombie hoặc boss.

Điểm đáng chú ý:
- Wave được mô tả bằng config trả về từ `_get_wave_config()`.
- Mỗi wave có thể có boss riêng.
- Hiện wave config đã có thêm `exploder`.
- Khi hết quái và hết lượt spawn, wave tiếp theo được kích hoạt sau thời gian nghỉ.

### 5.3 `scripts/player.gd`

Vai trò:
- Điều khiển người chơi.
- Tự động tìm mục tiêu gần nhất và bắn.
- Quản lý weapon system và upgrade weapon hiện tại.
- Phát signal khi HP thay đổi, khi chết, và khi đổi weapon.

Weapon system:
- Weapon mặc định: `pistol`.
- Weapon hiện có: `pistol`, `shotgun`, `smg`, `rifle`.
- Mỗi weapon có các tham số:
  - `shoot_rate`
  - `bullet_speed`
  - `bullet_damage`
  - `bullet_life_time`
  - `projectile_count`
  - `spread_degrees`

### 5.4 `scripts/bullet.gd`

Vai trò:
- Đạn của player.
- Bay theo hướng đã cấu hình.
- Gây damage cho zombie khi va chạm.
- Spawn damage number tại vị trí zombie bị trúng.

Điểm đáng chú ý:
- Bullet nhận cấu hình qua `configure(...)`.
- Bullet tự hủy sau `life_time`.
- Bullet hỗ trợ crit nhẹ qua `critical_chance`.

### 5.5 `scripts/damage_number.gd`

Vai trò:
- Hiển thị số damage bay lên từ đầu zombie.

Hành vi:
- Spawn tại vị trí zombie.
- Chỉ pop nhẹ và fade out tại chỗ.
- Tự xóa sau `0.5s`.
- Có style riêng cho crit.

### 5.6 `scripts/zombie.gd`

Vai trò:
- Điều khiển zombie thường và các biến thể zombie.
- Chạy AI truy đuổi player.
- Tự attack khi vào phạm vi.
- Chết thì sinh reward và notify hệ thống.

Các loại zombie hiện có:
- `normal`
- `fast`
- `tank`
- `exploder`
- `mini_boss`
- `boss`

Mỗi loại có bộ chỉ số riêng:
- speed
- max HP
- damage
- EXP reward
- score reward
- knockback
- attack cooldown
- attack range
- xác suất rơi weapon

Zombie death flow:
- Spawn death effect.
- Spawn death burst nhỏ.
- Cộng score cho `Main`.
- Cộng EXP cho `Main`.
- Báo cho `WaveManager`.
- Spawn EXP gem.
- Có thể rơi weapon drop.

Exploder Zombie:
- Chạy nhanh tới player.
- Khi đủ gần sẽ self-destruct.
- Gây damage vùng nhỏ.
- Có hit flash, knockback và burst riêng.

### 5.7 `scripts/brute_boss.gd`

Vai trò:
- Boss AI cho Brute Zombie.
- Dùng state machine đơn giản để chuyển giữa chase, charge, slam, summon, recover.

Hành vi chính:
- `chase`: đuổi theo player.
- `charge`: lao nhanh và gây damage khi chạm.
- `slam_windup`: nạp đòn trước khi gây sát thương diện rộng.
- `recover`: hồi chiêu ngắn sau hành động.

Boss còn có thể:
- summon minion theo `summon_types`.
- rơi weapon drop giá trị cao hơn.
- rơi rare drop.
- thưởng score/EXP lớn hơn zombie thường.
- gây camera shake khi chết.
- spawn death effect lớn hơn.
- spawn death burst lớn hơn.

### 5.8 `scripts/exp_gem.gd`

Vai trò:
- Vật phẩm EXP.
- Tự hút về player khi ở gần.
- Tự thu thập khi chạm hoặc đủ gần.

Điểm đáng chú ý:
- Gem không tự tính EXP, chỉ gọi `Main.add_exp(exp_value)`.

### 5.9 `scripts/death_effect.gd`

Vai trò:
- Hiệu ứng nổ khi zombie hoặc boss chết.

Điểm đáng chú ý:
- Có biến thể nhẹ cho zombie thường.
- Có biến thể lớn, màu cam hơn cho boss.

### 5.10 `scripts/death_burst.gd`

Vai trò:
- Burst particle nhỏ tạo cảm giác combat có lực hơn.

Điểm đáng chú ý:
- Zombie thường dùng burst nhỏ màu xanh.
- Boss dùng burst lớn màu cam.
- Exploder có thể dùng màu cam riêng.

### 5.11 `scripts/rare_drop.gd`

Vai trò:
- Vật phẩm drop hiếm từ boss.
- Cho cảm giác “boss chết có phần thưởng xứng đáng”.

### 5.12 `scripts/upgrade_menu.gd`

Vai trò:
- Hiển thị lựa chọn upgrade khi lên level.
- Phát signal `upgrade_selected`.

### 5.13 `scripts/game_over_menu.gd`

Vai trò:
- Hiển thị màn hình kết thúc game.
- Phát signal `restart_pressed`.

## 6. Dòng chảy dữ liệu

### 6.1 Spawn enemy

1. `WaveManager` quyết định loại enemy cần spawn.
2. `WaveManager` phát `spawn_zombie_requested` hoặc `spawn_boss_requested`.
3. `Main` nhận signal và gọi scene tương ứng.
4. Enemy được add vào `ZombieContainer`.
5. `WaveManager` được notify rằng enemy đã spawn.

### 6.2 Combat

1. Player tìm zombie gần nhất.
2. Player bắn bullet theo weapon hiện tại.
3. Bullet chạm zombie và gây damage.
4. Zombie nhận sát thương, nháy trắng và bị knockback.
5. Damage number hiện lên trên đầu zombie.
6. Nếu HP về 0, zombie chết và trả reward.

### 6.3 Exploder flow

1. `Exploder Zombie` chạy tới gần player.
2. Khi vào khoảng cách nổ, nó self-destruct.
3. Gây damage vùng nhỏ.
4. Spawn hiệu ứng nổ và burst.
5. Cộng score/EXP như kill bình thường.

### 6.4 Boss death flow

1. Boss về 0 HP.
2. Spawn death effect lớn.
3. Spawn burst lớn.
4. Camera rung nhẹ.
5. Rơi rare drop.
6. Cộng score lớn hơn.
7. Cộng EXP và weapon drop như bình thường.

### 6.5 Level up

1. EXP tăng qua zombie hoặc gem.
2. Khi đạt ngưỡng `exp_to_next_level`, `Main.level_up()` chạy.
3. Game cộng `upgrade_points`.
4. `UpgradeMenu` cập nhật số điểm.
5. Người chơi chọn upgrade, `Main` áp hiệu ứng vào player.

### 6.6 Game over

1. Player phát `died`.
2. `Main` hiển thị game over menu.
3. Game bị pause.
4. Người chơi bấm restart.
5. `Main` unpause và reload scene.

## 7. Trạng thái hiện tại của hệ thống

### 7.1 Gameplay đã có

- Di chuyển top-down.
- Auto-shoot nearest target.
- Weapon system với nhiều loại súng.
- Zombie nhiều biến thể.
- Exploder Zombie tự nổ khi áp sát.
- Boss có state machine và skill riêng.
- Damage number khi trúng đạn.
- Hit flash và knockback rõ hơn.
- Death effect và death burst.
- EXP gems hút về player.
- Level-up và upgrade menu.
- Game over và restart.
- HUD hiển thị HP, weapon, wave, time, enemies, score, level.

### 7.2 Kỹ thuật hiện tại

- Dùng `groups` để tìm player và zombie.
- Dùng `signal` để giảm coupling giữa scene.
- Dùng `PackedScene` để spawn động.
- Dùng placeholder visuals bằng `Polygon2D`.
- `Main` là orchestrator chính.

## 8. Collision Layers

Theo cấu hình hiện tại:
- Layer 1: Player
- Layer 2: Zombie
- Layer 3: Bullet
- Layer 4: Item
- Layer 5: EnemyAttack

## 9. Input

Các action trong `project.godot`:
- `move_up`: `W` hoặc Up Arrow
- `move_down`: `S` hoặc Down Arrow
- `move_left`: `A` hoặc Left Arrow
- `move_right`: `D` hoặc Right Arrow

## 10. Điểm mở rộng tốt

Kiến trúc này phù hợp để mở rộng theo các hướng:
- Thêm zombie type mới bằng data table.
- Thêm boss mới bằng `PackedScene` và config riêng.
- Tách weapon library ra data file nếu muốn cân bằng dễ hơn.
- Tách wave config ra resource để chỉnh difficulty linh hoạt hơn.
- Thêm audio, VFX, screen shake, hit stop và UI polish mà không phải sửa nhiều core logic.

## 11. Định hướng V5

V4 đã có core loop ổn. Mục tiêu của V5 là biến game từ một demo gameplay chạy được thành một game có thể mở rộng nội dung nhanh.

### 11.1 Mục tiêu của V5

- Tách logic theo domain rõ ràng hơn.
- Giảm phụ thuộc giữa gameplay, UI, VFX, audio, data.
- Thêm content mới mà không phải sửa nhiều file lõi.
- Chuẩn bị nền cho save/load, balance tuning và thêm mode mới.

### 11.2 Cấu trúc thư mục đề xuất

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

### 11.3 Ý nghĩa của từng lớp mới

- `core/`: chứa vòng đời game, state toàn cục và save/load.
- `managers/`: mỗi manager chỉ lo một domain rõ ràng, ví dụ spawn, wave, VFX, audio.
- `player/`: tách điều khiển di chuyển khỏi weapon logic.
- `enemies/`: gom AI, stats và boss logic vào một cụm dễ mở rộng.
- `projectiles/`: mọi thứ bay hoặc gây sát thương theo kiểu đạn.
- `items/`: loot, gem, drop, rare reward.
- `ui/`: HUD và các màn hình UI tách biệt.
- `data/`: data-driven balance layer, giúp thêm content mà ít sửa code.
- `resources/`: nơi lưu dữ liệu cân bằng theo từng nhóm nội dung.

### 11.4 Quy tắc refactor nên theo

- Scene không nên tự gọi sâu sang nhau nếu có thể đi qua manager.
- Stats và balance nên nằm ở data/resource, không hardcode rải rác.
- VFX, audio và UI nên là hệ phụ trợ, không chen vào core combat.
- Player và enemy nên giữ logic hành vi riêng, còn spawn/reward đi qua manager.

### 11.5 Lợi ích thực tế

- Thêm zombie mới chỉ cần thêm dữ liệu và scene.
- Thêm boss mới không phải sửa `Main` quá nhiều.
- Cân bằng game nhanh hơn vì số liệu nằm tập trung.
- Dễ thêm event, mode, perk, weapon và wave mới.
- Dễ test từng phần vì trách nhiệm đã tách rõ.

## 12. Kết luận

Đây là một kiến trúc game nhỏ gọn, thiên về data-driven vừa đủ:
- `Main` điều phối.
- `WaveManager` kiểm soát nhịp game.
- `Player`, `Zombie`, `Boss`, `Bullet`, `EXP Gem` tự xử lý hành vi của mình.
- UI chỉ lắng nghe và hiển thị.

Với cấu trúc này, bạn có thể mở rộng nội dung khá nhanh mà không phải đụng nhiều vào core loop.
