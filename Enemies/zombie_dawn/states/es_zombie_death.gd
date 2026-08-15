class_name ESZombieDeath
extends ESDeath

#@export var death_audio: AudioStream


func enter() -> void:
	blackboard.can_decide = false
	if death_audio:
		Audio.play_spatial_sound(death_audio, enemy.global_position)
	if enemy.has_method("spawn_death_effect"):
		enemy.spawn_death_effect()
	# LootDropper has already received was_killed before this state is entered.
	enemy.queue_free()


func physics_update(_delta: float) -> void:
	pass
