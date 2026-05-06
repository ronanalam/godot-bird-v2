extends Node3D

@onready var player: CharacterBody3D = $player
@onready var ground: CSGBox3D = $ground

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.


# Called every frame. 'dt' is the elapsed time since the previous frame.
func _physics_process(dt: float) -> void:
	
	
	var chunk_size = 16.0
	
	var r_mod_chunk: Vector3 = Vector3(fmod(player.position.x, chunk_size), fmod(player.position.y, chunk_size), fmod(player.position.z, chunk_size))
	
	if 16*floor(player.position/16) == floor(player.position):
		pass
	
	
	if abs(player.position.x - ground.position.x) > ground.size.x/2:
		ground.set_position(Vector3(player.position.x + ground.size.x/2, ground.position.y, ground.position.z))
	if abs(player.position.z - ground.position.z) > ground.size.z/2:
		ground.set_position( Vector3(ground.position.x, ground.position.y, player.position.z + ground.size.y/2) )
