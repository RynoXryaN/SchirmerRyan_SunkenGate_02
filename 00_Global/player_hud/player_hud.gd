extends CanvasLayer


@onready var hp_margin_container: MarginContainer = $Control/HP_MarginContainer
@onready var hp_bar: TextureProgressBar = $Control/HP_MarginContainer/NinePatchRect/HP_Bar
@onready var mp_bar : TextureProgressBar = $Control/MP_MarginContainer/NinePatchRect/MP_Bar
@onready var message_label: Label = $Control/MessageLabel
@onready var game_over: Control = %GameOver


@onready var test_particles: Button = $Control/DebugTestButtons/TestParticles
@onready var test_dust: Button = $Control/DebugTestButtons/TestDust
@onready var test_game_over: Button = $Control/DebugTestButtons/TestGameOver

# TEMP DEBUG: Ability testing controls. Remove this section and the matching
# scene nodes once ability progression testing is complete.
@onready var test_double_jump: Button = $Control/DebugTestButtons/TestDoubleJump
@onready var test_dash: Button = $Control/DebugTestButtons/TestDash
@onready var test_ground_slam: Button = $Control/DebugTestButtons/TestGroundSlam
@onready var test_morph_roll: Button = $Control/DebugTestButtons/TestMorphRoll

@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	
	Messages.player_health_changed.connect( update_health_bar )
	Messages.player_mana_changed.connect(update_mana_bar)
	Messages.message_requested.connect( show_message )
	message_label.visible = false
	message_label.text = ""
	
	game_over.visible = false
	load_button.pressed.connect( _on_load_pressed )
	quit_button.pressed.connect( _on_quit_pressed )

	# TEMP DEBUG: Toggle the real runtime ability fields without changing the
	# persistent unlock dictionary.
	test_double_jump.pressed.connect( _on_test_double_jump_pressed )
	test_dash.pressed.connect( _on_test_dash_pressed )
	test_ground_slam.pressed.connect( _on_test_ground_slam_pressed )
	test_morph_roll.pressed.connect( _on_test_morph_roll_pressed )
	_update_ability_test_labels()
	
	pass


# TEMP DEBUG: Keeping labels synchronized here also reflects abilities acquired
# from normal pickups while the HUD is visible.
func _process( _delta: float ) -> void:
	_update_ability_test_labels()


func _get_player() -> Player:
	return get_tree().get_first_node_in_group( "Player" ) as Player


func _update_ability_test_labels() -> void:
	var player: Player = _get_player()
	if not player:
		return

	test_double_jump.text = "Double Jump: %s" % _ability_state_text( player.double_jump )
	test_dash.text = "Dash: %s" % _ability_state_text( player.dash and player.back_dash )
	test_ground_slam.text = "Ground Slam: %s" % _ability_state_text( player.ground_slam )
	test_morph_roll.text = "Morph Roll: %s" % _ability_state_text( player.morph_roll )


func _ability_state_text( enabled: bool ) -> String:
	return "ON" if enabled else "OFF"


func _on_test_double_jump_pressed() -> void:
	var player: Player = _get_player()
	if player:
		player.double_jump = not player.double_jump
		_update_ability_test_labels()


func _on_test_dash_pressed() -> void:
	var player: Player = _get_player()
	if player:
		var enabled: bool = not ( player.dash and player.back_dash )
		player.dash = enabled
		player.back_dash = enabled
		_update_ability_test_labels()


func _on_test_ground_slam_pressed() -> void:
	var player: Player = _get_player()
	if player:
		player.ground_slam = not player.ground_slam
		_update_ability_test_labels()


func _on_test_morph_roll_pressed() -> void:
	var player: Player = _get_player()
	if player:
		player.morph_roll = not player.morph_roll
		_update_ability_test_labels()
	
	
func update_health_bar( hp: float, max_hp: float ) -> void:
	
	var value : float = ( hp / max_hp ) * 100
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22
	
	pass
	
	
func update_mana_bar(mana : float, max_mana : float) -> void:
	
	var value : float = (mana / max_mana) * 100
	mp_bar.value = value
	
	pass
	

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
	
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	if player:
		player.queue_free()
		
	await SceneManager.scene_entered
	game_over.visible = false
	
	pass
	
	
func _on_load_pressed () -> void:
	
	SaveManager.load_game( SaveManager.current_slot )
	clear_game_over ()
	
	pass
	
	
func _on_quit_pressed () -> void:
	
	print( "test" )
	
	SceneManager.transition_scene( "res://Title_Screen/title_screen.tscn", "", Vector2.ZERO, "up" )
	clear_game_over ()
	
	pass
