extends Node2D

func _ready():
	for marker in get_children():
		if marker is Marker2D:
			var id = int(marker.name)
			Data.spot_positions[id] = marker.global_position
