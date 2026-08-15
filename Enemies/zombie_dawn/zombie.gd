@icon("res://General/Icons/enemy.svg")
class_name ZombieDawn
extends Enemy

@export var death_pieces_scene: PackedScene


func _ready() -> void:
	super()


func _on_damage_taken(attack_area: AttackArea) -> void:
	# Keep this enemy's damage path aligned with Slime's single subtraction.
	blackboard.damage_source = attack_area
	blackboard.health -= attack_area.damage
	blackboard.can_decide = true

	if blackboard.health <= health * 0.5:
		bleeding = true

	if blackboard.health <= 0:
		bleeding = false
		damage_area.queue_free()
		hazard_area.queue_free()
		was_killed.emit()
	else:
		was_hit.emit(attack_area)


func show_damage_number(amount: float) -> void:
	VisualEffectsFactory.damage_number(global_position + Vector2(0.0, -58.0), amount)


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
