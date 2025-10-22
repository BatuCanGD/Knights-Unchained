extends CharacterBody2D

var gravity = 761.0
var gravity_pull = 1.5
var terminal_vel = 800.0

@onready var leg_right: RayCast2D = $LegRight
@onready var leg_left: RayCast2D = $LegLeft
@onready var head_right: RayCast2D = $HeadRight
@onready var head_left: RayCast2D = $HeadLeft
@onready var legs_jump_cast: RayCast2D = $LegsJumpCast

@onready var sprite: AnimatedSprite2D = $Sprite

var move_speed := 65.0
var jump_force := -300.0
var health := 100.0

var is_jumping := false

@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	
	if velocity.y > 1000:
		queue_free()
	if health <= 0:
		Global.add_experience(15)
		queue_free()
	
	
	if leg_right.is_colliding() and not is_jumping:
		is_jumping = true
		velocity.y = jump_force
	elif leg_left.is_colliding() and not is_jumping:
		is_jumping = true
		velocity.y = jump_force
	elif is_on_floor():
		is_jumping = false
	
	
	
	velocity.y += gravity * gravity_pull * delta
	velocity.y = min(velocity.y, terminal_vel)
	npc_sprite()
	move_and_slide()

func npc_sprite():
	if velocity.x != 0:
		sprite.play("walk")
	elif velocity.x == 0:
		sprite.play("Idle")
	if velocity.y > 0 and not is_on_floor():
		sprite.play("fall")

func take_damage(amount) -> void:
	health -= amount
	health = clamp(health, 0, 100)
