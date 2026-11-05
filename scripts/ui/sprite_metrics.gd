class_name SpriteMetrics
extends RefCounted
## Where a character's body really is inside its animation frames. The frames of most sprites
## have transparent padding, so "bottom of the frame" is not "feet on the ground".

static var _cache := {}


## The rectangle (in frame pixels) covering the visible pixels of every frame of `anim`.
static func body_rect(frames: SpriteFrames, anim: StringName) -> Rect2:
	var key := "%d/%s" % [frames.get_instance_id(), anim]
	if _cache.has(key):
		return _cache[key]
	var result := Rect2()
	var have := false
	for i in frames.get_frame_count(anim):
		var tex := frames.get_frame_texture(anim, i)
		if tex == null:
			continue
		var img := tex.get_image()
		if img == null:
			continue
		if img.is_compressed():
			img.decompress()
		var used := Rect2(img.get_used_rect())
		if used.size == Vector2.ZERO:
			continue
		result = used if not have else result.merge(used)
		have = true
	if not have:
		var t := frames.get_frame_texture(anim, 0)
		result = Rect2(Vector2.ZERO, t.get_size() if t else Vector2.ONE)
	_cache[key] = result
	return result
