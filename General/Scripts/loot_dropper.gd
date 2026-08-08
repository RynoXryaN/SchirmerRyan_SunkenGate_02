@icon ( "res://General/Icons/loot_drop.svg" )
class_name LootDropper
extends Marker2D

@export var items : Array[ LootData ]

func _ready() -> void:
	if owner is Enemy:
		owner.was_killed.connect( drop_loot )
	elif owner is Breakable:
		owner.destroyed.connect( drop_loot )
	pass
	
	
func drop_loot() -> void:
	print( "Drop Loot Signal Received")
	for i in items:
		
		print("Item path: ", i.item)
		
		var drop_scene = load( i.item )
		var count : int = randi_range( i.minimum, i.maximum )
		
		print("Count: ", count)
		
		for j in count:
			var drop = drop_scene.instantiate()
			
			print("Created drop: ", drop)
			
			#owner.add_sibling.call_deferred( drop )
			#drop.global_position = global_position
			owner.add_sibling.call_deferred(drop)
			drop.set_deferred("global_position", global_position)
			if drop is CharacterBody2D:
				drop.velocity = Vector2( randf_range( 150, 50 ), randf_range( -200, -400 ))
	pass
