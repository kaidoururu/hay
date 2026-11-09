extends Node2D
## Ядро игры: поле, копание, находки, уровни, лавка, смерть и победа.

var level := 1
var money := 0
var hay := 0

var health := GameConfig.HEALTH_BASE
var max_health := GameConfig.HEALTH_BASE
var stamina := GameConfig.STAMINA_BASE
var max_stamina := GameConfig.STAMINA_BASE
var regen := GameConfig.REGEN_BASE
var dig_power := 1
var luck := 1.0
var price_mult := 1.0

var up := {}
var field: Array = []
var needle := Vector2i(-1, -1)
var straws: Array = []
var notices: Array = []
var poisoned := false
var poison_left := 0.0
var inv_bandage := 1
var inv_antidote := 0
var state := "play"  # play | dead | win

var hud: CanvasLayer
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	for id in GameConfig.UPGRADE_ORDER:
		up[id] = 0
	hud = load("res://scripts/hud.gd").new()
	add_child(hud)
	new_game()


func _apply_upgrades() -> void:
	max_stamina = GameConfig.STAMINA_BASE + GameConfig.STAMINA_STEP * float(up["stamina"])
	regen = GameConfig.REGEN_BASE + float(up["regen"])
	dig_power = 1 + int(up["dig"])
	luck = 1.0 + 0.15 * float(up["luck"])
	price_mult = 1.0 + 0.25 * float(up["wallet"])
	max_health = GameConfig.HEALTH_BASE + 20.0 * float(up["health"])


func new_game() -> void:
	level = 1
	money = 0
	hay = 0
	poisoned = false
	poison_left = 0.0
	inv_bandage = 1
	inv_antidote = 0
	_apply_upgrades()
	health = max_health
	stamina = max_stamina
	build_field()
	hud.refresh()


func restart() -> void:
	state = "play"
	new_game()


# ---------------- Поле ----------------

func build_field() -> void:
	field.clear()
	needle = Vector2i(rng.randi_range(0, GameConfig.COLS - 1), rng.randi_range(0, GameConfig.ROWS - 1))
	for r in GameConfig.ROWS:
		for c in GameConfig.COLS:
			field.append({
				"shade": rng.randf_range(0.8, 1.05),
				"hays": rng.randi_range(GameConfig.STRAW_MIN, GameConfig.STRAW_MAX),
				"dug": false,
			})


func field_rect() -> Rect2:
	return Rect2(0, GameConfig.FIELD_TOP, GameConfig.COLS * GameConfig.CELL, GameConfig.ROWS * GameConfig.CELL)


func pos_center(c: int, r: int) -> Vector2:
	return Vector2(c * GameConfig.CELL + GameConfig.CELL / 2.0, GameConfig.FIELD_TOP + r * GameConfig.CELL + GameConfig.CELL / 2.0)


# ---------------- Ввод ----------------

func _unhandled_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
		tapped = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		tapped = true
	if not tapped:
		return
	if state != "play":
		restart()
		return
	handle_tap(pos)


func handle_tap(pos: Vector2) -> void:
	var rect := field_rect()
	if not rect.has_point(pos):
		return
	var c := int((pos.x - rect.position.x) / GameConfig.CELL)
	var r := int((pos.y - rect.position.y) / GameConfig.CELL)
	dig_cell(r, c)


# ---------------- Копание ----------------

func dig_cell(r: int, c: int) -> void:
	var cell: Dictionary = field[r * GameConfig.COLS + c]
	if cell["dug"]:
		return
	if stamina < 1.0:
		notice("Силы на нуле — передохните", pos_center(c, r))
		return
	stamina -= 1.0
	var took := mini(dig_power, int(cell["hays"]))
	cell["hays"] = int(cell["hays"]) - took
	hay += took
	spawn_straws(pos_center(c, r))
	roll_items(c, r)
	if int(cell["hays"]) <= 0:
		cell["dug"] = true
		if Vector2i(c, r) == needle:
			notice("Игла найдена!", Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H / 2.0))
			next_level()
	hud.refresh()


func roll_items(c: int, r: int) -> void:
	var roll := rng.randf()
	var acc := GameConfig.P_COIN * luck
	if roll < acc:
		var n := rng.randi_range(1, 3)
		money += n
		notice("+%d монет" % n, pos_center(c, r))
		return
	acc += GameConfig.P_STONE
	if roll < acc:
		notice("Камень — пусто", pos_center(c, r))
		return
	acc += GameConfig.P_PLANT * luck
	if roll < acc:
		if rng.randf() < GameConfig.PLANT_POISON_CHANCE:
			poisoned = true
			poison_left = GameConfig.POISON_TIME
			notice("Ядовитое растение!", pos_center(c, r))
		else:
			hay += 2
			notice("Растение: +2 сена", pos_center(c, r))
		return
	acc += GameConfig.P_ANIMAL * luck
	if roll < acc:
		var dmg := GameConfig.ANIMAL_DAMAGE_BASE + 2 * (level - 1)
		health -= dmg
		notice("Укус! -%d здоровья" % dmg, pos_center(c, r))
		if rng.randf() < GameConfig.ANIMAL_POISON_CHANCE:
			poisoned = true
			poison_left = GameConfig.POISON_TIME
			notice("Вы отравлены!", pos_center(c, r))
		return
	acc += GameConfig.P_BANDAGE
	if roll < acc:
		inv_bandage += 1
		notice("Найден бинт", pos_center(c, r))
		return
	acc += GameConfig.P_ANTIDOTE
	if roll < acc:
		inv_antidote += 1
		notice("Найдено противоядие", pos_center(c, r))


# ---------------- Действия кнопок ----------------

func sell_hay() -> void:
	if state != "play":
		return
	if hay <= 0:
		notice("Сена нет", Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H - 260.0))
		return
	var gain := int(round(float(hay) * (1.0 + 0.25 * float(level - 1)) * price_mult))
	money += gain
	hay = 0
	notice("+%d монет за сено" % gain, Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H - 260.0))
	hud.refresh()


func use_bandage() -> void:
	if state != "play" or inv_bandage <= 0 or health >= max_health:
		return
	inv_bandage -= 1
	health = minf(health + GameConfig.BANDAGE_HEAL, max_health)
	notice("Бинт: +25 здоровья", Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H - 200.0))
	hud.refresh()


func use_antidote() -> void:
	if state != "play" or inv_antidote <= 0:
		return
	inv_antidote -= 1
	poisoned = false
	poison_left = 0.0
	notice("Отравление снято", Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H - 200.0))
	hud.refresh()


func buy_upgrade(id: String) -> void:
	var info: Dictionary = GameConfig.UPGRADES[id]
	var price := int(round(float(info["base"]) * pow(float(info["growth"]), float(up[id]))))
	if money < price:
		notice("Не хватает монет", Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H - 200.0))
		return
	money -= price
	up[id] = int(up[id]) + 1
	_apply_upgrades()
	if id == "health":
		health = minf(health + 20.0, max_health)
	hud.refresh()
	hud.refresh_shop()


func toggle_shop() -> void:
	if state != "play":
		return
	var open: bool = not hud.shop_root.visible
	hud.shop_root.visible = open
	if open:
		hud.refresh_shop()


func toggle_help() -> void:
	if state != "play":
		return
	hud.help_root.visible = not hud.help_root.visible


# ---------------- Уровни ----------------

func next_level() -> void:
	if level >= GameConfig.MAX_LEVEL:
		state = "win"
		hud.refresh()
		return
	level += 1
	max_stamina += GameConfig.STAMINA_STEP
	stamina = max_stamina
	health = minf(health + 25.0, max_health)
	build_field()
	notice("Уровень %d!" % level, Vector2(GameConfig.SCREEN_W / 2.0, GameConfig.SCREEN_H / 2.0))
	hud.refresh()


# ---------------- Эффекты ----------------

func spawn_straws(center: Vector2) -> void:
	var count := rng.randi_range(GameConfig.STRAWS_PER_DIG_MIN, GameConfig.STRAWS_PER_DIG_MAX)
	for i in count:
		straws.append({
			"pos": center + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)),
			"ang": rng.randf() * PI,
			"len": rng.randf_range(14.0, 30.0),
			"life": GameConfig.STRAW_LIFE,
			"max": GameConfig.STRAW_LIFE,
		})


func notice(text: String, pos: Vector2) -> void:
	notices.append({"text": text, "pos": pos, "life": 1.4, "max": 1.4})


# ---------------- Процесс и отрисовка ----------------

func _process(delta: float) -> void:
	if state == "play":
		stamina = minf(max_stamina, stamina + regen * delta)
		if poisoned:
			poison_left -= delta
			health -= GameConfig.POISON_DPS * delta
			if poison_left <= 0.0:
				poisoned = false
		if health <= 0.0:
			health = 0.0
			state = "dead"
			hud.refresh()
	var keep_straws: Array = []
	for s in straws:
		s["life"] = float(s["life"]) - delta
		if float(s["life"]) > 0.0:
			keep_straws.append(s)
	straws = keep_straws
	var keep_notices: Array = []
	for n in notices:
		n["life"] = float(n["life"]) - delta
		if float(n["life"]) > 0.0:
			keep_notices.append(n)
	notices = keep_notices
	hud.refresh()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, GameConfig.SCREEN_W, GameConfig.SCREEN_H), GameConfig.COLOR_BG)
	var fr := field_rect()
	# Клетки поля
	for r in GameConfig.ROWS:
		for c in GameConfig.COLS:
			var cell: Dictionary = field[r * GameConfig.COLS + c]
			var rect := Rect2(fr.position.x + c * GameConfig.CELL, fr.position.y + r * GameConfig.CELL, GameConfig.CELL - 2.0, GameConfig.CELL - 2.0)
			var col: Color
			if bool(cell["dug"]):
				col = GameConfig.COLOR_DIRT_DARK
			else:
				col = GameConfig.COLOR_HAY.darkened((1.05 - float(cell["shade"])) * 0.4)
			draw_rect(rect, col)
			draw_rect(rect, Color(0, 0, 0, 0.15), false, 2.0)
	# Летящие соломинки
	for s in straws:
		var alpha: float = clampf(float(s["life"]) / float(s["max"]), 0.0, 1.0)
		var dir := Vector2(cos(float(s["ang"])), sin(float(s["ang"])))
		var half: Vector2 = dir * float(s["len"]) * 0.5
		var sc: Color = GameConfig.COLOR_HAY_DARK
		sc.a = alpha
		draw_line(Vector2(s["pos"]) - half, Vector2(s["pos"]) + half, sc, 3.0)
	# Всплывающие уведомления
	for n in notices:
		var alpha2: float = clampf(float(n["life"]) / float(n["max"]), 0.0, 1.0)
		var pos: Vector2 = Vector2(n["pos"]) + Vector2(0, -40.0 * (1.0 - alpha2))
		var shadow: Color = Color(0, 0, 0, alpha2)
		draw_string(font, pos + Vector2(2, 2), String(n["text"]), HORIZONTAL_ALIGNMENT_CENTER, 300.0, 26, shadow)
		var tc: Color = GameConfig.COLOR_TEXT
		tc.a = alpha2
		draw_string(font, pos, String(n["text"]), HORIZONTAL_ALIGNMENT_CENTER, 300.0, 26, tc)
	# Экраны смерти и победы
	if state == "dead":
		_draw_overlay(font, "Вы погибли", "Коснитесь экрана, чтобы начать заново")
	elif state == "win":
		_draw_overlay(font, "Стог расчищен!", "Вы прошли все уровни. Коснитесь экрана")


func _draw_overlay(font: Font, title: String, sub: String) -> void:
	draw_rect(Rect2(0, 0, GameConfig.SCREEN_W, GameConfig.SCREEN_H), Color(0, 0, 0, 0.65))
	var cx := GameConfig.SCREEN_W / 2.0
	var cy := GameConfig.SCREEN_H / 2.0
	draw_string(font, Vector2(cx, cy - 40), title, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 52, GameConfig.COLOR_TEXT)
	draw_string(font, Vector2(cx, cy + 40), sub, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 28, Color(0.9, 0.85, 0.7))
