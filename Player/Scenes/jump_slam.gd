class_name PlayerStateJumpSlam
extends PlayerState

const DASH_AUDIO = preload("uid://bkaogxsakt1wl")
const BOOM_AUDIO = preload("uid://byjx710kqcabp")
const BREAK_WOOD_AUDIO = preload("uid://brv656rb7cddj")

@export var hop_velocity: float = -300.0
@export var minimum_hop_time: float = 0.10

var hop_timer: float = 0.0


func init() -> void:
	pass


func enter() -> void:
	hop_timer = 0.0


	player.collision_stand.set_deferred("disabled", false)
	player.collision_crouch.set_deferred("disabled", true)
	player.da_stand.set_deferred("disabled", false)
	player.da_crouch.set_deferred("disabled", true)


	player.animation_player.play("Jump")


	player.velocity.y = hop_velocity


	Audio.play_spatial_sound(DASH_AUDIO, player.global_position)


func exit() -> void:
	pass


func handle_inputs(_event: InputEvent) -> PlayerState:
	return null


func process(_delta: float) -> PlayerState:
	return null


func physics_process(delta: float) -> PlayerState:
	hop_timer += delta


	if hop_timer >= minimum_hop_time and player.velocity.y >= 0:
		return ground_slam

	return next_state
