extends Area2D
## The trophy at the end of a level. Touching it finishes the level - if `rooms` are set,
## only once every fruit in those rooms is collected (otherwise `blocked` fires, with the
## rooms that still have fruit, e.g. "THE LOW TUNNEL 2").

signal reached
signal blocked(fruit_left: int, where: String)

@export var rooms: Array[Node] = []  ## Rooms whose fruit must be collected first (empty = none).

var _done := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _done or not body.is_in_group("player"):
		return
	var left := 0
	var where: Array[String] = []
	for room in rooms:
		var missing: int = room.fruit_total - room.fruit_collected
		if missing > 0:
			left += missing
			where.append("%s %d" % [room.short_title(), missing])
	if left > 0:
		blocked.emit(left, ", ".join(where))
		return
	_done = true
	sprite.play("pressed")
	reached.emit()
