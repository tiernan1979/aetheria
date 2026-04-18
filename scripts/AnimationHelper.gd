class_name AnimationHelper
# AnimationHelper.gd
# Call AnimationHelper.setup_player(anim_player, sprite) after scene loads.
# Builds all animations from the spritesheet without needing .anim resources.
# Spritesheet layout (20px wide, 32px tall per frame):
#   Row 0: idle  (4 frames)
#   Row 1: run   (6 frames)
#   Row 2: jump  (2 frames)
#   Row 3: fall  (2 frames)
#   Row 4: swing (4 frames)
#   Row 5: mine  (4 frames)
#   Row 6: die   (5 frames)

extends RefCounted

const PLAYER_ANIMS = {
	"idle":  {row=0, frames=4, fps=6,  loop=true},
	"run":   {row=1, frames=6, fps=12, loop=true},
	"jump":  {row=2, frames=2, fps=8,  loop=false},
	"fall":  {row=3, frames=2, fps=6,  loop=true},
	"swing": {row=4, frames=4, fps=16, loop=false},
	"mine":  {row=5, frames=4, fps=14, loop=false},
	"die":   {row=6, frames=5, fps=8,  loop=false},
}

static func setup_player(anim: AnimationPlayer, sprite: Sprite2D) -> void:
	if not anim or not sprite:
		push_warning("AnimationHelper.setup_player: null anim or sprite")
		return
	# Load spritesheet if not already set
	if not sprite.texture:
		var tex_path = "res://assets/sprites/player/player_sheet.png"
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = true
		else:
			push_warning("AnimationHelper: player_sheet.png not found at " + tex_path)
			return
	var lib = AnimationLibrary.new()
	for anim_name in PLAYER_ANIMS:
		var info = PLAYER_ANIMS[anim_name]
		var a    = Animation.new()
		a.loop_mode = Animation.LOOP_LINEAR if info.loop else Animation.LOOP_NONE
		a.length    = float(info.frames) / float(info.fps)

		var track = a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(track, "%s:frame" % sprite.get_path())

		for f in info.frames:
			var t  = float(f) / float(info.fps)
			var fr = info.row * sprite.hframes + f
			a.track_insert_key(track, t, fr)

		lib.add_animation(anim_name, a)

	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)

static func setup_enemy_simple(anim: AnimationPlayer, sprite: Sprite2D,
		idle_frames:int=2, walk_frames:int=2,
		attack_frames:int=2, die_frames:int=3) -> void:
	if not anim or not sprite: return
	"""For single-row enemy spritesheets: idle|walk|attack|die"""
	var lib = AnimationLibrary.new()
	var anims = [
		["idle",   0,                                     idle_frames,   6,  true],
		["walk",   idle_frames,                           walk_frames,  10,  true],
		["attack", idle_frames+walk_frames,               attack_frames,14,  false],
		["die",    idle_frames+walk_frames+attack_frames, die_frames,    8,  false],
	]
	for info in anims:
		var a  = Animation.new()
		a.loop_mode = Animation.LOOP_LINEAR if info[4] else Animation.LOOP_NONE
		a.length    = float(info[2]) / float(info[3])
		var track = a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(track, "%s:frame" % sprite.get_path())
		for f in info[2]:
			var t  = float(f) / float(info[3])
			a.track_insert_key(track, t, info[1] + f)
		lib.add_animation(info[0], a)

	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
