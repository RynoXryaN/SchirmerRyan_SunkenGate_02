class_name NewDungeon05BossEncounter
extends Node2D

const DEFEATED_KEY := "boss_creaking_skull_new_dungeon_05"

@export var boss_scene: PackedScene
@export var boss_music: AudioStream
@export var main_play_music: AudioStream
@export_range(0.1, 4.0, 0.1) var entrance_duration := 1.35
@export_range(0.0, 2.0, 0.05) var post_slam_beat := 0.55
@export var boss_scale := Vector2(2.0, 2.0)

@onready var intro_trigger: Area2D = $BossIntroTrigger
@onready var entrance_start: Marker2D = $BossEntranceStart
@onready var combat_position: Marker2D = $BossCombatPosition

var boss: CreakingSkullBoss
var intro_started := false
var intro_slam_count := 0
var player_locked: Player
var player_previous_process_mode := Node.PROCESS_MODE_INHERIT


func _ready() -> void:
	intro_trigger.body_entered.connect(_on_intro_trigger_body_entered)
	if _is_defeated():
		intro_trigger.set_deferred("monitoring", false)
		Audio.play_music(main_play_music)
	else:
		var current_music := Audio.get_music_player(Audio.current_track).stream
		# Do not replace boss music or death-transition silence merely because the
		# room reloaded. Normalize only an unrelated incoming level/menu track.
		if current_music and current_music != boss_music and current_music != main_play_music:
			Audio.play_music(main_play_music)


func _exit_tree() -> void:
	_unlock_player()


func _on_intro_trigger_body_entered(body: Node2D) -> void:
	if intro_started or _is_defeated() or not body is Player:
		return
	intro_started = true
	intro_trigger.set_deferred("monitoring", false)
	_run_intro.call_deferred(body as Player)


func _run_intro(player: Player) -> void:
	_lock_player(player)
	Audio.play_music(boss_music)

	boss = _find_existing_boss()
	if not boss:
		boss = boss_scene.instantiate() as CreakingSkullBoss
		if not boss:
			push_error("NewDungeon_05 boss encounter could not instantiate its boss scene.")
			_unlock_player()
			return
		get_parent().add_child(boss)

	boss.global_position = entrance_start.global_position
	boss.scale = boss_scale
	boss.face_direction(-1.0)
	boss.set_combat_enabled(false)
	if not boss.was_killed.is_connected(_on_boss_killed):
		boss.was_killed.connect(_on_boss_killed)
	boss.play_animation("shamble")

	var entrance_tween := create_tween()
	entrance_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(boss, "global_position", combat_position.global_position, entrance_duration)
	await entrance_tween.finished
	if not _intro_is_valid():
		_unlock_player()
		return

	# Face into the empty space on the entrance side and reuse the authored slam.
	boss.face_direction(-1.0)
	intro_slam_count += 1
	await boss.play_harmless_slam()
	if not _intro_is_valid():
		_unlock_player()
		return
	await get_tree().create_timer(post_slam_beat).timeout
	if not _intro_is_valid():
		_unlock_player()
		return

	boss.set_combat_enabled(true)
	_unlock_player()


func _on_boss_killed() -> void:
	SaveManager.persistent_data[DEFEATED_KEY] = "defeated"
	Audio.play_music(main_play_music)
	_unlock_player()
	SaveManager.save_game()


func _lock_player(player: Player) -> void:
	player_locked = player
	player_previous_process_mode = player.process_mode
	player.velocity = Vector2.ZERO
	player.process_mode = Node.PROCESS_MODE_DISABLED


func _unlock_player() -> void:
	if is_instance_valid(player_locked) and not player_locked.is_queued_for_deletion():
		player_locked.process_mode = player_previous_process_mode
	player_locked = null


func _find_existing_boss() -> CreakingSkullBoss:
	for node in get_tree().get_nodes_in_group("Boss"):
		if node is CreakingSkullBoss and is_instance_valid(node) and not node.is_queued_for_deletion():
			return node as CreakingSkullBoss
	return null


func _is_defeated() -> bool:
	return SaveManager.persistent_data.get(DEFEATED_KEY, "") == "defeated"


func _intro_is_valid() -> bool:
	return is_instance_valid(boss) and not boss.is_queued_for_deletion() and not boss._death_started
