extends Node3D

@onready var player: CharacterBody3D = $player
@onready var ground: CSGBox3D = $ground

var chunk_size: float = 80.0
var view_Xpos: bool = true
var view_Ypos: bool = true



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(ground.size)
	pass # Replace with function body.



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
	



# Called every frame. 'dt' is the elapsed time since the previous frame.
func _physics_process(_dt: float) -> void:
	
	var current_chunk: Vector3 = (player.position/chunk_size).floor()
	var _render_radius: float = 80.
	
	var _r_mod_chunk: Vector3 = Vector3(fmod(player.position.x, chunk_size), 
									fmod(player.position.y, chunk_size), 
									fmod(player.position.z, chunk_size));
	
	ground.position = (current_chunk + 0.5*Vector3.ONE) * chunk_size
	
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
