@tool
@icon ("res://General/Icons/ability_pickup.svg")
class_name AbilityPickup
extends Node2D

enum Type { DOUBLE_JUMP, DASH, GROUND_SLAM, MORPH_ROLL }

@export var type : Type = Type.DOUBLE_JUMP :
	set( value ):
		type = value
		_set_animation()

@onready var ability_anim: AnimationPlayer = %AbilityAnim
@onready var orb_anim: AnimationPlayer = %OrbAnim
@onready var breakable: Breakable = $Breakable
@onready var orb_sprite: Sprite2D = %OrbSprite
@onready var hint_area: Area2D = %HintArea

var hint_message_shown: bool = false


func _ready() -> void:
	_set_animation()
	print("ABILITY PICKUP READY: ", name, " ability=", get_ability_name(), " saved=", SaveManager.persistent_data.get(get_ability_name(), "NOT FOUND"))

	if SaveManager.persistent_data.get_or_add( get_ability_name(), "" ) == "acquired":
		queue_free()
		return

	breakable.destroyed.connect( _on_destroyed )
	breakable.damage_taken.connect( _on_damage_taken )

	hint_area.body_entered.connect( _on_hint_area_body_entered )
	hint_area.body_exited.connect( _on_hint_area_body_exited )
	pass
	
func _on_damage_taken() -> void:
	orb_sprite.frame += 1
	print("ABILITY PICKUP HIT: ", get_ability_name())
	pass

func _on_destroyed() -> void:
	print("ABILITY DESTROYED: ", get_ability_name(), " type=", type)
	
	SaveManager.persistent_data[ get_ability_name() ] = "acquired"
	
	_reward_ability()
	_show_ability_message()
	
	orb_anim.play( "destroy" )
	await orb_anim.animation_finished
	queue_free()
	pass

func _reward_ability() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	match type:
		Type.DOUBLE_JUMP:
			player.double_jump = true
		Type.DASH:
			player.dash = true
		Type.GROUND_SLAM:
			player.ground_slam = true
		Type.MORPH_ROLL:
			player.morph_roll = true
	pass

func _show_ability_message() -> void:
	match type:
		Type.DOUBLE_JUMP:
			Messages.message_requested.emit(
				"DOUBLE JUMP ACQUIRED\nPress Jump again while airborne to reach higher places.", 10.0 )

		Type.DASH:
			Messages.message_requested.emit(
				"DASH ACQUIRED\nPress Dash (z for keyboard, b for xbox or circle for DualSense) to burst forward across gaps and hazards.", 10.0 )

		Type.GROUND_SLAM:
			Messages.message_requested.emit(
				"GROUND SLAM ACQUIRED\nWhile airborne, use Ground Slam (DOWN plus ATTACK) to smash fragile floors.", 10.0 )

		Type.MORPH_ROLL:
			Messages.message_requested.emit(
				"MORPH ROLL ACQUIRED\nC / Xbox Y / DualSense Triangle: enter or exit Morph Roll.", 10.0 )

func _set_animation() -> void:
	if not ability_anim:
		ability_anim = %AbilityAnim
	ability_anim.play( get_ability_name() )
	pass
	
func get_ability_name() -> String:
	match type:
		Type.DOUBLE_JUMP:
			return "double_jump"
		Type.DASH:
			return "dash"
		Type.GROUND_SLAM:
			return "ground_slam"
		Type.MORPH_ROLL:
			return "morph_roll"
	return ""
	
func _on_hint_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	Messages.input_hint_changed.emit("attack")

	if not hint_message_shown:
		hint_message_shown = true
		Messages.message_requested.emit("Attack and BREAK the orb to claim the ability.", 10.0 )


func _on_hint_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	Messages.input_hint_changed.emit("")
