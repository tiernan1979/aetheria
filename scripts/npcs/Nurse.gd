# Nurse.gd
class_name Nurse
extends NPCBase

func _ready() -> void:
	npc_name = "Dael the Nurse"
	wander_speed = 28.0
	super._ready()

func get_greeting() -> String:
	return "You look hurt. I can heal you — for a price."

func get_dialogues() -> Array:
	return [
		"Health is life. Come to me whenever you're hurt.",
		"The healing cost scales with how much HP you're missing.",
		"I can't cure curses or debuffs — only raw damage.",
	]

func has_shop() -> bool:
	return true

func get_shop_inventory() -> Array:
	# Nurse sells healing — price based on HP missing
	var player = get_tree().get_first_node_in_group("player")
	if not player: return []
	var missing = player.max_hp - player.hp
	if missing <= 0:
		return [{id="_heal_full", name="You're already at full health!", count=0, price=0}]
	var cost = int(missing * 0.8)
	return [{id="_heal_full", name="Heal to Full (%d HP)" % missing, count=1, price=cost}]

func _on_shop_purchase(item_id: String, _player) -> void:
	if item_id == "_heal_full":
		_player.hp = _player.max_hp
		_player.emit_signal("hp_changed", _player.hp, _player.max_hp)
