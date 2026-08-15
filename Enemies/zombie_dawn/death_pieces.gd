class_name ZombieDeathPieces
extends Node2D

@export var lifetime: float = 2.5
@export var fade_duration: float = 0.75
@export var collide_with_player: bool = false
@export var collide_with_enemies: bool = false
@export var initial_impulse: float = 70.0
@export var separation_impulse: float = 45.0
@export var rotation_impulse: float = 2.5
@export var gravity_scale: float = 1.0

var _launch_right := true
var _fading := false
var _fade_timer := 0.0


func set_launch_direction(launch_right: bool) -> void:
	_launch_right = launch_right


func _ready() -> void:
	for index in get_child_count():
		var body := get_child(index)
		if body is RigidBody2D:
			body.gravity_scale = gravity_scale
			body.collision_layer = 0
			body.collision_mask = 1
			if collide_with_player:
				body.set_collision_mask_value(5, true)
			if collide_with_enemies:
				body.set_collision_mask_value(6, true)
			var direction := 1.0 if _launch_right else -1.0
			var separation := -1.0 if index == 0 else 1.0
			body.apply_central_impulse(Vector2(direction * initial_impulse + separation * separation_impulse, -initial_impulse * 0.7))
			body.apply_torque_impulse(separation * rotation_impulse)


func _process(delta: float) -> void:
	if _fading:
		_fade_timer += delta
		var alpha: float= 1.0 - clamp(_fade_timer / fade_duration, 0.0, 1.0)
		for body in get_children():
			if body is RigidBody2D:
				body.modulate.a = alpha
		if _fade_timer >= fade_duration:
			queue_free()
	elif lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			_fading = true
			_fade_timer = 0.0
