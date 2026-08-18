class_name DaggerProjectile
extends Projectile

@export var ricochet_scene : PackedScene
@export var ricochet_speed : float = 220.0
@export var ricochet_angle_variation : float = 0.9

@onready var sprite : Sprite2D = $Sprite2D
@onready var attack_area : AttackArea = $AttackArea

var _handled_breakable : bool = false


func _ready() -> void:
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.set_active(true)


func launch( new_direction : Vector2 ) -> void:
	super( new_direction )
	sprite.flip_h = new_direction.x < 0
	pass
	
	
func collision_response( collision : KinematicCollision2D ) -> void:
	var breakable : Breakable = _find_breakable_from_node( collision.get_collider() )
	if breakable and not _handled_breakable:
		_handled_breakable = true
		var damage_area : DamageArea = _find_damage_area( breakable )
		if damage_area:
			damage_area.take_damage( attack_area )
		_respond_to_breakable( breakable )
		return

	var ricochet_direction : Vector2 = collision.get_normal().rotated(
		randf_range(
			-ricochet_angle_variation,
			ricochet_angle_variation
		)
	).normalized()
	
	_spawn_ricochet( ricochet_direction )
	pass


func _on_attack_area_entered(area: Area2D) -> void:
	if not area is DamageArea:
		return
	if _handled_breakable:
		return

	var breakable : Breakable = _find_breakable( area )
	if not breakable:
		queue_free()
		return

	_handled_breakable = true
	_respond_to_breakable( breakable )


func _respond_to_breakable( breakable : Breakable ) -> void:
	match breakable.dagger_response:
		Breakable.DaggerResponse.STICK_IN:
			_stick_into( breakable )
		Breakable.DaggerResponse.BOUNCE_OFF:
			_spawn_ricochet( _breakable_bounce_direction() )
		Breakable.DaggerResponse.BOUNCE_THROUGH:
			var through_direction : Vector2 = _breakable_bounce_direction()
			through_direction.x *= -1.0
			_spawn_ricochet( through_direction )


func _find_breakable( area : Area2D ) -> Breakable:
	if area.get_parent() is Breakable:
		return area.get_parent() as Breakable
	if area.owner is Breakable:
		return area.owner as Breakable
	return null


func _find_breakable_from_node( node : Object ) -> Breakable:
	if node is Breakable:
		return node as Breakable
	if node is Node and node.get_parent() is Breakable:
		return node.get_parent() as Breakable
	return null


func _find_damage_area( breakable : Breakable ) -> DamageArea:
	for child in breakable.get_children():
		if child is DamageArea:
			return child as DamageArea
	return null


func _breakable_bounce_direction() -> Vector2:
	return (-direction).rotated(
		randf_range(-ricochet_angle_variation, ricochet_angle_variation)
	).normalized()


func _spawn_ricochet( ricochet_direction : Vector2 ) -> void:
	if not ricochet_scene:
		queue_free()
		return

	var ricochet : DaggerRicochet = ricochet_scene.instantiate() as DaggerRicochet
	if not ricochet:
		queue_free()
		return

	add_sibling( ricochet )
	ricochet.global_position = global_position
	ricochet.rotation = rotation
	ricochet.get_node( "Sprite2D" ).flip_h = sprite.flip_h
	ricochet.launch( ricochet_direction * ricochet_speed )
	queue_free()


func _stick_into( breakable : Breakable ) -> void:
	if breakable.is_destroyed():
		queue_free()
		return

	set_physics_process( false )
	attack_area.set_active( false )
	$CollisionShape2D.set_deferred( "disabled", true )
	global_position += direction.normalized() * 4.0
	reparent.call_deferred( breakable, true )
