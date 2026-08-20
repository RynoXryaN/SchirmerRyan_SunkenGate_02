class_name CreakingSkullFireball
extends Projectile

@onready var attack_area: AttackArea = $AttackArea
@onready var fireball_sprite: Sprite2D = $Visual/FireballSprite


func _ready() -> void:
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.set_active(true)


func configure(projectile_damage: float, projectile_speed: float) -> void:
	attack_area.damage = projectile_damage
	speed = projectile_speed


func launch(new_direction: Vector2) -> void:
	super(new_direction)
	# The sheet's projectile points left, matching the source creature.
	fireball_sprite.flip_h = direction.x > 0.0


func collision_response(_collision: KinematicCollision2D) -> void:
	queue_free()


func _on_attack_area_entered(area: Area2D) -> void:
	if area is DamageArea:
		queue_free()


func _process(_delta: float) -> void:
	# Retain only a subtle pulse; the visible projectile is source-sheet artwork.
	var pulse := 1.0 + sin(lifetime * 18.0) * 0.08
	$Visual.scale = Vector2.ONE * pulse
