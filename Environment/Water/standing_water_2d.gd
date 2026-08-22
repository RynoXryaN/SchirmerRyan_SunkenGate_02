@tool
class_name StandingWater2D
extends WaterRegion2D

const PLAYER_SPLASH := preload("res://Environment/Water/PlayerWaterSplashParticles.tscn")
const BUBBLE_PARTICLES := preload("res://Environment/Water/WaterBubbleParticles.tscn")

@export_group("Appearance")
@export_range(0.0, 1.0, 0.01) var opacity := 0.40:
	set(value):
		opacity = value
		_update_visual()
@export var tint := Color(0.07, 0.20, 0.30, 1.0):
	set(value):
		tint = value
		_update_visual()
@export_range(0.0, 0.25, 0.01) var depth_opacity_gain := 0.08:
	set(value):
		depth_opacity_gain = value
		_update_visual()
@export_range(0.0, 0.08, 0.001) var shimmer_strength := 0.015:
	set(value):
		shimmer_strength = value
		_update_visual()
@export_range(0.0, 4.0, 0.05) var shimmer_speed := 0.7:
	set(value):
		shimmer_speed = value
		_update_visual()

@export_group("Underwater Actors")
@export var underwater_actor_tint_enabled := true
@export var underwater_actor_tint := Color(0.62, 0.80, 0.90, 1.0)

@export_group("Bubbles")
@export var bubbles_enabled := true
@export_range(0.5, 12.0, 0.1) var bubble_interval_min := 2.5
@export_range(0.5, 12.0, 0.1) var bubble_interval_max := 5.0

@export_group("Player Splashes")
@export var player_splash_enabled := true
@export_range(0.05, 1.0, 0.01) var player_splash_cooldown := 0.18
@export_range(1.0, 500.0, 1.0) var movement_splash_threshold := 35.0

var _player_cooldowns: Dictionary = {}
var _previous_vertical_velocity: Dictionary = {}
var _tinted_bodies: Dictionary = {}
var _bubble_timer := 1.0


func _apply_region_size() -> void:
	super()
	_update_visual()


func _ready() -> void:
	super()
	add_to_group("standing_water")
	_update_visual()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		set_physics_process(true)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not enabled:
		return
	_update_bubbles(delta)
	for body: Node2D in get_overlapping_bodies():
		if not body.is_in_group("Player") or not body is CharacterBody2D:
			continue
		_update_player_breath(body)
		if not player_splash_enabled:
			continue
		var character_body := body as CharacterBody2D
		var velocity: Vector2 = character_body.velocity
		var id := body.get_instance_id()
		_player_cooldowns[id] = maxf(0.0, _player_cooldowns.get(id, 0.0) - delta)
		var surface_y := get_global_rect().position.y
		var feet_near_surface := absf(body.global_position.y - surface_y) <= 18.0
		if feet_near_surface and absf(velocity.x) >= movement_splash_threshold and _player_cooldowns[id] <= 0.0:
			_spawn_player_splash(body, clampf(absf(velocity.x) / 200.0, 0.45, 1.8))
			_player_cooldowns[id] = player_splash_cooldown / clampf(absf(velocity.x) / 140.0, 1.0, 2.0)
		_previous_vertical_velocity[id] = velocity.y


func _on_body_entered(body: Node2D) -> void:
	_apply_underwater_tint(body)
	var character_body := body as CharacterBody2D
	if character_body and body.is_in_group("Player") and character_body.velocity.y > 80.0:
		_spawn_player_splash(body, clampf(character_body.velocity.y / 260.0, 0.8, 1.8))


func _on_body_exited(body: Node2D) -> void:
	_remove_underwater_tint(body)
	_set_player_breath_submerged(body, false)
	if not body.is_in_group("Player"):
		return
	var id := body.get_instance_id()
	var character_body := body as CharacterBody2D
	if character_body and character_body.velocity.y < -80.0:
		_spawn_player_splash(body, 0.8)
	_player_cooldowns.erase(id)
	_previous_vertical_velocity.erase(id)


func _spawn_player_splash(body: Node2D, strength: float) -> void:
	var splash := PLAYER_SPLASH.instantiate()
	add_child(splash)
	var rect := get_global_rect()
	splash.global_position = Vector2(clampf(body.global_position.x, rect.position.x, rect.end.x), rect.position.y)
	splash.burst(strength)


func _update_player_breath(body: Node2D) -> void:
	_set_player_breath_submerged(body, _is_crouch_shape_fully_submerged(body))


func _set_player_breath_submerged(body: Node2D, submerged: bool) -> void:
	if not body.is_in_group("Player"):
		return
	var breath_component := body.get_node_or_null("BreathComponent")
	if breath_component:
		breath_component.set_water_submerged(self, submerged)


func _is_crouch_shape_fully_submerged(body: Node2D) -> bool:
	var crouch_collision := body.get_node_or_null("CollisionCrouch") as CollisionShape2D
	if not crouch_collision or not crouch_collision.shape:
		return false
	var local_rect := crouch_collision.shape.get_rect()
	var corners := PackedVector2Array([
		crouch_collision.to_global(local_rect.position),
		crouch_collision.to_global(Vector2(local_rect.end.x, local_rect.position.y)),
		crouch_collision.to_global(local_rect.end),
		crouch_collision.to_global(Vector2(local_rect.position.x, local_rect.end.y))
	])
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return get_global_rect().encloses(Rect2(minimum, maximum - minimum))


func _update_bubbles(delta: float) -> void:
	if not bubbles_enabled:
		return
	_bubble_timer -= delta
	if _bubble_timer > 0.0:
		return
	var rect := get_global_rect()
	if rect.size.x >= 8.0 and rect.size.y >= 12.0:
		var bubbles := BUBBLE_PARTICLES.instantiate() as WaterBubbleParticles
		add_child(bubbles)
		bubbles.global_position = Vector2(
			randf_range(rect.position.x + 4.0, rect.end.x - 4.0),
			randf_range(rect.position.y + minf(16.0, rect.size.y * 0.3), rect.end.y - 4.0)
		)
		bubbles.burst()
	_bubble_timer = randf_range(minf(bubble_interval_min, bubble_interval_max), maxf(bubble_interval_min, bubble_interval_max))


func _apply_underwater_tint(body: Node2D) -> void:
	if not underwater_actor_tint_enabled or not _is_water_actor(body) or _tinted_bodies.has(body):
		return
	var count: int = body.get_meta("water_tint_count", 0)
	if count == 0:
		body.set_meta("water_original_modulate", body.modulate)
	body.set_meta("water_tint_count", count + 1)
	body.modulate = body.modulate * underwater_actor_tint
	_tinted_bodies[body] = true


func _remove_underwater_tint(body: Node2D) -> void:
	if not _tinted_bodies.has(body):
		return
	_tinted_bodies.erase(body)
	if not is_instance_valid(body):
		return
	var count: int = maxi(0, int(body.get_meta("water_tint_count", 1)) - 1)
	body.set_meta("water_tint_count", count)
	if count == 0:
		body.modulate = body.get_meta("water_original_modulate", Color.WHITE)
		body.remove_meta("water_original_modulate")
		body.remove_meta("water_tint_count")


func _is_water_actor(body: Node2D) -> bool:
	if body.is_in_group("Player") or body.is_in_group("Enemy"):
		return true
	return body is CollisionObject2D and (body as CollisionObject2D).get_collision_layer_value(6)


func _exit_tree() -> void:
	for body: Node2D in _tinted_bodies.keys():
		_set_player_breath_submerged(body, false)
		_remove_underwater_tint(body)


func _update_visual() -> void:
	var visual := get_node_or_null("Visual") as ColorRect
	if visual:
		visual.modulate = Color.WHITE
		if visual.material is ShaderMaterial:
			visual.material.set_shader_parameter("tint", tint)
			visual.material.set_shader_parameter("base_opacity", opacity)
			visual.material.set_shader_parameter("depth_opacity_gain", depth_opacity_gain)
			visual.material.set_shader_parameter("shimmer_strength", shimmer_strength)
			visual.material.set_shader_parameter("shimmer_speed", shimmer_speed)
