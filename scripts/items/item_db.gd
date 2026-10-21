class_name ItemDB
extends RefCounted
## Every item that can go in the hotbar. Add new items here.
##   name     shown above the hotbar when the item is selected
##   texture  sprite sheet the icon comes from
##   region   the icon's pixels inside that sheet
##   diagonal draw the icon tilted 45 degrees (Minecraft-style swords and tools)
## Manuals are items too: "manual_<id>" for every manual in ManualLibrary (left-click to read).

const MANUAL_PREFIX := "manual_"
const BOOKS := preload("res://assets/shared/items/books.png")

const ITEMS := {
	"sword": {
		"name": "SWORD",
		"texture": preload("res://assets/level2_treasure_hunters/characters/captain_clown_nose/sword_idle.png"),
		"region": Rect2(16, 15, 19, 7),
		"diagonal": true,
	},
}


static func has(id: String) -> bool:
	return not get_item(id).is_empty()


static func get_item(id: String) -> Dictionary:
	if id.begins_with(MANUAL_PREFIX):
		var manual_id := id.trim_prefix(MANUAL_PREFIX)
		var manual := ManualLibrary.get_manual(manual_id)
		if manual.is_empty():
			return {}
		var book: int = manual.get("book", 0)
		return {
			"name": manual["title"],
			"texture": BOOKS,
			"region": Rect2(book * 16, 0, 16, 16),
			"manual": manual_id,
		}
	return ITEMS.get(id, {})


## The item id for a manual, e.g. "variables_101" -> "manual_variables_101".
static func manual_item(manual_id: String) -> String:
	return MANUAL_PREFIX + manual_id
