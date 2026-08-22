class_name WaterSplashParticles
extends GPUParticles2D


func configure_width(width: float) -> void:
	configure_impact(width, 1.0)


func configure_impact(width: float, intensity: float = 1.0) -> void:
	var particle_material := process_material as ParticleProcessMaterial
	if particle_material:
		particle_material = particle_material.duplicate()
		process_material = particle_material
		particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		particle_material.emission_box_extents = Vector3(maxf(1.0, width * 0.5), 1.0, 1.0)
		particle_material.initial_velocity_min = 38.0 * intensity
		particle_material.initial_velocity_max = 72.0 * intensity
	amount = clampi(roundi(width * 0.75 * intensity), 8, 64)
	emitting = true
