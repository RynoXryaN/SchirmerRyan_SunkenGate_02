@tool
class_name WaterRegion2D
extends Area2D

## Shared editor resizing and bounds logic for all rectangular water regions.
@export var region_size: Vector2 = Vector2(64.0, 96.0):
	set(value):
		region_size = Vector2(maxf(1.0, value.x), maxf(1.0, value.y)).round()
		_apply_region_size()

@export var enabled: bool = true:
	set(value):
		enabled = value
		_apply_enabled()

var _last_shape_size := Vector2.ZERO


func _ready() -> void:
	_apply_region_size()
	_apply_enabled()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is RectangleShape2D:
		var edited_size: Vector2 = collision.shape.size
		if edited_size != _last_shape_size and edited_size != region_size:
			region_size = edited_size


func get_global_rect() -> Rect2:
	var half_size := region_size * global_scale.abs() * 0.5
	return Rect2(global_position - half_size, half_size * 2.0)


func _apply_region_size() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is RectangleShape2D:
		# Make the shape unique before modifying an instanced scene.
		if not collision.shape.resource_local_to_scene:
			collision.shape = collision.shape.duplicate()
			collision.shape.resource_local_to_scene = true
		collision.shape.size = region_size
		_last_shape_size = region_size
	var visual := get_node_or_null("Visual") as Control
	if visual:
		visual.position = -region_size * 0.5
		visual.size = region_size
	queue_redraw()


func _apply_enabled() -> void:
	visible = enabled
	monitoring = enabled
	monitorable = enabled
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", not enabled)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-region_size * 0.5, region_size), Color(0.2, 0.75, 1.0, 0.8), false, 1.0)
