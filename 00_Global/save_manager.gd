#Save Manager Script
extends Node

const DEFAULT_LEVEL: String = "uid://dkvomvhpxo00k"
const DEFAULT_POSITION := Vector2(60.0, 230.0)

const SLOTS : Array[ String ] = [
	"save_01", "save_02", "save_03"
]

var current_slot : int = 0
var save_data : Dictionary
var discovered_areas : Array = []
var persistent_data : Dictionary ={}



func _ready() -> void:
	
	pass
	
	
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F7:
			load_game( current_slot )
	pass
	
	
	
func create_new_game_save( slot : int ) -> void:
	current_slot = slot
	persistent_data = {}
	discovered_areas = [DEFAULT_LEVEL]
	save_data = {
		"scene_path" : DEFAULT_LEVEL,
		# check coordinates
		"x" : 60,
		"y" : 230,
		"hp" : 20,
		"max_hp" : 20,
		"dash" : false,
		"double_jump" : false,
		"ground_slam" : false,
		"morph_roll" : false,
		"discovered_areas" : discovered_areas, 
		"persistent_data" : persistent_data
	}
	# Save game data
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify(save_data) )
	
	save_file.close()
	
	await load_game( slot )
	pass
	
func save_game() -> void:
	var player := _get_player()
	if not player:
		push_warning("Save requested without an active Player; ignoring request.")
		return
	save_data = {
		"scene_path" : SceneManager.current_scene_uid,
		# check coordinates
		"x" : player.global_position.x,
		"y" : player.global_position.y,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		"dash" : player.dash_unlocked,
		"double_jump" : player.double_jump,
		"ground_slam" : player.ground_slam,
		"morph_roll" : player.morph_roll,
		"discovered_areas" : discovered_areas, 
		"persistent_data" : persistent_data
	}
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify(save_data) )
	save_file.close()
	pass
	
func load_game( slot : int ) -> void:
	current_slot = slot
	save_data = _read_save_or_default(current_slot)
	var loaded_persistent: Variant = save_data.get("persistent_data", {})
	persistent_data = loaded_persistent if loaded_persistent is Dictionary else {}
	var loaded_areas: Variant = save_data.get("discovered_areas", [])
	discovered_areas = loaded_areas if loaded_areas is Array else []
	var scene_path := str(save_data.get("scene_path", DEFAULT_LEVEL))
	if not _is_valid_playable_scene(scene_path):
		scene_path = DEFAULT_LEVEL
		save_data["scene_path"] = scene_path
		save_data["x"] = DEFAULT_POSITION.x
		save_data["y"] = DEFAULT_POSITION.y

	var spawn_position := Vector2(
		float(save_data.get("x", DEFAULT_POSITION.x)),
		float(save_data.get("y", DEFAULT_POSITION.y))
	)
	await SceneManager.transition_scene(
		scene_path,
		"",
		Vector2.ZERO,
		"up",
		spawn_position,
		_apply_save_to_player,
		true
	)
	pass


func _apply_save_to_player(player: Player) -> void:
	player.max_hp = save_data.get( "max_hp", 20 )
	player.hp = save_data.get( "hp", 20 )
	player.apply_saved_abilities()


func _read_save_or_default(slot: int) -> Dictionary:
	if FileAccess.file_exists(get_file_name(slot)):
		var save_file := FileAccess.open(get_file_name(slot), FileAccess.READ)
		if save_file:
			var parsed = JSON.parse_string(save_file.get_line())
			if parsed is Dictionary:
				return parsed
	return _default_save_data()


func _default_save_data() -> Dictionary:
	return {
		"scene_path": DEFAULT_LEVEL,
		"x": DEFAULT_POSITION.x,
		"y": DEFAULT_POSITION.y,
		"hp": 20,
		"max_hp": 20,
		"dash": false,
		"double_jump": false,
		"ground_slam": false,
		"morph_roll": false,
		"discovered_areas": [DEFAULT_LEVEL],
		"persistent_data": {}
	}


func _is_valid_playable_scene(scene_path: String) -> bool:
	var resolved: String = SceneManager.resolve_scene_path(scene_path)
	return SceneManager.is_playable_scene(scene_path) and ResourceLoader.exists(resolved)


func _get_player() -> Player:
	for node in get_tree().get_nodes_in_group("Player"):
		if node is Player and is_instance_valid(node) and not node.is_queued_for_deletion():
			return node as Player
	return null

func get_file_name( slot : int ) -> String:
	
	return "user://" + SLOTS[ slot ] + ".sav"
	
func save_file_exists( slot : int ) -> bool:
	return FileAccess.file_exists( get_file_name( slot ) )
