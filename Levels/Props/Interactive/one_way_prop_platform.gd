@tool
class_name OneWayPropPlatform
extends Node2D

@export_group("Appearance")
@export var platform_texture: Texture2D:
	set(value):
		platform_texture = value
		_refresh_platform()
@export var sprite_position := Vector2.ZERO:
	set(value):
		sprite_position = value
		_refresh_platform()

@export_group("Platform Collision")
@export var collision_size := Vector2(64.0, 6.0):
	set(value):
		collision_size = value
		_refresh_platform()
@export var collision_position := Vector2.ZERO:
	set(value):
		collision_position = value
		_refresh_platform()


func _ready() -> void:
	_refresh_platform()


func _refresh_platform() -> void:
	var platform_sprite := get_node_or_null("Sprite2D") as Sprite2D
	var collision_shape := get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D

	if platform_sprite:
		platform_sprite.texture = platform_texture
		platform_sprite.position = sprite_position

	if collision_shape:
		collision_shape.position = collision_position
		var rectangle := collision_shape.shape as RectangleShape2D
		if rectangle:
			rectangle.size = collision_size
