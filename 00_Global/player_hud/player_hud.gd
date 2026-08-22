extends CanvasLayer


@onready var hp_margin_container: MarginContainer = $Control/HP_MarginContainer
@onready var hp_bar: TextureProgressBar = $Control/HP_MarginContainer/NinePatchRect/HP_Bar
@onready var mp_bar : TextureProgressBar = $Control/MP_MarginContainer/NinePatchRect/MP_Bar
@onready var message_label: Label = $Control/MessageLabel
@onready var game_over: Control = %GameOver
@onready var air_gauge: Control = %AirGauge
@onready var air_bar: ProgressBar = %AirBar
@onready var air_value_label: Label = %AirValueLabel


@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton

var _air_fade_tween: Tween
var _air_gauge_submerged := false


func _ready() -> void:
	
	Messages.player_health_changed.connect( update_health_bar )
	Messages.player_mana_changed.connect(update_mana_bar)
	Messages.player_air_changed.connect(update_air_gauge)
	Messages.message_requested.connect( show_message )
	message_label.visible = false
	message_label.text = ""
	
	game_over.visible = false
	air_gauge.visible = false
	air_gauge.modulate.a = 0.0
	load_button.pressed.connect( _on_load_pressed )
	quit_button.pressed.connect( _on_quit_pressed )
	
	pass

func update_health_bar( hp: float, max_hp: float ) -> void:
	
	var value : float = ( hp / max_hp ) * 100
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22
	
	pass
	
	
func update_mana_bar(mana : float, max_mana : float) -> void:
	
	var value : float = (mana / max_mana) * 100
	mp_bar.value = value
	
	pass


func update_air_gauge(air: float, max_air: float, submerged: bool) -> void:
	air_bar.value = (air / maxf(max_air, 0.001)) * 100.0
	air_value_label.text = "%02d" % ceili(air)
	air_bar.self_modulate = Color(0.45, 0.92, 1.0) if air > max_air * 0.25 else Color(1.0, 0.5, 0.35)
	if submerged == _air_gauge_submerged:
		return
	_air_gauge_submerged = submerged
	if _air_fade_tween and _air_fade_tween.is_running():
		_air_fade_tween.kill()
	_air_fade_tween = create_tween()
	if submerged:
		air_gauge.visible = true
		_air_fade_tween.tween_property(air_gauge, "modulate:a", 1.0, 0.2)
	else:
		_air_fade_tween.tween_property(air_gauge, "modulate:a", 0.0, 0.3)
		_air_fade_tween.tween_callback(air_gauge.hide)
	

func show_message(message : String, display_time : float = 10.0) -> void:
	
	message_label.text = message
	message_label.visible = true

	await get_tree().create_timer(display_time).timeout

	message_label.visible = false
	message_label.text = ""
	
	pass
	
	
func show_game_over () -> void:
	
	load_button.visible = false
	quit_button.visible = false
	
	game_over.modulate.a = 0
	game_over.visible = true
	
	var tween : Tween = create_tween()
	tween.tween_property( game_over, "modulate", Color.WHITE, 3.0 )
	await tween.finished
	
	load_button.visible = true
	quit_button.visible = true
	
	load_button.grab_focus()
	load_button.grab_click_focus()
	
	pass
	
	
func clear_game_over () -> void:
	
	load_button.visible = false
	quit_button.visible = false
	
	game_over.visible = false
	
	pass
	
	
func _on_load_pressed () -> void:
	load_button.disabled = true
	quit_button.disabled = true
	await SaveManager.load_game(SaveManager.current_slot)
	clear_game_over()
	load_button.disabled = false
	quit_button.disabled = false
	
	pass
	
	
func _on_quit_pressed () -> void:
	load_button.disabled = true
	quit_button.disabled = true
	await SceneManager.transition_scene("res://Title_Screen/title_screen.tscn", "", Vector2.ZERO, "up")
	clear_game_over()
	load_button.disabled = false
	quit_button.disabled = false
	
	pass
