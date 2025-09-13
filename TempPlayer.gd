extends CharacterBody2D

# Movement constants
const SPEED = 200.0
const DASH_SPEED = 400.0
const JUMP_VELOCITY = -400.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 1.0
const ATTACK_DURATION = 0.3
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.8

# State variables
var is_dashing = false
var can_dash = true
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var is_attacking = false
var attack_timer = 0.0
var dash_direction = Vector2.ZERO
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var was_on_floor = false

# Node references (removed sprite and attack references since we use ColorRect)
# @onready var sprite = $Sprite2D
# @onready var attack_area = $AttackArea


func _ready():
	# No texture creation needed - using ColorRect for visual
	pass

func _physics_process(delta):
	var current_on_floor = is_on_floor()
	
	# Coyote time
	if was_on_floor and not current_on_floor:
		coyote_timer = COYOTE_TIME
	elif current_on_floor:
		coyote_timer = 0.0
	else:
		coyote_timer -= delta
	
	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	was_on_floor = current_on_floor
	
	update_timers(delta)
	handle_input()
	apply_movement(delta)
	
	# Debug collision detection
	if not is_on_floor():
		print("Player not on floor - Position: ", global_position, " Velocity: ", velocity)
	
	move_and_slide()

func update_timers(delta):
	# Update dash timer
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
	
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true
	
	# Update attack timer
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
		

func handle_input():
	# Handle jump with coyote time and buffering
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	
	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# Handle dash
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()
	
	# Handle attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	
	# Get dash direction from input
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# Default to facing direction if no input
	if input_dir == Vector2.ZERO:
		input_dir = Vector2(1, 0)  # Default to right direction
	
	dash_direction = input_dir.normalized()

func start_attack():
	# Attack functionality removed for simple capsule
	pass

func apply_movement(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_dashing:
		# Dash movement
		velocity = dash_direction * DASH_SPEED
	else:
		# Normal movement
		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = direction * SPEED
			# No sprite flipping needed for simple capsule
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

func _input(event):
	# Debug info
	if event.is_action_pressed("ui_home"):
		print("Player State:")
		print("Position: ", global_position)
		print("Velocity: ", velocity)
		print("On Floor: ", is_on_floor())
		print("Dashing: ", is_dashing)
		print("Can Dash: ", can_dash)
		print("Attacking: ", is_attacking)
