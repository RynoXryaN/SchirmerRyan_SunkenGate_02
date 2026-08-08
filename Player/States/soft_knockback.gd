class_name PlayerStateSoftKnockback
extends PlayerState


@export var default_push_speed: float = 100.0
@export var default_duration: float = 0.35

var push_speed: float
var push_direction: float
var time_remaining: float


func enter() -> void:
	time_remaining = maxf(time_remaining, default_duration)


func exit() -> void:
	player.velocity.x = 0.0


func handle_inputs(_event: InputEvent) -> PlayerState:
	return null


func process(delta: float) -> PlayerState:
	time_remaining -= delta

	if time_remaining <= 0.0:
		return idle

	return null


func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = push_speed * push_direction
	return null


func start(
	direction: float,
	speed: float = default_push_speed,
	duration: float = default_duration
) -> void:
	push_direction = signf(direction)
	push_speed = speed
	time_remaining = duration
	player.change_state(self)
