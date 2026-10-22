extends CanvasLayer
## In-game HUD: current hero + trait, health and stamina bars, fruit counter, and short messages.

# The pixel font has no round brackets, so keys are shown after a dash.
const TRAIT_TEXT := {
	"wall_jump": "WALL JUMP",
	"dash": "DASH - SHIFT",
	"double_jump": "DOUBLE JUMP",
	"sprint": "SPRINT - SHIFT",
}
const STAMINA_COLOR := Color(1, 0.827451, 0.301961)
const EXHAUSTED_COLOR := Color(0.5, 0.48, 0.52)

@onready var hero_icon: AnimatedSprite2D = $TopLeft/HeroIcon
@onready var hero_label: Label = $TopLeft/HeroLabel
@onready var trait_label: Label = $TopLeft/TraitLabel
@onready var fruit_label: Label = $TopRight/FruitLabel
@onready var message_label: Label = $Message
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_text: Label = $HealthBar/HealthText
@onready var stamina_bar: ProgressBar = $StaminaBar

var fruits := 0  ## Total fruit collected in the level.
var _room: Node  ## The Room whose fruit the counter shows.
var _message_tween: Tween
var _health_tween: Tween
var _stamina_fill: StyleBoxFlat


func _ready() -> void:
	add_to_group("hud")
	message_label.modulate.a = 0.0
	set_fruits(0)
	# Own copy of the fill style so its colour can change when exhausted.
	_stamina_fill = stamina_bar.get_theme_stylebox("fill").duplicate()
	stamina_bar.add_theme_stylebox_override("fill", _stamina_fill)


func set_health(health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_text.text = "HP %d/%d" % [ceili(health), ceili(max_health)]
	if _health_tween:
		_health_tween.kill()
	_health_tween = create_tween()
	_health_tween.tween_property(health_bar, "value", health, 0.2)


func set_stamina(stamina: float, max_stamina: float, exhausted: bool) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina
	_stamina_fill.bg_color = EXHAUSTED_COLOR if exhausted else STAMINA_COLOR


func show_hero(hero_id: String, hero_data: Dictionary) -> void:
	hero_icon.sprite_frames = load(hero_data["frames"])
	hero_icon.play("idle")
	hero_label.text = hero_data["name"]
	trait_label.text = "TRAIT: " + TRAIT_TEXT.get(hero_data["trait"], "?")


func set_fruits(count: int) -> void:
	fruits = count
	if _room == null:
		fruit_label.text = "FRUITS: %d" % count


func add_fruit() -> void:
	set_fruits(fruits + 1)


## Show the fruit of the room the player is in, e.g. FRUIT 3/15 (green once it's all collected).
func track_room(room: Node) -> void:
	if _room == room:
		return
	if _room and _room.fruit_changed.is_connected(_on_room_fruit):
		_room.fruit_changed.disconnect(_on_room_fruit)
	_room = room
	_room.fruit_changed.connect(_on_room_fruit)
	_on_room_fruit(_room.fruit_collected, _room.fruit_total)


func _on_room_fruit(collected: int, total: int) -> void:
	if total == 0:
		fruit_label.text = "FRUITS: %d" % fruits
		fruit_label.remove_theme_color_override("font_color")
		return
	fruit_label.text = "FRUIT %d/%d" % [collected, total]
	if collected >= total:
		fruit_label.add_theme_color_override("font_color", Color("7cf07c"))
	else:
		fruit_label.remove_theme_color_override("font_color")


func show_message(text: String, duration := 2.0) -> void:
	message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.15)
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.4)
