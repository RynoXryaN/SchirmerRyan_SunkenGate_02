class_name HitParticles
extends GPUParticles2D


func start( dir : Vector2, settings : HitParticleSettings ) -> void:
	if settings:
		amount = settings.count
		modulate = settings.color
		texture = settings.texture
	# Each burst needs its own material so simultaneous hits cannot redirect each other.
	process_material = process_material.duplicate()
	process_material.direction = Vector3( dir.x, dir.y, 0 )
	restart()
	emitting = true
	await finished
	queue_free()
	pass
