extends RuleMachine
## A room's exit: crates stacked in the doorway, and above them a sign with the captain's door
## rule and its live values, e.g. if (coins >= 12) -> 9 >= 12 false. The rule is run by a
## locked RuleRunner in the room (machine_vars ["doorOpen"]); doorOpen = true breaks the crates.
## Every room shows a different operator, so players read conditions without typing them.
## The node's position is the bottom-middle of the doorway; `size` is the opening.

const BOX := preload("res://assets/level2_treasure_hunters/objects/merchant_ship/box/box_frames.tres")

@export var size := Vector2(32, 64)

var is_open := false
var _shape: CollisionShape2D
var _boxes: Array[AnimatedSprite2D] = []
var _sign: Label


func _ready() -> void:
	super()
	variables = ["doorOpen"]
	var body := StaticBody2D.new()
	body.collision_layer = 1
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(0, -size.y / 2.0)
	body.add_child(_shape)
	add_child(body)
	var y := 0.0
	while y < size.y - 4.0:
		var b := AnimatedSprite2D.new()
		b.sprite_frames = BOX
		b.play("idle")
		b.position = Vector2(0, -y - 14.0)
		add_child(b)
		_boxes.append(b)
		y += 26.0
	_sign = Label.new()
	_sign.position = Vector2(-150, -size.y - 6.0)
	_sign.size = Vector2(130, 20)
	_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	_sign.add_theme_font_override("font", font)
	_sign.add_theme_font_size_override("font_size", 7)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.43, 0.29, 0.23, 0.95)
	box.border_color = Color("3d2429")
	box.set_border_width_all(1)
	box.set_content_margin_all(2)
	_sign.add_theme_stylebox_override("normal", box)
	_sign.z_index = 6
	add_child(_sign)
	_hook.call_deferred()


func _hook() -> void:
	if runner:
		runner.ran.connect(func(_t): _update_sign())
	_update_sign()


func _update_sign() -> void:
	if runner == null or runner.rule.is_empty():
		_sign.text = "LOCKED"
		return
	var cond: Dictionary = runner.rule["branches"][0]["cond"]
	var line := "if (%s)" % cond["text"]
	var conds: Array = runner.last_trace.get("conds", [])
	if not conds.is_empty():
		var c: Dictionary = conds[0]
		line += "\n%s -> %s" % [c["shown"], "true" if c["result"] else "false"]
	_sign.text = line
	_sign.add_theme_color_override("font_color", Color("7cf07c") if is_open else Color("fff5e3"))


func _on_set(_var_name: String, value: Variant) -> void:
	if value != true or is_open:
		return
	is_open = true
	_shape.set_deferred("disabled", true)
	Sound.play_at("crates_break", global_position)
	for b in _boxes:
		b.play("destroyed")
		var t := create_tween()
		t.tween_property(b, "modulate:a", 0.0, 0.5).set_delay(0.3)
	_update_sign()
