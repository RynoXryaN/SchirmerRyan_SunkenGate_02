@tool
@icon( "res://General/Icons/breakable.svg" )
class_name Breakable
extends Node2D

signal destroyed
signal damage_taken

@export var hp : float = 3
@export var fixed_hit_count : bool = false
@export var persistent_id : String = ""
@export var use_persistence : bool = false

@export_category( "Particles" )
@export var emission_offset : Vector2 = Vector2.ZERO
@export var hit_particles : Array[ HitParticleSettings ]
@export var destroy_particles : Array[ HitParticleSettings ]

@export_category( "Audio" )
@export var hit_audio : AudioStream = preload( "res://General/Audio/hit.wav" )
@export var destroy_audio : AudioStream = preload( "res://General/Audio/break_wood.wav" )


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if use_persistence and persistent_id != "":
		if SaveManager.persistent_data.get(persistent_id, "") == "destroyed":
			queue_free()
			return
	for c in get_children():
		if c is DamageArea:
			c.damage_taken.connect( _on_damage_taken )
	pass
	
func _on_damage_taken( attack_area : AttackArea ) -> void:
	if get_parent() is AbilityPickup and attack_area.name == "GroundSlamAttackArea":
		print("IGNORED GROUND SLAM ON ABILITY PICKUP: ", get_parent().name)
		return

	if fixed_hit_count:
		hp -= 1
	else:
		hp -= attack_area.damage
		
	var pos : Vector2 = global_position + emission_offset
	var dir : Vector2 = Vector2( 1, -1 )
	if attack_area.global_position.x > global_position.x:
		dir.x *= -1
		
	if hp > 0:
		damage_taken.emit()
		Audio.play_spatial_sound( hit_audio, pos )
		#for p in hit_particles:
			#VisualEffectsFactory.hit_particles( pos, Vector2(dir, 0), p )
	else:
		if use_persistence and persistent_id != "":
			SaveManager.persistent_data[persistent_id] = "destroyed"
		destroyed.emit()
		Audio.play_spatial_sound( hit_audio, pos )
		#for p in destroy_particles:
			#VisualEffectsFactory.destroy_particles( pos, Vector2(dir, 0), p )
		clear_collisions()
		var tween : Tween = create_tween()
		tween.tween_property( self, "modulate", Color(modulate, 0), 0.4)
		await tween.finished
	if hp <= 0:
		queue_free()
	pass
	
func clear_collisions() -> void:
	for c in get_children():
		if c is StaticBody2D:
			c.queue_free()
	pass
	
	
func _get_configuration_warnings() -> PackedStringArray:
	if _check_for_damage_area() == false:
		return ["Requires a DamageArea node!"]
	else:
		return[]
		
func _check_for_damage_area() -> bool:
	for c in get_children():
		if c is DamageArea:
			return true
	return false
