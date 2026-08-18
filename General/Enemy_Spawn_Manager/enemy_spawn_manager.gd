@tool
class_name EnemySpawnManager
extends Node2D

@export_category("Enemy")
@export var enemy_scene: PackedScene
## Optional entrance animation. Leave empty for enemies that should activate immediately.
@export var spawn_animation_name: StringName = &""
@export var disable_combat_during_spawn_animation: bool = true

@export_category("Spawn Timing")
@export var spawn_enabled: bool = true
@export_range(1, 30, 1) var max_alive_enemies: int = 4
@export_range(0.1, 30.0, 0.1, "suffix:s") var spawn_interval_min: float = 1.5
@export_range(0.1, 30.0, 0.1, "suffix:s") var spawn_interval_max: float = 3.0

@export_category("Player Safety")
@export_range(0.0, 1000.0, 1.0, "suffix:px") var minimum_distance_from_player: float = 96.0
@export_range(0.0, 1200.0, 1.0, "suffix:px") var maximum_distance_from_player: float = 420.0
@export_range(1, 30, 1) var spawn_position_attempts: int = 12

@export_category("Placement Validation")
@export_flags_2d_physics var terrain_collision_mask: int = 3
@export var require_ground_below: bool = true
@export_range(1.0, 512.0, 1.0, "suffix:px") var ground_check_distance: float = 48.0
@export_range(1.0, 64.0, 1.0, "suffix:px") var wall_clearance_radius: float = 10.0
@export_range(1.0, 256.0, 1.0, "suffix:px") var minimum_enemy_separation: float = 48.0
@export var require_clear_sightline: bool = true
@export var require_near_camera: bool = true
@export_range(0.0, 256.0, 1.0, "suffix:px") var camera_edge_allowance: float = 48.0

@export_category("Debug")
@export var show_debug_spawn_attempts: bool = false

@onready var spawn_area: Area2D = $SpawnArea
@onready var spawn_shape: CollisionShape2D = $SpawnArea/CollisionShape2D

var _player: Node2D
var _timer: Timer
var _spawned_enemies: Dictionary = {}
var _debug_points: Array[Vector2] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_timer)
	_schedule_next_attempt()


func _draw() -> void:
	if not show_debug_spawn_attempts:
		return
	for point in _debug_points:
		draw_circle(to_local(point), 4.0, Color(1.0, 0.25, 0.15, 0.9))


func _on_spawn_timer_timeout() -> void:
	_cleanup_freed_enemies()
	if spawn_enabled and enemy_scene and _spawned_enemies.size() < max_alive_enemies:
		_player = _find_player()
		if _player:
			_try_spawn_enemy()
	_schedule_next_attempt()


func _schedule_next_attempt() -> void:
	var low := maxf(0.1, minf(spawn_interval_min, spawn_interval_max))
	var high := maxf(low, maxf(spawn_interval_min, spawn_interval_max))
	_timer.start(randf_range(low, high))


func _find_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	return get_tree().get_first_node_in_group("Player") as Node2D


func _try_spawn_enemy() -> void:
	var rectangle := _get_spawn_rectangle()
	if not rectangle:
		push_warning("EnemySpawnManager requires a RectangleShape2D at SpawnArea/CollisionShape2D.")
		return

	if show_debug_spawn_attempts:
		_debug_points.clear()

	var first_side := -1.0 if randf() < 0.5 else 1.0
	for attempt in spawn_position_attempts:
		var side := first_side if attempt % 2 == 0 else -first_side
		var candidate := _find_candidate(rectangle, side)
		if show_debug_spawn_attempts and candidate != Vector2.INF:
			_debug_points.append(candidate)
			queue_redraw()
		if candidate != Vector2.INF and _is_valid_spawn_position(candidate, rectangle):
			_spawn_enemy(candidate)
			return


func _find_candidate(rectangle: RectangleShape2D, side: float) -> Vector2:
	var shape_rect := Rect2(-rectangle.size * 0.5, rectangle.size)
	var minimum := maxf(0.0, minf(minimum_distance_from_player, maximum_distance_from_player))
	var maximum := maxf(minimum, maxf(minimum_distance_from_player, maximum_distance_from_player))
	var candidate_x: float
	if maximum > 0.0:
		candidate_x = _player.global_position.x + side * randf_range(minimum, maximum)
	else:
		candidate_x = spawn_shape.to_global(Vector2(randf_range(shape_rect.position.x, shape_rect.end.x), 0.0)).x

	var local_x := spawn_shape.to_local(Vector2(candidate_x, spawn_shape.global_position.y)).x
	if local_x < shape_rect.position.x or local_x > shape_rect.end.x:
		return Vector2.INF

	if not require_ground_below:
		return spawn_shape.to_global(Vector2(
			local_x,
			randf_range(shape_rect.position.y, shape_rect.end.y)
		))

	# Cast through the editable rectangle and slightly below it, then use the
	# detected floor point as the enemy's feet position.
	var ray_start := spawn_shape.to_global(Vector2(local_x, shape_rect.position.y))
	var ray_end := spawn_shape.to_global(Vector2(local_x, shape_rect.end.y + ground_check_distance))
	var ray := PhysicsRayQueryParameters2D.create(ray_start, ray_end, terrain_collision_mask)
	var hit := get_viewport().world_2d.direct_space_state.intersect_ray(ray)
	if hit.is_empty() or (hit.normal as Vector2).y > -0.65:
		return Vector2.INF
	return hit.position as Vector2


func _is_valid_spawn_position( candidate_position: Vector2, rectangle: RectangleShape2D ) -> bool:
	if not _is_inside_spawn_area( candidate_position, rectangle ):
		return false
	var distance := candidate_position.distance_to( _player.global_position )
	if distance < minimum_distance_from_player:
		return false
	if maximum_distance_from_player > 0.0 and distance > maximum_distance_from_player:
		return false
	if not _is_near_camera(candidate_position):
		return false
	if not _has_clear_terrain_space(candidate_position):
		return false
	if not _has_clear_sightline(candidate_position):
		return false
	if _is_near_an_enemy(candidate_position):
		return false
	return true


func _is_inside_spawn_area(candidate_position: Vector2, rectangle: RectangleShape2D) -> bool:
	var local_position := spawn_shape.to_local(candidate_position)
	return Rect2(-rectangle.size * 0.5, rectangle.size).has_point(local_position)


func _is_near_camera(candidate_position: Vector2) -> bool:
	if not require_near_camera:
		return true
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return true
	var visible_size := get_viewport().get_visible_rect().size / camera.zoom
	var camera_rect := Rect2(camera.get_screen_center_position() - visible_size * 0.5, visible_size)
	return camera_rect.grow(camera_edge_allowance).has_point(candidate_position)


func _has_clear_terrain_space(candidate_position: Vector2) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = wall_clearance_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, candidate_position + Vector2(0.0, -wall_clearance_radius - 1.0))
	query.collision_mask = terrain_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return get_viewport().world_2d.direct_space_state.intersect_shape(query, 1).is_empty()


func _has_clear_sightline(candidate_position: Vector2) -> bool:
	if not require_clear_sightline:
		return true
	var ray := PhysicsRayQueryParameters2D.create(
		_player.global_position + Vector2(0.0, -24.0),
		candidate_position + Vector2(0.0, -24.0),
		terrain_collision_mask
	)
	return get_viewport().world_2d.direct_space_state.intersect_ray(ray).is_empty()


func _is_near_an_enemy(candidate_position: Vector2) -> bool:
	for node in get_parent().find_children("*", "Enemy", true, false):
		if node is Enemy and (node as Enemy).global_position.distance_to(candidate_position) < minimum_enemy_separation:
			return true
	return false


func _spawn_enemy(candidate_position: Vector2) -> void:
	var enemy := enemy_scene.instantiate() as Node2D
	if not enemy:
		push_warning("EnemySpawnManager enemy_scene must instantiate a Node2D.")
		return

	enemy.visible = spawn_animation_name.is_empty()
	get_parent().add_child(enemy)
	enemy.global_position = candidate_position

	var instance_id := enemy.get_instance_id()
	_spawned_enemies[instance_id] = weakref(enemy)
	enemy.tree_exiting.connect(_on_spawned_enemy_exiting.bind(instance_id), CONNECT_ONE_SHOT)

	if not spawn_animation_name.is_empty():
		_prepare_spawn_animation(enemy)


func _prepare_spawn_animation(enemy: Node2D) -> void:
	var animation := enemy.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not animation or not animation.has_animation(spawn_animation_name):
		enemy.visible = true
		return

	var disabled_areas: Array[Dictionary] = []
	if disable_combat_during_spawn_animation:
		for area_name in [&"HazardArea", &"DamageArea"]:
			var area := enemy.find_child(area_name, true, false) as Area2D
			if area:
				disabled_areas.append({"area": area, "layer": area.collision_layer, "monitoring": area.monitoring})
				area.set_deferred("collision_layer", 0)
				area.set_deferred("monitoring", false)

	animation.play(spawn_animation_name)
	animation.seek(0.0, true)
	enemy.visible = true
	_finish_spawn_animation(enemy, animation, disabled_areas)


func _finish_spawn_animation(
	enemy: Node2D,
	animation: AnimationPlayer,
	disabled_areas: Array[Dictionary]
) -> void:
	await animation.animation_finished
	if not is_instance_valid(enemy):
		return
	for stored in disabled_areas:
		var area := stored.area as Area2D
		if is_instance_valid(area):
			area.set_deferred("collision_layer", stored.layer)
			area.set_deferred("monitoring", stored.monitoring)


func _cleanup_freed_enemies() -> void:
	for instance_id in _spawned_enemies.keys():
		var reference := _spawned_enemies[instance_id] as WeakRef
		if not reference or not is_instance_valid(reference.get_ref()):
			_spawned_enemies.erase(instance_id)


func _on_spawned_enemy_exiting(instance_id: int) -> void:
	_spawned_enemies.erase(instance_id)


func _get_spawn_rectangle() -> RectangleShape2D:
	if not spawn_shape:
		return null
	return spawn_shape.shape as RectangleShape2D
