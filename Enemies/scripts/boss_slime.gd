@tool
@icon( "res://General/Icons/enemy.svg" )
class_name BossSlime
extends Enemy

@export var boss_scale : float = 5.0
@export var boss_health : float = 150.0
@export var phase_2_health_percent : float = 0.5

var phase_2_started : bool = false

func setup() -> void:
	scale = Vector2.ONE * boss_scale
	health = boss_health
	super.setup()


func _physics_process(delta : float) -> void:
	super._physics_process(delta)
	
	if not phase_2_started and blackboard.health <= boss_health * phase_2_health_percent:
		phase_2_started = true
		start_phase_2()
		
func start_phase_2() -> void:
	print("Boss Slime phase 2!")
