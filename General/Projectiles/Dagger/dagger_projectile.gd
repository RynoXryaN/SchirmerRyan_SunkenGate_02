class_name DaggerProjectile
extends Projectile

@export var ricochet_scene : PackedScene
@export var ricochet_speed : float = 220.0
@export var ricochet_angle_variation : float = 0.9

@onready var sprite : Sprite2D = $Sprite2D
@onready var attack_area : AttackArea = $AttackArea


func _ready() -> void:
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.set_active(true)


func launch( new_direction : Vector2 ) -> void:
	super( new_direction )
	sprite.flip_h = new_direction.x < 0
	pass
	
	
func collision_response( collision : KinematicCollision2D ) -> void:
	if not ricochet_scene:
		queue_free()
		return
	
	var ricochet_direction : Vector2 = collision.get_normal().rotated(
		randf_range(
			-ricochet_angle_variation,
			ricochet_angle_variation
		)
	).normalized()
	
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
	pass


func _on_attack_area_entered(area: Area2D) -> void:
	if area is DamageArea:
		queue_free()
