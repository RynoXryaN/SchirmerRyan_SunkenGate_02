@tool
@icon("res://General/Icons/enemy.svg")
class_name ZombieDawn
extends Enemy

@export var death_pieces_scene: PackedScene


func _ready() -> void:
	super()


func change_dir(new_dir: float) -> void:
	blackboard.dir = new_dir
	direction_changed.emit(new_dir)
	# This source sprite's native artwork faces left, while the shared Enemy
	# convention assumes the opposite. Invert the flip rule for this enemy.
	if sprite:
		sprite.flip_h = new_dir > 0


func spawn_death_effect() -> void:
	var launch_right := true
	if blackboard.damage_source:
		launch_right = global_position.x < blackboard.damage_source.global_position.x
	if VisualEffectsFactory.has_method("spawn_zombie_death"):
		VisualEffectsFactory.spawn_zombie_death(global_position, launch_right)
	elif death_pieces_scene:
		var effect = death_pieces_scene.instantiate()
		effect.set_launch_direction(launch_right)
		get_parent().add_child(effect)
		effect.global_position = global_position
