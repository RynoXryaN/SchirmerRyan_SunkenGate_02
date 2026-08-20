@tool
class_name DestructibleProp
extends Breakable

enum DestructionMode {
	DISAPPEAR,
	EFFECT_ONLY,
	DESTROYED_REPLACEMENT,
	DEBRIS_OR_PHYSICS,
	DEBRIS_AND_EFFECT,
}
enum PixelScale { ONE_X = 1, TWO_X = 2 }

@export_category("Destructible Prop")
@export var pixel_scale: PixelScale = PixelScale.ONE_X:
	set(value):
		pixel_scale = value
		_apply_pixel_scale()
@export var one_hit_destroy: bool = true
@export var destruction_mode: DestructionMode = DestructionMode.DEBRIS_AND_EFFECT

@export_category("Prop Light")
@export var light_enabled: bool = false:
	set(value):
		light_enabled = value
		_apply_light_settings()
		if is_inside_tree() and not Engine.is_editor_hint():
			set_process(light_enabled and light_flicker)
@export var light_color: Color = Color(0.45, 0.75, 1.0, 1.0):
	set(value):
		light_color = value
		_apply_light_settings()
@export_range(0.0, 8.0, 0.05) var light_energy: float = 1.0:
	set(value):
		light_energy = value
		_apply_light_settings()
@export_range(0.1, 4.0, 0.05) var light_radius: float = 1.0:
	set(value):
		light_radius = value
		_apply_light_settings()
@export var light_offset: Vector2 = Vector2(0.0, -4.0):
	set(value):
		light_offset = value
		_apply_light_settings()
@export var light_flicker: bool = true
@export_range(0.0, 0.5, 0.01) var flicker_strength: float = 0.08
@export_range(0.1, 20.0, 0.1) var flicker_speed: float = 7.0

@export_category("Loot")
@export var drop_loot: bool = false
@export_range(0.0, 1.0, 0.01) var overall_drop_chance: float = 1.0

@export_category("Destruction Output")
@export var destruction_effect: PackedScene
@export var destroyed_replacement: PackedScene
@export var debris_impulse: Vector2 = Vector2(45.0, -90.0)
@export_range(0.0, 20.0, 0.1) var debris_lifetime: float = 2.0
@export_range(0.0, 10.0, 0.1) var debris_fade_duration: float = 0.5
@export var inherit_scale_for_effect: bool = false
@export var inherit_scale_for_replacement: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var loot_dropper: LootDropper = $SpawnMarker/LootDropper
@onready var prop_light: PointLight2D = $PointLight2D

var _flicker_time: float = 0.0
var _flicker_phase: float = 0.0
var _flicker_rate: float = 1.0


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		_apply_pixel_scale()
		return
	add_to_group("destructible")
	add_to_group("breakable_prop")
	_flicker_phase = randf_range(0.0, TAU)
	_flicker_rate = randf_range(0.88, 1.12)
	_apply_pixel_scale()
	_apply_light_settings()
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(&"idle"):
		animated_sprite.play(&"idle")
	set_process(light_enabled and light_flicker)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not prop_light:
		return
	_flicker_time += delta * flicker_speed * _flicker_rate
	var t := _flicker_time + _flicker_phase
	var flicker := sin(t) * 0.55 + sin(t * 2.37 + 1.4) * 0.3 + sin(t * 5.71) * 0.15
	prop_light.energy = light_energy * (1.0 + flicker * flicker_strength)
	prop_light.texture_scale = light_radius * float(pixel_scale) * (1.0 + flicker * flicker_strength * 0.18)


func _on_damage_taken(attack_area: AttackArea) -> void:
	if one_hit_destroy:
		_destroy(global_position + emission_offset, _direction_from_attack(attack_area))
		return
	super(attack_area)


func _destroy(pos: Vector2 = Vector2.INF, dir: Vector2 = Vector2.UP) -> void:
	if _is_destroyed:
		return
	if not pos.is_finite():
		pos = global_position + emission_offset

	_is_destroyed = true
	hp = 0
	if use_persistence and persistent_id != "":
		SaveManager.persistent_data[persistent_id] = "destroyed"

	_spawn_destruction_output(dir)
	_try_drop_loot()
	destroyed.emit()
	if destroy_audio:
		Audio.play_spatial_sound(destroy_audio, pos)
	clear_collisions()
	queue_free()


func _spawn_destruction_output(direction: Vector2) -> void:
	var wants_effect := destruction_mode in [
		DestructionMode.EFFECT_ONLY,
		DestructionMode.DEBRIS_AND_EFFECT,
	]
	var wants_replacement := destruction_mode in [
		DestructionMode.DESTROYED_REPLACEMENT,
		DestructionMode.DEBRIS_OR_PHYSICS,
		DestructionMode.DEBRIS_AND_EFFECT,
	]

	if wants_effect and destruction_effect:
		var effect := destruction_effect.instantiate()
		_add_world_sibling(effect)
		if effect is Node2D:
			effect.global_position = spawn_marker.global_position
			if inherit_scale_for_effect:
				effect.scale *= float(pixel_scale)

	if wants_replacement:
		var replacement: Node = null
		if destroyed_replacement:
			replacement = destroyed_replacement.instantiate()
		else:
			var debris_scene: PackedScene = load("res://Levels/Props/destructibles/destructible_prop_debris.tscn")
			replacement = debris_scene.instantiate()
		_add_world_sibling(replacement)
		if replacement is Node2D:
			replacement.global_transform = global_transform
			if inherit_scale_for_replacement:
				replacement.scale *= float(pixel_scale)
			else:
				replacement.scale = Vector2.ONE
		if replacement.has_method("setup_from_prop"):
			replacement.setup_from_prop(animated_sprite, direction, debris_impulse, debris_lifetime, debris_fade_duration)
		elif replacement.has_method("start"):
			replacement.start(direction, debris_impulse, debris_lifetime, debris_fade_duration)


func _try_drop_loot() -> void:
	if not drop_loot or randf() > overall_drop_chance:
		return
	loot_dropper.drop_loot()


func _add_world_sibling(node: Node) -> void:
	var target_parent := get_parent()
	if not target_parent:
		target_parent = get_tree().current_scene
	target_parent.add_child(node)


func _direction_from_attack(attack_area: AttackArea) -> Vector2:
	var direction := Vector2(1.0, -1.0)
	if attack_area.global_position.x > global_position.x:
		direction.x = -1.0
	return direction.normalized()


func _apply_pixel_scale() -> void:
	var factor := float(pixel_scale)
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var shape := get_node_or_null("DamageArea/CollisionShape2D") as CollisionShape2D
	var marker := get_node_or_null("SpawnMarker") as Marker2D
	if sprite:
		sprite.scale = Vector2.ONE * factor
	if shape:
		shape.scale = Vector2.ONE * factor
	if marker:
		marker.position = emission_offset * factor
	_apply_light_settings()


func _apply_light_settings() -> void:
	var light := get_node_or_null("PointLight2D") as PointLight2D
	if not light:
		return
	light.enabled = light_enabled
	light.color = light_color
	light.energy = light_energy
	light.texture_scale = light_radius * float(pixel_scale)
	light.position = light_offset * float(pixel_scale)
