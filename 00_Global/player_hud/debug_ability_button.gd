class_name DebugAbilityButton
extends CheckButton


# TEMP DEBUG: Reusable runtime ability control. This intentionally uses the
# canonical pickup enum instead of maintaining a second ability list.
@export var ability: AbilityPickup.Type = AbilityPickup.Type.DOUBLE_JUMP

var _is_selected: bool = false
var _syncing_switch: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggled.connect( _on_toggled )
	focus_entered.connect( set_selected.bind( true ) )
	focus_exited.connect( set_selected.bind( false ) )
	refresh_label()


func _process( _delta: float ) -> void:
	# Reflect normal pickups and save loads as soon as the real player state changes.
	refresh_label()


func set_ability_enabled( enabled: bool ) -> void:
	var player: Player = _get_player()
	if not player:
		return

	match ability:
		AbilityPickup.Type.DOUBLE_JUMP:
			player.double_jump = enabled
		AbilityPickup.Type.DASH:
			player.dash_unlocked = enabled
		AbilityPickup.Type.GROUND_SLAM:
			player.ground_slam = enabled
		AbilityPickup.Type.MORPH_ROLL:
			player.morph_roll = enabled
		_:
			push_warning( "DebugAbilityButton has no runtime mapping for ability %s." % ability )

	refresh_label()


func is_ability_enabled() -> bool:
	var player: Player = _get_player()
	if not player:
		return false

	match ability:
		AbilityPickup.Type.DOUBLE_JUMP:
			return player.double_jump
		AbilityPickup.Type.DASH:
			return player.dash_unlocked
		AbilityPickup.Type.GROUND_SLAM:
			return player.ground_slam
		AbilityPickup.Type.MORPH_ROLL:
			return player.morph_roll

	return false


func set_selected( selected: bool ) -> void:
	_is_selected = selected
	refresh_label()


func refresh_label() -> void:
	var enabled: bool = is_ability_enabled()
	var prefix: String = "▶ " if _is_selected else ""
	_syncing_switch = true
	button_pressed = enabled
	_syncing_switch = false
	text = "%s%s: %s" % [ prefix, _ability_display_name(), _state_text( enabled ) ]


func _on_toggled( toggled_on: bool ) -> void:
	if not _syncing_switch:
		set_ability_enabled( toggled_on )


func _get_player() -> Player:
	return get_tree().get_first_node_in_group( "Player" ) as Player


func _ability_display_name() -> String:
	match ability:
		AbilityPickup.Type.DOUBLE_JUMP:
			return "Double Jump"
		AbilityPickup.Type.DASH:
			return "Dash"
		AbilityPickup.Type.GROUND_SLAM:
			return "Ground Slam"
		AbilityPickup.Type.MORPH_ROLL:
			return "Morph Roll"

	return "Unsupported Ability"


func _state_text( enabled: bool ) -> String:
	return "ON" if enabled else "OFF"
