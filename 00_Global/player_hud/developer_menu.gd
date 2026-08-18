class_name DeveloperMenu
extends VBoxContainer


@export var developer_menu_enabled: bool = true
@export var open_close_action: StringName = &"Dev_Menu_OpenClose"
@export var always_visible_controls: Array[NodePath] = []
@export var menu_only_controls: Array[NodePath] = []
@export var navigable_controls: Array[NodePath] = []
@export var blocking_controls: Array[NodePath] = []

var _is_open: bool = false
var _selected_index: int = -1
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
	elif event.is_action_pressed( "ui_up" ):
		_select_control( _selected_index - 1 )
	elif event.is_action_pressed( "ui_down" ):
		_select_control( _selected_index + 1 )
	elif event.is_action_pressed( "ui_left" ):
		_set_selected_ability( false )
	elif event.is_action_pressed( "ui_right" ):
		_set_selected_ability( true )
	elif event.is_action_pressed( "ui_accept" ):
		_activate_selected_control()
	else:
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
		_select_control( 0 )


func close_menu() -> void:
	if not _is_open:
		return

	_clear_selection()
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


func _select_control( index: int ) -> void:
	if _navigable.is_empty():
		return

	_clear_selection()
	_selected_index = wrapi( index, 0, _navigable.size() )
	_set_control_selected( _navigable[_selected_index], true )


func _clear_selection() -> void:
	if _selected_index >= 0 and _selected_index < _navigable.size():
		_set_control_selected( _navigable[_selected_index], false )
	_selected_index = -1


func _set_control_selected( control: Control, selected: bool ) -> void:
	if control is DebugAbilityButton:
		(control as DebugAbilityButton).set_selected( selected )
	else:
		control.modulate = Color( 1.0, 1.0, 0.65 ) if selected else Color.WHITE


func _set_selected_ability( enabled: bool ) -> void:
	var selected: Control = _get_selected_control()
	if selected is DebugAbilityButton:
		(selected as DebugAbilityButton).set_ability_enabled( enabled )


func _activate_selected_control() -> void:
	var selected: Control = _get_selected_control()
	if selected is DebugAbilityButton:
		var ability_button := selected as DebugAbilityButton
		ability_button.set_ability_enabled( not ability_button.is_ability_enabled() )
	elif selected is BaseButton:
		(selected as BaseButton).pressed.emit()


func _get_selected_control() -> Control:
	if _selected_index < 0 or _selected_index >= _navigable.size():
		return null
	return _navigable[_selected_index]


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
