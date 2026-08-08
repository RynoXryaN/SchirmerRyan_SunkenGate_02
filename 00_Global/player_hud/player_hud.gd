extends CanvasLayer

@onready var hp_margin_container: MarginContainer = $Control/HP_MarginContainer
@onready var hp_bar: TextureProgressBar = $Control/HP_MarginContainer/NinePatchRect/HP_Bar
@onready var message_label: Label = $Control/MessageLabel

func _ready() -> void:
	Messages.player_health_changed.connect( update_health_bar )
	Messages.message_requested.connect( show_message )
	message_label.visible = false
	message_label.text = ""
	pass
	
func update_health_bar( hp: float, max_hp: float ) -> void:
	var value : float = ( hp / max_hp ) * 100
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22
	pass

func show_message(message : String, display_time : float = 10.0) -> void:
	message_label.text = message
	message_label.visible = true

	await get_tree().create_timer(display_time).timeout

	message_label.visible = false
	message_label.text = ""
