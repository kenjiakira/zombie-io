# ZombieIO - Kiến Trúc và Tính Năng Hiện Có

## 1. Tổng Quan

ZombieIO là một game 2D top-down trong Godot, nơi người chơi điều khiển nhân vật, tự động bắn đạn vào zombie gần nhất, tiêu diệt quái để nhận điểm và kinh nghiệm, sau đó tăng cấp để mạnh hơn.

Project hiện chia theo 2 phần chính:
- `scenes/`: chứa các scene của game
- `scripts/`: chứa logic gameplay cho từng đối tượng

## 2. Cấu Trúc Dự Án

### 2.1 Scene chính

- [`scenes/main.tscn`](./scenes/main.tscn)
  - Scene gốc của game
  - Chứa player, vùng sinh zombie, timer spawn, và UI

### 2.2 Scene nhân vật và đối tượng

- [`scenes/player.tscn`](./scenes/player.tscn)
  - Scene của người chơi
- [`scenes/zombie.tscn`](./scenes/zombie.tscn)
  - Scene của zombie
- [`scenes/bullet.tscn`](./scenes/bullet.tscn)
  - Scene của viên đạn
- [`scenes/exp_gem.tscn`](./scenes/exp_gem.tscn)
  - Scene viên kinh nghiệm rơi ra từ zombie
- [`scenes/death_effect.tscn`](./scenes/death_effect.tscn)
  - Hiệu ứng khi zombie chết

## 3. Kiến Trúc Script

### 3.1 [`scripts/main.gd`](./scripts/main.gd)

Vai trò:
- Điều phối game chính
- Spawn zombie theo timer
- Cập nhật UI
- Quản lý điểm, EXP, level

Chức năng chính:
- Lấy tham chiếu tới player, timer, UI
- Tạo zombie ở khoảng cách ngẫu nhiên quanh player
- Tăng điểm khi zombie chết
- Tăng EXP và xử lý level up

### 3.2 [`scripts/player.gd`](./scripts/player.gd)

Vai trò:
- Điều khiển người chơi
- Bắn đạn tự động
- Nhận sát thương

Chức năng chính:
- Di chuyển bằng `move_left`, `move_right`, `move_up`, `move_down`
- Xoay theo hướng đang di chuyển
- Phát tín hiệu `hp_changed`
- Phát tín hiệu `died`
- Tìm zombie gần nhất và bắn đạn vào mục tiêu đó
- Hiệu ứng rung/đổi màu khi bị đánh

### 3.3 [`scripts/zombie.gd`](./scripts/zombie.gd)

Vai trò:
- Logic AI của zombie

Chức năng chính:
- Tự tìm player trong group `player`
- Di chuyển về phía player
- Có knockback khi bị bắn
- Khi chết:
  - tạo death effect
  - cộng điểm cho `Main`
  - spawn EXP gem
  - tự xóa khỏi scene

### 3.4 [`scripts/bullet.gd`](./scripts/bullet.gd)

Vai trò:
- Logic viên đạn của player

Chức năng chính:
- Di chuyển theo vector `direction`
- Tự hủy sau một khoảng thời gian
- Khi chạm zombie thì gây damage và biến mất

### 3.5 [`scripts/exp_gem.gd`](./scripts/exp_gem.gd)

Vai trò:
- Logic của EXP gem

Chức năng chính:
- Lắc nhẹ bằng animation đơn giản
- Hút về phía player khi đứng gần
- Khi chạm player thì cộng EXP và tự hủy

### 3.6 [`scripts/death_effect.gd`](./scripts/death_effect.gd)

Vai trò:
- Hiệu ứng hình ảnh khi zombie chết

Chức năng chính:
- Tạo hình đơn giản bằng `Polygon2D`
- Tween scale và alpha
- Tự hủy sau khi animation kết thúc

## 4. Luồng Gameplay Hiện Tại

1. Game mở scene `Main`
2. Player xuất hiện
3. Timer trong `Main` định kỳ spawn zombie
4. Zombie chạy về phía player
5. Player tự động bắn đạn vào zombie gần nhất
6. Zombie bị trúng đạn mất máu và nhận knockback
7. Zombie chết sẽ:
   - tạo hiệu ứng chết
   - rơi EXP gem
   - cộng điểm
8. Player nhặt EXP gem để lên cấp
9. Khi đủ EXP:
   - level tăng
   - ngưỡng EXP tiếp theo tăng
   - speed của player tăng

## 5. Tính Năng Hiện Có

- Di chuyển người chơi bằng bàn phím
- Camera gắn theo player
- Player tự động bắn theo zombie gần nhất
- Zombie đuổi theo player
- Zombie có máu, chết và tạo hiệu ứng
- Zombie rơi EXP gem khi chết
- Hệ thống điểm số
- Hệ thống EXP và level up
- Tăng tốc độ player khi lên level
- Hiệu ứng visual đơn giản bằng `Polygon2D`
- Có group `player` và `zombie` để tìm mục tiêu

## 6. Input Hiện Có

Trong `project.godot`:

- `move_up`: `W` hoặc phím mũi tên lên
- `move_down`: `S` hoặc phím mũi tên xuống
- `move_left`: `A` hoặc phím mũi tên trái
- `move_right`: `D` hoặc phím mũi tên phải

## 7. Layer Va Chạm

Project đang đặt các layer vật lý 2D:

- Layer 1: Player
- Layer 2: Zombie
- Layer 3: Bullet
- Layer 4: Item
- Layer 5: EnemyAttack

## 8. Ghi Chú Kỹ Thuật

- Game đang dùng placeholder visuals bằng `Polygon2D`, chưa dùng sprite art thật.
- Nhiều đối tượng được điều khiển bằng `group` để tìm kiếm và tương tác nhanh.
- `Main` đóng vai trò trung tâm điều phối các hệ thống gameplay.

## 9. Hướng Mở Rộng Đề Xuất

- Thêm nhiều loại zombie
- Thêm hệ thống nâng cấp khi lên level
- Thêm UI đẹp hơn cho HP, Score, EXP
- Thêm âm thanh cho bắn, trúng đạn, nhặt EXP, chết
- Thêm menu chính, pause, game over
- Thêm spawn theo wave hoặc tăng độ khó theo thời gian

