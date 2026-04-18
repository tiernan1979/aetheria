# Merchant.gd
class_name Merchant
extends NPCBase

func _ready() -> void:
	npc_name = "Sela the Merchant"
	wander_speed = 35.0
	super._ready()

func get_greeting() -> String:
	return "Coins! I need coins. Have a look."

func get_dialogues() -> Array:
	return [
		"I stock essentials — rope, torches, potions. Check back often.",
		"The rarer the ore you find, the more I'll pay for it.",
		"A Mining Potion will speed up your excavation significantly.",
	]

func has_shop() -> bool:
	return true

func get_shop_inventory() -> Array:
	return [
		{id="rope",           name="Rope",          count=99, price=2},
		{id="torch",          name="Torch",         count=99, price=1},
		{id="healing_potion", name="Healing Potion", count=20, price=15},
		{id="mana_potion",    name="Mana Potion",   count=20, price=18},
		{id="mining_potion",  name="Mining Potion", count=10, price=25},
		{id="coal",           name="Coal",          count=50, price=3},
		{id="platform",       name="Platform",      count=99, price=2},
	]
