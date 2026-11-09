extends CanvasLayer

@onready var game_config = get_node_or_null("../game_config")
# Если автоматический поиск не сработает, раскомментируй строку ниже и назначь узел в инспекторе:
# @export var game_config: Node

func _ready():
	if not game_config:
		push_warning("hud.gd: game_config не найден! Проверь путь или используй @export.")
		return

	if game_config.has_signal("game_started"):
		game_config.connect("game_started", on_game_started)

	if game_config.has_signal("game_over"):
		game_config.connect("game_over", on_game_over)

func on_game_started():
	visible = true
	print("HUD: Игра началась, интерфейс включен.")

func on_game_over():
	visible = true
	print("HUD: Игра окончена, показываем экран проигрыша.")

func _exit_tree():
	if game_config:
		if game_config.is_connected("game_started", on_game_started):
			game_config.disconnect("game_started", on_game_started)
		if game_config.is_connected("game_over", on_game_over):
			game_config.disconnect("game_over", on_game_over)
