class_name PlayerStateGroundSlam
extends PlayerState

const DASH_AUDIO = preload("uid://bkaogxsakt1wl")
const BOOM_AUDIO = preload("uid://byjx710kqcabp")
const BREAK_WOOD_AUDIO = preload("uid://brv656rb7cddj")

# ADD PARTICLE EFFECTS HERE!!!

@export var velocity : float = 400
@export var effect_delay : float = 0.075
var effect_timer : float = 0

@onready var damage_area: DamageArea = $"../../DamageArea"
@onready var ground_slam_attack_area: AttackArea = %GroundSlamAttackArea
@onready var ground_slam_shape_cast: ShapeCast2D = $"../../GroundSlamShapeCast"


func init()	-> void:
	
	pass
	

func enter() -> void:
	player.animation_player.play( "ground_slam" )
	player.character.tween_color()
	Audio.play_spatial_sound( DASH_AUDIO, player.global_position )
	damage_area.start_invulnerable()
	ground_slam_attack_area.set_active()
	pass
	

func exit() -> void:
	VisualEffectsFactory.camera_shake( 10.0 )
	VisualEffectsFactory.land_dust( player.global_position )
	VisualEffectsFactory.hit_dust( player.global_position )
	Audio.play_spatial_sound( BOOM_AUDIO, player.global_position)
	damage_area.end_invulnerable()
	ground_slam_attack_area.set_active( false )
	pass
	

func handle_inputs( _event : InputEvent ) -> PlayerState:
	return null
	

func process( _delta: float ) -> PlayerState:
	check_collisions( _delta )
	effect_timer -= _delta
	if effect_timer < 0:
		effect_timer = effect_delay
		player.character.ghost()
	return null
		

func physics_process( _delta: float ) -> PlayerState:
	player.velocity = Vector2( 0, velocity )
	if player.is_on_floor():
		if not check_collisions( _delta ):
			return idle
	return next_state

func check_collisions ( _delta : float ) -> float:
	ground_slam_shape_cast.target_position.y = velocity * _delta
	ground_slam_shape_cast.force_shapecast_update()
	if ground_slam_shape_cast.is_colliding():
		for i in ground_slam_shape_cast.get_collision_count():
			var c = ground_slam_shape_cast.get_collider( i )
			var pos : Vector2 = ground_slam_shape_cast.get_collision_point( i )
			
			VisualEffectsFactory.hit_dust( pos )
			VisualEffectsFactory.camera_shake( 10.0 )
			
			if c.get_parent() is Breakable:
				var b : Breakable = c.get_parent()
				b.break_apart()
				for p in b.destroy_particles:
					VisualEffectsFactory.hit_particles( pos, Vector2.DOWN, p )
			else:
				if c.has_method("break_apart"):
					c.break_apart()
				else:
					c.queue_free()
				#VisualEffectsFactory.hit_particles( pos, Vector2.DOWN, HIT_WOOD_LARGE )
				#VisualEffectsFactory.hit_particles( pos, Vector2.DOWN, HIT_WOOD_MEDIUM )
				#VisualEffectsFactory.hit_particles( pos, Vector2.UP, HIT_WOOD_SMALL )
				Audio.play_spatial_sound( BREAK_WOOD_AUDIO, player.global_position )
		return true
	return false
	
	
	
