class_name PlayerStateIdle
extends PlayerState



func init()	-> void:
	pass
	

func enter() -> void:
	player.animation_player.play( "idle" )
	player.jump_count = 0
	player.dash_count = 0
	pass
	

func exit() -> void:
	pass
	

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
	

func process( _delta: float ) -> PlayerState:
	if player.direction.x != 0:
		return run
	elif player.direction.y > 0.5:
		return crouch
	return next_state
		

func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0
	return next_state
