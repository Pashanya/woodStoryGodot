extends CharacterBody2D

@export var movement_data : PlayerMovementData

@onready var wall_climb_check = %WallClimbCheck
@onready var empty_climb_check = %EmptyClimbCheck

@onready var coyote_jump_timer = $CoyoteJumpTimer
@onready var ledge_grab_timer = $LedgeGrabTimer
@onready var player_root_for_flip = $PlayerRootForFlip
@onready var animated_sprite_2d = $PlayerRootForFlip/AnimatedSprite2D

var is_jump_start
var is_jumping
var max_fall_velocity = 600
var is_can_climbing

var scale_min = 0.75
var scale_max = 1.25
var scale_decay = 0.1


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	apply_gravity(delta)
	wall_check()
	ledge_grab()
	handle_jump()
	jump_process(delta)
	var input_axis = Input.get_axis("ui_left", "ui_right")
	update_animation(input_axis)
	handle_movement()
	var wasOnFloor = is_on_floor()
	move_and_slide()
	var justLeftLedge = wasOnFloor and is_on_floor() and velocity.y >= 0
	
	if justLeftLedge:
		coyote_jump_timer.start()
	
	#Чтобы не дергалась камера
	position = Vector2(round(position.x), round(position.y))

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
		
func update_animation(input_axis):
	if is_on_floor() and is_jumping and velocity.y >= 0:
		animated_sprite_2d.scale.x = scale_max
		animated_sprite_2d.scale.y = scale_min
		is_jumping = false
	
	animated_sprite_2d.scale.x = lerp(animated_sprite_2d.scale.x, 1.0, scale_decay)
	animated_sprite_2d.scale.y = lerp(animated_sprite_2d.scale.y, 1.0, scale_decay)
	
	if !is_can_climbing:
		if input_axis < 0:
			player_root_for_flip.scale.x = -1
		if input_axis > 0:
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
