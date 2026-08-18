@icon("res://General/Icons/enemy.svg")
class_name CreakingSkull
extends Enemy

## Self-contained placeholder boss controller. State timing is kept here so the
## attack hitbox can never remain active because of an interrupted animation.

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVERY, HURT, DEATH }

@export_category("Boss Tuning")
@export var boss_health: float = 240.0
@export var move_speed: float = 24.0
@export var detection_range: float = 300.0
@export var attack_range: float = 92.0
@export var damage: float = 12.0
@export var attack_cooldown: float = 1.6
@export var debug_logging: bool = false
@export_category("Attack Timing")
@export_range(0.1, 2.0, 0.05) var windup_duration: float = 0.55
@export_range(0.05, 1.0, 0.05) var active_duration: float = 0.22
@export_range(0.1, 2.0, 0.05) var recovery_duration: float = 0.7
@export_range(0.05, 1.0, 0.05) var hurt_duration: float = 0.22

@onready var attack_hitbox: AttackArea = $AttackHitbox
@onready var edge_check: RayCast2D = $EdgeCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var visuals: Node2D = $Visuals
@onready var death_pieces: Node2D = $DeathPieces

var state: State = State.IDLE
var state_time := 0.0
var cooldown_time := 0.0
var target: Node2D
var facing := -1.0
var _death_started := false


func _ready() -> void:
	# Use the shared Enemy receiver/feedback contract without its roaming state
	# machine; this boss owns a small deterministic combat state flow instead.
	health = boss_health
	blackboard = BlackBoard.new()
	blackboard.health = boss_health
	sprite = $Visuals/Pose/BodySprite
	animation = $AnimationPlayer
	damage_area = $DamageArea
	hazard_area = $ContactHazard
	damage_area.damage_taken.connect(_on_damage_taken)
	was_killed.connect(_begin_death)
	attack_hitbox.damage = damage
	hazard_area.damage = damage * 0.5
	attack_hitbox.set_active(false)
	_play_state_animation("idle")


func _physics_process(delta: float) -> void:
	if affected_by_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	if state == State.DEATH:
		velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
		move_and_slide()
		return

	cooldown_time = maxf(0.0, cooldown_time - delta)
	state_time = maxf(0.0, state_time - delta)
	_acquire_target()
	_update_state()
	move_and_slide()


func _acquire_target() -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("Player") as Node2D
	if target and global_position.distance_to(target.global_position) > detection_range:
		target = null


func _update_state() -> void:
	var distance := INF if not target else global_position.distance_to(target.global_position)
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 100.0)
			if target:
				_set_state(State.CHASE)
		State.CHASE:
			if not target:
				_set_state(State.IDLE)
				return
			_face_target()
			if distance <= attack_range and cooldown_time <= 0.0:
				_set_state(State.WINDUP)
			elif _can_advance():
				velocity.x = move_speed * facing
			else:
				velocity.x = 0.0
		State.WINDUP:
			velocity.x = 0.0
			_face_target()
			if state_time <= 0.0:
				_set_state(State.ATTACK)
		State.ATTACK:
			velocity.x = 0.0
			if state_time <= 0.0:
				_set_state(State.RECOVERY)
		State.RECOVERY, State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 120.0)
			if state_time <= 0.0:
				_set_state(State.CHASE if target else State.IDLE)


func _set_state(next: State) -> void:
	if state == State.DEATH:
		return
	attack_hitbox.set_active(false)
	state = next
	match state:
		State.IDLE:
			_play_state_animation("idle")
		State.CHASE:
			_play_state_animation("shamble")
		State.WINDUP:
			state_time = windup_duration
			_play_state_animation("attack_windup")
		State.ATTACK:
			state_time = active_duration
			attack_hitbox.damage = damage
			attack_hitbox.set_active(true)
			_play_state_animation("attack")
		State.RECOVERY:
			state_time = recovery_duration
			cooldown_time = attack_cooldown
			_play_state_animation("recovery")
		State.HURT:
			state_time = hurt_duration
			_play_state_animation("hurt")
	if debug_logging:
		print("CreakingSkull: ", State.keys()[state])


func _face_target() -> void:
	if not target:
		return
	var new_facing := signf(target.global_position.x - global_position.x)
	if not is_zero_approx(new_facing) and new_facing != facing:
		facing = new_facing
		visuals.scale.x = absf(visuals.scale.x) * facing
		attack_hitbox.flip(facing)
		edge_check.position.x = absf(edge_check.position.x) * facing
		wall_check.target_position.x = absf(wall_check.target_position.x) * facing


func _can_advance() -> bool:
	if not is_on_floor():
		return false
	edge_check.force_raycast_update()
	wall_check.force_raycast_update()
	return edge_check.is_colliding() and not wall_check.is_colliding()


func _on_damage_taken(hit: AttackArea) -> void:
	if state == State.DEATH:
		return
	super(hit)
	if blackboard.health > 0.0:
		_set_state(State.HURT)


func _begin_death() -> void:
	if _death_started:
		return
	_death_started = true
	state = State.DEATH
	attack_hitbox.set_active(false)
	# Shared Enemy already removes DamageArea and ContactHazard before emitting.
	collision_layer = 0
	collision_mask = 3
	_play_state_animation("death")
	await get_tree().create_timer(0.28).timeout
	if not is_instance_valid(self):
		return
	visuals.hide()
	_scatter_death_pieces()
	await get_tree().create_timer(1.5).timeout
	queue_free()


func _scatter_death_pieces() -> void:
	death_pieces.show()
	var index := 0
	for child in death_pieces.get_children():
		if child is Sprite2D:
			var piece := child as Sprite2D
			var direction := -1.0 if index % 2 == 0 else 1.0
			var destination: Vector2 = piece.position + Vector2(direction * (34.0 + index * 7.0), 24.0 + index * 5.0)
			var tween := create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(piece, "position", destination + Vector2(0.0, -52.0), 0.42)
			tween.tween_property(piece, "rotation", direction * (1.8 + index * 0.35), 0.75)
			var fall := create_tween()
			fall.tween_interval(0.42)
			fall.tween_property(piece, "position:y", destination.y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall.tween_property(piece, "modulate:a", 0.0, 0.45)
			index += 1


func _play_state_animation(name: StringName) -> void:
	if animation.has_animation(name):
		animation.play(name)
