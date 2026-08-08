extends CanvasLayer

#region /// OnReady Variables
@onready var main_menu: VBoxContainer = %MainMenu
@onready var new_game_menu: VBoxContainer = %NewGameMenu
@onready var load_game_menu: VBoxContainer = %LoadGameMenu

@onready var new_game_button: TextureButton = %NewGameButton
@onready var load_game_button: TextureButton = %LoadGameButton
@onready var options_button_3: TextureButton = %OptionsButton3

@onready var new_slot_1: Button = %NewSlot1
@onready var new_slot_2: Button = %NewSlot2
@onready var new_slot_3: Button = %NewSlot3

@onready var load_slot_1: Button = %LoadSlot1
@onready var load_slot_2: Button = %LoadSlot2
@onready var load_slot_3: Button = %LoadSlot3


#endregion

func _ready() -> void:
	new_game_button.pressed.connect(show_new_game_menu)
	load_game_button.pressed.connect(show_load_game_menu)

	new_slot_1.pressed.connect(_on_new_game_pressed.bind(0))
	new_slot_2.pressed.connect(_on_new_game_pressed.bind(1))
	new_slot_3.pressed.connect(_on_new_game_pressed.bind(2))

	load_slot_1.pressed.connect(_on_load_game_pressed.bind(0))
	load_slot_2.pressed.connect(_on_load_game_pressed.bind(1))
	load_slot_3.pressed.connect(_on_load_game_pressed.bind(2))

	new_game_button.mouse_entered.connect(new_game_button.grab_focus)
	load_game_button.mouse_entered.connect(load_game_button.grab_focus)

	new_slot_1.mouse_entered.connect(new_slot_1.grab_focus)
	new_slot_2.mouse_entered.connect(new_slot_2.grab_focus)
	new_slot_3.mouse_entered.connect(new_slot_3.grab_focus)

	load_slot_1.mouse_entered.connect(load_slot_1.grab_focus)
	load_slot_2.mouse_entered.connect(load_slot_2.grab_focus)
	load_slot_3.mouse_entered.connect(load_slot_3.grab_focus)

	show_main_menu()
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if new_game_menu.visible or load_game_menu.visible:
			show_main_menu()
			get_viewport().set_input_as_handled()
	pass

func show_main_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	load_game_menu.visible = false

	set_menu_controller_focus(main_menu, true)
	set_menu_controller_focus(new_game_menu, false)
	set_menu_controller_focus(load_game_menu, false)

	new_game_button.grab_focus()
	pass


func show_new_game_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = true
	load_game_menu.visible = false

	set_menu_controller_focus(main_menu, false)
	set_menu_controller_focus(new_game_menu, true)
	set_menu_controller_focus(load_game_menu, false)

	new_slot_1.grab_focus()

	new_slot_1.text = "Begin Slot 01"
	new_slot_2.text = "Begin Slot 02"
	new_slot_3.text = "Begin Slot 03"

	if SaveManager.save_file_exists(0):
		new_slot_1.text = "Replace Slot 01"

	if SaveManager.save_file_exists(1):
		new_slot_2.text = "Replace Slot 02"

	if SaveManager.save_file_exists(2):
		new_slot_3.text = "Replace Slot 03"
	pass
	
func show_load_game_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	load_game_menu.visible = true

	set_menu_controller_focus(main_menu, false)
	set_menu_controller_focus(new_game_menu, false)
	set_menu_controller_focus(load_game_menu, true)

	load_slot_1.grab_focus()

	load_slot_1.disabled = not SaveManager.save_file_exists(0)
	load_slot_2.disabled = not SaveManager.save_file_exists(1)
	load_slot_3.disabled = not SaveManager.save_file_exists(2)
	pass
	
func _on_new_game_pressed( slot : int ) -> void:
	SaveManager.create_new_game_save( slot )
	#SceneManager.transition_scene( "uid://b5beoshdgyky1","", Vector2.ZERO, "up" )
	pass

func _on_load_game_pressed( slot : int ) -> void:
	SaveManager.load_game( slot )
	pass

#func save_file_exists( slot : int ) -> bool:
	#return FileAccess.file_exists( get_file_name( slot ) )
	
func set_menu_controller_focus(menu: Control, enabled: bool) -> void:
	for child in menu.get_children():
		if child is BaseButton:
			child.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
