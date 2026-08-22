@tool
extends Node2D

enum PanelVariant {
	INTACT,
	BROAD_COLLAPSE,
	VERTICAL_FRACTURE,
	LOWER_COLLAPSE,
	HIGH_ERODED_BREACH,
	RANDOM_BROKEN,
}

const PANEL_TEXTURES: Array[Texture2D] = [
	preload("res://Assets/Built/Sprites/Background/wall_panel_intact.png"),
	preload("res://Assets/Built/Sprites/Background/broken_wall_panel_01.png"),
	preload("res://Assets/Built/Sprites/Background/broken_wall_panel_02.png"),
	preload("res://Assets/Built/Sprites/Background/broken_wall_panel_03.png"),
	preload("res://Assets/Built/Sprites/Background/broken_wall_panel_04.png"),
]
const FIRST_BROKEN_VARIANT := PanelVariant.BROAD_COLLAPSE
const BROKEN_VARIANT_COUNT := 4

@export var panel_variant: PanelVariant = PanelVariant.INTACT:
	set(value):
		panel_variant = value
		_refresh_texture()

@export var random_seed: int = 1:
	set(value):
		random_seed = value
		_refresh_texture()

@onready var panel_sprite: Sprite2D = $PanelSprite


func _ready() -> void:
	_refresh_texture()


func _refresh_texture() -> void:
	if not is_node_ready():
		return

	panel_sprite.texture = PANEL_TEXTURES[_resolved_variant()]


func _resolved_variant() -> int:
	if panel_variant != PanelVariant.RANDOM_BROKEN:
		return panel_variant

	var seeded_random := RandomNumberGenerator.new()
	seeded_random.seed = random_seed
	return FIRST_BROKEN_VARIANT + seeded_random.randi_range(0, BROKEN_VARIANT_COUNT - 1)
