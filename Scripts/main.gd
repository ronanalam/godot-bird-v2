extends Node3D

@onready var player: CharacterBody3D = $player
@onready var ground: CSGBox3D = $ground
@onready var sun: DirectionalLight3D = $sun
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var target_box: Area3D = $TargetBox

#var chunk_size: float = 800.0
var view_Xpos: bool = true
var view_Ypos: bool = true



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Init sun to be on the eastern horizon
	sun.basis = sun.basis.rotated(Vector3.UP, PI/2)
	world_environment.environment.sky.sky_material.set_shader_parameter("sun_disk_angle", 3.0 )
	
	# Init box to (0,2,0)
	target_box.position = 2*Vector3.UP



func _process(_dt: float) -> void:
	# Calculates which quadrant of the world our head is facing
	match floor( fmod(player.head.rotation.y+PI/4, TAU) * (2/PI) ):
		0.: # Quadrant I
			#ground.size = chunk_size * Vector3(1,0,3)
			view_Xpos = true
			view_Ypos = true
		1.: # Quadrant II
			#ground.size = chunk_size * Vector3(3,0,1)
			view_Xpos = false
			view_Ypos = true
		2.: # Quadrant III
			#ground.size = chunk_size * Vector3(1,0,3)
			view_Xpos = true
			view_Ypos = true
		3.: # Quadrant IV
			#ground.size = chunk_size * Vector3(3,0,1)
			view_Xpos = true
			view_Ypos = true
	


var time_since_last_update: float
var target_box_hits: int = 0

# Called every frame. 'dt' is the elapsed time since the previous frame.
func _physics_process(_dt: float) -> void:
	
	const time_between_world_updates: float = 1./60. # seconds
	
	time_since_last_update += _dt
	
	if time_since_last_update > time_between_world_updates:
		update_world(time_between_world_updates)
		time_since_last_update = 0.0
	
	# Handle target_box stuff
	if target_box.has_overlapping_bodies():
		target_box.position = random_box_position()
		target_box_hits += 1
		
	
	var chunk_size: float = 10.0
	var _current_chunk: Vector3 = (player.position/chunk_size).floor()

	#print("current_chunk = "+"{current_chunk.x}")
	
	
	
	#var _render_radius: float = 80.
	#
	#var _r_mod_chunk: Vector3 = Vector3(fmod(player.position.x, chunk_size), 
									#fmod(player.position.y, chunk_size), 
									#fmod(player.position.z, chunk_size));
	#
	#ground.position = (current_chunk + 0.5*Vector3.ONE) * chunk_size
	
	#if = floor(player.position)/16:
		#pass;
	
	#if abs(player.position.x - ground.position.x) > ground.size.x/2:
		#ground.set_position(Vector3(player.position.x + ground.size.x/2, 
							#ground.position.y, 
							#ground.position.z))
	#
	#if abs(player.position.z - ground.position.z) > ground.size.z/2:
		#ground.set_position( Vector3(ground.position.x, 
									#ground.position.y, 
									#player.position.z + ground.size.y/2) )



func update_world(delta_t: float) -> void:
	var _r: Vector3 = player.position
	var time_multiplier: float = 50.
	
	# Update sun direction
	#sun.rotate(global_basis.z, Time.get_datetime_dict_from_system()["second"])
	sun.quaternion = Quaternion( -sun.basis.x, TAU * delta_t * time_multiplier/(24.*3600.) ) * sun.quaternion
	world_environment.environment.sky.sky_material.set_shader_parameter("sun_dir", sun.basis.z.normalized() )
	#print( sun.basis.z )
	#sun.light_color = 
	
	#print("Updated world!")
	#print(Time.get_datetime_string_from_system()+"\n")



func random_box_position() -> Vector3:
	return Vector3(randf_range(-10,10),randf_range(1,20),randf_range(-10,10))
