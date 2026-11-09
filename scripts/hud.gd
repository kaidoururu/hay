extends CanvasLayer

@export var btn_sell: Button
@export var btn_shop: Button
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar
@export var coins_label: Label
@export var hay_label: Label
@export var level_label: Label
@export var poison_label: Label
@export var needle_label: Label
@export var бинты_label: Label
@export var противоядия_label: Label

var game_state: Dictionary
var game_config: Dictionary # Добавляем объявление

func _ready():
    # Инициализация интерфейса
    health_bar.max_value = 100
    stamina_bar.max_value = 100
    update_ui()
    
    # Правильное подключение сигналов
    btn_sell.connect("pressed", self, "_on_sell_clicked")
    btn_shop.connect("pressed", self, "_on_shop_clicked")

func update_ui():
    # Обновление всех элементов интерфейса
    health_bar.value = game_state.health
    stamina_bar.value = game_state.stamina
    coins_label.text = "Монеты: " + str(game_state.coins)
    hay_label.text = "Сено: " + str(game_state.hay)
    level_label.text = "Уровень: " + str(game_state.level)
    poison_label.text = "Яд: " + str(game_state.poison)
    needle_label.text = "Игла: " + str(game_state.needle_found)
    бинты_label.text = "Бинты: " + str(game_state.bandages)
    противоядия_label.text = "Противоядия: " + str(game_state.antidotes)

func _on_sell_clicked():
    # Логика продажи сена
    var price = game_state.hay * game_config.sell_price
    game_state.coins += price
    game_state.hay = 0
    update_ui()

func _on_shop_clicked():
    # Открытие лавки
    # Здесь должна быть логика открытия меню лавки
    pass

func update_health(amount: float):
    game_state.health = clamp(game_state.health + amount, 0, 100)
    update_ui()

func update_stamina(amount: float):
    game_state.stamina = clamp(game_state.stamina + amount, 0, 100)
    update_ui()

func add_bandage():
    game_state.bandages += 1
    update_ui()

func add_antidote():
    game_state.antidotes += 1
    update_ui()
