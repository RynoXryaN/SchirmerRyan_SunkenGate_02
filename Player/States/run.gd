class_name PlayerStateRun
extends PlayerState


# What happens when this state is initialized?
func init()	-> void:
	pass
	
	
# What happens when we enter this state?
func enter() -> void:
	#play animation
	player.animation_player.play( "Run")
	pass
	

# What happens when you exit this state?
func exit() -> void:
	pass
	

# What happens when an input is pressed?
func handle_inputs( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "dash" ) and player.can_dash():
		return dash
	if event.is_action_pressed( "attack" ):
		return attack
	if event.is_action_pressed( "jump" ):
		return jump
	if event.is_action_pressed( "ball" ) and player.can_morph():
		return ball
	return next_state
	
	
# What happens each process tick in this state?	
func process( _delta: float ) -> PlayerState:
	if player.direction.x == 0:
		return idle
	elif player.direction.y > 0.5:
		return crouch
	return next_state
		

# What happens each physics_process tick in this state?	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	if player.is_on_floor() == false:
		return fall
	return next_state
