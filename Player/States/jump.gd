class_name PlayerStateJump
extends PlayerState

@export var jump_velocity : float = 250
@export var jump_speed : float = 125

# What happens when this state is initialized?
func init()	-> void:
	pass
	
	
# What happens when we enter this state?
func enter() -> void:
	VisualEffectsFactory.jump_dust( player.global_position )
	player.animation_player.play( "Jump")
	#player.animation_player.pause()
	#player.add_debug_indicator( Color.GREEN)
	player.velocity.y -= jump_velocity
	
	do_jump()
	
	#Check if this is a buffer jump
	#If it is, handle jump button release condition retroactively
	if player.previous_state == fall and not Input.is_action_just_pressed( "jump" ):
		await get_tree().physics_frame
		player.velocity.y *= 0.5
		player.change_state( fall )
		pass
	pass
	
	

# What happens when you exit this state?
func exit() -> void:
	#player.add_debug_indicator( Color.YELLOW)
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
	if event.is_action_pressed( "left_dash" ) and player.can_dodge():
		return dodge
	if event.is_action_pressed( "attack" ):
		if player.ground_slam and Input.is_action_pressed( "down" ):
			return ground_slam
		return attack
	if event.is_action_released( "jump" ):
		player.velocity.y *= 0.5
		return fall
	if event.is_action_pressed( "ball" ) and player.can_morph():
		return ball
	return next_state
	
	
# What happens each process tick in this state?	
func process( _delta: float ) -> PlayerState:
	set_jump_frame()
	return next_state
		

# What happens each physics_process tick in this state?	
func physics_process( _delta: float ) -> PlayerState:
	if player.is_on_floor():
		return idle
	if player.velocity.y >= 0:
		return fall
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
	
func do_jump() -> void:
	if player.jump_count > 0:
		if player.double_jump == false:
			return
		elif player.jump_count > 1:
			return
	player.jump_count += 1
	player.velocity.y -= jump_velocity
	pass	
	
func set_jump_frame() -> void:
	var frame : float = remap( player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5 )
	player.animation_player.seek( frame, true )
	pass
