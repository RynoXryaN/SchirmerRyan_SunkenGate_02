@tool
class_name StreamingWater2D
extends WaterRegion2D

enum OriginShape { CIRCLE, ROUNDED_RECTANGLE }

const IMPACT_SPLASH := preload("res://Environment/Water/WaterSplashParticles.tscn")
const DEFAULT_WATER_TEXTURE := preload("res://Environment/Water/stream_water_tile.png")

@export_group("Streaming Water")
@export var water_texture: Texture2D:
	set(value):
		water_texture = value
		_update_visual_style()
@export_range(0.0, 8.0, 0.05) var animation_speed := 1.0:
	set(value):
		animation_speed = value
		_update_visual_style()
@export_range(0.0, 256.0, 1.0) var flow_speed := 40.0:
	set(value):
		flow_speed = value
		_update_visual_style()
@export var flow_direction := Vector2.DOWN:
	set(value):
		flow_direction = value.normalized() if not value.is_zero_approx() else Vector2.DOWN
		_update_visual_style()
@export_range(0.0, 1.0, 0.01) var opacity := 0.85:
	set(value):
		opacity = value
		_update_visual_style()
@export var tint := Color(0.55, 0.85, 1.0, 1.0):
	set(value):
		tint = value
		_update_visual_style()
@export var splash_enabled := true:
	set(value):
		splash_enabled = value
		if not value:
			_remove_impact()
@export_range(1.0, 3.0, 0.05) var character_impact_multiplier := 1.8
@export_group("Hybrid Animation")
@export_range(0.0, 1.0, 0.01) var detail_strength := 0.38:
	set(value):
		detail_strength = value
		_update_visual_style()
@export_range(1.0, 30.0, 1.0) var animation_fps := 12.0:
	set(value):
		animation_fps = value
		_update_visual_style()
@export_group("Origin")
@export var origin_shape := OriginShape.ROUNDED_RECTANGLE:
	set(value):
		origin_shape = value
		_update_visual_style()
@export_range(1.0, 64.0, 1.0) var origin_depth := 12.0:
	set(value):
		origin_depth = value
		_update_visual_style()
@export_range(0.0, 32.0, 1.0) var origin_corner_radius := 5.0:
	set(value):
		origin_corner_radius = value
		_update_visual_style()

var _impact_emitter: WaterSplashParticles
var _impact_collider: Object


func _ready() -> void:
	super()
	add_to_group("streaming_water")
	_update_visual_style()
	if not Engine.is_editor_hint():
		set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not enabled:
		_remove_impact()
		return
	var cast := get_node_or_null("FlowCast") as ShapeCast2D
	if not cast:
		return
	cast.force_shapecast_update()
	var hit := _find_nearest_hit(cast)
	var new_length: float = hit.distance if hit.collider else region_size.y
	_apply_flow_length(clampf(new_length, 1.0, region_size.y))
	_update_impact(hit.collider, hit.point)


func _find_nearest_hit(cast: ShapeCast2D) -> Dictionary:
	var scale_y := maxf(global_scale.abs().y, 0.001)
	var source_y := global_position.y - region_size.y * scale_y * 0.5
	var nearest_distance := region_size.y
	var nearest_point := Vector2(global_position.x, source_y + nearest_distance * scale_y)
	var nearest_collider: Object
	for index in cast.get_collision_count():
		var point := cast.get_collision_point(index)
		var distance := maxf(0.0, point.y - source_y) / scale_y
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_point = point
			nearest_collider = cast.get_collider(index)
	return {"collider": nearest_collider, "point": nearest_point, "distance": nearest_distance}


func _update_impact(collider: Object, point: Vector2) -> void:
	if not splash_enabled or collider == null:
		_remove_impact()
		return
	var intensity := 1.0
	if collider is Node:
		var node := collider as Node
		if node.is_in_group("Player") or node.is_in_group("Enemy"):
			intensity = character_impact_multiplier
		elif collider is CollisionObject2D:
			var collision_object := collider as CollisionObject2D
			if collision_object.get_collision_layer_value(5) or collision_object.get_collision_layer_value(6):
				intensity = character_impact_multiplier
			elif not collider is StandingWater2D:
				intensity = 0.8
		elif not collider is StandingWater2D:
			intensity = 0.8
	if not is_instance_valid(_impact_emitter):
		_impact_emitter = IMPACT_SPLASH.instantiate() as WaterSplashParticles
		add_child(_impact_emitter)
		_impact_collider = null
	_impact_emitter.global_position = Vector2(global_position.x, roundf(point.y))
	if _impact_collider != collider:
		_impact_emitter.configure_impact(region_size.x * global_scale.abs().x, intensity)
		_impact_collider = collider


func _remove_impact() -> void:
	if is_instance_valid(_impact_emitter):
		_impact_emitter.queue_free()
	_impact_emitter = null
	_impact_collider = null


func _apply_region_size() -> void:
	var cast := get_node_or_null("FlowCast") as ShapeCast2D
	if cast:
		if cast.shape is RectangleShape2D:
			if not cast.shape.resource_local_to_scene:
				cast.shape = cast.shape.duplicate()
				cast.shape.resource_local_to_scene = true
			cast.shape.size = Vector2(region_size.x, 2.0)
		cast.position = Vector2(0.0, -region_size.y * 0.5)
		cast.target_position = Vector2(0.0, region_size.y)
	_apply_flow_length(region_size.y)
	queue_redraw()


func _apply_flow_length(length: float) -> void:
	var source_y := -region_size.y * 0.5
	var visual := get_node_or_null("Visual") as Control
	if visual:
		visual.position = Vector2(-region_size.x * 0.5, source_y)
		visual.size = Vector2(region_size.x, length)
		if visual.material is ShaderMaterial:
			visual.material.set_shader_parameter("region_size", Vector2(region_size.x, length))
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is RectangleShape2D:
		if not collision.shape.resource_local_to_scene:
			collision.shape = collision.shape.duplicate()
			collision.shape.resource_local_to_scene = true
		collision.position = Vector2(0.0, source_y + length * 0.5)
		collision.shape.size = Vector2(region_size.x, length)
		_last_shape_size = region_size


func _update_visual_style() -> void:
	var visual := get_node_or_null("Visual") as TextureRect
	if not visual:
		return
	visual.texture = water_texture if water_texture else DEFAULT_WATER_TEXTURE
	visual.modulate = Color(1.0, 1.0, 1.0, opacity)
	if visual.material is ShaderMaterial:
		visual.material.set_shader_parameter("use_texture", true)
		visual.material.set_shader_parameter("speed", flow_direction * flow_speed * animation_speed / 64.0)
		visual.material.set_shader_parameter("tint", tint)
		visual.material.set_shader_parameter("detail_strength", detail_strength)
		visual.material.set_shader_parameter("animation_fps", animation_fps)
		visual.material.set_shader_parameter("region_size", visual.size)
		visual.material.set_shader_parameter("origin_shape", origin_shape)
		visual.material.set_shader_parameter("origin_depth", origin_depth)
		visual.material.set_shader_parameter("origin_corner_radius", origin_corner_radius)
