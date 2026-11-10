extends CanvasLayer
## Level 2's rule panel (top right): the rule of the room the player is in, on several lines,
## with live values - `if (tide >= 4)` shows `3 >= 4 -> false`. The branch that ran is bright,
## the rest is dim, and conditions Java never got to are grey. It flashes each time the rule
## runs. See docs/level2_design.md. Built in code; the level just adds this node.

const WIDTH := 236.0
const C_HEAD := "5ef2e0"
const C_CODE := "ffffff"
const C_DIM := "6f7f95"
const C_TRUE := "7cf07c"
const C_FALSE := "ff5c6c"
const C_WAIT := "ffd34d"

var _panel: PanelContainer
var _label: RichTextLabel
var _runner: RuleRunner
var _flash: Tween


func _ready() -> void:
	layer = 30
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.15, 0.82)
	style.border_color = Color("5ef2e0")
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	style.anti_aliasing = false
	_panel.add_theme_stylebox_override("panel", style)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -WIDTH - 6.0
	_panel.offset_right = -6.0
	_panel.offset_top = 28.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(WIDTH - 8.0, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_override("normal_font", font)
	_label.add_theme_font_size_override("normal_font_size", 8)
	_panel.add_child(_label)
	_panel.visible = false


func _process(_delta: float) -> void:
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	var room: Room = terminal.current_room if terminal else null
	var runner: RuleRunner = room.panel_runner() if room else null
	if runner != _runner:
		_watch(runner)


func _watch(runner: RuleRunner) -> void:
	if _runner and is_instance_valid(_runner):
		if _runner.ran.is_connected(_on_ran):
			_runner.ran.disconnect(_on_ran)
		if _runner.rule_changed.is_connected(_redraw):
			_runner.rule_changed.disconnect(_redraw)
	_runner = runner
	_panel.visible = runner != null
	if runner == null:
		return
	runner.ran.connect(_on_ran)
	runner.rule_changed.connect(_redraw)
	_redraw()


func _on_ran(_trace: Dictionary) -> void:
	_redraw()
	if _flash:
		_flash.kill()
	_panel.modulate = Color(1.6, 1.6, 1.6)
	_flash = create_tween()
	_flash.tween_property(_panel, "modulate", Color.WHITE, 0.35)


func _redraw() -> void:
	if _runner == null:
		return
	var out := PackedStringArray()
	var owner_text := "RULE" if not _runner.locked else "CAPTAIN'S RULE"
	var when := ("runs " + _runner.trigger_text) if _runner.trigger_text != "" else ""
	out.append("[color=#%s]%s[/color] [color=#%s]%s[/color]" % [C_HEAD, owner_text, C_DIM, _esc(when)])

	if _runner.error != "":
		for line in Rules.format_source(_runner.source):
			out.append("[color=#%s]%s[/color]" % [C_CODE, _esc(line)])
		out.append("[color=#%s]X CAN'T RUN - open the terminal (E)[/color]" % C_FALSE)
	elif _runner.rule.is_empty():
		out.append("[color=#%s]No rule yet - open the terminal (E)[/color]" % C_WAIT)
	else:
		var trace: Dictionary = _runner.last_trace
		var ran: Array = trace.get("ran", [])
		var conds: Array = trace.get("conds", [])
		var noted := []
		for line in Rules.format(_runner.rule):
			var b: int = line["branch"]
			var color := C_CODE
			if line["part"] == "body":
				color = C_CODE if b in ran else C_DIM
			var text := "[color=#%s]%s[/color]" % [color, _esc(line["text"])]
			if line["part"] == "head" and not b in noted:
				noted.append(b)
				text += _cond_note(conds, b)
			out.append(text)
		if trace.has("waiting"):
			out.append("[color=#%s]waiting: %s doesn't exist yet[/color]" % [C_WAIT, trace["waiting"]])
	_label.text = "\n".join(out)


## "   3 >= 4 -> false" after a branch's first line.
func _cond_note(conds: Array, b: int) -> String:
	if b >= conds.size():
		return ""
	var cond: Dictionary = conds[b]
	if cond["text"] == "else":
		return "   [color=#%s]%s[/color]" % [C_TRUE if cond["checked"] else C_DIM, "runs" if cond["checked"] else "skipped"]
	if not cond["checked"]:
		return "   [color=#%s]not checked[/color]" % C_DIM
	var color := C_TRUE if cond["result"] else C_FALSE
	return "   [color=#%s]%s -> %s[/color]" % [color, _esc(cond["shown"]), "true" if cond["result"] else "false"]


func _esc(text: String) -> String:
	return text.replace("[", "[lb]")
