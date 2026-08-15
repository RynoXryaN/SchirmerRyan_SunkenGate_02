#VisualEffects
extends Node

const DUST_EFFECT = preload("uid://ctfdruvli7tvj")
const HIT_PARTICLES = preload("uid://cnhuevkyfd4oy")
const ZOMBIE_DEATH = preload("res://Enemies/zombie_dawn/zombie_death_pieces.tscn")
const DAMAGE_NUMBER = preload("res://00_Global/visual_effects/damage_number.tscn")

signal camera_shook( strength : float )



# Create Dust Effects
func _create_dust_effect( pos : Vector2 ) -> DustEffect:
	var dust : DustEffect = DUST_EFFECT.instantiate()
	add_child( dust )
	dust.global_position = pos
	print("create dust effect")
	return dust
	

func jump_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.JUMP )
	pass


func land_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.LAND )
	pass


func hit_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.HIT )
	pass
	
func hit_particles( pos : Vector2, dir : Vector2, settings : HitParticleSettings) -> HitParticles:
	var p : HitParticles = HIT_PARTICLES.instantiate()
	add_child( p )
	p.global_position = pos
	p.start( dir, settings )
	return p
	
func camera_shake( strength : float = 1.0 ) -> void:
	camera_shook.emit( strength )
	pass


func spawn_zombie_death(pos: Vector2, launch_right: bool = true) -> ZombieDeathPieces:
	var effect: ZombieDeathPieces = ZOMBIE_DEATH.instantiate()
	effect.set_launch_direction(launch_right)
	var parent := get_tree().current_scene if get_tree().current_scene else self
	parent.add_child(effect)
	effect.global_position = pos
	effect.z_index = 50
	return effect


func damage_number( pos : Vector2, amount : float, color : Color = Color( 1.0, 0.85, 0.25, 1.0 )) -> DamageNumber:
	print( "FACTORY: damage_number called — ", amount )
	
	var number : DamageNumber = DAMAGE_NUMBER.instantiate()
	print( "FACTORY: instantiated successfully — ", number )
	
	var parent := get_tree().current_scene if get_tree().current_scene else self
	parent.add_child( number )
	
	number.global_position = pos
	print(
		"FACTORY: added to ",
		number.get_parent().name,
		" at ",
		number.global_position
	)
	
	number.setup( amount, color )
	print( "FACTORY: setup completed" )
	
	return number
