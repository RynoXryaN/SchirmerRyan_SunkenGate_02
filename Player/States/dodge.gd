class_name PlayerStateDodge
extends PlayerState


@export var duration: float = 0.20
@export var speed: float = 160.0
@export var audio: AudioStream

var direction: float = 1.0
var timer: float = 0.0

@onready var damage_area: DamageArea = $"../../DamageArea"


func enter() -> void:
	# Dodge is the baseline backward movement. It intentionally reuses the
	# current back-dash animation until dedicated Dodge art is available.
	player.animation_player.play( "back_dash" )
	timer = duration
	direction = 1.0 if player.character.flip_h else -1.0
	damage_area.make_invulnerable( duration )
	if audio:
		Audio.play_spatial_sound( audio, player.global_position )
	player.gravity_multiplier = 0.0
	player.velocity.y = 0.0
	player.dodge_count += 1


func exit() -> void:
	player.gravity_multiplier = 1.0


func process( delta: float ) -> PlayerState:
	timer -= delta
	if timer <= 0.0:
		if player.is_on_floor():
			return idle
		else:
			return fall

	return null


func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = ( speed * ( timer / duration ) + speed ) * direction
	return next_state
