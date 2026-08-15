class_name ESZombieRise
extends EnemyState


func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity = Vector2.ZERO
	enemy.play_animation(animation_name if animation_name else "rise")
	await enemy.animation.animation_finished
	if not is_instance_valid(enemy) or not state_machine:
		return
	blackboard.can_decide = true
	var walk := state_machine.get_node_or_null("ESWalk") as EnemyState
	if walk:
		state_machine.change_state(walk)


func physics_update(_delta: float) -> void:
	enemy.velocity = Vector2.ZERO
