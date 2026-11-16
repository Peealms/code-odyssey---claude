extends SceneTree
## Checks that music tracks never pile up (Sound.music / Sound.stop_music). After every switch
## has finished fading, exactly one track may be heard.
## Run:  godot --path . --script res://tools/test_sound.gd
## The sequences are the ones that used to overlap: the backstory (menu -> stop -> menu ->
## final_exam) going into the tutorial (rooms), and switches faster than the 1 s fade.

var sound: Node
var results: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	results.append(("PASS  " if ok else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	print(results[-1])


func wait(s: float) -> void:
	await create_timer(s).timeout


func heard() -> int:
	return sound.music_playing()


func _run() -> void:
	sound = root.get_node("Sound")
	sound.music("menu")
	await wait(1.3)
	check("The menu music plays alone", heard() == 1, "tracks=%d" % heard())

	# The backstory: it stops the menu music, starts it again, then switches to the exam music.
	sound.stop_music()
	await wait(0.3)
	sound.music("menu")
	await wait(1.3)
	check("Story: stop, then menu again - one track", heard() == 1, "tracks=%d" % heard())
	sound.music("final_exam")
	await wait(1.3)
	check("Story: menu -> final_exam - one track", heard() == 1, "tracks=%d" % heard())
	# Into the tutorial: its room starts the room music.
	sound.music("rooms")
	await wait(1.3)
	check("Tutorial: final_exam -> rooms - one track", heard() == 1, "tracks=%d" % heard())
	sound.music("menu")
	await wait(1.3)
	check("Back to the menu - one track", heard() == 1, "tracks=%d" % heard())

	# Switches faster than the fade.
	sound.music("rooms")
	await wait(0.2)
	sound.music("final_exam")
	await wait(0.2)
	sound.music("menu")
	await wait(0.2)
	check("Mid-crossfade, at most two tracks", heard() <= 2, "tracks=%d" % heard())
	await wait(1.3)
	check("Three quick switches end with one track", heard() == 1, "tracks=%d" % heard())

	sound.stop_music()
	await wait(0.2)
	sound.music("rooms")
	await wait(1.3)
	check("Music started during a fade-out isn't cut off", heard() == 1, "tracks=%d" % heard())
	sound.stop_music()
	await wait(1.3)
	check("stop_music silences everything", heard() == 0, "tracks=%d" % heard())

	var failed := results.filter(func(r): return r.begins_with("FAIL")).size()
	print("%d checks, %d failed" % [results.size(), failed])
	quit()
