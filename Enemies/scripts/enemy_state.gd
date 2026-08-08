@icon( "res://Assets/MetroVan_Assets/ch_01_player_foundations/state.svg" )
class_name EnemyState
extends Node

@export var animation_name : String

var state_machine : EnemyStateMachine
var enemy : Enemy
var blackboard : BlackBoard

func enter() -> void: pass
func re_enter() -> void: pass
func exit() -> void: pass
func physics_update( _delta : float ) -> void: pass
