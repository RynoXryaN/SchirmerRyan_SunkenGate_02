class_name ESZombieWalk
extends ESWalk


func physics_update(_delta: float) -> void:
	# Keep movement aligned with the direction used by Enemy.change_dir().
	# The shared walk state only assigns velocity while touching a wall,
	# which makes this enemy appear to moonwalk or remain stationary.
	if enemy.is_on_wall():
		enemy.change_dir(-blackboard.dir)
	enemy.velocity.x = walk_speed * blackboard.dir
