extends Area2D

@export var target_level: String
@export var target_transition: String = "door"

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		enter_door()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		Messages.input_hint_changed.emit( "interact" )
		# Optional: show "Press E" prompt here

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		Messages.input_hint_changed.emit( "" )
		# Optional: hide prompt here

func enter_door() -> void:
	print("Entering door to: ", target_level)

	# Replace this with your existing transition/change-level function
	get_tree().change_scene_to_file(target_level)
