class_name SlamBreakable
extends StaticBody2D

@export var use_persistence : bool = true
@export var persistent_id : String = ""

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	print("SLAM BREAKABLE READY: ", name, " id=", persistent_id, " saved=", SaveManager.persistent_data.get(persistent_id, "NOT FOUND"))

	if use_persistence and persistent_id != "":
		if SaveManager.persistent_data.get(persistent_id, "") == "destroyed":
			queue_free()
			return

func break_apart() -> void:
	print("BREAK APART CALLED: ", name, " id=", persistent_id)
	if use_persistence and persistent_id != "":
		SaveManager.persistent_data[persistent_id] = "destroyed"

	queue_free()
