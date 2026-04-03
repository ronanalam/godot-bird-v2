extends CharacterBody3D

### Body parts
@onready var head: Node3D = $head
@onready var body: Node3D = $body
@onready var player_hitbox: CollisionShape3D = $player_hitbox
@onready var wingL: Node3D = $body/wingL
@onready var wingR: Node3D = $body/wingR
@onready var tail: Node3D = $body/tail

### Camera
@onready var player_camera: Camera3D = $head/player_camera
@onready var camera_arm: SpringArm3D = $head/camera_arm
@onready var camera_arm_endpoint: Marker3D = $head/camera_arm/camera_arm_endpoint
@onready var label: Label3D = $head/label
const camera_arm_step: float = 0.25

### Menu variables
var inMenu: bool = false

### Lerp Parameters
const MOUSE_SENS: float = 0.35
const CAMERA_LERP: float = 5.0
const BODY_LERP: float = 6.0

### Physics constants
const jump_strength: float = 15.0
const MASS: float = 0.450 # kg
const ONE_WINGED_AREA: float = (0.925/2.0) * 0.2 # m^2
const TAIL_AREA: float = 0.025 # m^2 (approx)
const beta: float = 0.6

### Physics vars
var acceleration: Vector3
var F_gravity: Vector3
var F_run: Vector3
var F_run_friction: Vector3
var F_jump: Vector3
# Flight
var F_liftLeft: Vector3
var F_liftRght: Vector3
var F_liftTail: Vector3
var F_dragLeft: Vector3
var F_dragRght: Vector3
var F_dragTail: Vector3
var F_dragBasic: Vector3
var F_Left: Vector3
var F_Rght: Vector3
var F_Tail: Vector3
var F_aero: Vector3
var rho: float = 1.225 # kg m^-3 #TODO: Altitude-dependent density
# Torques/rotations
var torque: Vector3
var alpha: Vector3
var ω: Vector3
var I: Basis = Basis(
	Vector3(0.1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, 0, 0.1)
)
var torque_input: Vector3
var torque_aero: Vector3
var torque_drag: Vector3

### Gameplay input vars
var pressedJump: bool
var input2D: Vector2
var inputQE: float
var inputWS: float
var inputAD: float
var direction: Vector3



func _ready() -> void:
	# Init mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Init camera arm
	camera_arm.spring_length = 3 * camera_arm_step
	
	# Detach head from body
	head.top_level = true



func _unhandled_input(event: InputEvent) -> void:
	### Rotate camera w/ mouse
	if event is InputEventMouseMotion and !inMenu:
		head.rotation.y -= event.relative.x * MOUSE_SENS/180.0
		head.rotation.y = wrapf(head.rotation.y, 0.0, 2*PI)
		head.rotation.x -= event.relative.y * MOUSE_SENS/180.0
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/4)



func _unhandled_key_input(event: InputEvent) -> void:
	### Scroll to zoom camera
	if event.is_action_pressed('scroll_up'):
		camera_arm.spring_length += camera_arm_step
	if event.is_action_pressed('scroll_down'):
		camera_arm.spring_length -= camera_arm_step
	camera_arm.spring_length = clampf(camera_arm.spring_length, camera_arm_step, 10*camera_arm_step)
	
	### Handle mouse capture with ESC
	if event.is_action_pressed('ui_cancel'):
		if inMenu:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		inMenu = !inMenu



func _physics_process(dt: float) -> void:
	### Camera Movement
	camera_arm_endpoint.translate_object_local( Vector3.BACK * camera_arm.spring_length )
	player_camera.position = player_camera.position.lerp( camera_arm_endpoint.position, dt * CAMERA_LERP )
	# Reattach head position to body
	head.position = position
	
	### Grab player input
	input2D = Input.get_vector('left', 'right', 'forward', 'back')
	inputQE = Input.get_axis('yaw_left', 'yaw_right')
	inputWS = Input.get_axis('back', 'forward')
	inputAD = Input.get_axis('left', 'right')
	pressedJump = Input.is_action_just_pressed('jump')
	direction = Vector3(input2D.x, 0, input2D.y).normalized()
	
	
	### Determine forces
	F_gravity = MASS * get_gravity()
	F_jump = 150. * float(pressedJump) * basis.y.normalized()
	
	# Flight forces
	var vel_across_wing = velocity.dot(basis.z) * basis.z
	var C_L = 14.0
	var C_D = 0.2
	F_liftLeft = basis.y.normalized() * rho/2 * vel_across_wing.length_squared() * C_L * ONE_WINGED_AREA
	F_liftRght = basis.y.normalized() * rho/2 * vel_across_wing.length_squared() * C_L * ONE_WINGED_AREA
	F_liftTail = basis.y.normalized() * rho/2 * vel_across_wing.length_squared() * C_L * TAIL_AREA

	F_dragLeft = basis.z.normalized() * rho/2 * vel_across_wing.length_squared() * C_D * ONE_WINGED_AREA
	F_dragRght = basis.z.normalized() * rho/2 * vel_across_wing.length_squared() * C_D * ONE_WINGED_AREA
	F_dragTail = basis.z.normalized() * rho/2 * vel_across_wing.length_squared() * C_D * TAIL_AREA
	
	F_Left = F_liftLeft + F_dragLeft
	F_Rght = F_liftRght + F_dragRght
	F_Tail = F_liftTail + F_dragTail
	
	F_dragBasic = -beta * velocity.dot(velocity) * velocity.normalized()
	F_aero = F_Left + F_Rght + F_Tail + F_dragBasic
	
	### When on floor (walking)
	if is_on_floor():
		# Rotate WASD axis w/ camera
		direction = direction.rotated(Vector3.UP, head.global_rotation.y)
		# Set run forces
		F_run = 9 * direction * quaternion.inverse()
		F_run_friction = -5 * velocity
		# Set torques/rotations to zero
		torque = Vector3.ZERO
		alpha = Vector3.ZERO
		ω = Vector3.ZERO
		if direction:
			quaternion = Quaternion.IDENTITY
	
	### When not on floor (flying)
	else:
		F_run = Vector3.ZERO
		F_run_friction = Vector3.ZERO
		
		torque_input = -Vector3(inputWS, inputQE, inputAD) * basis.inverse()
		torque_drag = (-0.75)*torque
		torque_aero = torque_from_forces([F_Left, F_Rght, F_Tail], [wingL.position, wingR.position, tail.position]) # Make sure the two input arrays are the same length!
		torque = torque_input + torque_aero + torque_drag
	
	
	### Process player movement
	acceleration = 1/MASS * ( F_gravity + F_run + F_run_friction + F_jump + F_aero )
	velocity += acceleration * dt
	
	alpha = I.inverse() * torque
	ω += alpha * dt
	if ω.is_zero_approx():
		quaternion = Quaternion.IDENTITY * quaternion
	else:
		quaternion = Quaternion(ω.normalized(), ω.length() * dt) * quaternion
	
	
	move_and_slide()
	
	
	### DEBUG ----------------------------------------
	## Drive label text
	label.text = str('vx: ') + String.num(velocity.x,3) + str(' vy: ') + String.num(velocity.y,3) + str(' vz: ') + String.num(velocity.z,3) + str('\nv: ') + String.num(velocity.length(), 4) + str('\na: ') + String.num(acceleration.length(), 4)
	label.font_size = 36
	label.pixel_size = 0.001
	
	## Debug arrows
	# Body basis
	DebugDraw3D.draw_arrow_ray(position, basis.x, 0.2, Color.RED, false)
	DebugDraw3D.draw_arrow_ray(position, basis.y, 0.2, Color.GREEN, false)
	DebugDraw3D.draw_arrow_ray(position, basis.z, 0.2, Color.BLUE, false)
	
	# Input/run direction (Vec3 direction)
	DebugDraw3D.draw_arrow_ray(position, direction, 0.5, Color.BLACK, false)
	
	# Velocity
	DebugDraw3D.draw_arrow_ray(position, velocity, velocity.length(), Color.ORANGE, false)
	DebugDraw3D.draw_arrow_ray(position, vel_across_wing, vel_across_wing.length(), Color.HOT_PINK, false)
	
	# Wing forces
	DebugDraw3D.draw_arrow_ray(wingL.global_position, F_liftLeft, F_liftLeft.length(), Color.WHITE, false)
	DebugDraw3D.draw_arrow_ray(wingR.global_position, F_liftRght, F_liftRght.length(), Color.WHITE, false)
	DebugDraw3D.draw_arrow_ray(tail.global_position, F_liftTail, F_liftTail.length(), Color.WHITE, false)
	DebugDraw3D.draw_arrow_ray(wingL.global_position, F_dragLeft, F_dragLeft.length(), Color.BLACK, false)
	DebugDraw3D.draw_arrow_ray(wingR.global_position, F_dragRght, F_dragRght.length(), Color.BLACK, false)
	DebugDraw3D.draw_arrow_ray(tail.global_position, F_dragTail, F_dragTail.length(), Color.BLACK, false)
	
	# Wing torques/rotations
	DebugDraw3D.draw_arrow_ray(position, torque, torque.length(), Color.DARK_VIOLET, false)
	#DebugDraw3D.draw_arrow_ray(position, ω, ω.length(), Color.DEEP_PINK, false)




func torque_from_forces(_forces: Array, _force_origins: Array) -> Vector3:
	var _torque: Vector3
	
	for i in range(len(_forces)):
		_torque += _force_origins[i].cross(_forces[i])
	return _torque
