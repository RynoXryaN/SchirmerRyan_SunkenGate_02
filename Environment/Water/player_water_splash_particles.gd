class_name PlayerWaterSplashParticles
extends GPUParticles2D


func burst(strength: float = 1.0) -> void:
	amount = clampi(roundi(7.0 * strength), 4, 16)
	var particle_material := process_material as ParticleProcessMaterial
	if particle_material:
		particle_material = particle_material.duplicate()
		process_material = particle_material
		particle_material.initial_velocity_min *= strength
		particle_material.initial_velocity_max *= strength
	restart()
	emitting = true
	await get_tree().create_timer(lifetime + 0.25).timeout
	queue_free()
