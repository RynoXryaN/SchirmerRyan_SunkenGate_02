class_name ESZombieDeath
extends ESDeath

func enter() -> void:
	blackboard.can_decide = false
	if enemy.has_method("spawn_death_effect"):
		enemy.spawn_death_effect()
	# LootDropper has already received was_killed before this state is entered.
	enemy.queue_free()


func physics_update(_delta: float) -> void:
	pass
