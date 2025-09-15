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
	ATTACK,
	DASH
}

var current_anim_state: AnimState = AnimState.IDLE
var was_on_floor: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var body_sprite: Sprite2D = $Skeleton2D/TorsoBone/BodySprite
@onready var head_sprite: Sprite2D = $Skeleton2D/TorsoBone/HeadBone/HeadSprite
@onready var torso_bone = $Skeleton2D/TorsoBone
@onready var left_arm_bone = $Skeleton2D/TorsoBone/LeftArmBone
@onready var right_arm_bone = $Skeleton2D/TorsoBone/RightArmBone
@onready var cloak_bone = $Skeleton2D/TorsoBone/CloakBone

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
	# Handle jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity
		current_anim_state = AnimState.JUMP
		animation_player.play("jump")
	
	if Input.is_action_just_pressed("attack") and is_on_floor():
		current_anim_state = AnimState.ATTACK
		animation_player.play("attack")
	
	if Input.is_action_just_pressed("dash") and is_on_floor():
		dash()

func apply_gravity(delta):
	# Add gravity when not on floor
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement(delta):
	# Get input direction
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Handle horizontal movement
	if direction != 0:
		# Accelerate towards target speed
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		# Flip sprites based on direction
		body_sprite.flip_h = direction < 0
		head_sprite.flip_h = direction < 0
	else:
		# Apply friction when no input
		var friction_force = friction if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, 0, friction_force * delta)

func update_animation_state():
	if is_on_floor():
		# Handle landing
		if current_anim_state == AnimState.JUMP:
			current_anim_state = AnimState.LAND
			animation_player.play("land")
			return
		
		# Skip animation changes during attack or dash
		if current_anim_state == AnimState.ATTACK or current_anim_state == AnimState.DASH:
			return
		
		# Normal ground animations
		if abs(velocity.x) > 10:  # Moving threshold
			if current_anim_state != AnimState.WALK:
				current_anim_state = AnimState.WALK
				animation_player.play("walk")
		else:
			if current_anim_state != AnimState.IDLE and current_anim_state != AnimState.LAND:
				current_anim_state = AnimState.IDLE
				animation_player.play("idle")
			elif current_anim_state == AnimState.LAND and not animation_player.is_playing():
				current_anim_state = AnimState.IDLE
				animation_player.play("idle")
	else:
		# In air - maintain jump state
		if current_anim_state != AnimState.JUMP and current_anim_state != AnimState.DASH:
			current_anim_state = AnimState.JUMP
			animation_player.play("jump")

# Optional: Add dash functionality
func dash():
	var dash_direction = 1 if not body_sprite.flip_h else -1
	velocity.x = dash_direction * speed * 2
	current_anim_state = AnimState.DASH
	animation_player.play("dash")
	print("Dash executed in direction: ", dash_direction)

# Handle animation finished signals
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack" or anim_name == "dash" or anim_name == "land":
		if is_on_floor():
			if abs(velocity.x) > 10:
				current_anim_state = AnimState.WALK
				animation_player.play("walk")
			else:
				current_anim_state = AnimState.IDLE
				animation_player.play("idle")
		else:
			current_anim_state = AnimState.JUMP
			animation_player.play("jump")
