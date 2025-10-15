extends CharacterBody2D

var gravity = 761.0
var gravity_pull = 1.5
var terminal_vel = 800.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	velocity.y += gravity * gravity_pull * delta
	velocity.y = min(velocity.y, terminal_vel)
	move_and_slide()
