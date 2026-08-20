@icon ( "res://General/Icons/loot_drop.svg" )
class_name LootDropper
extends Marker2D

@export var items : Array[ LootData ]
@export var auto_connect_to_owner: bool = true

func _ready() -> void:
	if not auto_connect_to_owner:
		return
	if owner is Enemy:
		owner.was_killed.connect( drop_loot )
	elif owner is Breakable:
		owner.destroyed.connect( drop_loot )
	pass
	
	
func drop_loot() -> void:
	print( "Drop Loot Signal Received")
	for i in items:
		if randf() > clampf(i.drop_chance, 0.0, 1.0):
			continue
		
		print("Item path: ", i.item)
		if i.item.is_empty() or not ResourceLoader.exists(i.item):
			push_warning("LootDropper skipped invalid item scene: %s" % i.item)
			continue
		
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
				drop.velocity = Vector2( randf_range( -50, 50 ), randf_range( -180, -120 ))
	pass
