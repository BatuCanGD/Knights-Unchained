extends CharacterBody2D

signal checkplayerdead (is_dead: bool)
signal updatehealth (health: int)
signal updateskillpoints (player_skill_points: int)

const gravity = 761.0
const gravity_pull = 1.5
const terminal_vel = 800.0

@onready var player_collision: CollisionShape2D = $Collision

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var low_health_panel: Panel = $CanvasLayer/LowHealthPanel

@onready var left_attack: Area2D = $Left_Attack
@onready var leftcol: CollisionShape2D = $Left_Attack/Leftcol
@onready var upleftcol: CollisionShape2D = $Left_Attack/Upleftcol

@onready var right_attack: Area2D = $Right_Attack
@onready var rightcol: CollisionShape2D = $Right_Attack/Rightcol
@onready var uprightcol: CollisionShape2D = $Right_Attack/Uprightcol

@onready var rayunder: RayCast2D = $rayunder

@onready var rayleftholding = [$Rayleftup, $rayleftmid, $rayleftbottom]
@onready var rayrightholding = [$rayrightup, $rayrightmid, $rayrightbottom]

@onready var status_panel: Panel = $CanvasLayer/StatusPanel

@onready var health_bar: ProgressBar = $CanvasLayer/StatusPanel/HealthBar
@onready var stamina_bar: ProgressBar = $CanvasLayer/StatusPanel/StaminaBar
@onready var experience_bar: ProgressBar = $CanvasLayer/StatusPanel/ExperienceBar

@onready var health_label: Label = $CanvasLayer/StatusPanel/Health
@onready var stamina_label: Label = $CanvasLayer/StatusPanel/Stamina
@onready var experience_label: Label = $CanvasLayer/StatusPanel/Experience

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audioplayer: AudioStreamPlayer = $AudioStreamPlayer



var player_base_health: float = 100.0
var player_skill_points: int = 0
var base_max_health: float = 100.0
@export var health: float = 100.0
@export var player_weight: float = 80.0

var slow_down: float = 10.0
var walk_speed: float = 110.0
var crouch_mult: float = 0.35
var run_speed: float = 100.0
var jump_force: int = -300
var wallholdtime = 0.0
var wallholdmax = 100.0
var veldecrease = 6.5
var slide_speed = 300.0
var base_stamina = 100.000
var stamina = 100.000
var stamina_regen = 5.0
var jump_drain = 10.0
var run_drain = 7.5
var attack_drain = 10.0
var slide_drain = 7.5

var is_idle: bool = true
var is_attacking: bool = false
var is_moving: bool = false
var is_dead: bool = false
var is_running: bool = false
var is_jumping: bool = false
var is_falling: bool = false
var is_rolling: bool = false
var is_climbing: bool = false #CAUTION no climbing only holding and sliding down
var is_crouching: bool = false
var is_sliding: bool = false

var CTimer = 0.30
var CTime = 0.0

var ATimer = 0.45
var ATime = 0.0

var falltimer = 5.0
var falltime = 0.0

var awaittimer = 0.0
var awaitclamp = 5.0


var attack_sfx: AudioStream = preload("res://SFX/JDSherbert - Ultimate UI SFX Pack/Free/Mono/mp3/JDSherbert - Ultimate UI SFX Pack - Swipe - 2.mp3")
var death_sfx: AudioStream = preload("res://SFX/JDSherbert - Ultimate UI SFX Pack/Free/Stereo/wav (HD)/JDSherbert - Ultimate UI SFX Pack - Error - 1.wav")

func _ready() -> void:
	rightcol.disabled = true
	uprightcol.disabled = true
	leftcol.disabled = true
	upleftcol.disabled = true
	emit_signals()

func _process(delta: float) -> void:
	print(is_crouching)
	health = clamp(health, 0, base_max_health)
	
	if health <= 0 and not is_dead:
		player_has_died()
	
	var not_doing_anything = not is_moving and not is_running and not is_rolling and not is_attacking and not is_sliding and not is_falling and not is_dead
	is_idle = not_doing_anything
	
	
	hud_updates()
	camera_movement(delta)
	player_collision_resize()
	player_sprite()



func _physics_process(delta: float) -> void:
	velocity.y += gravity * gravity_pull * delta
	velocity.y = min(velocity.y, terminal_vel)
	print(is_jumping)
	if is_dead:
		return
	
	
	if velocity.y > 100 and not is_on_floor():
		is_falling = true
	elif is_on_floor():
		is_falling = false
	
	
	
	player_movement(delta)
	player_wallhold(delta)
	player_sliding(delta)
	player_attack(delta)
	player_crouch(delta)
	move_and_slide()
	player_stamina(delta)
	fall_damage(delta)


@warning_ignore("unused_parameter")
func player_movement(delta: float):
	if is_dead or is_sliding:
		return
	var direction = 0
	if Input.is_action_pressed("left"):
		direction = -1
	elif Input.is_action_pressed("right"):
		direction = 1
	
	if is_attacking:
		velocity.x = direction * slow_down
		return
	if direction != 0:
		is_moving = true
		velocity.x = direction * walk_speed
		if is_crouching:
			velocity.x = direction * (walk_speed * crouch_mult)
		
		if Input.is_action_pressed("shift") and stamina >= run_drain:
			is_running = true
			if is_running:
				velocity.x = direction * (walk_speed + run_speed)
		if Input.is_action_just_released("shift") or stamina < run_drain:
			is_running = false
	else:
		velocity.x = 0
		is_moving = false
		is_running = false
	#JUMPING
	if Input.is_action_just_pressed("space") and is_on_floor() and stamina >= jump_drain:
		velocity.y = jump_force
		is_jumping = true
	elif is_jumping and is_on_floor():
		is_jumping = false
		

func player_sliding(delta: float) -> void:
	if Input.is_action_just_pressed("control") and is_moving and not is_attacking and stamina >= slide_drain and is_on_floor():
		is_sliding = true
		if Input.is_action_pressed("right"):
			velocity.x = slide_speed
		elif Input.is_action_pressed("left"):
			velocity.x = -slide_speed
	elif is_sliding:
		if velocity.x > 0:
			velocity.x -= veldecrease
			if velocity.x < 0:
				velocity.x = 0
		elif velocity.x < 0:
			velocity.x += veldecrease
			if velocity.x > 0:
				velocity.x = 0
		else:
			is_sliding = false


func player_sprite():
	if is_dead:
		player_has_died()
		return
	if not is_on_floor():
		if velocity.y < -100:
			sprite.play("Jump")
		elif velocity.y < 0:
			sprite.play("FallTrans")
			sprite.frame = 0
		elif velocity.y < 100:
			sprite.frame = 1
		else:
			sprite.play("Fall")
	elif is_sliding:
		sprite.play("Slide")
		sprite.frame = 1
	elif CTime < 0.30 and not CTime <= 0:
		sprite.play("CrouchTrans")
	elif is_crouching and is_attacking:
		sprite.play("CrouchAttack")
	elif is_crouching and is_moving:
		sprite.play("CrouchWalk")
	elif is_crouching:
		sprite.play("Crouch")
	elif is_attacking:
		sprite.play("Attack")
	elif is_running:
		sprite.play("Run")
	elif velocity.x != 0:
		sprite.play("Walk")
	else:
		sprite.play("Idle")
	
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func player_collision_resize():
	var player_col = player_collision.shape as RectangleShape2D
	#CROUCHING
	if is_sliding:
		player_col.size = Vector2(30.0, 10.0)
		player_collision.position = Vector2(player_collision.position.x, 33.0)
	elif is_crouching:
		player_col.size = Vector2(8.0, 10.0)
		player_collision.position = Vector2(player_collision.position.x, 33.0)
	else:
		player_col.size = Vector2(8.0, 32.5)
		player_collision.position = Vector2(player_collision.position.x, 23.5)
	# ATTACKING
	if is_attacking and not is_crouching:
		if sprite.flip_h:
			player_collision.position.x = -10
		else:
			player_collision.position.x = 10
	else:
		player_collision.position.x = 0

func player_crouch(delta: float):
	if Input.is_action_pressed("control") or Input.is_action_pressed("down") and not is_attacking:
		CTime += delta
		CTime = clamp(CTime, 0, CTimer)
		if CTime >= CTimer:
			is_crouching = true
	else:
		CTime = 0
		is_crouching = false


func player_attack(delta: float):
	if is_dead:
		return
	ATime = clamp(ATime, 0, ATimer)
	if Input.is_action_just_pressed("Click") and not is_attacking and is_on_floor() and stamina >= attack_drain:
		is_attacking = true
		stamina -= attack_drain
		ATime = 0.0
		play_sounds(attack_sfx)
	if is_attacking:
		ATime += delta
		if sprite.flip_h:
			# Facing left
			if is_crouching:
				upleftcol.disabled = true
				leftcol.disabled = false
			else:
				upleftcol.disabled = ATime >= 0.15
				leftcol.disabled = ATime >= ATimer
			rightcol.disabled = true
			uprightcol.disabled = true
		else:
			# Facing right
			if is_crouching:
				uprightcol.disabled = true
				rightcol.disabled = false
			else:
				uprightcol.disabled = ATime >= 0.15
				rightcol.disabled = ATime >= ATimer
			leftcol.disabled = true
			upleftcol.disabled = true
		# End attack after timer
		if ATime >= ATimer:
			is_attacking = false
			uprightcol.disabled = true
			upleftcol.disabled = true
			rightcol.disabled = true
			leftcol.disabled = true
			audioplayer.stop()

func player_stamina(delta: float)-> void:
	print(stamina)
	print(awaittimer)
	awaittimer += delta
	if is_running:
		stamina -= run_drain * delta
		awaittimer = 0
	elif is_sliding:
		stamina -= slide_drain * delta
		awaittimer = 0
	elif is_climbing and not is_on_floor():
		stamina -= velocity.y * 0.01
	else:
		if is_idle and is_crouching:
			stamina += (stamina_regen * 2) * delta
		elif is_idle:
			stamina += (stamina_regen * 1.5) * delta
		elif awaittimer >= 5:
			if is_crouching:
				stamina += (stamina_regen * 1.25) * delta
			else:
				stamina += stamina_regen * delta
	stamina = clamp(stamina, 0, base_stamina)
	awaittimer = clamp(awaittimer, 0, awaitclamp)

func player_wallhold(delta: float):
	var touching_wall := false  # must start as false
	var negative_nancy := not wallholdtime >= wallholdmax and not is_on_floor()

	# Check the three left rays
	for rayleft in rayleftholding:
		if rayleft.is_colliding() and negative_nancy:
			var collider = rayleft.get_collider()
			if collider and collider.is_in_group("Wall"): # be consistent with group name
				touching_wall = true
				break
	# If left side didn't find anything, check the right
	if not touching_wall:
		for rayright in rayrightholding:
			if rayright.is_colliding() and negative_nancy:
				var collider = rayright.get_collider()
				if collider and collider.is_in_group("Wall"):
					touching_wall = true
					break
	is_climbing = touching_wall
	# Apply wall-hold logic
	if stamina < 10.0:
		is_climbing = false
	elif is_on_floor() and not is_climbing:
		wallholdtime = 0
	elif is_climbing and velocity.y >= -100:
		wallholdtime = clamp(wallholdtime + 50 * delta, 0, wallholdmax)
		sprite.play("WallHold")
		velocity.y = wallholdtime
	elif wallholdtime >= wallholdmax:
		is_climbing = false


func fall_damage(delta: float):
	if is_falling and not is_on_floor():
		if not is_climbing:
			falltime += delta
			falltime = clamp(falltime, 0, falltimer)
	elif is_on_floor():
		if falltime > 0.5:
			health -= falltime * player_weight
		falltime = 0

func player_has_died():
	if is_dead:
		return
	is_dead = true
	low_health_panel.visible = true
	status_panel.visible = false
	sprite.play("Dead")
	play_sounds(death_sfx)
	await sprite.animation_finished
	await get_tree().create_timer(1.5).timeout
	scene_reset()

func scene_reset():
	if is_inside_tree(): #PLACEHOLDER!! add death screen menu to the scene here
		get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func camera_movement(delta: float):
	var target_offset_x: float = 0.0
	var target_offset_y: float = 0.0
	if velocity.x == 0.0:
		target_offset_x = 0.0
	elif velocity.x > 0.0:
		target_offset_x = 100.0
	elif velocity.x < 0.0:
		target_offset_x = -100.0
	
	if Input.is_action_pressed("leftcam"):
		target_offset_x = -100.0
	elif Input.is_action_pressed("rightcam"):
		target_offset_x = 100.0
	elif Input.is_action_pressed("downcam"):
		target_offset_y = 100.0
	elif Input.is_action_pressed("upcam"):
		target_offset_y = -100.0
	
	camera.offset.x = lerp(camera.offset.x, target_offset_x, 5 * delta)
	camera.offset.y = lerp(camera.offset.y, target_offset_y, 5 * delta)
	
	if is_running:
		camera.zoom = camera.zoom.move_toward(Vector2(2.5, 2.5), 7.0 * delta)
	else:
		camera.zoom = camera.zoom.move_toward(Vector2(4, 4), 7.0 * delta)
		camera.position.x = 0.0
	if is_dead:
		camera.zoom = camera.zoom.move_toward(Vector2(6, 6), 1.0 * delta)

func hud_updates():
	var experience = Global.experience
	var explimit = Global.exp_limit
	if is_inside_tree():
		health_label.text = str("%.2f HP" % health)
		stamina_label.text = str("%.2f ST" % stamina)
		experience_label.text = str("%.2f XP" % experience)
		health_bar.value = health
		health_bar.max_value = base_max_health
		stamina_bar.value = stamina
		stamina_bar.max_value = base_stamina
		experience_bar.value = experience
		experience_bar.max_value = explimit

func play_sounds(sfx: AudioStream):
	audioplayer.stop()
	audioplayer.stream = sfx
	audioplayer.play()


func emit_signals():
	checkplayerdead.emit(is_dead)
	updatehealth.emit(health)
	updateskillpoints.emit(player_skill_points)
