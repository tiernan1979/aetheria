# Guide.gd
class_name Guide
extends NPCBase

func _ready() -> void:
	npc_name = "Arin the Guide"
	wander_speed = 32.0
	super._ready()

func get_greeting() -> String:
	return "Welcome to Aetheria! I can help you find your way."

func get_dialogues() -> Array:
	var world = get_tree().get_first_node_in_group("world")
	var hardmode = world.hardmode if world else false
	if hardmode:
		return [
			"Hardmode has begun. The world is more dangerous now.",
			"Seek out Aethite and Voidite ore — they're deep underground.",
			"The Void Herald is the final challenge. Prepare well.",
		]
	return [
		"Dig down to find blazite ore — it's your first metal.",
		"Build a Furnace to smelt ore into bars, then an Anvil to forge gear.",
		"At night, zombies and demon eyes attack. Build walls to stay safe.",
		"Look for glowing crystals deep underground — each ore tier unlocks new gear.",
		"Defeat the Slime King first. It's the easiest boss — summon it at night.",
	]
