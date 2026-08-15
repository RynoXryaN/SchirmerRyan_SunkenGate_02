@icon( "res://assets/MetroVan_Assets/ch_01_player_foundations/state.svg" )
class_name PlayerState
extends Node

var player : Player
var next_state : PlayerState

#region /// state references
# reference to all other states
@onready var idle: PlayerStateIdle = %Idle
@onready var run: PlayerStateRun = %Run
@onready var jump: PlayerStateJump = %Jump
@onready var fall: PlayerStateFall = %Fall
@onready var crouch: PlayerStateCrouch = %Crouch
@onready var attack: PlayerStateAttack = %Attack
@onready var take_damage: PlayerStateTakeDamage = %TakeDamage
@onready var dash: PlayerStateDash = %Dash
@onready var ground_slam: PlayerStateGroundSlam = %GroundSlam
@onready var ball: PlayerStateBall = %Ball
@onready var jump_slam: PlayerStateJumpSlam = %JumpSlam
@onready var soft_knockback: PlayerStateSoftKnockback = %SoftKnockback
@onready var back_dash: PlayerStateBackDash = %BackDash


#endregion

# What happens when this state is initialized?
func init()	-> void:
	pass
	
	
# What happens when we enter this state?
func enter() -> void:
	pass
	

# What happens when you exit this state?
func exit() -> void:
	pass
	

# What happens when an input is pressed?
func handle_inputs( _event : InputEvent ) -> PlayerState:
	return next_state
	
	
# What happens each process tick in this state?	
func process( _delta: float ) -> PlayerState:
	return next_state
		

# What happens each physics_process tick in this state?	
func physics_process( _delta: float ) -> PlayerState:
	return next_state



## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
