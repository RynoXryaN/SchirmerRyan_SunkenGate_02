class_name PlayerStateDeath
extends PlayerState

const DEATH_AUDIO = preload("uid://eimeawmlftt7")


@export var invulnerable_duration : float = 0.5

@onready var damage_area: DamageArea = $"../../DamageArea"


func init()	-> void:
	pass
	

func enter() -> void:
	
	damage_area.make_invulnerable( invulnerable_duration )
	
	player.animation_player.play( "death" )
	
	Audio.play_spatial_sound( DEATH_AUDIO, player.global_position )
	Audio.play_music( null )
	
	await player.animation_player.animation_finished
	PlayerHud.show_game_over()
	
	pass
	

func exit() -> void:
	pass
	

func handle_inputs( event : InputEvent ) -> PlayerState:
	return null
	

func process( _delta: float ) -> PlayerState:
	return null
		

func physics_process( _delta: float ) -> PlayerState:
	
	player.velocity.x = 0
	
	return null
	
func make_invulnerable( duration : float = 1.0 ) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer( duration ).timeout
	process_mode = Node.PROCESS_MODE_INHERIT
	pass


func start_invulnerable() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED	
	pass
	
func end_invulnerable() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	pass
	
func _on_death() -> void:
	player.change_state( self )
	pass
