@tool
@icon( "res://General/Icons/enemy.svg" )
class_name Enemy
extends CharacterBody2D

signal direction_changed( new_sir )
signal was_hit( a : AttackArea )
signal was_killed()


@export var health : float = 50
@export var affected_by_gravity : bool = true
@export var face_left_on_start : bool = false
@export_category("Combat Feedback")
@export var show_damage_numbers: bool = true
@export var damage_number_color: Color = Color(1.0, 0.35, 0.35, 1.0)
@export var flash_on_hit: bool = true
@export var hit_flash_color: Color = Color.WHITE
@export_range(0.01, 0.30, 0.01) var hit_flash_duration: float = 0.08
@export var spawn_blood_on_hit: bool = true
@export var blood_color: Color = Color(0.75, 0.05, 0.05, 1.0)
@export_range(0, 30, 1) var blood_particles_per_hit: int = 5
@export var spawn_blood_on_death: bool = true
@export_range(0, 60, 1) var blood_particles_on_death: int = 14
@export var hit_sound: AudioStream = preload( "res://General/Audio/hit.wav" )
@export var death_sound: AudioStream = preload( "res://General/Audio/death.wav" )
@export_range(-40.0, 10.0, 0.5) var hit_sound_volume_db: float = 0.0
@export_range(-40.0, 10.0, 0.5) var death_sound_volume_db: float = 0.0
@export_range( 0.0, 0.25, 0.01 ) var audio_pitch_variation : float = 0.05
@export_range( 0.0, 6.0, 0.1, "suffix:dB" ) var audio_volume_variation_db : float = 1.0

var sprite : Sprite2D
var animation : AnimationPlayer
var damage_area : DamageArea
var hazard_area : HazardArea

var state_machine : EnemyStateMachine
var decision_engine : DecisionEngine
var blackboard : BlackBoard

var bleed_timer : float = 0.0
var bleeding : bool = false
var _death_feedback_played: bool = false
var _flash_generation: int = 0
var _flash_active: bool = false
var _flash_original_self_modulate: Color

#var dir : float = 1.0
#var move_tween : Tween
#
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var sprite_2d: Sprite2D = $Sprite2D
#@onready var hazard_area: HazardArea = $HazardArea
#@onready var damage_area: DamageArea = $DamageArea
#@onready var edge_detector: EdgeDetector = $EdgeDetector
#
#
#
func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process( false )
		return
	setup()
	#animation_player.play( "walk" )
	#animation_player.animation_finished.connect( _on_animation_finished )
	#edge_detector.edge_detected.connect( _on_edge_detected )
	#change_direction( -1.0 if face_left_on_start else 1.0 )
	#damage_area.damage_taken.connect( _on_damage_taken )
	pass
#
func setup() -> void:
	blackboard = BlackBoard.new()
	blackboard.health = health
	
	for c in get_children():
		if c is AnimationPlayer and not animation:
			animation = c
		elif c is Sprite2D and not sprite:
			sprite = c
		elif c is DamageArea and not damage_area:
			damage_area = c
			c.damage_taken.connect( _on_damage_taken )
		elif c is HazardArea and not hazard_area:
			hazard_area = c
		elif c is EnemyStateMachine and not state_machine:
			state_machine = c
		elif c is DecisionEngine and not decision_engine:
			decision_engine = c
		pass
		
	if state_machine and decision_engine:
		state_machine.setup( self, blackboard )
		decision_engine.enemy = self
		decision_engine.blackboard = blackboard
	else:
		set_physics_process( false )
	pass

#
## physics process will move enemy and call state_machine.physics_process
func _physics_process( delta: float ) -> void:
	blackboard.update_distance_to_target( global_position )
	state_machine.change_state( decision_engine.decide() )
	if affected_by_gravity:
		velocity += get_gravity() * delta
	state_machine.physics_update( delta )
	
	if bleeding:
		bleed_timer -= delta

		if bleed_timer <= 0:
			bleed_timer = 0.2

			#VisualEffectsFactory.hit_particles( global_position, Vector2.DOWN,
				#$EnemyHitParticles.hit_particles[0] )
	#if is_on_wall():
		#change_direction( -dir )
	#
	#velocity += get_gravity() * delta
	#velocity.x = dir * move_speed
	move_and_slide()
	pass
#
func change_dir( new_dir : float ) -> void:
	blackboard.dir = new_dir
	direction_changed.emit( new_dir )
	if sprite:
		if new_dir < 0:
			sprite.flip_h = true
		elif new_dir > 0:
			sprite.flip_h = false

	pass
	
func play_animation( anim_name : String ) -> void:
	if animation.has_animation( anim_name ):
		animation.play( anim_name )
	pass
	

func _on_damage_taken( a : AttackArea ) -> void:
	if _death_feedback_played:
		return
	blackboard.damage_source = a
	blackboard.health -= a.damage
	blackboard.can_decide = true
	var hit_position := global_position + Vector2(0.0, -32.0)
	var hit_direction := (global_position - a.global_position).normalized()
	if hit_direction.is_zero_approx():
		hit_direction = Vector2.UP
	if show_damage_numbers:
		VisualEffectsFactory.damage_number(hit_position + Vector2(0.0, -20.0), a.damage, damage_number_color)

	if blackboard.health <= health * 0.5:
		bleeding = true
	
	if blackboard.health <= 0:
		_death_feedback_played = true
		bleeding = false
		_play_audio(death_sound, death_sound_volume_db)
		if spawn_blood_on_death:
			VisualEffectsFactory.blood_burst(hit_position, hit_direction, blood_color, blood_particles_on_death)
		damage_area.queue_free()
		hazard_area.queue_free()
		was_killed.emit()
		return

	if flash_on_hit:
		_flash_sprite()
	if spawn_blood_on_hit:
		VisualEffectsFactory.blood_burst(hit_position, hit_direction, blood_color, blood_particles_per_hit)
	_play_audio(hit_sound, hit_sound_volume_db)
	was_hit.emit( a )


func _flash_sprite() -> void:
	if not sprite:
		return
	_flash_generation += 1
	var generation := _flash_generation
	if not _flash_active:
		_flash_original_self_modulate = sprite.self_modulate
		_flash_active = true
	sprite.self_modulate = hit_flash_color
	await get_tree().create_timer(hit_flash_duration).timeout
	if is_instance_valid(sprite) and generation == _flash_generation:
		sprite.self_modulate = _flash_original_self_modulate
		_flash_active = false


func _play_audio(stream: AudioStream, volume_db: float) -> void:
	if stream:
		Audio.play_spatial_sound(
			stream,
			global_position,
			audio_pitch_variation,
			audio_volume_variation_db,
			volume_db
		)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray
	
	if not find_children( "*", "AnimationPlayer", false ):
		warnings.append( "Requires an AnimationPlayer!" )
	if not find_children( "*", "Sprite2D", false ):
		warnings.append( "Requires a Sprite2D!" )
	if not find_children( "*", "DamageArea", false ):
		warnings.append( "Requires a DamageArea!" )
	if not find_children( "*", "HazardArea", false ):
		warnings.append( "Requires a HazardArea!" )
	if not find_children( "*", "EnemyStateMachine", false ):
		warnings.append( "Requires an EnemyStateMachine!" )
	if not find_children( "*", "DecisionEngine", false ):
		warnings.append( "Requires a DecisionEngine!" )
		
	return warnings
