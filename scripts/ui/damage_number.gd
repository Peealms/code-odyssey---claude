class_name DamageNumber
extends Label
## A number that pops out of whoever got hurt, hops up, and fades away.
## Use: DamageNumber.spawn(self, 10, DamageNumber.ENEMY_HIT)

const ENEMY_HIT := Color(1, 0.894118, 0.470588)  ## Damage the player deals (yellow).
const PLAYER_HIT := Color(1, 0.36, 0.42)  ## Damage the player takes (red).
const HEAL := Color(0.45, 1, 0.5)  ## Health the player gets back (green, shown as +30).


## Spawns the number above `target` in the current scene, so it stays put if the target moves or is freed.
static func spawn(target: Node2D, amount: float, color: Color, height := 24.0, prefix := "") -> void:
	var label := DamageNumber.new()
	label.text = prefix + str(roundi(amount))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.129, 0.122, 0.188))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.z_index = 20
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.get_tree().current_scene.add_child(label)
	label.size = label.get_combined_minimum_size()
	label.pivot_offset = label.size / 2.0
	label.global_position = target.global_position + Vector2(randf_range(-6, 6), -height) - label.size / 2.0
	label._animate()


func _animate() -> void:
	# Pop in big, hop up and to the side, then fade out.
	scale = Vector2(1.6, 1.6)
	var side := randf_range(-10, 10)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_property(self, "position:y", position.y - 18.0, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", position.x + side, 0.7)
	tween.tween_property(self, "position:y", position.y - 8.0, 0.35).set_delay(0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(queue_free)
