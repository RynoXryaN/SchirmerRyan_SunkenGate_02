class_name DaggerRicochet
extends RigidBody2D

@export var fade_duration : float = 1.5
@export var minimum_spin_speed : float = 10.0
@export var maximum_spin_speed : float = 18.0


func launch( initial_velocity : Vector2 ) -> void:
	linear_velocity = initial_velocity
	
	angular_velocity = randf_range(
		minimum_spin_speed,
		maximum_spin_speed
	)
	
	if randf() < 0.5:
		angular_velocity *= -1.0
	
	var fade_tween : Tween = create_tween()
	fade_tween.set_trans( Tween.TRANS_SINE )
	fade_tween.set_ease( Tween.EASE_IN )
	fade_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_duration
	)
	
	await fade_tween.finished
	queue_free()
	pass
