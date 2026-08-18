class_name MainScene
extends Node

@onready var level_container: Node = %LevelContainer

var current_level: Node


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
