extends CharacterBody3D

### Body parts
@onready var head: Node3D = $head
@onready var body: Node3D = $body
@onready var player_hitbox: CollisionShape3D = $player_hitbox
@onready var wingL: Node3D = $body/wingL
@onready var wingR: Node3D = $body/wingR
@onready var tail: Node3D = $body/tail

@onready var mesh_body: MeshInstance3D = $body/mesh_body_stripped
@onready var mesh_wingL: MeshInstance3D = $body/wingL/mesh_wingL
@onready var mesh_wingR: MeshInstance3D = $body/wingR/mesh_wingR
@onready var mesh_tail: MeshInstance3D = $body/tail/mesh_tail


### Camera
@onready var player_camera: Camera3D = $head/player_camera
@onready var camera_arm: SpringArm3D = $head/camera_arm
@onready var camera_arm_endpoint: Marker3D = $head/camera_arm/camera_arm_endpoint
@onready var label: Label3D = $head/label
@onready var label_keybinds: Label3D = $head/player_camera/label_keybinds
const camera_arm_step: float = 0.25


### Menu variables
var inMenu: bool = false
var is_debug_text_enabled: bool = true
var cycle_debug_arrows: int = 3%3
var cycle_species: int = 2%2


### Lerp Parameters
const MOUSE_SENS: float = 0.35
const CAMERA_LERP: float = 5.0
const BODY_LERP: float = 6.0


### Physics constants
const jump_strength: float = 15.0
const MASS: float = 0.450 # kg
const ONE_WINGED_AREA: float = (0.925/2.0) * 0.2 # m^2
const TAIL_AREA: float = 0.025 # m^2 (approx)
const beta: float = 0.1

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
var AoA: float = 30
var rho: float = 1.225 # kg m^-3 #TODO: Altitude-dependent density
# Torques/rotations
var torque: Vector3
var alpha: Vector3
var ω: Vector3
var I: Basis = Basis(
	Vector3(0.1, 0, 0),
	Vector3(0, 0.1, 0),
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

var input_up_down: float



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
		
	### Handle toggle hotkeys of debug visibility
	if event.is_action_pressed("toggle_debug_text"):
		if inMenu:
			pass
		else:
			is_debug_text_enabled = !is_debug_text_enabled
	if event.is_action_pressed("cycle_debug_arrows"):
		if inMenu:
			pass
		else:
			cycle_debug_arrows += 1
			cycle_debug_arrows = cycle_debug_arrows % 3
	
	### Handle hotkey to cycle species
	if event.is_action_pressed("cycle_species"):
		if inMenu:
			pass
		else:
			cycle_species += 1
			cycle_species = cycle_species % 2



#func _process(dt: float) -> void:
	#
	## Calculates which quadrant of the world our head is facing
	#match floor( fmod(head.rotation.y+PI/4, TAU) * (2/PI) ):
		#0.: # Quadrant I
			#print('i')
		#1.: # Quadrant II
			#print("ii")
		#2.: # Quadrant III
			#print("iii")
		#3.: # Quadrant IV
			#print("iv")



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
	
	input_up_down = Input.get_axis('pitch_wingR_down', 'pitch_wingR_up')
	
	
	
	### Species selection
	match cycle_species:
		1:
			mesh_body.mesh = preload("res://Assets/crow_body_stripped.obj")
			mesh_wingL.mesh = preload("res://Assets/crow_wingL.obj")
			mesh_wingR.mesh = preload("res://Assets/crow_wingR.obj")
			mesh_tail.mesh = preload("res://Assets/crow_tail.obj")
		0:
			mesh_body.mesh = preload("res://Assets/sandhill_crane_body_flying_stripped.obj")
			mesh_wingL.mesh = preload("res://Assets/sandhill_crane_wingL.obj")
			mesh_wingR.mesh = preload("res://Assets/sandhill_crane_wingR.obj")
			mesh_tail.mesh = preload("res://Assets/sandhill_crane_legs.obj")
		_:
			print("cycle_species Error: int is out of the set {0,1}")
	
	
	
	### Determine forces
	F_gravity = MASS * get_gravity()
	F_jump = 150. * float(pressedJump) * ( basis * Vector3(0,2,-1).normalized() ) #basis.y.normalized()
	
	# Flight forces
	var vel_across_wingL: Vector3 = velocity.dot(-wingL.basis.z) * wingL.basis.z
	var vel_across_wingR: Vector3 = velocity.dot(-wingR.basis.z) * wingR.basis.z
	var vel_across_tail: Vector3 = velocity.dot(-tail.basis.z) * tail.basis.z
	
	var C_L: float = 1.6
	var C_D: float = 0.2
	F_liftLeft = wingL.basis.y * rho * 0.5 * vel_across_wingL.length_squared() * C_L * ONE_WINGED_AREA
	F_liftRght = wingR.basis.y * rho * 0.5 * vel_across_wingR.length_squared() * C_L * ONE_WINGED_AREA
	F_liftTail = tail.basis.y * rho * 0.5 * vel_across_tail.length_squared() * C_L * TAIL_AREA

	F_dragLeft = wingL.basis.z * rho * 0.5 * vel_across_wingL.length_squared() * C_D * ONE_WINGED_AREA
	F_dragRght = wingR.basis.z * rho * 0.5 * vel_across_wingR.length_squared() * C_D * ONE_WINGED_AREA
	F_dragTail = tail.basis.z * rho * 0.5 * vel_across_tail.length_squared() * C_D * TAIL_AREA
	
	F_Left = F_liftLeft + F_dragLeft
	F_Rght = F_liftRght + F_dragRght
	F_Tail = F_liftTail + F_dragTail
	
	F_dragBasic = beta * velocity.dot(velocity) * -velocity.normalized()
	
	F_aero = F_Left + F_Rght + F_Tail + F_dragBasic
	
	
	
	### When on floor (walking)
	if is_on_floor():
		# Rotate WASD axis w/ camera
		direction = direction.rotated(Vector3.UP, head.global_rotation.y)
		# Set run forces
		F_run = 9 * direction * quaternion.inverse()
		F_run_friction = -5 * velocity
		# Set torques/rotations to zero
		# TODO: IF YOU LAND WHILE HOLDING TORQUE YOU WILL SPIN THE OPPOSITE WAY WHEN YOU NEXT TAKE TO THE AIR
		torque = Vector3.ZERO
		torque_input = Vector3.ZERO
		torque_aero = Vector3.ZERO
		torque_drag = Vector3.ZERO
		alpha = Vector3.ZERO
		ω = Vector3.ZERO
		if direction:
			quaternion = Quaternion.IDENTITY
	
	
	
	### When not on floor (flying)
	else:
		F_run = Vector3.ZERO
		F_run_friction = Vector3.ZERO
		
		torque_input = -Vector3(inputWS, inputQE, inputAD) * basis.inverse()
		torque_drag += (-0.2)*torque
		torque_aero = torque_from_forces([F_Left, F_Rght, F_Tail], [wingL.position, wingR.position, tail.position]) # Make sure the two input arrays are the same length!
		torque = torque_input + torque_aero + torque_drag
	
	wingR.rotate_x(input_up_down/(2*TAU))
	#wingL.rotate_x(-inputWS/TAU)
	wingL.rotate_x(input_up_down/(2*TAU))
	
	
	### Process player movement
	acceleration = 1/MASS * ( F_gravity + F_run + F_run_friction + F_jump + F_aero )
	velocity += acceleration * dt
	
	alpha = I.inverse() * torque
	ω += alpha * dt
	if ω.is_zero_approx():
		quaternion = Quaternion.IDENTITY * quaternion
	else:
		quaternion = Quaternion(ω.normalized(), TAU * ω.length() * dt) * quaternion # Added a factor of TAU
	
	move_and_slide()
	
	
	
	
	### --------------------------
	###   ---    DEBUGGING    ---
	### --------------------------
	
	## Drive label text
	if is_debug_text_enabled:
		label.visible = true
		label.text = str('vx: ') + String.num(velocity.x,3) + str(' vy: ') + String.num(velocity.y,3) + str(' vz: ') + String.num(velocity.z,3) + str('\nv: ') + String.num(velocity.length(), 4) + str('\na: ') + String.num(acceleration.length(), 4) + str('\nvel_across_wingL: ') + String.num(vel_across_wingL.length(), 4)
		label.font_size = 36
		label.pixel_size = 0.001
	else:
		label.visible = false
		
	# Label_keybinds shows the current keybinds as text on the screen
	label_keybinds.text = str("Toggle debug text:  "+"[T]\n"+"Cycle debug arrows:  "+"[G]\n"+"Cycle thru species:  "+"[Q]")
	label_keybinds.font_size = 36
	label_keybinds.pixel_size = 0.001
	label_keybinds.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	
	## Debug arrows
	# int cycle_debug_arrows is an element of {0,1,2}
	match cycle_debug_arrows:
		2:
			# Draw only the body basis
			# Body basis
			DebugDraw3D.draw_arrow_ray(position, basis.x, 0.2, Color.RED, false)
			DebugDraw3D.draw_arrow_ray(position, basis.y, 0.2, Color.GREEN, false)
			DebugDraw3D.draw_arrow_ray(position, basis.z, 0.2, Color.BLUE, false)
			#print('2')
		1:
			# Draw all arrows
			# Body basis
			DebugDraw3D.draw_arrow_ray(position, basis.x, 0.2, Color.RED, false)
			DebugDraw3D.draw_arrow_ray(position, basis.y, 0.2, Color.GREEN, false)
			DebugDraw3D.draw_arrow_ray(position, basis.z, 0.2, Color.BLUE, false)
	
			# Input/run direction (Vec3 direction)
			DebugDraw3D.draw_arrow_ray(position, direction, 0.5, Color.BLACK, false)
	
			# Velocity
			DebugDraw3D.draw_arrow_ray(position, velocity, velocity.length(), Color.ORANGE, false)
			DebugDraw3D.draw_arrow_ray(position, vel_across_wingL, vel_across_wingL.length(), Color.HOT_PINK, false)
	
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
			#print('1')
		0:
			# Render no arrows
			pass
			#print('0')
		_:
			print("cycle_debug_arrows Error: int is out of the set {0,1,2}")
	
	## Body basis
	#DebugDraw3D.draw_arrow_ray(position, basis.x, 0.2, Color.RED, false)
	#DebugDraw3D.draw_arrow_ray(position, basis.y, 0.2, Color.GREEN, false)
	#DebugDraw3D.draw_arrow_ray(position, basis.z, 0.2, Color.BLUE, false)
	#
	## Input/run direction (Vec3 direction)
	#DebugDraw3D.draw_arrow_ray(position, direction, 0.5, Color.BLACK, false)
	#
	## Velocity
	#DebugDraw3D.draw_arrow_ray(position, velocity, velocity.length(), Color.ORANGE, false)
	#DebugDraw3D.draw_arrow_ray(position, vel_across_wingL, vel_across_wingL.length(), Color.HOT_PINK, false)
	#
	## Wing forces
	#DebugDraw3D.draw_arrow_ray(wingL.global_position, F_liftLeft, F_liftLeft.length(), Color.WHITE, false)
	#DebugDraw3D.draw_arrow_ray(wingR.global_position, F_liftRght, F_liftRght.length(), Color.WHITE, false)
	#DebugDraw3D.draw_arrow_ray(tail.global_position, F_liftTail, F_liftTail.length(), Color.WHITE, false)
	#DebugDraw3D.draw_arrow_ray(wingL.global_position, F_dragLeft, F_dragLeft.length(), Color.BLACK, false)
	#DebugDraw3D.draw_arrow_ray(wingR.global_position, F_dragRght, F_dragRght.length(), Color.BLACK, false)
	#DebugDraw3D.draw_arrow_ray(tail.global_position, F_dragTail, F_dragTail.length(), Color.BLACK, false)
	#
	## Wing torques/rotations
	#DebugDraw3D.draw_arrow_ray(position, torque, torque.length(), Color.DARK_VIOLET, false)
	##DebugDraw3D.draw_arrow_ray(position, ω, ω.length(), Color.DEEP_PINK, false)




func torque_from_forces(_forces: Array, _force_origins: Array) -> Vector3:
	var _torque: Vector3 = Vector3.ZERO
	
	for i in range(len(_forces)):
		_torque += _force_origins[i].cross(_forces[i])
	return _torque
