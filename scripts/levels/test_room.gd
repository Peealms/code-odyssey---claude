extends Level
## Test room for trying movement, hero traits, the terminal and the Crabby tunnel.
## Paint new tiles on the "Terrain" TileMapLayer - camera limits update automatically.

@onready var terminal: CanvasLayer = $CodeTerminal
@onready var crab_zone: Area2D = $CrabZone
@onready var crabby: CharacterBody2D = $Crabby

var _crab_warned := false


func _ready() -> void:
	super()
	crab_zone.body_entered.connect(_on_crab_zone_entered)
	crabby.defeated.connect(_on_crabby_defeated)


## Walking up to the tunnel: Byte offers help, and the terminal gets a hint (not the answer).
func _on_crab_zone_entered(body: Node2D) -> void:
	if _crab_warned or body != player or player.has_sword:
		return
	_crab_warned = true
	byte.say("NEED A SWORD? PRESS E!", 4.0)
	terminal.pending_hint = "That crab is tough! Give yourself a sword with a boolean variable called hasSword."


func _on_crabby_defeated() -> void:
	hud.show_message("TUNNEL CLEAR!", 1.5)
	byte.react(true)
	byte.say("NICE SWORDWORK!", 2.5)
