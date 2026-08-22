class_name WaterBubbleParticles
extends GPUParticles2D


func burst() -> void:
	restart()
	emitting = true
	await get_tree().create_timer(lifetime + 0.25).timeout
	queue_free()
