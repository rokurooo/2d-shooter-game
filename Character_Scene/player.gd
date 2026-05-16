extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var player_id: int = 1

var input_direction: float = 0.0
var is_jumping: bool = false
var touch_active: bool = false


func _ready() -> void:
	# Set up for multiplayer
	set_multiplayer_authority(player_id)


func _input(event: InputEvent) -> void:
	# Only handle input if this player is controlled by local player
	if not is_multiplayer_authority():
		return
	
	# Mobile touch controls
	if event is InputEventScreenTouch:
		if event.pressed:
			handle_touch_press(event.position)
			touch_active = true
		else:
			touch_active = false
			input_direction = 0.0
	
	elif event is InputEventScreenDrag:
		if touch_active:
			handle_touch_drag(event.position)


func handle_touch_press(position: Vector2) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var touch_zone_width = screen_size.x / 3
	
	# Left third - move left
	if position.x < touch_zone_width:
		input_direction = -1.0
	# Right third - move right
	elif position.x > touch_zone_width * 2:
		input_direction = 1.0
	# Middle third - jump
	else:
		if is_on_floor():
			is_jumping = true


func handle_touch_drag(position: Vector2) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var touch_zone_width = screen_size.x / 3
	
	if position.x < touch_zone_width:
		input_direction = -1.0
	elif position.x > touch_zone_width * 2:
		input_direction = 1.0
	else:
		input_direction = 0.0


func _physics_process(delta: float) -> void:
	# Only process if this player is controlled by local player
	if not is_multiplayer_authority():
		return
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if is_jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = false
	
	# Keyboard input (for desktop testing)
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		input_direction = direction
	
	# Apply movement
	if input_direction:
		velocity.x = input_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Sync position to other players
	sync_position.rpc(global_position, velocity)


@rpc("unreliable")
func sync_position(pos: Vector2, vel: Vector2) -> void:
	# Remote players update their position based on network sync
	if not is_multiplayer_authority():
		global_position = pos
		velocity = vel
