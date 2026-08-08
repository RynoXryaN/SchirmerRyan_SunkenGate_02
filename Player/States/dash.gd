class_name PlayerStateDash
extends PlayerState

const DASH_AUDIO = preload("uid://bkaogxsakt1wl")

@export var duration : float = 0.25
@export var speed : float = 300
@export var effect_delay : float = 0.05

var dir : float = 1.0
var timer : float = 0.0
var effect_timer : float = 0.0

@onready var damage_area: DamageArea = $"../../DamageArea"


func init()	-> void:
	
	pass
	

func enter() -> void:
	player.animation_player.play( "dash" )
	timer = duration
	effect_timer = 0.0
	get_dash_direction()
	damage_area.make_invulnerable( duration )
	#Audio.play_spatial_sound( DASH_AUDIO, player.global_position )pass
	#player.character.tween_color()
	player.gravity_multiplier = 0.0
	player.velocity.y = 0.0
	
	player.dash_count += 1
	
	player.character.tween_color()
	
	pass
	

func exit() -> void:
	player.gravity_multiplier = 1.0
	pass
	

func handle_inputs( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "ball" ) and player.can_morph():
		return ball
	return null
	

func process( _delta: float ) -> PlayerState:
	# collision checking
	timer -= _delta
	if timer <= 0:
		if player.is_on_floor():
			return idle
		else:
			return fall
			
	effect_timer -= _delta
	if effect_timer < 0:
		effect_timer = effect_delay
		player.character.ghost()
	return null
		

func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = ( speed * (timer / duration) + speed ) * dir
	#if player.is_on_floor():
		#return idle
	return next_state
	
func get_dash_direction() -> void:
	dir = 1
	if player.character.flip_h == true:
		dir = -1.0
pass
