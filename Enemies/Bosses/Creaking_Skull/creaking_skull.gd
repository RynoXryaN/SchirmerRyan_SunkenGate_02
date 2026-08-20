@icon("res://General/Icons/enemy.svg")
class_name CreakingSkullBoss
extends CreakingSkullBase

@export_category("Boss Fireball")
@export var fireball_scene: PackedScene = preload("res://Enemies/Bosses/Creaking_Skull/creaking_skull_fireball.tscn")
@export var fireball_damage: float = 10.0
@export var fireball_speed: float = 155.0
@export var fireball_min_range: float = 118.0
@export var fireball_max_range: float = 290.0
@export var fireball_cooldown: float = 3.2
@export_range(0.1, 2.0, 0.05) var fireball_windup: float = 0.75
@export_range(0.1, 2.0, 0.05) var fireball_recovery: float = 0.65

@onready var fireball_mouth: Marker2D = $FireballMouth
@onready var fireball_charge: Polygon2D = $FireballMouth/FireballCharge
@onready var fireball_timer: Timer = $FireballCooldown

var _using_fireball := false
var _fireball_generation := 0


func _ready() -> void:
	super()
	fireball_timer.wait_time = fireball_cooldown


func _update_state() -> void:
	if _using_fireball:
		velocity.x = 0.0
		if target:
			_face_target()
		return

	if state == State.CHASE and _can_start_fireball():
		_start_fireball_attack()
		return

	super()


func _can_start_fireball() -> bool:
	if not target or not fireball_timer.is_stopped() or not fireball_scene:
		return false
	var distance := global_position.distance_to(target.global_position)
	return distance >= fireball_min_range and distance <= fireball_max_range


func _start_fireball_attack() -> void:
	_using_fireball = true
	_fireball_generation += 1
	var generation := _fireball_generation
	velocity.x = 0.0
	_face_target()
	fireball_timer.start()
	_position_fireball_mouth()
	fireball_charge.visible = true
	fireball_charge.scale = Vector2.ZERO
	fireball_charge.modulate.a = 1.0
	var charge_tween := create_tween()
	charge_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(fireball_charge, "scale", Vector2.ONE, fireball_windup)

	await get_tree().create_timer(fireball_windup).timeout
	if not _fireball_is_valid(generation):
		return
	_spawn_fireball()
	fireball_charge.visible = false

	await get_tree().create_timer(fireball_recovery).timeout
	if not _fireball_is_valid(generation):
		return
	_using_fireball = false


func _spawn_fireball() -> void:
	var projectile := fireball_scene.instantiate() as CreakingSkullFireball
	if not projectile:
		_using_fireball = false
		return
	get_parent().add_child(projectile)
	projectile.global_position = fireball_mouth.global_position
	projectile.configure(fireball_damage, fireball_speed)
	# Match the original boss's readable, mostly horizontal mouth shot.
	projectile.launch(Vector2(facing, 0.0))
	if debug_logging:
		print("CreakingSkullBoss: fireball launched")


func _position_fireball_mouth() -> void:
	# This marker is outside Visuals, so position it explicitly with combat facing.
	fireball_mouth.position = Vector2(43.0 * facing, -57.0)


func _on_damage_taken(hit: AttackArea) -> void:
	_cancel_fireball()
	super(hit)


func _cancel_fireball() -> void:
	if not _using_fireball:
		return
	_fireball_generation += 1
	_using_fireball = false
	fireball_charge.visible = false


func _fireball_is_valid(generation: int) -> bool:
	return is_instance_valid(self) and generation == _fireball_generation and state != State.DEATH
