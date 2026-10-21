extends CanvasLayer
## Press Esc in a level to pause. Works while the game tree is paused.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@onready var resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var restart_button: Button = $Center/Panel/VBox/RestartButton
@onready var menu_button: Button = $Center/Panel/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(func(): Game.reload_scene())
	menu_button.pressed.connect(func(): Game.change_scene(MAIN_MENU))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
