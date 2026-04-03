extends Node3D

@onready var player: CharacterBody3D = $player
@onready var floor: CSGBox3D = $floor

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.


# Called every frame. 'dt' is the elapsed time since the previous frame.
func _physics_process(dt: float) -> void:
	if abs(player.position.x - floor.position.x) > floor.size.x/2:
		floor.set_position(Vector3(player.position.x, floor.position.y, floor.position.z))
	if abs(player.position.z - floor.position.z) > floor.size.z/2:
		floor.set_position(Vector3(floor.position.x, floor.position.y, player.position.z))
