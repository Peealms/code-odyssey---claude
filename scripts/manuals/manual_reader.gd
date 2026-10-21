extends CanvasLayer
## Shows a manual from ManualLibrary as a paper book. The game pauses while it's open.
## A / D (or the arrow keys) turn pages; F or Esc closes it.
## Chests find this node through the "manual_reader" group, so put one in every level.

signal closed

var _manual: Dictionary = {}
var _page := 0

@onready var title_label: Label = $Center/Book/VBox/Title
@onready var body: RichTextLabel = $Center/Book/VBox/Body
@onready var page_label: Label = $Center/Book/VBox/Footer/Page
@onready var prev_label: Label = $Center/Book/VBox/Footer/Prev
@onready var next_label: Label = $Center/Book/VBox/Footer/Next


func _ready() -> void:
	add_to_group("manual_reader")
	visible = false


func open(manual_id: String) -> void:
	_manual = ManualLibrary.get_manual(manual_id)
	if _manual.is_empty():
		push_warning("Unknown manual: %s" % manual_id)
		return
	_page = 0
	title_label.text = _manual["title"]
	_show_page()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_turn(-1)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_turn(1)
	elif event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _turn(step: int) -> void:
	var count: int = _manual["pages"].size()
	_page = clampi(_page + step, 0, count - 1)
	_show_page()


func _show_page() -> void:
	var pages: Array = _manual["pages"]
	body.text = pages[_page]
	body.scroll_to_line(0)
	page_label.text = "PAGE %d/%d" % [_page + 1, pages.size()]
	prev_label.modulate.a = 1.0 if _page > 0 else 0.25
	next_label.modulate.a = 1.0 if _page < pages.size() - 1 else 0.25
