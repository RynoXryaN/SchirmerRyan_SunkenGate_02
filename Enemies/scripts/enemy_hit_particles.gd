@icon ( "res://General/Icons/enemy_hit_particles.svg" )
class_name EnemyHitParticles
extends Marker2D

@export var hit_particles : Array[ HitParticleSettings ]
#@export var bleeding_particles : Array[ HitParticles ] = []
@export var death_particles : Array[ HitParticleSettings ]

var enemy_was_killed : bool = false



func _ready() -> void:
	if owner is Enemy:
		owner.was_hit.connect( _on_hit )
		owner.was_killed.connect( _on_killed )
	else:
		pass
	

func _on_hit(a: AttackArea) -> void:
	if enemy_was_killed:
		return

	var dir: Vector2 = global_position.direction_to(a.global_position)
	dir.x *= -1.0

	for p in hit_particles:
		var particle: HitParticles = VisualEffectsFactory.hit_particles(global_position, dir, p)
	pass

func _on_killed() -> void:
	enemy_was_killed = true

	for p in death_particles:
		var particle : HitParticles = VisualEffectsFactory.hit_particles(global_position, Vector2.ZERO, p)
		particle.one_shot = true
