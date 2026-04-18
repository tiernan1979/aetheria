# Blacksmith.gd
class_name Blacksmith
extends NPCBase

func _ready() -> void:
	npc_name = "Gorin the Blacksmith"
	wander_speed = 30.0
	super._ready()

func get_greeting() -> String:
	return "Fine steel, finest in the realm. What do you need?"

func get_dialogues() -> Array:
	return [
		"I can reforge your equipment to improve its stats — for a fee.",
		"Bring me rare ore bars and I'll craft special items not found elsewhere.",
		"Ferrite is my favourite — tough but workable.",
	]

func has_shop() -> bool:
	return true

func get_shop_inventory() -> Array:
	return [
		{id="blazite_bar",  name="Blazite Bar",   count=20, price=12},
		{id="ferrite_bar",  name="Ferrite Bar",   count=10, price=28},
		{id="iron_door",    name="Iron Door",     count=5,  price=45},
		{id="anvil",        name="Iron Anvil",    count=1,  price=120},
	]
