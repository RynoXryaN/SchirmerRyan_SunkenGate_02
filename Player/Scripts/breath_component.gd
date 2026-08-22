class_name BreathComponent
extends Node

@export_range(1.0, 60.0, 0.5) var max_air_seconds := 12.0
@export_range(0.1, 20.0, 0.1) var recovery_per_second := 8.0
@export_range(0.1, 10.0, 0.1) var suffocation_damage := 2.0
@export_range(0.2, 5.0, 0.1) var suffocation_interval := 1.0

@onready var player := get_parent() as Player
@onready var mouth_bubbles := %MouthBubbles as MouthBubbleEmitter2D

var current_air := 0.0
var _submerged_sources: Dictionary = {}
var _was_submerged := false
var _suffocation_timer := 0.0


func _ready() -> void:
	current_air = max_air_seconds
	_emit_air_changed(false)


func _physics_process(delta: float) -> void:
	for source in _submerged_sources.keys():
		if not is_instance_valid(source):
			_submerged_sources.erase(source)
	var submerged := not _submerged_sources.is_empty()
	if submerged:
		current_air = maxf(0.0, current_air - delta)
		if current_air <= 0.0:
			_suffocation_timer -= delta
			if _suffocation_timer <= 0.0:
				player.apply_environmental_damage(suffocation_damage)
				_suffocation_timer = suffocation_interval
	else:
		current_air = minf(max_air_seconds, current_air + recovery_per_second * delta)
		_suffocation_timer = 0.0

	if mouth_bubbles:
		mouth_bubbles.emitting = submerged
		mouth_bubbles.position.x = 7.0 * player.facing_direction
		mouth_bubbles.surface_global_y = _get_active_surface_y()

	if submerged != _was_submerged or submerged or current_air < max_air_seconds:
		_emit_air_changed(submerged)
	_was_submerged = submerged


func set_water_submerged(source: Object, submerged: bool) -> void:
	if submerged:
		_submerged_sources[source] = true
	else:
		_submerged_sources.erase(source)


func _get_active_surface_y() -> float:
	var nearest_surface := -INF
	for source in _submerged_sources.keys():
		if is_instance_valid(source) and source.has_method("get_global_rect"):
			var surface_y: float = source.get_global_rect().position.y
			if surface_y <= player.global_position.y:
				nearest_surface = maxf(nearest_surface, surface_y)
	return nearest_surface


func _emit_air_changed(submerged: bool) -> void:
	Messages.player_air_changed.emit(current_air, max_air_seconds, submerged)
