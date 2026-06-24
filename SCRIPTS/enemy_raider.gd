extends CharacterBody2D

@export var max_health: int = 100
var health: int = 100
@export var gravity: float = 980.0

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	health = max_health
	if anim.has_animation("idle"):
		anim.play("idle")
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	move_and_slide()

func take_damage(amount: int) -> void:
	if health <= 0: return
	
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	if anim.has_animation("dead"):
		anim.play("dead")
	set_physics_process(false)
