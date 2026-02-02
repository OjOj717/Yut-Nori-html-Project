extends Node2D

@onready var player = $Player
var is_moving = false
var indicators = []

func _ready():
	Data.spot_positions.clear()
	var index = 1
	for marker in $Board.get_children():
		if marker is Marker2D:
			Data.spot_positions[index] = marker.global_position
			index += 1
	
	player.global_position = Data.spot_positions[Data.current_spot]

func _on_button_pressed():
	if is_moving: return
	
	var result = roll_yut()
	print("결과: ", result["name"])
	
	if result["steps"] == 0:
		print("낙입니다!")
		return
	
	var targets = calculate_targets(Data.current_spot, result["steps"])
	
	if targets.is_empty():
		print("갈 수 있는 길이 없습니다.")
		return

	show_indicators(targets)

func calculate_targets(start_spot, steps):
	var results = []
	
	if steps == -1:
		if Data.back_logic.has(start_spot):
			results.append([start_spot, Data.back_logic[start_spot]])
		return results

	var routes = [[start_spot]]
	
	for i in range(steps):
		var next_routes = []
		for route in routes:
			var last_spot = route[-1]
			if Data.move_logic.has(last_spot):
				var options = Data.move_logic[last_spot]
				
				if i == 0 and options.size() > 1:
					for next_spot in options:
						var new_route = route.duplicate()
						new_route.append(next_spot)
						next_routes.append(new_route)
				else:
					var new_route = route.duplicate()
					new_route.append(options[0])
					next_routes.append(new_route)
		
		routes = next_routes
		if routes.is_empty(): break
		
	return routes

func show_indicators(routes):
	clear_indicators()
	var indicator_tex = preload("res://Img/s_s_circle.png")
	
	for route in routes:
		var target_spot = route[-1]
		
		var btn = TextureButton.new()
		btn.texture_normal = indicator_tex
		
		btn.scale = Vector2(0.06, 0.06)
		
		var offset = (indicator_tex.get_size() * 0.06) / 2
		btn.global_position = Data.spot_positions[target_spot] - offset
		
		btn.pressed.connect(_on_target_selected.bind(route))
		
		add_child(btn)
		indicators.append(btn)

func _on_target_selected(full_route):
	clear_indicators()
	is_moving = true
	
	var path_to_follow = full_route.duplicate()
	path_to_follow.remove_at(0)
	
	for spot in path_to_follow:
		Data.current_spot = spot
		await animate_move(spot)
		if spot == 100:
			Data.current_spot = 1
			player.global_position = Data.spot_positions[1]
			break
			
	is_moving = false

func animate_move(target_idx):
	var tween = create_tween()
	tween.tween_property(player, "global_position", Data.spot_positions[target_idx], 0.2)
	await tween.finished

func clear_indicators():
	for ind in indicators:
		ind.queue_free()
	indicators.clear()

func roll_yut():
	var roll = randf()
	if roll < 0.10: return {"name": "낙", "steps": 0}
	var sub = randf()
	if sub < 0.0384: return {"name": "빽도", "steps": -1}
	elif sub < 0.1536: return {"name": "도", "steps": 1}
	elif sub < 0.4992: return {"name": "개", "steps": 2}
	elif sub < 0.8448: return {"name": "걸", "steps": 3}
	elif sub < 0.9744: return {"name": "윷", "steps": 4}
	else: return {"name": "모", "steps": 5}
