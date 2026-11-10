extends Node
## Автоматический логгер для отладки APK.
## Пишет журнал в user://logger.log, ловит краши и даёт кнопку "Журнал" в игре.

const LOG_PATH := "user://logger.log"
const CRASH_MARKER := "user://.crash_marker"
const LAST_LINES_PATH := "user://.last_log_lines"
const HEARTBEAT_SEC := 5.0
const MAX_FILE_BYTES := 400000
const KEEP_TAIL_LINES := 25

var _last_lines: PackedStringArray = PackedStringArray()
var _heartbeat: Timer
var _panel: PanelContainer
var _log_view: RichTextLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_crash()
	_write_header()
	_log("Логгер запущен")
	_init_ui()
	_start_heartbeat()


func _ts() -> String:
	return Time.get_datetime_string_from_system(true) + "." + str(Time.get_ticks_msec() % 1000).pad_zeros(3)


func _log(msg: String) -> void:
	var line := "[%s] %s" % [_ts(), msg]
	print("LOGGER: ", line)
	_append_to_file(line)
	_last_lines.append(line)
	while _last_lines.size() > KEEP_TAIL_LINES:
		_last_lines.remove_at(0)
	_save_last_lines()


func _append_to_file(line: String) -> void:
	_trim_file()
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE_READ)
	if f == null:
		print("LOGGER: не удалось открыть файл лога, код ", FileAccess.get_open_error())
		return
	f.seek_end()
	f.store_line(line)


func _trim_file() -> void:
	if not FileAccess.file_exists(LOG_PATH):
		return
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	if f == null:
		return
	var total := f.get_length()
	if total <= MAX_FILE_BYTES:
		return
	var text := f.get_as_text()
	var lines := text.split("\n")
	var keep := lines.slice(lines.size() / 2)
	var w := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if w:
		w.store_string("\n".join(keep))


func _save_last_lines() -> void:
	var f := FileAccess.open(LAST_LINES_PATH, FileAccess.WRITE)
	if f:
		for l in _last_lines:
			f.store_line(l)


func _write_header() -> void:
	_log("=== НОВАЯ СЕССИЯ ===")
	var ver: Dictionary = Engine.get_version_info()
	_log("Godot: %s" % str(ver.get("string", "?")))
	_log("ОС: %s, модель: %s" % [OS.get_name(), OS.get_model_name()])
	var win := DisplayServer.window_get_size()
	_log("Экран: %dx%d, язык: %s" % [win.x, win.y, OS.get_locale()])


func _check_crash() -> void:
	if FileAccess.file_exists(CRASH_MARKER):
		_log("!!! ПРЕДЫДУЩАЯ СЕССИЯ ЗАВЕРШИЛАСЬ НЕШТАТНО (краш) !!!")
		if FileAccess.file_exists(LAST_LINES_PATH):
			var f := FileAccess.open(LAST_LINES_PATH, FileAccess.READ)
			if f:
				_log("--- Последние строки перед крашем ---")
				var lines := f.get_as_text().split("\n")
				for l in lines:
					if l.strip_edges() != "":
						_log("  " + l)
				_log("--- Конец строк перед крашем ---")
	DirAccess.remove_absolute(CRASH_MARKER)


func _start_heartbeat() -> void:
	_heartbeat = Timer.new()
	_heartbeat.wait_time = HEARTBEAT_SEC
	_heartbeat.autostart = true
	_heartbeat.timeout.connect(_on_heartbeat)
	add_child(_heartbeat)


func _on_heartbeat() -> void:
	var scene := "?"
	var nodes := -1
	if get_tree():
		var cs := get_tree().current_scene
		if cs:
			scene = str(cs.name)
		nodes = get_tree().get_node_count()
	_log("ПУЛЬС: сцена=%s, узлов=%d, FPS=%d, памяти=%d МБ" % [
		scene, nodes, Engine.get_frames_per_second(),
		OS.get_static_memory_usage() / 1048576
	])


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_log("Приложение ушло в фон")
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_log("Приложение вернулось на передний план")
		NOTIFICATION_WM_CLOSE_REQUEST:
			_log("Штатное закрытие приложения")
			_clear_marker()


func _exit_tree() -> void:
	_clear_marker()
	_log("Сессия завершена штатно")


func _clear_marker() -> void:
	if FileAccess.file_exists(CRASH_MARKER):
		DirAccess.remove_absolute(CRASH_MARKER)


## Публичные помощники для кода игры:
func log_event(msg: String) -> void:
	_log("СОБЫТИЕ: " + msg)


func log_error(msg: String) -> void:
	_log("!!! ОШИБКА: " + msg)
	var st := get_stack()
	if st != null:
		for i in range(st.size() - 1, -1, -1):
			var fr: Dictionary = st[i]
			_log("    at %s:%d in %s()" % [str(fr.get("source", "?")), int(fr.get("line", 0)), str(fr.get("function", "?"))])


func _init_ui() -> void:
	if not OS.is_debug_build():
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var btn := Button.new()
	btn.text = "Журнал"
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -110
	btn.offset_right = -10
	btn.offset_top = -60
	btn.offset_bottom = -20
	btn.pressed.connect(_toggle_panel)
	layer.add_child(btn)

	_panel = PanelContainer.new()
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 20
	_panel.offset_top = 40
	_panel.offset_right = -20
	_panel.offset_bottom = -80
	_panel.visible = false
	layer.add_child(_panel)

	var vb := VBoxContainer.new()
	_panel.add_child(vb)

	var title := Label.new()
	title.text = "Журнал приложения"
	vb.add_child(title)

	_log_view = RichTextLabel.new()
	_log_view.bbcode_enabled = false
	_log_view.scroll_following = true
	_log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_log_view)

	var hb := HBoxContainer.new()
	vb.add_child(hb)

	var copy_btn := Button.new()
	copy_btn.text = "Копировать лог"
	copy_btn.pressed.connect(_copy_log)
	hb.add_child(copy_btn)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(_toggle_panel)
	hb.add_child(close_btn)


func _toggle_panel() -> void:
	if _panel:
		_panel.visible = not _panel.visible
		if _panel.visible:
			_log_view.text = _collect_log()
			_log_view.scroll_to_line(_log_view.get_line_count())


func _collect_log() -> String:
	var out := ""
	if FileAccess.file_exists(LOG_PATH):
		var f := FileAccess.open(LOG_PATH, FileAccess.READ)
		if f:
			out = f.get_as_text()
	if FileAccess.file_exists("user://logs/godot.log"):
		var f2 := FileAccess.open("user://logs/godot.log", FileAccess.READ)
		if f2:
			out += "\n=== СИСТЕМНЫЙ ЛОГ GODOT ===\n" + f2.get_as_text()
	if out.strip_edges() == "":
		out = "(лог пуст)"
	return out


func _copy_log() -> void:
	var text := _collect_log()
	DisplayServer.clipboard_set(text)
	log_event("Лог скопирован в буфер обмена (%d символов)" % text.length())
	if _log_view:
		_log_view.text = _collect_log()
