class_name DamageNumber
extends Label

@export var rise_distance: float = 24.0
@export var duration: float = 0.7


func setup(amount: float, color: Color = Color(1.0, 0.85, 0.25, 1.0)) -> void:
	print( "DAMAGE NUMBER: setup received ", amount )
	text = str(int(amount))
	add_theme_color_override("font_color", color)
	position.x = -16.0
	position.y = -8.0
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	z_index = 100
	var tween : Tween = create_tween()
	tween.set_parallel( true )
	tween.tween_property( self, "position:y", position.y - rise_distance, duration )
	tween.tween_property( self, "modulate:a", 0.0, duration ).set_delay( duration * 0.35 )
	tween.chain().tween_callback( queue_free )
	pass
