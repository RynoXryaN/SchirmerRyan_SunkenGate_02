@tool
@icon( "res://General/Icons/breakable.svg" )
class_name Breakable
extends Node2D

enum Size { SMALL, LARGE }
enum DaggerResponse { STICK_IN, BOUNCE_OFF, BOUNCE_THROUGH }

signal destroyed
signal damage_taken

@export_category( "Breakable" )
@export var size : Size = Size.SMALL
@export var dagger_response : DaggerResponse = DaggerResponse.BOUNCE_OFF

# Retained for special existing breakables such as ability orbs. Ordinary props
# use `size`: small props take one hit, while large props take two dagger hits.
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

var _large_dagger_hits_remaining : int = 2
var _is_destroyed : bool = false


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

	if _is_ground_slam( attack_area ):
		_destroy()
		return

	if fixed_hit_count:
		hp -= 1
	elif size == Size.SMALL:
		hp = 0
	elif _is_dagger( attack_area ):
		_large_dagger_hits_remaining -= 1
		hp = _large_dagger_hits_remaining
	else:
		# The player's main attack breaks large props in one hit.
		hp = 0
		
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
		_destroy( pos, dir )
	pass


func break_apart() -> void:
	_destroy()


func is_destroyed() -> bool:
	return _is_destroyed


func _destroy( pos : Vector2 = Vector2.INF, dir : Vector2 = Vector2.UP ) -> void:
	if _is_destroyed:
		return

	if not pos.is_finite():
		pos = global_position + emission_offset

	_is_destroyed = true
	hp = 0
	if use_persistence and persistent_id != "":
		SaveManager.persistent_data[persistent_id] = "destroyed"
	destroyed.emit()
	Audio.play_spatial_sound( destroy_audio, pos )
	#for p in destroy_particles:
		#VisualEffectsFactory.destroy_particles( pos, dir, p )
	clear_collisions()
	var tween : Tween = create_tween()
	tween.tween_property( self, "modulate", Color(modulate, 0), 0.4)
	await tween.finished
	queue_free()


func _is_dagger( attack_area : AttackArea ) -> bool:
	return attack_area.get_parent() is DaggerProjectile


func _is_ground_slam( attack_area : AttackArea ) -> bool:
	return attack_area.name == "GroundSlamAttackArea"
	
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
