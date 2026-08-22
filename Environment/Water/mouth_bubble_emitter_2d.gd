class_name MouthBubbleEmitter2D
extends Node2D

const BUBBLE_TEXTURE := preload("res://Environment/Water/water_bubble.svg")

@export var emitting := false:
	set(value):
		emitting = value
		if value and _spawn_timer <= 0.0:
			_spawn_timer = randf_range(0.05, 0.3)
@export_range(0.08, 1.5, 0.01) var interval_min := 0.18
@export_range(0.08, 1.5, 0.01) var interval_max := 0.65
@export_range(4.0, 40.0, 1.0) var rise_speed_min := 9.0
@export_range(4.0, 40.0, 1.0) var rise_speed_max := 22.0

var surface_global_y := -INF
var _spawn_timer := 0.0
var _bubbles: Dictionary = {}


func _physics_process(delta: float) -> void:
	if emitting and is_finite(surface_global_y):
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_bubble()
			_spawn_timer = randf_range(minf(interval_min, interval_max), maxf(interval_min, interval_max))

	for bubble: Sprite2D in _bubbles.keys():
		if not is_instance_valid(bubble):
			_bubbles.erase(bubble)
			continue
		var data: Dictionary = _bubbles[bubble]
		data.age += delta
		bubble.position.y -= data.rise_speed * delta
		bubble.position.x += data.drift_speed * delta + sin(data.age * data.wobble_speed + data.phase) * data.wobble_amount * delta
		_bubbles[bubble] = data
		if bubble.global_position.y <= surface_global_y:
			_bubbles.erase(bubble)
			bubble.queue_free()


func _spawn_bubble() -> void:
	var bubble := Sprite2D.new()
	bubble.texture = BUBBLE_TEXTURE
	bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bubble.z_index = 4
	bubble.position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0))
	var size := randf_range(0.55, 1.35)
	bubble.scale = Vector2.ONE * size
	bubble.modulate = Color(0.72, 0.95, 1.0, randf_range(0.65, 0.9))
	add_child(bubble)
	_bubbles[bubble] = {
		"age": 0.0,
		"rise_speed": randf_range(minf(rise_speed_min, rise_speed_max), maxf(rise_speed_min, rise_speed_max)),
		"drift_speed": randf_range(-3.5, 3.5),
		"wobble_speed": randf_range(2.0, 5.0),
		"wobble_amount": randf_range(2.5, 6.0),
		"phase": randf_range(0.0, TAU),
	}
