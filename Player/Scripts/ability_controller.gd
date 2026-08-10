class_name AbilityController
extends Node

@export var ability_data : AbilityData

@onready var player : Player = owner as Player
@onready var projectile_spawn : Marker2D = %ProjectileSpawn

var cooldown_remaining : float = 0.0


func _process( delta : float ) -> void:
	cooldown_remaining = maxf( cooldown_remaining - delta, 0.0 )
	pass
	
	
func _unhandled_input( event : InputEvent ) -> void:
	if event.is_action_pressed( "use_ability" ):
		use_ability()
	pass
	
	
func use_ability() -> void:
	if not ability_data:
		return
		
	if not ability_data.projectile_scene:
		return
		
	if cooldown_remaining > 0:
		return
		
	if not player.has_mana( ability_data.mana_cost ):
		return
	
	var projectile : Projectile = ability_data.projectile_scene.instantiate() as Projectile
	
	if not projectile:
		return
	
	if not player.spend_mana( ability_data.mana_cost ):
		projectile.queue_free()
		return
	
	projectile_spawn.position.x = absf( projectile_spawn.position.x ) * player.facing_direction
	
	player.add_sibling( projectile )
	projectile.global_position = projectile_spawn.global_position
	projectile.launch( Vector2( player.facing_direction, 0 ) )
	
	cooldown_remaining = ability_data.cooldown
	pass
