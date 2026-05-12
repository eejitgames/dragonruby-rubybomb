require "app/lowrez_emulation.rb"

class Game < LowrezGame
  FONT = "fonts/lowrez.ttf"
  TILE = 8
  LAST_WAVE = 9
  HIGH_SCORE_FILE = "data/highscore.txt"
  POWERUP_WAVES = [3, 6, 8]
  POWERUP_CHANCE_WAVES = [2, 4, 5, 7]
  MAX_SHOT_POWER = 4
  PICKUP_SPRITES = { heart: 13, powerup: 100 }
  ENEMY_BULLET_ANI = [32, 33, 34, 33]
  MAX_ENEMY_FIRE_SFX_PER_FRAME = 2
  BOSS_FOUR_ANGLES = [0, 0, 0.25, 0.5, 0.75]
  BLINK_COLORS = [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 7, 7, 6, 6, 5]
  WHITE = [255, 255, 255]

  PALETTE = [
    [0, 0, 0], [29, 43, 83], [126, 37, 83], [0, 135, 81],
    [171, 82, 54], [95, 87, 79], [194, 195, 199], [255, 241, 232],
    [255, 0, 77], [255, 163, 0], [255, 236, 39], [0, 228, 54],
    [41, 173, 255], [131, 118, 156], [255, 119, 168], [255, 204, 170]
  ]
  CIRCLE_OUTLINES = {}
  CIRCLE_SPANS = {}

  WAVE_MAPS = {
    1 => { attack: 80, fire: 20, rows: [
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0]
    ] },
    2 => { attack: 80, fire: 20, rows: [
      [1, 1, 2, 2, 1, 1, 2, 2, 1, 1],
      [1, 1, 2, 2, 1, 1, 2, 2, 1, 1],
      [1, 1, 2, 2, 2, 2, 2, 2, 1, 1],
      [1, 1, 2, 2, 2, 2, 2, 2, 1, 1]
    ] },
    3 => { attack: 70, fire: 20, rows: [
      [1, 1, 2, 2, 1, 1, 2, 2, 1, 1],
      [1, 1, 2, 2, 2, 2, 2, 2, 1, 1],
      [2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
      [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
    ] },
    4 => { attack: 70, fire: 15, rows: [
      [3, 3, 0, 1, 1, 1, 1, 0, 3, 3],
      [3, 3, 0, 1, 1, 1, 1, 0, 3, 3],
      [3, 3, 0, 1, 1, 1, 1, 0, 3, 3],
      [3, 3, 0, 1, 1, 1, 1, 0, 3, 3]
    ] },
    5 => { attack: 70, fire: 15, rows: [
      [3, 1, 3, 1, 2, 2, 1, 3, 1, 3],
      [1, 3, 1, 2, 1, 1, 2, 1, 3, 1],
      [3, 1, 3, 1, 2, 2, 1, 3, 1, 3],
      [1, 3, 1, 2, 1, 1, 2, 1, 3, 1]
    ] },
    6 => { attack: 60, fire: 10, rows: [
      [2, 2, 2, 0, 4, 0, 0, 2, 2, 2],
      [2, 2, 0, 0, 0, 0, 0, 0, 2, 2],
      [1, 1, 0, 1, 1, 1, 1, 0, 1, 1],
      [1, 1, 0, 1, 1, 1, 1, 0, 1, 1]
    ] },
    7 => { attack: 60, fire: 10, rows: [
      [3, 3, 0, 1, 1, 1, 1, 0, 3, 3],
      [4, 0, 0, 2, 2, 2, 2, 0, 4, 0],
      [0, 0, 0, 2, 1, 1, 2, 0, 0, 0],
      [1, 1, 0, 1, 1, 1, 1, 0, 1, 1]
    ] },
    8 => { attack: 50, fire: 10, rows: [
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [3, 3, 1, 1, 1, 1, 1, 1, 3, 3],
      [3, 3, 2, 2, 2, 2, 2, 2, 3, 3],
      [3, 3, 2, 2, 2, 2, 2, 2, 3, 3]
    ] },
    9 => { attack: 60, fire: 20, rows: [
      [0, 0, 0, 0, 5, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    ] }
  }

  def initialize
    super(w: 256, h: 128)
    @highscore = load_highscore
    @version = "v2"
    @buttons = {}
    @pressed = {}
    @released = true
    @tick_skip = 0
    @time = 0
    @blink_frame = 0
    @shake = 0
    @flash = 0
    @sprite_paths = {}
    @cheatmode = false
    @ruby_cheat_armed = false
    @wave_cheat_armed = false
    show_start
  end

  def tick
    read_inputs
    @advanced_frame = false
    @effects_frame = false
    @tick_skip += 1
    if @tick_skip >= 2
      @tick_skip = 0
      @advanced_frame = true
      calc
      @pressed.clear
    else
      @effects_frame = true
    end
    render
  end

  def calc
    @time += 1
    @blink_frame += 1

    case @mode
    when :start then update_start
    when :wave then update_wave_intro
    when :game then update_game
    when :over, :win then update_finish
    end
  end

  def show_start
    @mode = :start
    # PICO-8 sound placeholder: music(7)
    @peeker_x = center_x
    make_stars
    clear_playfield
  end

  def start_game
    @time = 0
    @wave = 0
    @score = 0
    @new_highscore = false
    @lives = 4
    @cherries = 0
    @invulnerable = 0
    @shot_power = 1
    @powerup_dropped_this_wave = false
    @bullet_timer = 0
    @muzzle = 0
    @flame_sprite = 5
    @flame_timer = 0
    @next_fire = 0
    @enemy_fire_sfx_frame = -1
    @enemy_fire_sfx_count = 0
    @attack_frequency = 60
    @fire_frequency = 20
    @ship = sprite(x: center_x - 4, y: 90, spr: 2)
    make_stars
    clear_playfield
    next_wave
  end

  def clear_playfield
    @player_bullets = []
    @enemy_bullets = []
    @enemies = []
    @pickups = []
    @particles = []
    @shockwaves = []
    @floaters = []
  end

  def update_start
    animate_stars(0.4)
    @peeker_x = center_x - 34 + Numeric.rand(61) if p8_sin(seconds / 3.5) > 0.5
    wait_for_release_then_start
  end

  def update_wave_intro
    update_game
    @wave_time -= 1
    return unless @wave_time <= 0

    @mode = :game
    spawn_wave
  end

  def update_finish
    return if @time < @lockout

    @released = true unless action_down?
    return unless @released && action_pressed?

    @released = false
    show_start
  end

  def load_highscore
    (DR.read_file(HIGH_SCORE_FILE) || "0").to_i
  end

  def save_highscore
    @highscore = @score
    @new_highscore = true
    DR.write_file(HIGH_SCORE_FILE, @highscore.to_s)
  end

  def wait_for_release_then_start
    @released = true unless action_down?
    return unless @released && action_pressed?

    @released = false
    start_game
  end

  def update_game
    update_ship
    update_objects
    update_enemies
    handle_collisions
    return finish_game(:over) if @lives <= 0

    schedule_enemy_actions if @mode == :game
    animate_stars(@mode == :wave ? 2 : 1)
    @flame_timer += 1
    if @flame_timer >= 2
      @flame_timer = 0
      @flame_sprite = @flame_sprite >= 9 ? 5 : @flame_sprite + 1
    end
    @muzzle -= 1 if @muzzle > 0

    if @mode == :game && @enemies.empty?
      @enemy_bullets.clear
      next_wave
    end
  end

  def update_ship
    return unless @ship

    @ship.sx = inputs.left_right * 2
    @ship.sy = -inputs.up_down * 2
    @ship.spr = @ship.sx < 0 ? 1 : (@ship.sx > 0 ? 3 : 2)

    if pressed?(:bomb)
      if @cherries > 0
        cherry_bomb
      else
        sfx("ruby_empty.wav", 1.0)
        @muzzle = 2
      end
      @cherries = 0 if @cherries > 0
    end

    if (pressed?(:fire) || down?(:fire)) && @bullet_timer <= 0 && @player_bullets.length < player_bullet_cap
      sfx("fire.wav", 0.1)
      fire_player_shots
      @muzzle = 5
      @bullet_timer = 4
    end

    @bullet_timer -= 1
    move(@ship)
    @ship.x = @ship.x.clamp(0, @w - 8)
    @ship.y = @ship.y.clamp(0, 120)
  end

  def fire_player_shots
    if @shot_power >= 4
      player_shot(0, 0, spr: 17, dmg: 3)
      player_shot(-3, -0.8)
      player_shot(5, 0.8)
    elsif @shot_power >= 3
      player_shot(1)
      player_shot(-3, -0.8)
      player_shot(5, 0.8)
    elsif @shot_power >= 2
      player_shot(-3)
      player_shot(5)
    else
      player_shot(1)
    end
  end

  def player_bullet_cap
    return 12 if @shot_power >= 3

    @shot_power >= 2 ? 8 : 4
  end

  def player_shot(x_offset, sx = 0, spr: 16, dmg: 1)
    @player_bullets << sprite(x: @ship.x + x_offset, y: @ship.y - 3, sx: sx, sy: -4, spr: spr, colw: 6, dmg: dmg, smooth: true)
  end

  def update_objects
    update_array(@player_bullets) { |bullet| move(bullet); bullet.y < -8 }
    update_array(@enemy_bullets) { |bullet| move(bullet); animate(bullet); outside_screen?(bullet) }
    update_array(@pickups) { |pickup| move(pickup); pickup.y > @h }
    @invulnerable -= 1 if @invulnerable > 0
  end

  def update_enemies
    update_array(@enemies) do |enemy|
      update_enemy(enemy)
      animate(enemy)
      enemy.remove_me || (enemy.mission != :flyin && (enemy.y > @h || enemy.x < -16 || enemy.x > @w + 8))
    end
  end

  def update_array(list)
    Array.reject!(list) { |item| yield(item) }
  end

  def handle_collisions
    killed_enemies = []

    Array.each(@enemies) do |enemy|
      next if enemy.remove_me

      Array.each(@player_bullets) do |bullet|
        next if bullet.remove_me
        next if bullet.y >= enemy.y + enemy.colh
        next if bullet.y + bullet.colh <= enemy.y
        next unless collide?(enemy, bullet)

        bullet.remove_me = true
        small_shockwave(bullet.x + bullet.colw / 2.0, bullet.y + bullet.colh / 2.0)
        small_spark(enemy.x + 4, enemy.y + 4)
        enemy.hp -= bullet.dmg unless enemy.mission == :flyin
        enemy.flash = enemy.boss ? 5 : 2
        if enemy.hp <= 0
          sfx("explode.wav", 0.5)
          enemy.remove_me = true unless enemy.boss
          killed_enemies << enemy
        end
        break
      end
    end

    Array.each(killed_enemies) { |enemy| kill_enemy(enemy) }
    Array.reject!(@player_bullets) { |bullet| bullet.remove_me }

    Array.each(@player_bullets) do |bullet|
      next unless bullet.spr == 17

      Array.each(@enemy_bullets) do |enemy_bullet|
        next if enemy_bullet.remove_me
        next if enemy_bullet.y >= bullet.y + bullet.colh
        next if enemy_bullet.y + enemy_bullet.colh <= bullet.y
        next if enemy_bullet.x >= bullet.x + bullet.colw
        next if enemy_bullet.x + enemy_bullet.colw <= bullet.x
        next unless collide?(enemy_bullet, bullet)

        enemy_bullet.remove_me = true
        @score += 500
        pop_float(score_text(500), enemy_bullet.x, enemy_bullet.y)
        small_shockwave(enemy_bullet.x, enemy_bullet.y, 8)
      end
    end
    Array.reject!(@enemy_bullets) { |bullet| bullet.remove_me }

    unless cheatmode?
      ship_hit if @invulnerable <= 0 && Array.any?(@enemies) { |enemy| collide?(enemy, @ship) }
      ship_hit if @invulnerable <= 0 && Array.any?(@enemy_bullets) { |bullet| collide?(bullet, @ship) }
    end

    Array.each(@pickups) do |pickup|
      next unless collide?(pickup, @ship)

      pickup.remove_me = true
      collect_pickup(pickup)
    end
    Array.reject!(@pickups) { |pickup| pickup.remove_me }
  end

  def schedule_enemy_actions
    if @time > @next_fire
      pick_fire
      @next_fire = @time + @fire_frequency + Numeric.rand(@fire_frequency)
    end
    pick_attack if @time % @attack_frequency == 0
  end

  def finish_game(mode)
    @mode = mode
    @lockout = @time + 30
    save_highscore if @score > @highscore
    # PICO-8 sound placeholder: music(6) for game over, music(4) for win
  end

  def next_wave
    @wave += 1
    return finish_game(:win) if @wave > LAST_WAVE

    sfx("new_wave.wav", 0.2)
    @mode = :wave
    @wave_time = 80
    @powerup_dropped_this_wave = false
  end

  def goto_wave(wave)
    return if wave < 1 || wave > LAST_WAVE

    clear_playfield
    @wave = wave
    @mode = :wave
    @wave_time = 80
  end

  def spawn_wave
    wave = WAVE_MAPS[@wave]
    sfx(@wave == LAST_WAVE ? "boss_arrive.wav" : "formation.wav", 0.8)
    @attack_frequency = wave.attack
    @fire_frequency = wave.fire
    place_enemies(wave.rows)
  end

  def place_enemies(rows)
    Array.each_with_index(rows) do |row, row_index|
      Array.each_with_index(row) do |type, column|
        next if type == 0

        x = 24 + column * ((@w - 56).fdiv(row.length - 1))
        y = 4 + (row_index + 1) * 12
        spawn_enemy(type, x, y, (column + 1) * 3)
      end
    end
  end

  def spawn_enemy(type, x, y, wait)
    enemy = sprite(x: x - 16, y: y - 66, posx: x, posy: y, type: type, wait: wait,
                   mission: :flyin, anispd: 0.1, attack_anispd: 0.15)

    case type
    when 1
      enemy.merge!(spr: 21, hp: scaled_enemy_hp(3), ani: [21, 22, 23, 24], score: 100)
    when 2
      enemy.merge!(spr: 148, hp: scaled_enemy_hp(2), ani: [148, 149], score: 200)
    when 3
      enemy.merge!(spr: 184, hp: scaled_enemy_hp(4), ani: [184, 185, 186, 187], score: 300)
    when 4
      enemy.merge!(spr: 208, hp: 180, ani: [208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219], sprw: 2, sprh: 2, colw: 16, colh: 16, score: 500)
    when 5
      enemy.merge!(spr: 62, hp: 1600, ani: [64, 68, 72, 76], sprw: 4, sprh: 4,
                   colw: 32, colh: 32, x: center_x - 16, y: -32, posx: center_x - 16, posy: 25, boss: true)
    end

    @enemies << enemy
  end

  def scaled_enemy_hp(base_hp)
    return base_hp + 10 if @wave >= 6
    return base_hp + 5 if @wave >= 3

    base_hp
  end

  def update_enemy(enemy)
    if enemy.wait > 0
      enemy.wait -= 1
      return
    end

    case enemy.mission
    when :flyin
      enemy.x += (enemy.posx - enemy.x) / 7.0
      enemy.y += [(enemy.posy - enemy.y) / 7.0, enemy.boss ? 1 : 99].min
      return unless (enemy.y - enemy.posy).abs < 0.7

      enemy.x = enemy.posx
      enemy.y = enemy.posy
      enemy.mission = enemy.boss ? :boss1 : :protect
      enemy.shake = enemy.boss ? 20 : 0
      enemy.wait = enemy.boss ? 28 : 0
      enemy.phase_start = @time
    when :attack
      update_attacker(enemy)
    when :boss1 then boss_one(enemy)
    when :boss2 then boss_two(enemy)
    when :boss3 then boss_three(enemy)
    when :boss4 then boss_four(enemy)
    when :boss5 then boss_death(enemy)
    end
  end

  def update_attacker(enemy)
    case enemy.type
    when 1
      enemy.sy = 1.7
      enemy.sx = p8_sin(@time / 45.0)
      enemy.sx += 1 - enemy.x / 32 if enemy.x < 32
      enemy.sx -= (enemy.x - attacker_right_edge) / 32 if enemy.x > attacker_right_edge
    when 2
      enemy.sy = 2.5
      enemy.sx = p8_sin(@time / 20.0)
      enemy.sx += 1 - enemy.x / 32 if enemy.x < 32
      enemy.sx -= (enemy.x - attacker_right_edge) / 32 if enemy.x > attacker_right_edge
    when 3
      if enemy.sx == 0
        enemy.sy = @ship.y <= enemy.y ? 0 : 2
        enemy.sx = @ship.x < enemy.x ? -2 : 2 if enemy.sy == 0
      end
    when 4
      enemy.sy = enemy.y > 110 ? 1 : 0.35
      fire_spread(enemy, 8, 1.3, rand) if enemy.y <= 110 && @time % 25 == 0
    end
    move(enemy)
  end

  def pick_attack
    enemy = random_recent_enemy
    return unless enemy&.mission == :protect

    enemy.mission = :attack
    enemy.anispd = enemy.attack_anispd
    enemy.wait = 60
    enemy.shake = 60
  end

  def pick_fire
    big_enemy = nil
    Array.each(@enemies) do |enemy|
      next unless enemy.type == 4 && enemy.mission == :protect && rand < 0.5

      big_enemy = enemy
      break
    end
    return fire_spread(big_enemy, 12, 1.3, rand) if big_enemy

    enemy = random_recent_enemy
    return unless enemy&.mission == :protect

    case enemy.type
    when 4 then fire_spread(enemy, 12, 1.3, rand)
    when 2 then aimed_fire(enemy, 2)
    else fire(enemy, 0, 2)
    end
  end

  def random_recent_enemy
    count = [10, @enemies.length].min
    return nil if count <= 0

    @enemies[@enemies.length - 1 - Numeric.rand(count)]
  end

  def kill_enemy(enemy)
    if enemy.boss
      enemy.remove_me = false
      enemy.mission = :boss5
      enemy.phase_start = @time
      enemy.ghost = true
      @enemy_bullets.clear
      # PICO-8 sound placeholder: music(-1), sfx(51)
      return
    end

    @enemies.delete(enemy)
    explode(enemy.x + 4, enemy.y + 4)
    multiplier = enemy.mission == :attack ? 2 : 1
    score = enemy.score * multiplier
    @score += score
    pop_float(score_text(score), enemy.x + 4, enemy.y + 4)
    pickup_chance = enemy.mission == :attack ? 0.2 : 0.1
    if enemy.type == 4
      drop_pickup(enemy.x, enemy.y, rand < pickup_chance * 2 ? :heart : :ruby)
    elsif can_drop_powerup?
      drop_powerup(enemy.x, enemy.y)
    elsif rand < pickup_chance
      drop_pickup(enemy.x, enemy.y)
    elsif can_roll_powerup? && rand < 0.05
      drop_powerup(enemy.x, enemy.y)
    end
    pick_attack if enemy.mission == :attack && rand < 0.5
  end

  def can_drop_powerup?
    POWERUP_WAVES.include?(@wave) && @shot_power < MAX_SHOT_POWER && !@powerup_dropped_this_wave
  end

  def can_roll_powerup?
    POWERUP_CHANCE_WAVES.include?(@wave) && @shot_power < MAX_SHOT_POWER && !@powerup_dropped_this_wave
  end

  def drop_powerup(x, y)
    drop_pickup(x, y, :powerup)
    @powerup_dropped_this_wave = true
  end

  def drop_pickup(x, y, kind = :ruby)
    sprite_id = PICKUP_SPRITES.fetch(kind, 48)
    fall_speed = kind == :powerup ? 0.4 : 0.75
    @pickups << sprite(x: x, y: y, sy: fall_speed, spr: sprite_id, kind: kind)
  end

  def collect_pickup(pickup)
    return collect_heart(pickup) if pickup.kind == :heart
    return collect_powerup(pickup) if pickup.kind == :powerup

    @cherries += 1
    @score += 500
    ruby_bonus = @cherries >= 10
    earns_life = ruby_bonus && @lives < 4
    sfx("ruby.wav") unless earns_life
    pop_float(score_text(500), pickup.x + 4, pickup.y + 4) unless ruby_bonus
    small_shockwave(pickup.x + 4, pickup.y + 4, 14)
    return unless @cherries >= 10

    if earns_life
      @lives += 1
      pop_float("1up!", pickup.x + 4, pickup.y + 4)
      sfx("1up.wav", 0.8)
    else
      @score += 5000
      pop_float(score_text(5000), pickup.x + 4, pickup.y + 4)
    end
    @cherries = 0
  end

  def collect_heart(pickup)
    small_shockwave(pickup.x + 4, pickup.y + 4, 14)
    if @lives >= 4
      @score += 500
      pop_float(score_text(500), pickup.x + 4, pickup.y + 4)
      sfx("ruby.wav")
      return
    end

    @lives += 1
    pop_float("1up!", pickup.x + 4, pickup.y + 4)
    sfx("1up.wav", 0.8)
  end

  def collect_powerup(pickup)
    @shot_power = [@shot_power + 1, MAX_SHOT_POWER].min
    sfx("ruby.wav")
    @score += 999
    pop_float(score_text(999), pickup.x + 4, pickup.y + 4)
    small_shockwave(pickup.x + 4, pickup.y + 4, 14)
  end

  def sfx(sound, gain = 1.0)
    audio[rand] = {
      input: "sounds/#{sound}",
      x: 0.0, y: 0.0, z: 0.0,
      gain: gain,
      pitch: 1.0,
      paused: false,
      looping: false
    }
  end

  def enemy_fire_sfx
    if @enemy_fire_sfx_frame != @time
      @enemy_fire_sfx_frame = @time
      @enemy_fire_sfx_count = 0
    end

    return if @enemy_fire_sfx_count >= MAX_ENEMY_FIRE_SFX_PER_FRAME

    @enemy_fire_sfx_count += 1
    sfx("enemy_fire.wav", 0.5)
  end

  def fire(enemy, angle, speed)
    enemy_fire_sfx
    bullet = enemy_bullet
    bullet.x = enemy.x + 3
    bullet.y = enemy.y + 6
    bullet.x = enemy.x + 7 if enemy.type == 4
    bullet.y = enemy.y + 13 if enemy.type == 4
    bullet.x = enemy.x + 15 if enemy.boss
    bullet.y = enemy.y + 11 if enemy.boss
    bullet.sx = p8_sin(angle) * speed
    bullet.sy = p8_cos(angle) * speed
    enemy.flash = 4 unless enemy.boss
    @enemy_bullets << bullet
    bullet
  end

  def fire_spread(enemy, count, speed, base = 0)
    count.times { |i| fire(enemy, (i + 1).fdiv(count) + base, speed) }
  end

  def aimed_fire(enemy, speed)
    bullet = fire(enemy, 0, speed)
    dx = @ship.x + 4 - bullet.x
    dy = @ship.y + 4 - bullet.y
    length = Math.sqrt(dx * dx + dy * dy)
    return if length.zero?

    bullet.sx = dx / length * speed
    bullet.sy = dy / length * speed
  end

  def cherry_bomb(rubies = @cherries)
    sfx("ruby_bomb.wav", 1.0)
    spacing = 0.25 / (rubies * 2)
    (0..(rubies * 2)).each do |i|
      angle = 0.375 + spacing * i
      @player_bullets << sprite(x: @ship.x, y: @ship.y - 3, spr: 17, dmg: 3, smooth: true,
                                sx: p8_sin(angle) * 4, sy: p8_cos(angle) * 4)
    end
    big_shockwave(@ship.x + 3, @ship.y + 3)
    @shake = 5
    @muzzle = 5
    @invulnerable = 30
    @flash = 3
  end

  def boss_one(enemy)
    enemy.sx = -2 if enemy.sx == 0 || enemy.x >= boss_right_edge
    enemy.sx = 2 if enemy.x <= 3
    fire(enemy, 0, 2) if @time % 30 > 3 && @time % 3 == 0
    if enemy.phase_start + 240 < @time
      enemy.mission = :boss2
      enemy.phase_start = @time
      enemy.subphase = 1
    end
    move(enemy)
  end

  def boss_two(enemy)
    box_phase(enemy, :boss3, 1.5)
    aimed_fire(enemy, 1.5) if @time % 15 == 0
    move(enemy)
  end

  def boss_three(enemy)
    enemy.sx = -0.5 if enemy.sx == 0 || enemy.x >= boss_right_edge
    enemy.sx = 0.5 if enemy.x <= 3
    fire_spread(enemy, 8, 2, seconds / 2.0) if @time % 10 == 0
    if enemy.phase_start + 240 < @time
      enemy.mission = :boss4
      enemy.subphase = 1
      enemy.phase_start = @time
    end
    move(enemy)
  end

  def boss_four(enemy)
    box_phase(enemy, :boss1, 1.5, reverse: true)
    fire(enemy, BOSS_FOUR_ANGLES[enemy.subphase], 2) if @time % 12 == 0
    move(enemy)
  end

  def box_phase(enemy, next_mission, speed, reverse: false)
    enemy.subphase ||= 1
    case enemy.subphase
    when 1
      enemy.sx = reverse ? speed : -speed
      enemy.sy = 0
    when 2
      enemy.sx = 0
      enemy.sy = speed
    when 3
      enemy.sx = reverse ? -speed : speed
      enemy.sy = 0
    else
      enemy.sx = 0
      enemy.sy = -speed
    end
    enemy.subphase = 2 if enemy.subphase == 1 && ((reverse && enemy.x >= boss_box_right) || (!reverse && enemy.x <= 4))
    enemy.subphase = 3 if enemy.subphase == 2 && enemy.y >= boss_box_bottom
    enemy.subphase = 4 if enemy.subphase == 3 && ((reverse && enemy.x <= 4) || (!reverse && enemy.x >= boss_box_right))
    return unless enemy.subphase == 4 && enemy.y <= 25

    enemy.mission = next_mission
    enemy.phase_start = @time
    enemy.sy = 0
  end

  def boss_death(enemy)
    enemy.shake = 10
    enemy.flash = 10

    if @time % 8 == 0
      sfx("explode.wav", 0.6)
      explode(enemy.x + rand * 32, enemy.y + rand * 32)
      @shake = 2
    end

    if enemy.phase_start + 90 < @time && @time % 4 == 2
      sfx("explode.wav", 0.6)
      explode(enemy.x + rand * 32, enemy.y + rand * 32)
      @shake = 2
    end

    if enemy.phase_start + 180 < @time
      sfx("explode.wav", 0.6)
      @flash = 3
      @score += 10000
      pop_float(score_text(10000), enemy.x + 16, enemy.y + 8)
      big_explode(enemy.x + 16, enemy.y + 16)
      @shake = 15
      enemy.remove_me = true
    end
  end

  def ship_hit
    sfx("die.wav", 0.8)
    explode(@ship.x + 4, @ship.y + 4, true)
    @lives -= 1
    @shake = 12
    @invulnerable = 60
    @ship.x = center_x - 4
    @ship.y = 100
    @flash = 3
  end

  def animate(enemy)
    return unless enemy.ani

    enemy.aniframe += enemy.anispd
    enemy.aniframe = 0 if enemy.aniframe.floor >= enemy.ani.length
    enemy.spr = enemy.ani[enemy.aniframe.floor]
  end

  def move(object)
    object.x += object.sx
    object.y += object.sy
  end

  def collide?(a, b)
    return false if a.nil? || b.nil? || a.ghost || b.ghost

    a.x < b.x + b.colw &&
      a.x + a.colw > b.x &&
      a.y < b.y + b.colh &&
      a.y + a.colh > b.y
  end

  def outside_screen?(object)
    object.y > @h || object.x < -8 || object.x > @w || object.y < -8
  end

  def make_stars
    @stars = 75.map { { x: Numeric.rand(@w), y: Numeric.rand(@h), speed: rand * 1.5 + 0.5 } }
  end

  def animate_stars(speed = 1)
    Array.each(@stars) do |star|
      star.y += star.speed * speed
      star.y -= @h if star.y > @h
    end
  end

  def explode(x, y, blue = false)
    @particles << particle(x: x, y: y, radius: 10, blue: blue)
    20.times { @particles << particle(x: x, y: y, sx: rand * 6 - 3, sy: rand * 6 - 3, radius: 1 + rand * 4, maxage: 10 + Numeric.rand(10), blue: blue) }
    10.times { @particles << particle(x: x, y: y, sx: rand * 8 - 4, sy: rand * 8 - 4, radius: 1, maxage: 8 + Numeric.rand(10), blue: blue, spark: true) }
    big_shockwave(x, y)
  end

  def big_explode(x, y)
    explode(x, y)
    5.times { explode(x + rand * 24 - 12, y + rand * 24 - 12) }
  end

  def small_spark(x, y)
    @particles << particle(x: x, y: y, sx: (rand - 0.5) * 8, sy: (rand - 1) * 3, radius: 1 + rand * 4, maxage: 10 + Numeric.rand(10), spark: true)
  end

  def small_shockwave(x, y, color = 6)
    @shockwaves << { x: x, y: y, r: 3, target: 6, speed: 1, color: color }
  end

  def big_shockwave(x, y)
    @shockwaves << { x: x, y: y, r: 3, target: 25, speed: 3.5, color: 13 }
  end

  def pop_float(text, x, y)
    @floaters << { x: x, y: y, text: text, age: 0 }
  end

  def render
    @screen = lowrez_outputs
    clear_lowrez_screen(@flash > 0 ? 2 : 0)
    @flash -= 1 if @flash > 0 && @advanced_frame
    apply_shake

    case @mode
    when :start then render_start
    when :wave then render_wave_intro
    when :game then render_game
    when :over then render_game_over
    when :win then render_win
    end
  end

  def clear_lowrez_screen(color)
    r, g, b = PALETTE[color]
    @screen.background_color = [r, g, b]
  end

  def render_start
    render_stars
    label(@version, 1, 1, 1)
    draw_sprite(21, @peeker_x, 28 + p8_sin(seconds / 3.5) * 4)
    draw_sprite(312, center_x - 40, 30, 10.125, 1.75)
    centered_label("a cherry bomb remake", center_x, 55, 6)
    if @highscore > 0
      centered_label("highscore:", center_x, 63, 12)
      centered_label(score_text(@highscore), center_x, 69, 12)
    end
    centered_label("press z/x to start", center_x, 90, blink_color)
    centered_label("special thanks to lazydevsacademy!", center_x, 110, 6)
  end

  def render_wave_intro
    render_game
    text = @wave == LAST_WAVE ? "final wave!" : "wave #{@wave} of #{LAST_WAVE}"
    centered_label(text, center_x, 40, blink_color)
  end

  def render_game_over
    render_game
    centered_label("game over", center_x, 40, 8)
    centered_label("score:#{score_text(@score)}", center_x, 60, 12)
    centered_label("new highscore!", center_x, 66, @time % 4 < 2 ? 10 : 7) if @new_highscore
    centered_label("press z/x", center_x, 90, blink_color)
  end

  def render_win
    render_game
    centered_label("congratulations", center_x, 40, 12)
    centered_label("score:#{score_text(@score)}", center_x, 60, 12)
    centered_label("new highscore!", center_x, 66, @time % 4 < 2 ? 10 : 7) if @new_highscore
    centered_label("press z/x", center_x, 90, blink_color)
  end

  def render_game
    render_stars
    render_ship
    Array.each(@pickups) { |pickup| draw_sprite(pickup.spr, pickup.x, pickup.y) }
    Array.each(@enemies) { |enemy| render_enemy(enemy) }
    Array.each(@player_bullets) { |bullet| render_object(bullet) }
    render_muzzle
    render_shockwaves
    render_particles
    Array.each(@enemy_bullets) { |bullet| render_object(bullet) }
    render_floaters
    render_hud
  end

  def render_ship
    return unless @ship && @lives > 0
    return if @invulnerable > 0 && p8_sin(@time / 5.0) >= 0.1

    render_object(@ship)
    draw_sprite(@flame_sprite, @ship.x, @ship.y + 7)
  end

  def render_enemy(enemy)
    if enemy.flash > 0
      enemy.flash -= 1 if @advanced_frame
      draw_sprite(enemy.spr, enemy.x, enemy.y, enemy.sprw, enemy.sprh, enemy.boss ? nil : 7)
    else
      render_object(enemy)
    end
  end

  def render_object(object)
    x = object.x
    y = object.y
    if object.smooth && @effects_frame && (@mode == :game || @mode == :wave)
      x += object.sx * 0.5
      y += object.sy * 0.5
    end
    if object.shake > 0
      object.shake -= 1 if @advanced_frame
      x += @time % 4 < 2 ? -1 : 1
    end
    x -= 2 if object.bulmode
    y -= 2 if object.bulmode
    draw_sprite(object.spr, x, y, object.sprw, object.sprh)
  end

  def render_muzzle
    return unless @muzzle > 0 && @ship

    filled_circle(@ship.x + 3, @ship.y - 2, @muzzle, 7)
    filled_circle(@ship.x + 4, @ship.y - 2, @muzzle, 7)
  end

  def render_stars
    Array.each(@stars) do |star|
      color = star.speed < 1 ? 1 : (star.speed < 1.5 ? 13 : 6)
      solid(star.x, star.y, 1, 1, color)
    end
  end

  def render_shockwaves
    Array.each(@shockwaves) { |wave| circle(wave.x, wave.y, wave.r, wave.color) }
    return unless @effects_frame

    update_array(@shockwaves) do |wave|
      wave.r += wave.speed
      wave.r > wave.target
    end
  end

  def render_particles
    Array.each(@particles) do |particle|
      next if particle.radius <= 0

      color = particle.blue ? blue_particle_color(particle.age) : red_particle_color(particle.age)
      if particle.spark || particle.radius < 1.5
        solid(particle.x, particle.y, 1, 1, particle.spark ? 7 : color)
      else
        filled_circle(particle.x, particle.y, particle.radius, color)
      end
    end
    return unless @effects_frame

    update_array(@particles) do |particle|
      particle.x += particle.sx
      particle.y += particle.sy
      particle.sx *= 0.85
      particle.sy *= 0.85
      particle.age += 1
      particle.radius -= 0.5 if particle.age > particle.maxage
      particle.radius <= 0
    end
  end

  def render_floaters
    Array.each(@floaters) { |floater| centered_label(floater.text, floater.x, floater.y, @time % 4 < 2 ? 8 : 7) }
    return unless @advanced_frame

    update_array(@floaters) do |floater|
      floater.y -= 0.5
      floater.age += 1
      floater.age > 60
    end
  end

  def render_hud
    label("score:#{score_text(@score)}", center_x - 24, 2, 12)
    4.times { |i| draw_sprite(@lives >= i + 1 ? 13 : 14, i * 8 + 1, 1) }
    draw_sprite(48, @w - 20, 1)
    label(@cherries.to_s, @w - 10, 2, 14)
  end

  def apply_shake
    @camera_x = 0
    @camera_y = 0
    return unless @shake > 0

    @camera_x = rand * @shake - @shake / 2.0
    @camera_y = rand * @shake - @shake / 2.0
    return unless @advanced_frame

    @shake = @shake > 10 ? @shake * 0.9 : @shake - 1
    @shake = 0 if @shake < 1
  end

  def draw_sprite(id, x, y, tiles_w = 1, tiles_h = 1, tint = nil)
    r, g, b = tint ? PALETTE[tint] : WHITE
    width = TILE * tiles_w
    height = TILE * tiles_h
    @screen.primitives << {
      x: draw_x(x),
      y: draw_y(y, height),
      w: width,
      h: height,
      path: sprite_path(id),
      r: r, g: g, b: b
    }
  end

  def solid(x, y, w, h, color)
    r, g, b = PALETTE[color]
    @screen.primitives << { x: draw_x(x), y: draw_y(y, h), w: w, h: h, path: :solid, r: r, g: g, b: b }
  end

  def circle(x, y, radius, color)
    Array.each(circle_outline(radius.ceil)) do |point|
      solid(x + point[0], y + point[1], 1, 1, color)
    end
  end

  def filled_circle(x, y, radius, color)
    Array.each(circle_spans(radius.ceil)) do |span|
      dy = span[0]
      half_width = span[1]
      solid(x - half_width, y + dy, half_width * 2 + 1, 1, color)
    end
  end

  def circle_spans(radius)
    CIRCLE_SPANS[radius] ||= ((-radius)..radius).map do |dy|
      [dy, Math.sqrt(radius * radius - dy * dy).floor]
    end
  end

  def circle_outline(radius)
    CIRCLE_OUTLINES[radius] ||= begin
      points = {}
      x = radius
      y = 0
      error = 1 - x
      while x >= y
        [[x, y], [y, x], [-y, x], [-x, y], [-x, -y], [-y, -x], [y, -x], [x, -y]].each { |point| points[point] = true }
        y += 1
        if error < 0
          error += 2 * y + 1
        else
          x -= 1
          error += 2 * (y - x) + 1
        end
      end
      points.keys
    end
  end

  def label(text, x, y, color)
    r, g, b = PALETTE[color]
    @screen.primitives << { x: draw_x(x), y: draw_point_y(y), text: text, size_px: 5, font: FONT, r: r, g: g, b: b }
  end

  def centered_label(text, x, y, color)
    label(text, (x - label_width(text) / 2.0).floor, y, color)
  end

  def label_width(text)
    @label_widths ||= {}
    @label_widths[text] ||= DR.calcstringbox(text, size_px: 5, font: FONT).first
  end

  def draw_x(x)
    x + @camera_x
  end

  def draw_y(y, height)
    @h - y - height + @camera_y
  end

  def draw_point_y(y)
    @h - y + @camera_y
  end

  def sprite_path(id)
    @sprite_paths[id] ||= "sprites/sprite_%03d.png" % id
  end

  def sprite(**attrs)
    result = {
      x: 0, y: 0, sx: 0, sy: 0,
      spr: 0, sprw: 1, sprh: 1,
      colw: 8, colh: 8,
      aniframe: 0, ani: nil, anispd: 0.4,
      flash: 0, shake: 0,
      bulmode: false, ghost: false, boss: false,
      smooth: false,
      remove_me: false,
      hp: 1, score: 0, dmg: 0,
      posx: 0, posy: 0, wait: 0,
      mission: nil, type: nil,
      phase_start: 0, subphase: 0
    }
    attrs.each { |key, value| result[key] = value }
    result
  end

  def particle(**attrs)
    result = { x: 0, y: 0, sx: 0, sy: 0, age: rand * 2, radius: 1, maxage: 0, blue: false, spark: false }
    attrs.each { |key, value| result[key] = value }
    result
  end

  def enemy_bullet
    {
      x: 0, y: 0, sx: 0, sy: 0,
      spr: 32, sprw: 1, sprh: 1,
      colw: 2, colh: 2,
      aniframe: 0, ani: ENEMY_BULLET_ANI, anispd: 0.5,
      flash: 0, shake: 0,
      bulmode: true, ghost: false, boss: false,
      smooth: false,
      remove_me: false,
      hp: 1, score: 0, dmg: 0,
      posx: 0, posy: 0, wait: 0,
      mission: nil, type: nil,
      phase_start: 0, subphase: 0
    }
  end

  def read_inputs
    key_held = inputs.keyboard.key_held
    key_down = inputs.keyboard.key_down

    @buttons[:bomb] = !!(key_held.z || key_held.j || key_held.space)
    @buttons[:fire] = !!(key_held.x || key_held.k || key_held.enter)
    @pressed[:bomb] ||= !!(key_down.z || key_down.j || key_down.space)
    @pressed[:fire] ||= !!(key_down.x || key_down.k || key_down.enter)
    if key_held.control && key_down.question_mark
      @cheatmode = !@cheatmode
      clear_cheat_arms unless @cheatmode
    end
    update_cheats(key_down) if @cheatmode
  end

  def action_down?
    down?(:bomb) || down?(:fire)
  end

  def action_pressed?
    pressed?(:bomb) || pressed?(:fire)
  end

  def down?(button)
    @buttons[button]
  end

  def pressed?(button)
    @pressed[button]
  end

  def cheatmode?
    @cheatmode
  end

  def update_cheats(key_down)
    update_ruby_cheat(key_down)
    update_wave_cheat(key_down)
  end

  def update_ruby_cheat(key_down)
    if key_down.r
      @ruby_cheat_armed = true
      @wave_cheat_armed = false
      return
    end
    return unless @ruby_cheat_armed

    amount = ruby_cheat_amount(key_down)
    return unless amount

    @cherries += amount
    @cherries = 9 if @cherries > 9
    @ruby_cheat_armed = false
  end

  def update_wave_cheat(key_down)
    if key_down.l
      @wave_cheat_armed = true
      @ruby_cheat_armed = false
      return
    end
    return unless @wave_cheat_armed

    wave = ruby_cheat_amount(key_down)
    return unless wave

    goto_wave(wave)
    @wave_cheat_armed = false
  end

  def clear_cheat_arms
    @ruby_cheat_armed = false
    @wave_cheat_armed = false
  end

  def ruby_cheat_amount(key_down)
    return 0 if key_down.zero
    return 1 if key_down.one
    return 2 if key_down.two
    return 3 if key_down.three
    return 4 if key_down.four
    return 5 if key_down.five
    return 6 if key_down.six
    return 7 if key_down.seven
    return 8 if key_down.eight
    return 9 if key_down.nine

    nil
  end

  def seconds
    @time / 30.0
  end

  def center_x
    @w.idiv(2)
  end

  def attacker_right_edge
    @w - 40
  end

  def boss_right_edge
    @w - 35
  end

  def boss_box_right
    @w - 37
  end

  def boss_box_bottom
    95
  end

  def p8_sin(value)
    -Math.sin(value * Math::PI * 2)
  end

  def p8_cos(value)
    Math.cos(value * Math::PI * 2)
  end

  def blink_color
    BLINK_COLORS[@blink_frame % BLINK_COLORS.length]
  end

  def score_text(value)
    value.to_s
  end

  def red_particle_color(age)
    return 8 if age > 10
    return 9 if age > 7
    return 10 if age > 5
    7
  end

  def blue_particle_color(age)
    return 13 if age > 10
    return 12 if age > 7
    return 6 if age > 5
    7
  end
end

DR.disable_framerate_warning!
DR.reset
