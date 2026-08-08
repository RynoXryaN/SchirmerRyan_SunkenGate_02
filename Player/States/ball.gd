class_name PlayerStateBall
extends PlayerState

const MORPH_AUDIO = preload("uid://d0bmvivsi0q3o")
const MORPH_OUT_AUDIO = preload("uid://c7uaktydkxkog")

@export var jump_velocity : float = 400

var on_floor : bool = true

@onready var ball_ray_up: RayCast2D = %BallRay_up
@onready var ball_ray_down: RayCast2D = %BallRay_down


func init()	-> void:
	pass
	

func enter() -> void:
	player.animation_player.play( "ball" )
	var shape : CapsuleShape2D = player.collision_stand.get_shape() as CapsuleShape2D
	shape.radius = 12.0
	shape.height = 24.0
	
	player.collision_stand.position.y = -12
	player.da_stand.position.y = -12

	player.velocity.y -= 100
	Audio.play_spatial_sound( MORPH_AUDIO, player.global_position )
	pass
	

func exit() -> void:
	player.animation_player.speed_scale = 1
	var shape : CapsuleShape2D = player.collision_stand.get_shape() as CapsuleShape2D
	shape.radius = 8.0
	shape.height = 46.0
	
	player.collision_stand.position.y = -23
	player.da_stand.position.y = -23
	
	Audio.play_spatial_sound( MORPH_OUT_AUDIO, player.global_position )
	pass
	

func handle_inputs( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "ball"):
		if can_stand():
			if player.is_on_floor():
				return idle
			return fall
	if event.is_action_pressed( "jump" ):
		if player.is_on_floor():
			if Input.is_action_just_pressed( "down" ):
				player.one_way_platform_raycast.force_raycast_update()
				if player.one_way_platform_raycast.is_colliding():
					player.position.y += 4
					return null
			player.velocity.y -= jump_velocity
			#jump_audio.play
			VisualEffectsFactory.jump_dust( player.global_position )
	if event.is_action_pressed( "dash" ) and player.can_dash():
		return dash
	if event.is_action_pressed( "attack" ):
		return attack
	#if _event.is_action_pressed( "jump" ):
		#return jump
	return next_state
	

func process( _delta: float ) -> PlayerState:
	if player.direction.x == 0:
		player.animation_player.speed_scale = 0
	else:
		player.animation_player.speed_scale = 1
	#elif player.direction.y > 0.5:
		#return crouch
	return next_state
		

func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed

	if on_floor:
		if not player.is_on_floor():
			on_floor = false
			VisualEffectsFactory.jump_dust( player.global_position )
		else:
			if player.is_on_floor():
				on_floor = true
				VisualEffectsFactory.land_dust( player.global_position )
	return next_state

func can_stand() -> bool:
	ball_ray_up.force_raycast_update()
	ball_ray_down.force_raycast_update()
	if ball_ray_down.is_colliding() and ball_ray_up.is_colliding():
		return false
	return true
