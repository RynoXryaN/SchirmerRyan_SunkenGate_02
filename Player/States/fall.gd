class_name PlayerStateFall
extends PlayerState

@export var fall_gravity_multiplier : float = 1.165
@export var coyote_time : float = 0.4
@export var jump_buffer_time : float = 0.2

var coyote_timer : float = 0
var buffer_timer : float = 0

# What happens when this state is initialized?
func init()	-> void:
	pass
	
	
# What happens when we enter this state?
func enter() -> void:
	player.animation_player.play( "Jump")
	player.animation_player.pause()
	player.gravity_multiplier = fall_gravity_multiplier
	
	# Handle jump count
	var prev : PlayerState = player.previous_state
	if prev == jump or prev == attack or prev == dash:
		coyote_timer = 0
	elif player.previous_state == crouch:
		coyote_timer = 0
		player.jump_count = 1
	else:
		coyote_timer = coyote_time
	pass
	

# What happens when you exit this state?
func exit() -> void:
	player.gravity_multiplier = 1.0
	pass
	

# What happens when an input is pressed?
func handle_inputs( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "right_dash" ) and player.can_dash():
		if player.character.flip_h:
			return back_dash
		else:
			return dash
	if event.is_action_pressed( "left_dash" ) and player.can_back_dash():
		if player.character.flip_h:
			return dash
		else:
			return back_dash
	if event.is_action_pressed( "attack" ):
		if player.ground_slam and Input.is_action_pressed( "down" ):
			return ground_slam
		return attack
	if event.is_action_pressed( "jump" ):
		if coyote_timer > 0:
			player.jump_count = 0
			return jump
		elif player.jump_count <= 1 and player.double_jump:
			return jump
		else:
			buffer_timer = jump_buffer_time
	if event.is_action_pressed( "ball" ) and player.can_morph():
		return ball
	return next_state
	
	
# What happens each process tick in this state?	
func process( _delta: float ) -> PlayerState:
	coyote_timer -= _delta
	buffer_timer -= _delta
	set_jump_frame()
	return next_state
		

# What happens each physics_process tick in this state?	
func physics_process( _delta: float ) -> PlayerState:
	if player.is_on_floor():
		VisualEffectsFactory.land_dust( player.global_position )
 		#player.add_debug_indicator( Color.RED)
		if buffer_timer > 0:
			player.jump_count = 0
			return jump
		return idle
	player.velocity.x = player.direction.x * player.move_speed	
	return next_state


func set_jump_frame() -> void:
	var frame : float = remap( player.velocity.y, 0.0, player.max_fall_speed, 0.5, 1.0 )
	player.animation_player.seek( frame, true )
	pass
