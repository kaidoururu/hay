class_name GameConfig
## Все константы игры (аналог game_config.py) и данные лавки.

const SCREEN_W := 720
const SCREEN_H := 1280

# Поле
const COLS := 9
const ROWS := 13
const CELL := 72
const FIELD_TOP := 210

const MAX_LEVEL := 10

# Силы и здоровье
const STAMINA_BASE := 20.0
const STAMINA_STEP := 4.0
const REGEN_BASE := 2.5
const HEALTH_BASE := 100.0
const ANIMAL_DAMAGE_BASE := 10

# Копание и находки
const STRAW_MIN := 3
const STRAW_MAX := 6
const STRAW_LIFE := 0.7
const STRAWS_PER_DIG_MIN := 4
const STRAWS_PER_DIG_MAX := 7

const P_COIN := 0.02
const P_STONE := 0.002
const P_PLANT := 0.008
const P_ANIMAL := 0.008
const P_BANDAGE := 0.004
const P_ANTIDOTE := 0.004

const PLANT_POISON_CHANCE := 0.3
const ANIMAL_POISON_CHANCE := 0.3
const POISON_TIME := 8.0
const POISON_DPS := 2.0

const BANDAGE_HEAL := 25.0

# Цвета
const COLOR_BG := Color8(40, 30, 18)
const COLOR_DIRT := Color8(85, 60, 33)
const COLOR_DIRT_DARK := Color8(58, 41, 23)
const COLOR_HAY := Color8(196, 154, 74)
const COLOR_HAY_DARK := Color8(150, 114, 48)
const COLOR_TEXT := Color8(255, 245, 220)
const COLOR_HP := Color8(200, 60, 60)
const COLOR_ST := Color8(90, 160, 220)

# Лавка: базовая цена и множитель роста за уровень
const UPGRADE_ORDER := ["stamina", "regen", "dig", "luck", "health", "wallet"]
const UPGRADES := {
	"stamina": {"name": "Выносливость", "desc": "+4 к максимуму сил", "base": 15, "growth": 2.0},
	"regen": {"name": "Отдых", "desc": "+1 к восстановлению сил", "base": 20, "growth": 2.2},
	"dig": {"name": "Крепкие руки", "desc": "+1 сена за копок", "base": 25, "growth": 2.5},
	"luck": {"name": "Удача", "desc": "+15% к шансу находок", "base": 30, "growth": 2.8},
	"health": {"name": "Здоровье", "desc": "+20 к максимуму здоровья", "base": 18, "growth": 2.2},
	"wallet": {"name": "Торг", "desc": "+25% к цене сена", "base": 22, "growth": 2.4},
}
