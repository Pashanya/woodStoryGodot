extends CharacterBody2D

@export var movement_data : PlayerMovementData
@export var max_health = 10
@export var zoom = 1

@onready var wall_climb_check = %WallClimbCheck
@onready var empty_climb_check = %EmptyClimbCheck

@onready var coyote_jump_timer = $CoyoteJumpTimer
@onready var ledge_grab_timer = $LedgeGrabTimer
@onready var player_root_for_flip = $PlayerRootForFlip
@onready var animated_sprite_2d = $PlayerRootForFlip/AnimatedSprite2D
@onready var health_bar_root = $GUI/HealthBarRoot
@onready var camera_2d = $Camera2D
@onready var gui = $GUI

@onready var wall_stuck_check = %WallStuckCheck
@onready var empty_stuck_check = %EmptyStuckCheck

signal is_activation

var is_jump_start = false
var is_jumping = false
var is_can_climbing = false
var is_facing_right = true
var no_input_move = false

var max_fall_velocity = 600

var scale_min = 0.75
var scale_max = 1.25
var scale_decay = 0.1
var health = 10

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	health = max_health
	health_bar_root.setup_health(health)
	apply_zoom(zoom)
	
	print("Я родился!")
	var state = GlobalData.player_state
	is_facing_right = state.is_facing_right
	if state.x != 0:
		position.x = state.x
	if state.y != 0:
		position.y = state.y
	
	if GlobalData.is_transaction_collided:
		GlobalData.player_create_on_transition = true
	print(GlobalData.is_transaction_collided)
	print(GlobalData.player_create_on_transition)

func _physics_process(delta):
	var input_axis = Input.get_axis("ui_left", "ui_right")
	
	if input_axis < 0:
		is_facing_right = false
	if input_axis > 0:
		is_facing_right = true
	
	apply_gravity(delta)
	wall_check()
	ledge_grab()
	handle_jump()
	jump_process(delta)
	update_animation(input_axis)
	handle_movement()
	handle_activation()
	handle_no_input_move(is_facing_right, delta)
	var wasOnFloor = is_on_floor()
	move_and_slide()
	var justLeftLedge = wasOnFloor and is_on_floor() and velocity.y >= 0
	
	if justLeftLedge:
		coyote_jump_timer.start()
	
	anti_pixel_shake(input_axis)

func apply_gravity(delta):
	if !is_on_floor() and velocity.y <= 0:
		velocity.y += gravity * delta
	elif velocity.y > 0 and velocity.y < max_fall_velocity:
		velocity.y += gravity * movement_data.fall_multiplier * delta;

func handle_jump():
	if is_on_floor() or coyote_jump_timer.time_left > 0.0 or is_can_climbing:
		if Input.is_action_just_pressed("jump"):
			is_jump_start = true
			if is_can_climbing:
				is_can_climbing = false
				ledge_grab_timer.start()
			velocity.y = movement_data.jump_velocity
			animated_sprite_2d.scale.x = scale_min
			animated_sprite_2d.scale.y = scale_max
			is_jumping = true

func  jump_process(delta):
	if is_jump_start and velocity.y < movement_data.jump_velocity:
		velocity.y = lerp(velocity.y, movement_data.jump_velocity, movement_data.jump_deceleration * delta)

	if velocity.y <= movement_data.jump_velocity:
		is_jump_start = false

func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		if is_on_floor() or velocity.y < 0:
			velocity.x = lerp(velocity.x, direction * movement_data.speed, 0.1)
		elif velocity.y > 0:
			velocity.x = direction * movement_data.speed / 1.5
	else:
		velocity.x = move_toward(velocity.x, 0, movement_data.speed)

func wall_check():
	if wall_climb_check.is_colliding():
		var collider = wall_climb_check.get_collider()
		if collider is TileMap:
			if (!empty_climb_check.is_colliding() or !empty_climb_check.get_collider() is TileMap) and !is_can_climbing and ledge_grab_timer.time_left == 0.0 and is_on_wall_only():
				print("Можно прилепиться")
				is_can_climbing = true  

func ledge_grab():
	if is_can_climbing:
		velocity = Vector2(0,0)
		
func handle_activation():
	if Input.is_action_just_pressed("ui_accept"):
		Events.emit_signal("is_activation")
	
func update_animation(input_axis):
	if is_on_floor() and is_jumping and velocity.y >= 0:
		animated_sprite_2d.scale.x = scale_max
		animated_sprite_2d.scale.y = scale_min
		is_jumping = false
	
	animated_sprite_2d.scale.x = lerp(animated_sprite_2d.scale.x, 1.0, scale_decay)
	animated_sprite_2d.scale.y = lerp(animated_sprite_2d.scale.y, 1.0, scale_decay)
	
	#facing character
	if !is_can_climbing:
		if !is_facing_right:
			player_root_for_flip.scale.x = -1
		if is_facing_right:
			player_root_for_flip.scale.x = 1
	
	if input_axis != 0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if !is_on_floor():
		animated_sprite_2d.play("jump")
		if velocity.y < 0:
			animated_sprite_2d.frame = 0
		else: 
			animated_sprite_2d.frame = 1
		
	if is_can_climbing:
		animated_sprite_2d.scale.x = lerp(animated_sprite_2d.scale.x, 1.0, scale_decay * 3)
		animated_sprite_2d.scale.y = lerp(animated_sprite_2d.scale.y, 1.0, scale_decay * 3)
		animated_sprite_2d.play("grab")
		
func damage_health(value):
	health -= value
	health_bar_root.update_health(health)

func apply_zoom(zoom):
	camera_2d.zoom.x = zoom
	camera_2d.zoom.y = zoom
	gui.scale.x = zoom
	gui.scale.y = zoom

func anti_pixel_shake(input_axis):
	#Чтобы не дергалась камера
	position = Vector2(round(position.x), round(position.y))
	
	if wall_stuck_check.is_colliding() and !empty_stuck_check.is_colliding() and input_axis != 0:
		var collider = wall_stuck_check.get_collider()
		if collider is TileMap:
			position = Vector2(round(position.x), round(position.y) - 1)

func handle_no_input_move(is_facing_right, delta):
	pass
#	if GlobalData.player_no_input_move:
#		var movement_vector
#		if is_facing_right:
#			movement_vector = Vector2(1, 0)  # Направление движения (вперед)
#		if !is_facing_right:
#			movement_vector = Vector2(-1, 0)  # Направление движения (вперед)
#		var movement = movement_vector.normalized() * movement_data.speed * delta
#		position += movement
