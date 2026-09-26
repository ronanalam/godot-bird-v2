extends CharacterBody3D

### Body parts
@onready var head: Node3D = $head
@onready var body: Node3D = $body
@onready var wingL: Node3D = $body/wingL
@onready var wingR: Node3D = $body/wingR
@onready var tail: Node3D = $body/tail

@onready var player_hitbox: CollisionShape3D = $player_hitbox

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
var is_debug_text_enabled: bool = false
var cycle_debug_arrows: int = 2
var cycle_species: int = 0
var bool_debug_input: bool = false


### Lerp Parameters
const MOUSE_SENS: float = 0.35
const CAMERA_LERP: float = 5.0
const BODY_LERP: float = 6.0


### Physics constants
const JUMP_STRENGTH: Array[float] = [150.0, 750.0]
const JUMPING_STRENGTH: Array[float] = [20.0, 150.0]
const JUMPING_FREQUENCY: Array[float] = [2.0, 2.0]
const beta: float = 0.1
@onready var curve_aoa_cn = preload("res://Assets/curve_aoa_cn.tres")
@onready var curve_aoa_ca = preload("res://Assets/curve_aoa_ca.tres")


### Species constants
const MASS: Array[float] = [0.450, 4.3] # kg
const ONE_WINGED_AREA: Array[float] = [(0.925/2) * 0.2, (2.00/2) * 0.5] # m^2
const TAIL_AREA: float = 0.025 # m^2 (approx)
const WINGL_POSITION: Array[Vector3] = [Vector3(-0.25,0.05,0.05), Vector3(-0.425,0.11,0.075)]
const WINGR_POSITION: Array[Vector3] = [Vector3(0.25,0.05,0.05), Vector3(0.425,0.11,0.075)]
const TAIL_POSITION: Array[Vector3] = [Vector3(0,0.02,0.18), Vector3(0,-0.025,0.3)]
const WINGSPAN: Array[float] = [0.925, 2.00]


### Physics vars
var acceleration: Vector3
var F_gravity: Vector3
var F_run: Vector3
var F_run_friction: Vector3
var F_jump: Vector3
var F_jumping: Vector3
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
var F_lift: Vector3
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
var input_QE: float
var input_WS: float
var input_AD: float
var direction: Vector3

var input_UDarrow: float
var input_LRarrow: float

var pressING_jump: float
var t_last_pressed_jump: float



func _ready() -> void:
	# Init mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Init camera arm
	camera_arm.spring_length = 3 * camera_arm_step
	
	# Detach head from body
	head.top_level = true



func _unhandled_input(event: InputEvent) -> void:
	var _head_rotation_x: float 
	var _head_rotation_y: float
	
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
	
	### Handle hotkey [] to cycle species
	if event.is_action_pressed("cycle_species"):
		if inMenu:
			pass
		else:
			cycle_species += 1
			cycle_species = cycle_species % 2
			init_species( cycle_species )
	
	### Handle hotkey [R] to reset position & velocity
	if event.is_action_pressed("reset"):
		if inMenu:
			pass
		else:
			position = Vector3(0,1,0)
			velocity = Vector3.ZERO
			quaternion = Quaternion.IDENTITY



### Species selection
func init_species( _species: int ) -> int:
	# Set appropriate model offsets
	wingL.position = WINGL_POSITION[_species]
	wingR.position = WINGR_POSITION[_species]
	tail.position = TAIL_POSITION[_species]
	#tail.position = basis * TAIL_POSITION[_species]
	
	match _species:
		0:
			mesh_body.mesh = preload("res://Assets/crow_body_stripped.obj")
			mesh_wingL.mesh = preload("res://Assets/crow_wingL.obj")
			mesh_wingR.mesh = preload("res://Assets/crow_wingR.obj")
			mesh_tail.mesh = preload("res://Assets/crow_tail.obj")
		1:
			mesh_body.mesh = preload("res://Assets/sandhill_crane_body_flying_stripped.obj")
			mesh_wingL.mesh = preload("res://Assets/sandhill_crane_wingL.obj")
			mesh_wingR.mesh = preload("res://Assets/sandhill_crane_wingR.obj")
			mesh_tail.mesh = preload("res://Assets/sandhill_crane_legs.obj")
		_:
			print("cycle_species Error: int is out of the set {0,1}")
	return 0



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
	#var t: float = Time.get_ticks_msec()/1000.
	
	
	### Camera Movement
	camera_arm_endpoint.translate_object_local( Vector3.BACK * camera_arm.spring_length )
	player_camera.position = player_camera.position.lerp( camera_arm_endpoint.position, dt * CAMERA_LERP )
	# Reattach head position to body
	head.position = position
	
	
	
	### Grab player input
	input2D = Input.get_vector('left', 'right', 'forward', 'back')
	input_QE = Input.get_axis('yaw_left', 'yaw_right')
	input_WS = Input.get_axis('forward', 'back')
	input_AD = Input.get_axis('left', 'right')
	pressedJump = Input.is_action_just_pressed('jump')
	#if pressedJump=1:
		
	pressING_jump = Input.get_action_strength("jump")
	direction = Vector3(input2D.x, 0, input2D.y).normalized()
	
	input_UDarrow = Input.get_axis('pitch_tail_up', 'pitch_tail_down')
	input_LRarrow = Input.get_axis('roll_tail_left', "roll_tail_right")
	
	
	
	
	### Determine forces
	F_gravity = MASS[cycle_species] * get_gravity()
	#F_jump    = JUMP_STRENGTH[cycle_species] * float(pressedJump) * ( basis * Vector3(0,2,-1).normalized() ) #basis.y.normalized()
	F_jumping = pressING_jump * JUMPING_STRENGTH[cycle_species] * ( wingR.global_basis.y ) * exp(-fmod(t_last_pressed_jump*JUMPING_FREQUENCY[cycle_species],1)/0.5)
	if pressedJump:
		print("\nPressed [Space]!")
		t_last_pressed_jump = 0.0
	if pressING_jump != 0:
		t_last_pressed_jump += dt
	
	# Flight forces
	var aoa_wingL: float = velocity.angle_to(-wingL.global_basis.z)
	var vel_across_wingL: float = velocity.dot(-wingL.global_basis.z)
	
	var aoa_wingR: float = velocity.angle_to(-wingR.global_basis.z)
	var vel_across_wingR: float = velocity.dot(-wingR.global_basis.z)
	
	var aoa_tail: float = velocity.angle_to(-tail.global_basis.z)
	var vel_across_tail: float = velocity.dot(-tail.global_basis.z)
	
	#var C_L: float = 1.6
	var C_N_left: float = curve_aoa_cn.sample(aoa_wingL/PI)
	var C_N_right: float = curve_aoa_cn.sample(aoa_wingR/PI)
	var C_N_tail: float = curve_aoa_cn.sample(aoa_tail/PI)
	
	#var C_D: float = 0.2
	var C_A_left: float = curve_aoa_ca.sample(aoa_wingL/PI)
	var C_A_right: float = curve_aoa_ca.sample(aoa_wingR/PI)
	var C_A_tail: float = curve_aoa_ca.sample(aoa_tail/PI)
	
	F_liftLeft = wingL.global_basis.y * rho * 0.5 * vel_across_wingL**2 * C_N_left * ONE_WINGED_AREA[cycle_species]
	F_liftRght = wingR.global_basis.y * rho * 0.5 * vel_across_wingR**2 * C_N_right * ONE_WINGED_AREA[cycle_species]
	F_liftTail = tail.global_basis.y * rho * 0.5 * vel_across_tail**2 * C_N_tail * TAIL_AREA

	F_dragLeft = wingL.global_basis.z * rho * 0.5 * vel_across_wingL**2 * C_A_left * ONE_WINGED_AREA[cycle_species]
	F_dragRght = wingR.global_basis.z * rho * 0.5 * vel_across_wingR**2 * C_A_right * ONE_WINGED_AREA[cycle_species]
	F_dragTail = tail.global_basis.z * rho * 0.5 * vel_across_tail**2 * C_A_tail * TAIL_AREA
	
	F_Left = F_liftLeft + F_dragLeft
	F_Rght = F_liftRght + F_dragRght
	F_Tail = F_liftTail + F_dragTail
	
	F_dragBasic = beta * velocity.dot(velocity) * -velocity.normalized()
	
	F_aero = F_Left + F_Rght + F_Tail + F_dragBasic
	F_lift = F_liftLeft + F_liftRght + F_liftTail
	
	
	
	### When on floor (walking)
	if is_on_floor():
		# Rotate WASD axis w/ camera
		direction = direction.rotated(Vector3.UP, head.global_rotation.y)
		# Set run forces
		F_run = 9 * direction #* quaternion.inverse()
		F_run_friction = -5 * velocity
		# Set torques/rotations to zero
		# FINISHED TODO: IF YOU LAND WHILE HOLDING TORQUE YOU WILL SPIN THE OPPOSITE WAY WHEN YOU NEXT TAKE TO THE AIR
		torque = Vector3.ZERO
		torque_input = Vector3.ZERO
		torque_aero = Vector3.ZERO
		torque_drag = Vector3.ZERO
		alpha = Vector3.ZERO
		ω = Vector3.ZERO
		if direction:
			quaternion = Quaternion( Vector3.UP, head.global_rotation.y ) * Quaternion.IDENTITY
	
	
	
	### When not on floor (flying)
	else:
		F_run = Vector3.ZERO
		F_run_friction = Vector3.ZERO
		
		if bool_debug_input:
			torque_input = -Vector3(input_WS, input_QE, input_AD) * basis.inverse()
		else:
			torque_input = Vector3.ZERO
		torque_drag += (-0.2)*torque
		torque_aero = torque_from_forces([F_Left, F_Rght, F_Tail], [basis * wingL.position, basis * wingR.position, basis * tail.position]) # Make sure the two input arrays are the same length!
		torque = torque_input + torque_aero + torque_drag
	
	### Rotate control surfaces with keyboard input:
	# W/S:              Wing pitch, common
	# A/D:              Wing pitch, differential
	# Up/down arrow:    tail pitch
	# Left/right arrow: tail roll
	
	wingR.rotate_x(input_WS/(2*TAU))
	wingR.rotation.x = clampf(wingR.rotation.x, -PI/12, PI/3)
	wingL.rotate_x(input_WS/(2*TAU))
	wingL.rotation.x = clampf(wingL.rotation.x, -PI/12, PI/3)
	
	wingR.rotate_x(-input_AD/(2*TAU))
	wingR.rotation.x = clampf(wingR.rotation.x, -PI/12, PI/3)
	wingL.rotate_x(input_AD/(2*TAU))
	wingL.rotation.x = clampf(wingL.rotation.x, -PI/12, PI/3)
	
	tail.rotate_x(input_UDarrow/(2*TAU))
	tail.rotation.x = clampf(tail.rotation.x, -PI/12, PI/3)
	tail.rotate_y(input_LRarrow/(2*TAU))
	tail.rotation.y = clampf(tail.rotation.y, -PI/12, PI/12)
	
	
	
	
	### Process player movement
	acceleration = 1/MASS[cycle_species] * ( F_gravity + F_run + F_run_friction + F_jump + F_jumping + F_aero )
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
		#label.text = str('vx: ') + String.num(velocity.x,3) + str(' vy: ') + String.num(velocity.y,3) + str(' vz: ') + String.num(velocity.z,3) + str('\nv: ') + String.num(velocity.length(), 4) + str('\na: ') + String.num(acceleration.length(), 4) + str('\nvel_across_wingL: ') + String.num(vel_across_wingL, 4)
		label.text = str("v_tot=\t")+String.num(velocity.length(),3)+str("\nv_y=\t")+String.num(velocity.y,3)
		label.font_size = 36
		label.pixel_size = 0.001
	else:
		label.visible = false
		
	# Label_keybinds shows the current keybinds as text on the screen
	label_keybinds.text = str("Toggle debug text:  "+"[T]\n"+"Cycle debug arrows:  "+"[G]\n"+"Cycle thru species:  "+"[K]")
	label_keybinds.font_size = 36
	label_keybinds.pixel_size = 0.001
	label_keybinds.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	
	## Debug arrows
	# int cycle_debug_arrows is an element of {0,1,2}
	match cycle_debug_arrows:
		2: # Draw only the body basis
			# Body basis
			DebugDraw3D.draw_arrow_ray(position, basis.x, WINGSPAN[cycle_species]/5., Color.RED, false)
			DebugDraw3D.draw_arrow_ray(position, basis.y, WINGSPAN[cycle_species]/5., Color.GREEN, false)
			DebugDraw3D.draw_arrow_ray(position, basis.z, WINGSPAN[cycle_species]/5., Color.BLUE, false)
		1: # Draw all arrows
			# Body basis
			DebugDraw3D.draw_arrow_ray(position, basis.x, WINGSPAN[cycle_species]/5., Color.RED, false)
			DebugDraw3D.draw_arrow_ray(position, basis.y, WINGSPAN[cycle_species]/5., Color.GREEN, false)
			DebugDraw3D.draw_arrow_ray(position, basis.z, WINGSPAN[cycle_species]/5., Color.BLUE, false)
			## WingL basis
			#DebugDraw3D.draw_arrow_ray(wingL.global_position, wingL.global_basis.x, 0.2, Color.RED, false)
			#DebugDraw3D.draw_arrow_ray(wingL.global_position, wingL.global_basis.y, 0.2, Color.GREEN, false)
			#DebugDraw3D.draw_arrow_ray(wingL.global_position, wingL.global_basis.z, 0.2, Color.BLUE, false)
	
			# Input/run direction (Vec3 direction)
			DebugDraw3D.draw_arrow_ray(position, direction, 0.5, Color.BLACK, false)
	
			# Velocity
			DebugDraw3D.draw_arrow_ray(position, velocity, velocity.length(), Color.ORANGE, false)
			DebugDraw3D.draw_arrow_ray(position, vel_across_wingL*basis.z, vel_across_wingL, Color.HOT_PINK, false)
	
			# Wing forces
			DebugDraw3D.draw_arrow_ray(wingL.global_position, F_liftLeft, F_liftLeft.length(), Color.WHITE, false)
			DebugDraw3D.draw_arrow_ray(wingR.global_position, F_liftRght, F_liftRght.length(), Color.WHITE, false)
			DebugDraw3D.draw_arrow_ray(tail.global_position, F_liftTail, F_liftTail.length(), Color.WHITE, false)
			DebugDraw3D.draw_arrow_ray(wingL.global_position, F_dragLeft, F_dragLeft.length(), Color.BLACK, false)
			DebugDraw3D.draw_arrow_ray(wingR.global_position, F_dragRght, F_dragRght.length(), Color.BLACK, false)
			DebugDraw3D.draw_arrow_ray(tail.global_position, F_dragTail, F_dragTail.length(), Color.BLACK, false)
			
			# Total lift force
			DebugDraw3D.draw_arrow_ray(position, F_aero, F_aero.length(), Color.OLIVE, false)
			DebugDraw3D.draw_arrow_ray(position, F_lift, F_lift.length(), Color.DARK_OLIVE_GREEN, false)
	
			# Wing torques/rotations
			DebugDraw3D.draw_arrow_ray(position, torque, torque.length(), Color.DARK_VIOLET, false)
			#DebugDraw3D.draw_arrow_ray(position, ω, ω.length(), Color.DEEP_PINK, false)
		0:
			# Render no arrows
			pass
		_:
			print("cycle_debug_arrows Error: int is out of the set {0,1,2}")



func torque_from_forces(_forces: Array, _force_origins: Array) -> Vector3:
	var _torque: Vector3 = Vector3.ZERO
	
	for i in range(len(_forces)):
		_torque += _force_origins[i].cross(_forces[i])
	return _torque
