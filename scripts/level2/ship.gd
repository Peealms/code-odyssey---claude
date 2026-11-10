extends RuleMachine
## The team's little ship (merchant ship art). The node sits at the dock; the deck moves.
##   mode "anchor" (Room 1, exam 2): anchorUp = true lets the current carry it to `trip`.
##        The tide at that moment must be at least `reef_need`, or it scrapes the reef halfway,
##        fails, and is towed back. It returns to the dock by itself once nobody is aboard.
##   mode "sail" (Room 3, exam 3): it leaves when the hero is aboard and the sails are up.
##        The room's wind (wind.gd) starts blowing; the sails must match it the whole way:
##        wind 7-9 -> sails 0, 3-6 -> 1, 0-2 -> 2. A wrong setting snaps the mast, rips the
##        sail or stalls the ship, and it is towed back.
## The deck floats on the room's water, if there is any.

const FRAMES := preload("res://assets/level2_treasure_hunters/objects/merchant_ship/ship/ship_frames.tres")
const SPEED := 70.0
const TOW_SPEED := 160.0
const GRACE := 0.6  ## Seconds a wrong sail setting is allowed (the rule answers at once anyway).

@export_enum("anchor", "sail") var mode := "anchor"
@export var trip := Vector2(320, 0)  ## From the dock to where the trip ends.
@export var reef_at := 0.5  ## anchor: where the reef is, as a part of the trip.
@export var reef_need := 4

enum State { DOCKED, SAILING, AGROUND, TOWING, ARRIVED, RETURNING }

var ship_state := State.DOCKED
var progress := 0.0  ## 0 at the dock, 1 at the end of the trip.
var _deck: AnimatableBody2D
var _hull: AnimatedSprite2D
var _sail: AnimatedSprite2D
var _anchor: AnimatedSprite2D
var _water: Node2D
var _wind: Node
var _depart_tide := 0
var _wrong_time := 0.0
var _empty_time := 0.0
var _shake := 0.0


func _ready() -> void:
	super()
	variables.assign(["anchorUp"] if mode == "anchor" else ["sails"])
	_deck = AnimatableBody2D.new()
	_deck.sync_to_physics = true
	_deck.collision_layer = 1
	_deck.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(66, 8)
	shape.shape = rect
	shape.position = Vector2(0, 4)
	shape.one_way_collision = true
	_deck.add_child(shape)
	add_child(_deck)
	_hull = _sprite("ship_idle")
	_sail = _sprite("no_wind")
	_anchor = _sprite("anchor")
	_find.call_deferred()


func _sprite(anim: String) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = FRAMES
	s.play(anim)
	s.position = Vector2(0, -2)
	_deck.add_child(s)
	return s


func _find() -> void:
	var room: Room = runner.room if runner else null
	for w in get_tree().get_nodes_in_group("water"):
		if room == null or room.contains(w.global_position + Vector2(w.width / 2.0, -2)):
			_water = w
	for src in get_tree().get_nodes_in_group("reading_source"):
		if src.has_reading("wind") and (room == null or room.contains(src.global_position)):
			_wind = src


func _on_set(var_name: String, value: Variant) -> void:
	if var_name == "anchorUp":
		_anchor.visible = value != true
		if value == true and ship_state == State.DOCKED:
			_depart_tide = lookup("tide") if lookup("tide") != null else 0
			ship_state = State.SAILING
			Sound.play_at("chest_open", global_position)
	elif var_name == "sails":
		_sail.play("no_wind" if int(value) == 0 else "wind")
		_sail.scale.x = 1.0 if int(value) != 1 else 0.75


func _physics_process(delta: float) -> void:
	match ship_state:
		State.DOCKED:
			if mode == "sail" and _player_aboard() and int(state.get("sails", 0)) > 0:
				ship_state = State.SAILING
				_wrong_time = 0.0
				if _wind:
					_wind.start()
		State.SAILING:
			if mode == "anchor":
				progress += SPEED * delta / trip.length()
				if progress >= reef_at and _depart_tide < reef_need:
					progress = reef_at
					_run_aground()
			else:
				_check_sails(delta)
				if ship_state == State.SAILING:
					progress += SPEED * delta / trip.length()
			if progress >= 1.0:
				progress = 1.0
				ship_state = State.ARRIVED
				_empty_time = 0.0
				if _wind:
					_wind.reset()
		State.ARRIVED:
			if mode == "anchor":
				_empty_time = 0.0 if _player_aboard() else _empty_time + delta
				if _empty_time > 2.5:
					ship_state = State.RETURNING
		State.TOWING, State.RETURNING:
			progress -= TOW_SPEED * delta / trip.length()
			if progress <= 0.0:
				progress = 0.0
				ship_state = State.DOCKED
				state["anchorUp"] = false
				_anchor.visible = true
				if runner and mode == "sail":
					runner.run()  # the calm wind again
	_shake = maxf(_shake - delta, 0.0)
	var pos := trip * progress
	if _water:
		pos.y = _water.surface_y() - global_position.y - 10.0 + trip.y * progress
	if _shake > 0.0:
		pos.x += sin(_shake * 60.0) * 2.0
	_deck.position = pos


func _run_aground() -> void:
	ship_state = State.AGROUND
	_shake = 0.6
	Sound.play_at("bridge_collapse", _deck.global_position)
	fail("The tide was %d when the anchor came up - the reef needs %d or more. The ship scraped the reef and gets towed back." % [_depart_tide, reef_need])
	await get_tree().create_timer(0.8).timeout
	ship_state = State.TOWING


## Sail mode: the sails must fit the wind.
func _check_sails(delta: float) -> void:
	var wind: int = lookup("wind") if lookup("wind") != null else 0
	var sails := int(state.get("sails", 0))
	var need := 0 if wind >= 7 else (1 if wind >= 3 else 2)
	if sails == need:
		_wrong_time = 0.0
		return
	_wrong_time += delta
	if _wrong_time < GRACE:
		return
	var text := ""
	if wind >= 7:
		text = "The wind was %d and the sails were up - the mast snapped!" % wind
	elif sails > need:
		text = "Full sails in a wind of %d ripped the sail!" % wind
	else:
		text = "The wind was %d and the sails were at %d - not enough sail, so the ship stalled." % [wind, sails]
	var why: String = runner.explain() if runner else ""
	if why != "":
		text += " " + why
	ship_state = State.AGROUND
	_shake = 0.6
	Sound.play_at("bridge_collapse", _deck.global_position)
	fail(text + " Back to the dock!")
	if _wind:
		_wind.reset()
	await get_tree().create_timer(0.8).timeout
	ship_state = State.TOWING


func _player_aboard() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var d := player.global_position - _deck.global_position
	return absf(d.x) < 36.0 and d.y > -40.0 and d.y < 2.0
