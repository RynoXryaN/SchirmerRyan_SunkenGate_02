class_name DestructiblePropDebris
extends RigidBody2D

@onready var sprite: Sprite2D = $Sprite2D


func setup_from_prop(
	source: AnimatedSprite2D,
	direction: Vector2,
	impulse: Vector2,
	lifetime: float,
	fade_duration: float
) -> void:
	if source.sprite_frames and source.sprite_frames.has_animation(source.animation):
		sprite.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	sprite.flip_h = source.flip_h
	sprite.flip_v = source.flip_v
	apply_central_impulse(Vector2(absf(impulse.x) * direction.x, impulse.y))
	angular_velocity = randf_range(-5.0, 5.0)
	_fade_and_free(lifetime, fade_duration)


func start(direction: Vector2, impulse: Vector2, lifetime: float, fade_duration: float) -> void:
	apply_central_impulse(Vector2(absf(impulse.x) * direction.x, impulse.y))
	_fade_and_free(lifetime, fade_duration)


func _fade_and_free(lifetime: float, fade_duration: float) -> void:
	if lifetime > 0.0:
		await get_tree().create_timer(lifetime).timeout
	if fade_duration > 0.0:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, fade_duration)
		await tween.finished
	queue_free()

