extends CanvasLayer

# Ссылка на узел game_config. 
# Вариант 1: если game_config — это узел в сцене (например, в корне или рядом)
@onready var game_config = get_node_or_null("../game_config")

# Вариант 2 (альтернатива): если game_config не находится автоматически, раскомментируй строку ниже
# и перетащи узел game_config в это поле в инспекторе Godot:
# @export var game_config: Node

func _ready():
	# Проверка, что game_config найден
	if not game_config:
		push_warning("hud.gd: game_config не найден! Проверь путь или используй @export.")
		return

	# ИСПРАВЛЕНИЕ ОШИБОК ИЗ ЛОГА:
	# В Godot 4 connect() принимает Callable (не строку-путь) и флаги (не строку).
	# Используем callable(self, "имя_функции") для передачи метода.
	
	# Подключаем сигнал game_started
	if game_config.has_signal("game_started"):
		game_config.connect("game_started", callable(self, "on_game_started"))
	
	# Подключаем сигнал game_over
	if game_config.has_signal("game_over"):
		game_config.connect("game_over", callable(self, "on_game_over"))

func on_game_started():
	# Логика отображения интерфейса при старте игры
	visible = true
	print("HUD: Игра началась, интерфейс включен.")
	# Здесь можно добавить анимацию появления, сброс очков и т.д.

func on_game_over():
	# Логика отображения экрана проигрыша
	visible = true
	print("HUD: Игра окончена, показываем экран проигрыша.")
	# Здесь можно добавить анимацию, кнопку рестарта и т.д.

func _exit_tree():
	# Отключаем сигналы при выходе из сцены, чтобы избежать ошибок
	if game_config and game_config.is_connected("game_started", callable(self, "on_game_started")):
		game_config.disconnect("game_started", callable(self, "on_game_started"))
	
	if game_config and game_config.is_connected("game_over", callable(self, "on_game_over")):
		game_config.disconnect("game_over", callable(self, "on_game_over"))
