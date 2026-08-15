class_name Player
extends CharacterBody2D

const D_BUG_JUMP_INDICATOR = preload("uid://cxynln4h88jwb")

#region /// signals

signal damage_taken

#endregion

#region /// on ready variables
@onready var character: CharacterSprite = $Character
@onready var attack_sprite: Sprite2D = %AttackSprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var da_stand: CollisionShape2D = $DamageArea/DA_Stand
@onready var da_crouch: CollisionShape2D = $DamageArea/DA_Crouch
@onready var one_way_platform_raycast: RayCast2D = $OneWayPlatformRaycast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: AttackArea = %AttackArea
@onready var damage_area: DamageArea = $DamageArea
@onready var soft_knockback_state: PlayerStateSoftKnockback = %SoftKnockback

#endregion

#region /// Export variables
@export var move_speed : float = 100
@export var	max_fall_speed : float = 600
#endregion


#region /// State Machine Variables
var states : Array[ PlayerState ]
var current_state : PlayerState :
	get : return states.front()
var previous_state : PlayerState :
	get : return states[ 1 ]
#endregion

#region /// player stats
var hp : float = 20 :
	set( value ):
		hp = clampf( value, 0, max_hp )
		Messages.player_health_changed.emit( hp, max_hp)
		
var max_hp : float = 20 :
	set( value ):
		max_hp = value
		Messages.player_health_changed.emit( hp, max_hp)
		
var mana : float = 20:
	set(value):
		mana = clampf(value, 0, max_mana)
		Messages.player_mana_changed.emit(mana, max_mana)

var max_mana : float = 20:
	set(value):
		max_mana = maxf(value, 0)
		mana = clampf(mana, 0, max_mana)
		Messages.player_mana_changed.emit(mana, max_mana)
		
var dash : bool = true:
	set(value):
		if dash != value:
			print("DASH CHANGED FROM ", dash, " TO ", value, " ON ", get_path())
			print_stack()
		dash = value
var dash_count : int = 0
var back_dash : bool = true:
	set(value):
		if back_dash != value:
			print("BACK DASH CHANGED FROM ", back_dash, " TO ", value, " ON ", get_path())
			print_stack()
		back_dash = value
var back_dash_count : int = 0
var double_jump : bool = false
var jump_count : int = 0
var ground_slam : bool = false
var morph_roll : bool = false

#endregion

#region /// standard variables
var direction : Vector2 = Vector2.ZERO
var facing_direction : float = 1.0
var gravity : float = 980
var gravity_multiplier : float = 1.0
#endregion



func _ready() -> void:
	initialize_states()
	print("AFTER INITIALIZE | dash: ", dash)

	apply_saved_abilities()
	print("AFTER APPLY | dash: ", dash)

	Messages.player_healed.connect( _on_player_healed )
	damage_area.damage_taken.connect( _on_damage_taken )
	
	Messages.player_health_changed.emit(hp, max_hp)
	Messages.player_mana_changed.emit(mana, max_mana)
	pass



func _unhandled_input( event: InputEvent ) -> void:
	if event.is_action_released( "jump" ) and velocity.y < 0:
		velocity.y *= 0.5
	if event.is_action_pressed( "action_interact" ):
		Messages.player_interacted.emit( self )
		return
	#Get rid of this
	#if event.is_actiopressed( "attack" ):
		#attack_area.activate()
		#return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_MINUS:
			if Input.is_key_pressed( KEY_SHIFT ):
				max_hp -= 10
			else:
				hp -= 2
		elif event.keycode == KEY_EQUAL:
			if Input.is_key_pressed( KEY_SHIFT ):
				max_hp += 10
			else:
				hp += 2
	if event.is_action_pressed("ui_page_down"):
		spend_mana(2)

	if event.is_action_pressed("ui_page_up"):
		restore_mana(2)
	
	
	change_state( current_state.handle_inputs( event ) )
	pass



func _process( _delta: float ) -> void:
	update_direction()
	change_state( current_state.process( _delta ) )
	pass

func _physics_process( _delta: float ) -> void:
	velocity.y += gravity * _delta * gravity_multiplier
	velocity.y = clampf( velocity.y, -1000.0, max_fall_speed )
	move_and_slide()
	change_state( current_state.physics_process( _delta ) )
	pass


	
func initialize_states() -> void:
	states = []
	# gather all states
	for c in $States.get_children():
		if c is PlayerState:
			states.append( c )
			c.player = self
		pass
		
	if states.size() == 0:
		return

	# initialize all states
	for state in states:
		state.init()
		
	change_state( current_state )
	current_state.enter()
	# set our first state
	
	pass
	
	
	
func change_state( new_state : PlayerState ) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return
		
	if current_state:
		current_state.exit()
	
	states.push_front( new_state )
	current_state.enter()
	states.resize( 3 )
	pass
	
	
	
func update_direction() -> void:
	var prev_direction : Vector2 = direction
	var x_axis = Input.get_axis( "move_left", "move_right" )
	var y_axis = Input.get_axis( "up", "down" )
	direction = Vector2( x_axis, y_axis )
	
	if direction.x != 0:
		facing_direction = signf( direction.x )
	
	if prev_direction.x != direction.x:
		attack_area.flip( direction.x )
		if direction.x < 0:
			character.flip_h = true
			attack_sprite.flip_h = true
			attack_sprite.position.x = -24
		elif direction.x > 0:
			character.flip_h = false
			attack_sprite.flip_h = false
			attack_sprite.position.x = 24
	pass
	
	
#func add_debug_indicator( color : Color = Color.RED ) -> void:
	#var d : Node2D = D_BUG_JUMP_INDICATOR.instantiate()
	#get_tree().root.add_child( d )
	#d.global_position = global_position
	#d.modulate = color
	#await get_tree().create_timer( 3.0 ).timeout
	#d.queue_free()
	#
func _on_player_healed( amount : float ) -> void:
	hp += amount
	# Audio/visual
	pass
	
func _on_damage_taken( a : AttackArea ) -> void:
	# reduce hp
	hp -= a.damage
	damage_taken.emit()
	# emit signal
	pass
	
func has_mana(amount : float) -> bool:
	return mana >= amount


func spend_mana(amount : float) -> bool:
	if not has_mana(amount):
		return false

	mana -= amount
	return true


func restore_mana(amount : float) -> void:
	mana += amount
	
func can_dash() -> bool:
	print("CAN DASH CHECK FROM: ", get_path(), " | dash: ", dash, " dash_count: ", dash_count)

	if dash == false or dash_count > 0:
		return false

	return true
	
func can_back_dash() -> bool:
	print("CAN BACK DASH CHECK FROM: ", get_path(), " | back_dash: ", back_dash, " back_dash_count: ", back_dash_count)

	if back_dash == false or back_dash_count > 0:
		return false

	return true
	
func can_morph() -> bool:
	if morph_roll == false:
		return false
	return true
	
	
func apply_saved_abilities() -> void:
	double_jump = SaveManager.persistent_data.get("double_jump", "") == "acquired"
	dash = SaveManager.persistent_data.get("right_dash", "") == "acquired"
	ground_slam = SaveManager.persistent_data.get("ground_slam", "") == "acquired"
	morph_roll = SaveManager.persistent_data.get("morph_roll", "") == "acquired"
	
	print("APPLIED ABILITIES TO: ", get_path())
	print("double_jump: ", double_jump)
	print("dash: ", dash)
	print("ground_slam: ", ground_slam)
	print("morph_roll: ", morph_roll)
	print("persistent data: ", SaveManager.persistent_data)
	pass
	
func apply_soft_knockback(
	push_direction: float,
	push_speed: float,
	push_duration: float
) -> void:
	soft_knockback_state.start(
		push_direction,
		push_speed,
		push_duration
	)
	
	#if not is_on_floor():
		#velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
	
