extends CharacterBody2D

# Soymaba Player Controller
# Handles movement, jumping, and animation states

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0
@export var air_resistance: float = 200.0

# Animation states
enum AnimState {
	IDLE,
	WALK,
	JUMP,
	LAND,
	ATTACK
}

var current_anim_state: AnimState = AnimState.IDLE
var was_on_floor: bool = false
var attack_timer: float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	was_on_floor = is_on_floor()

func _physics_process(delta):
	handle_input(delta)
	apply_gravity(delta)
	handle_movement(delta)
	update_animation_state()
	move_and_slide()
	
	# Update floor state for landing detection
	was_on_floor = is_on_floor()

func handle_input(delta):
	# Handle attack
	if Input.is_action_just_pressed("ui_accept") and current_anim_state != AnimState.ATTACK:
		current_anim_state = AnimState.ATTACK
		attack_timer = 0.6  # Attack animation duration
		return
	
	# Decrease attack timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			current_anim_state = AnimState.IDLE
		return
	
	# Handle jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity
		current_anim_state = AnimState.JUMP

func apply_gravity(delta):
	# Add gravity when not on floor
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement(delta):
	# Skip movement during attack
	if current_anim_state == AnimState.ATTACK:
		return
	
	# Get input direction
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Handle horizontal movement
	if direction != 0:
		# Accelerate towards target speed
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		# Flip sprite based on direction
		sprite.flip_h = direction < 0
	else:
		# Apply friction when no input
		var friction_force = friction if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, 0, friction_force * delta)

func update_animation_state():
	# Skip animation updates during attack
	if current_anim_state == AnimState.ATTACK:
		if not animation_player.is_playing() or animation_player.current_animation != "attack":
			animation_player.play("attack")
		return
	
	# Check for landing
	if not was_on_floor and is_on_floor() and velocity.y >= 0:
		current_anim_state = AnimState.LAND
		animation_player.play("land")
		# Auto-transition to idle after landing
		await animation_player.animation_finished
		current_anim_state = AnimState.IDLE
		return
	
	# Check if in air
	if not is_on_floor():
		if current_anim_state != AnimState.JUMP:
			current_anim_state = AnimState.JUMP
			animation_player.play("jump")
		return
	
	# Ground-based animations
	if abs(velocity.x) > 10:  # Moving threshold
		if current_anim_state != AnimState.WALK:
			current_anim_state = AnimState.WALK
			animation_player.play("walk")
	else:
		if current_anim_state != AnimState.IDLE:
			current_anim_state = AnimState.IDLE
			animation_player.play("idle")

# Optional: Add dash functionality
func dash():
	if Input.is_action_just_pressed("ui_select"):  # Assuming shift for dash
		var dash_direction = 1 if not sprite.flip_h else -1
		velocity.x = dash_direction * speed * 2
		# You can add dash animation here if you have dash sprites