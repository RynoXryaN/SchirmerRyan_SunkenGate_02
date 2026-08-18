class_name DeveloperMenu
extends VBoxContainer


@export var developer_menu_enabled: bool = true
@export var open_close_action: StringName = &"Dev_Menu_OpenClose"
@export var always_visible_controls: Array[NodePath] = []
@export var menu_only_controls: Array[NodePath] = []
@export var navigable_controls: Array[NodePath] = []
@export var blocking_controls: Array[NodePath] = []

var _is_open: bool = false
var _paused_tree: bool = false
var _always_visible: Array[Control] = []
var _menu_only: Array[Control] = []
var _navigable: Array[Control] = []
var _blockers: Array[Control] = []


func _ready() -> void:
	_always_visible = _resolve_controls( always_visible_controls )
	_menu_only = _resolve_controls( menu_only_controls )
	_navigable = _resolve_controls( navigable_controls )
	_blockers = _resolve_controls( blocking_controls )
	_apply_closed_visibility()


func _input( event: InputEvent ) -> void:
	if event.is_action_pressed( open_close_action ):
		if _is_open:
			close_menu()
		elif _can_open():
			open_menu()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	if event.is_action_pressed( "ui_cancel" ):
		close_menu()
	elif event.is_action_pressed( "ui_select" ):
		if _activate_focused_control():
			get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed( "ui_accept" ):
		# Ability switches use normal focused CheckButton activation. Ordinary
		# test buttons are intentionally activated only through ui_select.
		if not get_viewport().gui_get_focus_owner() is DebugAbilityButton:
			get_viewport().set_input_as_handled()
		return
	else:
		# Match the title menu: let Godot's Control focus system process
		# UI directions and ui_accept, including analog deadzone/repeat.
		return

	get_viewport().set_input_as_handled()


func open_menu() -> void:
	if _is_open or not _can_open():
		return

	_is_open = true
	_set_controls_visible( _always_visible, developer_menu_enabled )
	_set_controls_visible( _menu_only, true )
	_paused_tree = not get_tree().paused
	if _paused_tree:
		get_tree().paused = true

	if not _navigable.is_empty():
		_set_navigation_enabled( true )
		_navigable.front().grab_focus()


func close_menu() -> void:
	if not _is_open:
		return

	_set_navigation_enabled( false )
	_is_open = false
	_apply_closed_visibility()
	if _paused_tree:
		get_tree().paused = false
	_paused_tree = false


func _can_open() -> bool:
	if not developer_menu_enabled:
		return false
	if get_tree().get_first_node_in_group( "Player" ) == null:
		return false
	for blocker in _blockers:
		if blocker.visible:
			return false
	return true


func _activate_focused_control() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	if not focused is BaseButton:
		return false
	if not focused in _navigable:
		return false
	if focused is DebugAbilityButton:
		var ability_button := focused as DebugAbilityButton
		ability_button.set_ability_enabled( not ability_button.is_ability_enabled() )
		return true
	if focused is DebugPlayerFlagButton:
		var flag_button := focused as DebugPlayerFlagButton
		flag_button.set_debug_enabled( not flag_button.is_debug_enabled() )
		return true

	var test_button := focused as BaseButton
	close_menu()
	test_button.pressed.emit()
	return true


func _set_navigation_enabled( enabled: bool ) -> void:
	for control in _navigable:
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		if not enabled:
			control.release_focus()


func _apply_closed_visibility() -> void:
	_set_controls_visible( _always_visible, developer_menu_enabled )
	_set_controls_visible( _menu_only, false )


func _set_controls_visible( controls: Array[Control], visible: bool ) -> void:
	for control in controls:
		control.visible = visible


func _resolve_controls( paths: Array[NodePath] ) -> Array[Control]:
	var controls: Array[Control] = []
	for path in paths:
		var control := get_node_or_null( path ) as Control
		if control:
			controls.append( control )
		else:
			push_warning( "DeveloperMenu could not resolve Control at '%s'." % path )
	return controls
