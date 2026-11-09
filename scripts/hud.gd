extends CanvasLayer
## Интерфейс: показатели, полосы, кнопки, лавка и справка.

var main: Node
var shop_root: Control
var shop_rows: VBoxContainer
var help_root: Control

var lbl_level: Label
var lbl_money: Label
var lbl_hay: Label
var bar_hp: ColorRect
var bar_st: ColorRect

const BAR_X := 22.0
const BAR_W := 676.0


func _ready() -> void:
	main = get_parent()
	_build()


func _mk_label(parent: Control, pos: Vector2, size: int, text: String = "") -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_TEXT)
	parent.add_child(lbl)
	return lbl


func _mk_button(parent: Control, rect: Rect2, text: String) -> Button:
	var btn := Button.new()
	btn.position = rect.position
	btn.size = rect.size
	btn.text = text
	btn.add_theme_font_size_override("font_size", 26)
	parent.add_child(btn)
	return btn


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	lbl_level = _mk_label(root, Vector2(20, 10), 30, "Уровень 1/10")
	lbl_money = _mk_label(root, Vector2(260, 10), 30, "Монеты: 0")
	lbl_hay = _mk_label(root, Vector2(520, 10), 30, "Сено: 0")

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(BAR_X, 58)
	hp_bg.size = Vector2(BAR_W, 32)
	hp_bg.color = Color(0.15, 0.1, 0.06, 0.9)
	root.add_child(hp_bg)
	bar_hp = ColorRect.new()
	bar_hp.position = Vector2(BAR_X + 2, 60)
	bar_hp.size = Vector2(BAR_W - 4, 28)
	bar_hp.color = GameConfig.COLOR_HP
	root.add_child(bar_hp)

	var st_bg := ColorRect.new()
	st_bg.position = Vector2(BAR_X, 100)
	st_bg.size = Vector2(BAR_W, 32)
	st_bg.color = Color(0.15, 0.1, 0.06, 0.9)
	root.add_child(st_bg)
	bar_st = ColorRect.new()
	bar_st.position = Vector2(BAR_X + 2, 102)
	bar_st.size = Vector2(BAR_W - 4, 28)
	bar_st.color = GameConfig.COLOR_ST
	root.add_child(bar_st)

	btn_sell = _mk_button(root, Rect2(10, 1150, 230, 64), "Продать сено")
	btn_sell.pressed.connect(main.sell_hay)
	btn_shop = _mk_button(root, Rect2(245, 1150, 230, 64), "Лавка")
	btn_shop.pressed.connect(main.toggle_shop)
	var btn_help := _mk_button(root, Rect2(480, 1150, 230, 64), "?")
	btn_help.pressed.connect(main.toggle_help)

	var btn_bandage := _mk_button(root, Rect2(10, 1220, 230, 54), "Бинт ×0")
	btn_bandage.pressed.connect(main.use_bandage)
	var btn_antidote := _mk_button(root, Rect2(245, 1220, 465, 54), "Противоядие ×0")
	btn_antidote.pressed.connect(main.use_antidote)

	# Сохраняем ссылки на кнопки инвентаря для обновления
	root.set_meta("btn_bandage", btn_bandage)
	root.set_meta("btn_antidote", btn_antidote)

	_build_shop(root)
	_build_help(root)


func _build_shop(root: Control) -> void:
	shop_root = Control.new()
	shop_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_root.visible = false
	root.add_child(shop_root)

	var bg := ColorRect.new()
	bg.position = Vector2(20, 180)
	bg.size = Vector2(680, 900)
	bg.color = Color(0.12, 0.08, 0.04, 0.96)
	shop_root.add_child(bg)

	var title := _mk_label(shop_root, Vector2(40, 200), 36, "Лавка улучшений")
	title.add_theme_color_override("font_color", GameConfig.COLOR_HAY)

	shop_rows = VBoxContainer.new()
	shop_rows.position = Vector2(40, 260)
	shop_rows.size = Vector2(640, 700)
	shop_rows.add_theme_constant_override("separation", 14)
	shop_root.add_child(shop_rows)

	var btn_close := _mk_button(shop_root, Rect2(240, 1000, 240, 60), "Закрыть")
	btn_close.pressed.connect(func(): shop_root.visible = false)


func refresh_shop() -> void:
	for child in shop_rows.get_children():
		child.queue_free()
	for id in GameConfig.UPGRADE_ORDER:
		var info: Dictionary = GameConfig.UPGRADES[id]
		var lvl: int = main.up[id]
		var price := int(round(float(info["base"]) * pow(float(info["growth"]), float(lvl))))
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(640, 90)
		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl := _mk_label(left, Vector2.ZERO, 26, "%s (ур. %d)" % [info["name"], lvl])
		name_lbl.custom_minimum_size = Vector2(420, 34)
		_mk_label(left, Vector2.ZERO, 22, info["desc"])
		row.add_child(left)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 80)
		btn.text = "Купить\n%d" % price
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(main.buy_upgrade.bind(id))
		row.add_child(btn)
		shop_rows.add_child(row)


func _build_help(root: Control) -> void:
	help_root = Control.new()
	help_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_root.visible = false
	root.add_child(help_root)

	var bg := ColorRect.new()
	bg.position = Vector2(20, 180)
	bg.size = Vector2(680, 900)
	bg.color = Color(0.12, 0.08, 0.04, 0.96)
	help_root.add_child(bg)

	var lines := [
		"Как играть:",
		"1. Копайте стог: каждое касание - 1 сила.",
		"2. Силы восстанавливаются со временем.",
		"3. Находки: монеты, растения, звери, бинты.",
		"4. Укусы отнимают здоровье, растения",
		"   могут отравить - лечитесь бинтом,",
		"   яд снимайте противоядием.",
		"5. Продавайте сено и улучшайтесь в лавке.",
		"6. Найдите иглу, чтобы пройти уровень.",
		"Цель - расчистить все 10 стогов.",
	]
	var y := 220.0
	for line in lines:
		_mk_label(help_root, Vector2(50, y), 26, line)
		y += 40.0

	var btn_close := _mk_button(help_root, Rect2(240, 1000, 240, 60), "Понятно")
	btn_close.pressed.connect(func(): help_root.visible = false)


func refresh() -> void:
	if main == null:
		return
	lbl_level.text = "Уровень %d/%d" % [main.level, GameConfig.MAX_LEVEL]
	lbl_money.text = "Монеты: %d" % main.money
	lbl_hay.text = "Сено: %d" % main.hay
	bar_hp.size.x = (BAR_W - 4.0) * clampf(main.health / main.max_health, 0.0, 1.0)
	bar_st.size.x = (BAR_W - 4.0) * clampf(main.stamina / main.max_stamina, 0.0, 1.0)
	var root := shop_root.get_parent()
	var btn_bandage: Button = root.get_meta("btn_bandage")
	var btn_antidote: Button = root.get_meta("btn_antidote")
	btn_bandage.text = "Бинт ×%d" % main.inv_bandage
	btn_antidote.text = "Противоядие ×%d" % main.inv_antidote
