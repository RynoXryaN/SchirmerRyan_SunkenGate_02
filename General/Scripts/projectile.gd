class_name Projectile
extends CharacterBody2D

@export var speed : float = 300.0
@export var direction : Vector2 = Vector2.RIGHT
@export var max_lifetime : float = 5.0

var lifetime : float = 0.0


func _physics_process( delta : float ) -> void:
	lifetime += delta
	
	if lifetime >= max_lifetime:
		queue_free()
		return
	
	velocity = direction.normalized() * speed
	
	var collision : KinematicCollision2D = move_and_collide( velocity * delta )
	
	if collision:
		collision_response( collision )
	pass
	
	
func launch( new_direction : Vector2 ) -> void:
	direction = new_direction.normalized()
	pass
	
	
func collision_response( _collision : KinematicCollision2D ) -> void:
	pass
