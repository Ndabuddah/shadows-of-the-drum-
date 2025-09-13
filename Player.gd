extends CharacterBody2D

# Movement constants
const SPEED = 300.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Player state
enum State {
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
	LANDING,
	DASHING,
	ATTACKING
}

var current_state = State.IDLE
var previous_state = State.IDLE

# Movement variables
var facing_direction = 1
var is_on_ground = false
var was_on_ground = false
var jump_buffer = false
var can_dash = true
var is_dashing = false
var dash_direction = Vector2.ZERO

# Attack variables
var attack_combo = 0
var max_combo = 3
var is_attacking = false

# Node references
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var dash_timer = $DashTimer
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBufferTimer

func _ready():
	# Connect timer signals
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	coyote_timer.timeout.connect(_on_coyote_timer_timeout)
	jump_buffer_timer.timeout.connect(_on_jump_buffer_timer_timeout)
	
	# Setup animations
	setup_animations()

func _physics_process(delta):
	update_ground_state()
	handle_input()
	update_state()
	apply_movement(delta)
	update_sprite()
	move_and_slide()

func update_ground_state():
	was_on_ground = is_on_ground
	is_on_ground = is_on_floor()
	
	# Start coyote time when leaving ground
	if was_on_ground and not is_on_ground and current_state != State.JUMPING:
		coyote_timer.start()
	
	# Reset dash when touching ground
	if is_on_ground and not was_on_ground:
		can_dash = true
		if current_state == State.FALLING:
			current_state = State.LANDING

func handle_input():
	# Jump input with buffer
	if Input.is_action_just_pressed("jump"):
		if is_on_ground or not coyote_timer.is_stopped():
			jump()
		else:
			# Jump buffer
			jump_buffer = true
			jump_buffer_timer.start()
	
	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# Dash input
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		dash()
	
	# Attack input
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func update_state():
	previous_state = current_state
	
	if is_dashing:
		current_state = State.DASHING
	elif is_attacking:
		current_state = State.ATTACKING
	elif not is_on_ground:
		if velocity.y < 0:
			current_state = State.JUMPING
		else:
			current_state = State.FALLING
	elif current_state == State.LANDING:
		# Stay in landing state briefly
		pass
	elif abs(velocity.x) > 10:
		current_state = State.WALKING
	else:
		current_state = State.IDLE

func apply_movement(delta):
	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		return
	
	# Horizontal movement with proper momentum
	var direction = Input.get_axis("move_left", "move_right")
	
	# Update facing direction only when actively moving
	if direction != 0:
		facing_direction = sign(direction)
	
	# Apply acceleration when moving, friction when stopping
	if direction != 0:
		# Reduce horizontal control during attacks but don't eliminate it
		var speed_modifier = 0.5 if is_attacking else 1.0
		velocity.x = move_toward(velocity.x, direction * SPEED * speed_modifier, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# More responsive gravity for better jumping feel
	if not is_on_floor():
		# Faster falling than rising (like Hollow Knight)
		var fall_multiplier = 1.5 if velocity.y > 0 else 1.0
		velocity.y += gravity * fall_multiplier * delta
	
	# Jump buffer check
	if jump_buffer and (is_on_ground or not coyote_timer.is_stopped()):
		jump()
		jump_buffer = false

func jump():
	velocity.y = JUMP_VELOCITY
	current_state = State.JUMPING
	coyote_timer.stop()
	jump_buffer = false

func dash():
	var direction = Vector2.ZERO
	
	# Get dash direction from input
	var h_input = Input.get_axis("move_left", "move_right")
	var v_input = Input.get_axis("move_up", "move_down")
	
	if h_input != 0 or v_input != 0:
		direction = Vector2(h_input, v_input).normalized()
	else:
		# Default to facing direction
		direction = Vector2(facing_direction, 0)
	
	dash_direction = direction
	is_dashing = true
	can_dash = false
	dash_timer.start()

func attack():
	is_attacking = true
	attack_combo = (attack_combo + 1) % (max_combo + 1)
	if attack_combo == 0:
		attack_combo = 1
	
	# Play attack animation based on combo
	match attack_combo:
		1:
			animation_player.play("attack1")
		2:
			animation_player.play("attack2")
		3:
			animation_player.play("attack3")

func update_sprite():
	# Only flip the sprite based on movement direction, not attack direction
	# PNG images originally face left, so flip when facing right
	if not is_attacking:
		if Input.get_axis("move_left", "move_right") != 0:
			sprite.flip_h = facing_direction > 0
	
	# Play appropriate animation based on state
	match current_state:
		State.IDLE:
			if previous_state != State.IDLE or not animation_player.is_playing() or animation_player.current_animation != "idle":
				animation_player.play("idle")
		State.WALKING:
			if previous_state != State.WALKING or not animation_player.is_playing() or animation_player.current_animation != "walk":
				animation_player.play("walk")
		State.JUMPING:
			if previous_state != State.JUMPING or not animation_player.is_playing() or animation_player.current_animation != "jump":
				animation_player.play("jump")
		State.FALLING:
			if previous_state != State.FALLING or not animation_player.is_playing() or animation_player.current_animation != "fall":
				animation_player.play("fall")
		State.LANDING:
			if previous_state != State.LANDING or not animation_player.is_playing() or animation_player.current_animation != "land":
				animation_player.play("land")
		State.DASHING:
			if previous_state != State.DASHING or not animation_player.is_playing() or animation_player.current_animation != "dash":
				animation_player.play("dash")

func setup_animations():
	var library = AnimationLibrary.new()
	
	# Idle animation - slower with gentle frames
	var idle_anim = create_sprite_animation(["idle1", "idle2", "idle3"], 0.3, true)
	library.add_animation("idle", idle_anim)
	
	# Walk animation - consistent speed
	var walk_anim = create_sprite_animation(["walking"], 0.1, true)
	library.add_animation("walk", walk_anim)
	
	# Jump animation - non-looping
	var jump_anim = create_sprite_animation(["jump1", "jump2", "jump3", "jump4"], 0.08, false)
	library.add_animation("jump", jump_anim)
	
	# Fall animation - single frame or subtle animation
	var fall_anim = create_sprite_animation(["jump4"], 0.1, true)
	library.add_animation("fall", fall_anim)
	
	# Land animation
	var land_anim = create_sprite_animation(["land1", "land2"], 0.1, false)
	library.add_animation("land", land_anim)
	
	# Dash animation
	var dash_anim = create_sprite_animation(["dash1", "dash2", "dash3"], 0.05, true)
	library.add_animation("dash", dash_anim)
	
	# Attack animations - non-looping with proper timing
	var attack1_anim = create_sprite_animation(["attack1"], 0.07, false)
	library.add_animation("attack1", attack1_anim)
	
	var attack2_anim = create_sprite_animation(["attack2"], 0.07, false)
	library.add_animation("attack2", attack2_anim)
	
	var attack3_anim = create_sprite_animation(["attack3"], 0.07, false)
	library.add_animation("attack3", attack3_anim)
	
	# Add library to animation player
	animation_player.add_animation_library("", library)
	animation_player.animation_finished.connect(_on_animation_finished)

func create_sprite_animation(frame_names: Array, frame_duration: float, loop: bool = true) -> Animation:
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, "Sprite2D:texture")
	
	var total_time = frame_names.size() * frame_duration
	animation.length = total_time
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	
	for i in range(frame_names.size()):
		var time = i * frame_duration
		var texture_path = "res://ninjaafrica/character/" + frame_names[i] + ".png"
		var texture = load(texture_path)
		animation.track_insert_key(track_index, time, texture)
	
	return animation

# Timer callbacks
func _on_dash_timer_timeout():
	is_dashing = false

func _on_coyote_timer_timeout():
	# Coyote time expired
	pass

func _on_jump_buffer_timer_timeout():
	jump_buffer = false

func _on_animation_finished(anim_name: String):
	if anim_name.begins_with("attack"):
		is_attacking = false
		current_state = State.IDLE  # Reset to idle immediately
		attack_combo = 0  # Reset combo immediately if not continuing
		
		# Only schedule reset if in combo window
		if attack_combo > 0:
			get_tree().create_timer(0.5).timeout.connect(func():
				if not is_attacking:  # Only reset if not attacking again
					attack_combo = 0
			)
	elif anim_name == "land":
		current_state = State.IDLE
