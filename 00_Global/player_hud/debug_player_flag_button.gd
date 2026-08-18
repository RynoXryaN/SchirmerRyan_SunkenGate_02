class_name DebugPlayerFlagButton
extends CheckButton


enum DebugFlag { INVULNERABLE, UNTOUCHABLE }

@export var debug_flag: DebugFlag = DebugFlag.INVULNERABLE

var _is_selected: bool = false
var _syncing_switch: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggled.connect( _on_toggled )
	focus_entered.connect( _set_selected.bind( true ) )
	focus_exited.connect( _set_selected.bind( false ) )
	refresh_label()


func _process( _delta: float ) -> void:
	refresh_label()


func set_debug_enabled( enabled: bool ) -> void:
	var player: Player = _get_player()
	if not player:
		return

	match debug_flag:
		DebugFlag.INVULNERABLE:
			player.debug_invulnerable = enabled
		DebugFlag.UNTOUCHABLE:
			player.set_debug_untouchable( enabled )

	refresh_label()


func is_debug_enabled() -> bool:
	var player: Player = _get_player()
	if not player:
		return false

	match debug_flag:
		DebugFlag.INVULNERABLE:
			return player.debug_invulnerable
		DebugFlag.UNTOUCHABLE:
			return player.debug_untouchable

	return false


func refresh_label() -> void:
	var enabled: bool = is_debug_enabled()
	var prefix: String = "▶ " if _is_selected else ""
	_syncing_switch = true
	button_pressed = enabled
	_syncing_switch = false
	text = "%s%s: %s" % [ prefix, _display_name(), "ON" if enabled else "OFF" ]


func _on_toggled( toggled_on: bool ) -> void:
	if not _syncing_switch:
		set_debug_enabled( toggled_on )


func _set_selected( selected: bool ) -> void:
	_is_selected = selected
	refresh_label()


func _get_player() -> Player:
	return get_tree().get_first_node_in_group( "Player" ) as Player


func _display_name() -> String:
	match debug_flag:
		DebugFlag.INVULNERABLE:
			return "Invulnerable"
		DebugFlag.UNTOUCHABLE:
			return "Untouchable"

	return "Unsupported Debug Flag"
