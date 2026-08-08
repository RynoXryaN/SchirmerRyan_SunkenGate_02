@tool
class_name LevelTag
extends CanvasLayer


@export_category("Level Information")

@export var level_name: String = "LEVEL NAME":
	set(value):
		level_name = value
		update_text()

@export_multiline var description: String = "Describe the planned contents of this level.":
	set(value):
		description = value
		update_text()


@onready var level_name_label: Label = $MarginContainer/PanelContainer/VBoxContainer/LevelName
@onready var description_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Description


func _ready() -> void:
	update_text()


func update_text() -> void:
	if not is_node_ready():
		return

	level_name_label.text = level_name.to_upper()
	description_label.text = description
