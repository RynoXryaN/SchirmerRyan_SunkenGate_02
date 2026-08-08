class_name PlayerStateCrouch
extends PlayerState

@export var deceleration_rate : float = 15

# What happens when this state is initialized?
func init()	-> void:
	pass
	
	
# What happens when we enter this state?
func enter() -> void:
	# Play animation
	player.animation_player.play( "Crouch")
	player.collision_stand.disabled = true
	player.collision_crouch.disabled = false
	player.da_stand.disabled = true
	player.da_crouch.disabled = false
	pass
	

# What happens when you exit this state?
func exit() -> void:
	player.collision_stand.set_deferred( "disabled", false)
	player.collision_crouch.set_deferred( "disabled", true)
	player.da_stand.set_deferred( "disabled", false)
	player.da_crouch.set_deferred( "disabled", true)
	pass
	

# What happens when an input is pressed?
func handle_inputs( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "dash" ) and player.can_dash():
		return dash
	#if event.is_action_pressed( "attack" ):
		#return attack
	if event.is_action_pressed("attack"):
		if player.ground_slam and not player.one_way_platform_raycast.is_colliding():
			return jump_slam

		return attack
	if event.is_action_pressed( "jump" ):
		if player.one_way_platform_raycast.is_colliding() == true:
			player.position.y += 4
			return fall
		return jump
	if event.is_action_pressed( "ball" ) and player.can_morph():
		return ball
	return next_state
	
	
# What happens each process tick in this state?	
func process( _delta: float ) -> PlayerState:
	if player.direction.y <= 0.5:
		return idle
	return next_state
		

# What happens each physics_process tick in this state?	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x -= player.velocity.x * deceleration_rate * _delta
	return next_state
