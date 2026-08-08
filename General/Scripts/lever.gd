class_name Lever
extends Node2D

signal lever_activated(target_id: String)

@export var target_id: String = ""
@export var one_shot: bool = true


@onready var lever_sprite: AnimatedSprite2D = $Lever_Sprite
@onready var area_2d: Area2D = $Area2D


var player_nearby: bool = false
var activated: bool = false


func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("action_interact"):
		print("Interact pressed. Player nearby: ", player_nearby)
	
	if player_nearby and Input.is_action_just_pressed("action_interact"):
		activate()


func _on_body_entered(body: Node2D) -> void:
	print("Something entered lever area: ", body.name)
	Messages.input_hint_changed.emit( "interact" )
	if body.is_in_group("Player"):
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	print("Something exited lever area: ", body.name)
	Messages.input_hint_changed.emit( "" )
	if body.is_in_group("player"):
		print("Player exited lever area")
		player_nearby = false


func activate() -> void:
	if one_shot and activated:
		return

	activated = true

	if lever_sprite:
		lever_sprite.play("pull")
		await lever_sprite.animation_finished
		
	print("Lever activated: ", target_id)
	lever_activated.emit(target_id)
