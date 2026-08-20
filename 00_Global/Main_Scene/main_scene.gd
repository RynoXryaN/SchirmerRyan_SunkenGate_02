class_name MainScene
extends Node

const PLAYER_SCENE := preload("res://Player/Scenes/Player.tscn")

@onready var level_container: Node = %LevelContainer

var current_level: Node
var player_instance: Player


func load_level(scene_path: String) -> Node:
	if current_level:
		level_container.remove_child(current_level)
		current_level.queue_free()
		current_level = null

	var packed_level := load(scene_path) as PackedScene
	if not packed_level:
		push_error("Could not load level: %s" % scene_path)
		return null

	current_level = packed_level.instantiate()
	level_container.add_child(current_level)
	return current_level


func ensure_player_exists(spawn_position: Variant = null) -> Player:
	var players := _get_valid_players()
	if is_instance_valid(player_instance) and not player_instance.is_queued_for_deletion():
		players.erase(player_instance)
		players.push_front(player_instance)

	if players.is_empty():
		player_instance = PLAYER_SCENE.instantiate() as Player
		add_child(player_instance)
	else:
		player_instance = players.front()
		if player_instance.get_parent() != self:
			player_instance.reparent(self, true)

	# A malformed level or previous race must not leave two controllable players.
	for duplicate in players.slice(1):
		duplicate.get_parent().remove_child(duplicate)
		duplicate.queue_free()

	if spawn_position is Vector2:
		player_instance.global_position = spawn_position
	return player_instance


func clear_player() -> void:
	for player in _get_valid_players():
		player.get_parent().remove_child(player)
		player.queue_free()
	player_instance = null


func _get_valid_players() -> Array[Player]:
	var result: Array[Player] = []
	# Player.tscn currently also groups one child as "Player"; filter by class so
	# only actual Player scene roots participate in ownership and deduplication.
	for node in get_tree().get_nodes_in_group("Player"):
		if node is Player and is_instance_valid(node) and not node.is_queued_for_deletion():
			result.append(node as Player)
	return result
