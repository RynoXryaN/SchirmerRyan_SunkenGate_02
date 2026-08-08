@tool
class_name ConstructionBarrier
extends Node2D


enum SIDE { LEFT, RIGHT }


@export_category("Barrier Placement")

@export var location: SIDE = SIDE.LEFT:
	set(value):
		location = value
		apply_barrier_settings()

@export_range(1, 12, 1, "or_greater")
var size: int = 2:
	set(value):
		size = value
		apply_barrier_settings()


@export_category("Soft Knockback")

@export var push_speed: float = 100.0
@export var push_duration: float = 0.35


@onready var barrier: Area2D = $Barrier


func _ready() -> void:
	apply_barrier_settings()

	if Engine.is_editor_hint():
		return

	if not barrier.body_entered.is_connected(_on_barrier_body_entered):
		barrier.body_entered.connect(_on_barrier_body_entered)


func _on_barrier_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	print ("Entered Barrier")
	var push_direction: float

	if location == SIDE.LEFT:
		push_direction = 1.0
	else:
		push_direction = -1.0

	body.apply_soft_knockback(
		push_direction,
		push_speed,
		push_duration
	)


func apply_barrier_settings() -> void:
	barrier = get_node_or_null("Barrier")

	if not barrier:
		return

	barrier.position = Vector2.ZERO
	barrier.scale = Vector2.ONE
	barrier.scale.y = size

	if location == SIDE.LEFT:
		barrier.position.x = -32
	elif location == SIDE.RIGHT:
		barrier.position.x = 0
