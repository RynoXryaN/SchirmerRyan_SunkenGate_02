class_name MovingPlatform
extends Node2D

@export var move_time: float = 2.0
@export var wait_at_top: float = 0.5
@export var wait_at_bottom: float = 0.5

var powered := false
var moving := false

@onready var platform: AnimatableBody2D = $Platform
@onready var start_marker: Marker2D = $StartMarker
@onready var end_marker: Marker2D = $EndMarker


func _ready() -> void:
	platform.global_position = start_marker.global_position


func start_moving() -> void:
	if powered:
		return

	powered = true
	loop_platform()
	#
	#
	#var tween := create_tween()
#
	#tween.tween_property( platform, "global_position", end_marker.global_position, move_time )
#
	#await tween.finished
	#
	#if auto_return:
		#await get_tree().create_timer(wait_before_return).timeout
#
		#var return_tween := create_tween()
		#return_tween.tween_property( platform, "global_position", start_marker.global_position, return_time )
#
		#await return_tween.finished
#
#
	#moving = false
#
#func _process(_delta: float) -> void:
	#if Input.is_action_just_pressed("Action_Interact"):
		#print("Platform test triggered")
		#start_moving()
		
func loop_platform() -> void:
	if moving:
		return

	moving = true

	while powered:
		var up_tween := create_tween()
		up_tween.tween_property( platform, "global_position", end_marker.global_position, move_time )

		await up_tween.finished
		await get_tree().create_timer(wait_at_top).timeout

		var down_tween := create_tween()
		down_tween.tween_property( platform, "global_position", start_marker.global_position, move_time )

		await down_tween.finished
		await get_tree().create_timer(wait_at_bottom).timeout

	moving = false


func _on_lever_lever_activated(target_id: String) -> void:
	print("Lever signal received")
	start_moving()
