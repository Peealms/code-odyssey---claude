extends SceneTree
## Checks the pause menu's CONTROLS panel in Level 1: it opens from the pause buttons, lists
## every key, and BACK or Esc returns to the buttons. Screenshot: test_screenshots/pause_controls.png
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_pause_controls.gd

const LEVEL := "res://scenes/levels/level2/level2.tscn"
var fails := 0


func check(name: String, ok: bool, detail := "") -> void:
	if not ok:
		fails += 1
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Game").change_scene(LEVEL)
	await create_timer(2.0).timeout
	var pause: CanvasLayer = current_scene.find_child("PauseMenu", true, false)
	pause.open()
	await process_frame
	var button: Button = pause.find_child("ControlsButton", true, false)
	check("pause menu has CONTROLS", button != null and button.is_visible_in_tree())
	check("CONTROLS sits above MAIN MENU", button.get_index() == pause.menu_button.get_index() - 1)
	button.pressed.emit()
	await create_timer(0.3).timeout
	var panel: Control = pause.find_child("ControlsPanel", true, false)
	check("CONTROLS shows the keys", panel.is_visible_in_tree() and not pause.get_node("Center/Panel").visible)
	var keys: GridContainer = panel.find_child("Keys", true, false)
	check("every key listed", keys.get_child_count() == pause.CONTROLS.size() * 2, str(keys.get_child_count()))
	var view := root.get_visible_rect()
	var r := panel.get_global_rect()
	check("panel fits the screen", view.encloses(r), "%s in %s" % [r, view])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_screenshots/"))
	root.get_texture().get_image().save_png("user://test_screenshots/pause_controls.png")
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	pause._unhandled_input(ev)
	await process_frame
	check("Esc goes back to the buttons", not panel.visible and pause.get_node("Center/Panel").visible and pause.visible)
	button.pressed.emit()
	await process_frame
	pause.close()
	pause.open()
	check("reopening starts on the buttons", not panel.visible)
	print("\n%d failed" % fails)
	quit(1 if fails else 0)
