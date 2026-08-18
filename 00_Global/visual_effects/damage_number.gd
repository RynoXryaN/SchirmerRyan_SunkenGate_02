class_name DamageNumber
extends Label

@export var rise_distance: float = 24.0
@export var duration: float = 0.7


func setup(amount: float, color: Color = Color(1.0, 0.85, 0.25, 1.0)) -> void:
	text = str(int(amount))
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.02, 0.9))
	add_theme_constant_override("outline_size", 2)
	add_theme_font_size_override("font_size", 18)
	size = Vector2(64.0, 24.0)
	position -= Vector2(size.x * 0.5, size.y * 0.5)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	var tween : Tween = create_tween()
	tween.set_parallel( true )
	tween.tween_property( self, "position:y", position.y - rise_distance, duration )
	tween.tween_property( self, "modulate:a", 0.0, duration ).set_delay( duration * 0.35 )
	tween.chain().tween_callback( queue_free )
	pass
