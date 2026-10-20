extends CharacterBody3D

var input_direction : Vector2
var speed : float

var crouch_height = 0.5
var stand_height = 2.0
var crouching = false

@export var look_sensitivity: float = 0.005
@export var walk_speed = 4.0
@export var sprint_speed = 6.0
@export var sneak_speed = 2.0
@export var acceleration = 60.0
@export var jump_velocity = 4.0
@export var air_control = 3.0
@export var air_resistance = 2.0

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func crouch():
	if Input.is_action_just_pressed("crouch"):
		crouching = !crouching
		if crouching:
			$CollisionShape3D.shape.height = crouch_height
		else:
			$CollisionShape3D.shape.height = stand_height

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if Input.is_action_just_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	crouch()
	
	# Apply gravity when in the air
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle Sprint
	if Input.is_action_pressed("sprint") and is_on_floor() and !crouching:
		speed = sprint_speed
	elif Input.is_action_pressed("sneak") and !crouching:
		speed = sneak_speed
	else:
		speed = walk_speed
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get direction input
	input_direction = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	# Calculate movement
	var target_velocity = direction * speed
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if is_on_floor():
		# Ground movement
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	if crouching:
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
		velocity.x = horizontal_velocity.x * 0.5
		velocity.z = horizontal_velocity.z * 0.5
	else:
		# Air movement
		if direction:
			horizontal_velocity = horizontal_velocity.move_toward(target_velocity, air_control * delta)
		
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, air_resistance * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	
	move_and_slide()
