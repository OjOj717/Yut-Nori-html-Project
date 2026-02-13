extends Node2D

@onready var roll_button = $Button 
@onready var pieces_parent = $Pieces

var player_groups = []
var is_moving = false
var indicators = []
var current_roll_steps = 0
var game_started = false

func _ready():
	roll_button.visible = false
	for p in pieces_parent.get_children():
		p.visible = false
	
	_initialize_game_board()
	
func _initialize_game_board():
	game_started = true
	# Data.setup_game은 이미 이전 씬에서 했으므로 호출할 필요 없음
	var count = Data.player_count 
	
	player_groups = pieces_parent.get_children().slice(0, count)
	
	Data.spot_positions.clear()
	var index = 1
	for marker in $Board.get_children():
		if marker is Marker2D:
			Data.spot_positions[index] = marker.global_position
			index += 1
	
	for p_idx in range(count):
		player_groups[p_idx].visible = true
		var p_nodes = player_groups[p_idx].get_children()
		for i in range(p_nodes.size()):
			p_nodes[i].global_position = Vector2(100 + (p_idx * 150), 150 + (i * 70))
	
	roll_button.visible = true

func _on_button_pressed():
	if is_moving or not game_started: return
	var result = roll_yut()
	current_roll_steps = result["steps"]
	
	if current_roll_steps == 0:
		next_turn()
		return
	
	roll_button.visible = false
	show_piece_selection()

func show_piece_selection():
	clear_indicators()
	var p_idx = Data.current_player
	var p_nodes = player_groups[p_idx].get_children()
	
	for i in range(4):
		var spot = Data.piece_positions[p_idx][i]
		if spot == 100: continue
		
		var btn = Button.new()
		btn.text = str(i + 1) + "번"
		add_child(btn)
		
		if spot == 0:
			btn.global_position = p_nodes[i].global_position + Vector2(40, 0)
		else:
			btn.global_position = p_nodes[i].global_position - Vector2(20, 40)
		btn.pressed.connect(_on_piece_selected.bind(i))
		indicators.append(btn)

func _on_piece_selected(piece_idx):
	clear_indicators()
	var start_spot = Data.piece_positions[Data.current_player][piece_idx]
	var routes = calculate_targets(start_spot, current_roll_steps)
	
	if routes.is_empty():
		roll_button.visible = true
		return
	show_move_indicators(piece_idx, routes)

func show_move_indicators(piece_idx, routes):
	var small_indicator = preload("res://Img/s_s_circle.png")
	var big_indicator = preload("res://Img/b_s_circle.png")
	
	# 특수 칸 번호 목록
	var special_spots = [1, 6, 11, 16, 23]

	for route in routes:
		var target_spot = route[-1]
		if target_spot == 100:
			var exit_btn = Button.new()
			exit_btn.text = "탈출!"
			exit_btn.global_position = Vector2(500, 400)
			exit_btn.pressed.connect(_on_target_selected.bind(piece_idx, route))
			add_child(exit_btn)
			indicators.append(exit_btn)
		else:
			var btn = TextureButton.new()
			var target_scale = Vector2(1, 1)
			
			if target_spot in special_spots:
				btn.texture_normal = big_indicator
				target_scale = Vector2(1, 1)
			else:
				btn.texture_normal = small_indicator
			
			btn.scale = target_scale
			
			var current_tex = btn.texture_normal
			var offset = (current_tex.get_size() * target_scale) / 2
			
			btn.global_position = Data.spot_positions[target_spot] - offset
			btn.pressed.connect(_on_target_selected.bind(piece_idx, route))
			btn.z_index = 10
			add_child(btn)
			indicators.append(btn)

func _on_target_selected(piece_idx, full_route):
	clear_indicators()
	is_moving = true
	
	var p_idx = Data.current_player
	var p_nodes = player_groups[p_idx].get_children()
	var current_pos = Data.piece_positions[p_idx][piece_idx]
	
	var carried_indices = []
	for i in range(4):
		if current_pos != 0 and Data.piece_positions[p_idx][i] == current_pos:
			carried_indices.append(i)
	if not piece_idx in carried_indices: carried_indices.append(piece_idx)

	var path = full_route.duplicate()
	path.remove_at(0)
	
	for spot in path:
		var tweens = []
		for i in range(carried_indices.size()):
			var idx = carried_indices[i]
			Data.piece_positions[p_idx][idx] = spot
			if spot != 100:
				var stack_offset = Vector2(i * 10, i * 10)
				var tw = create_tween()
				tw.tween_property(p_nodes[idx], "global_position", Data.spot_positions[spot] + stack_offset, 0.2)
				tweens.append(tw)
				p_nodes[idx].z_index = 5 + i
		if not tweens.is_empty(): await tweens[-1].finished
		
		if spot == 100:
			for idx in carried_indices:
				p_nodes[idx].visible = false
				Data.finished_counts[p_idx] += 1
			break

	# --- 상대방 말 잡기 체크 로직 추가 ---
	var final_spot = Data.piece_positions[p_idx][piece_idx]
	var caught_someone = false
	if final_spot != 100 and final_spot != 0:
		for other_p in range(Data.player_count):
			if other_p == p_idx: continue # 내 말은 무시
			
			var other_p_nodes = player_groups[other_p].get_children()
			for other_i in range(4):
				if Data.piece_positions[other_p][other_i] == final_spot:
					# 잡았다! 대기실(0)로 보냄
					Data.piece_positions[other_p][other_i] = 0
					other_p_nodes[other_i].global_position = Vector2(100 + (other_p * 150), 150 + (other_i * 70))
					caught_someone = true
	# ---------------------------------

	is_moving = false
	if Data.finished_counts[p_idx] >= 4:
		print((p_idx + 1), "번 승리!")
	else:
		# 윷, 모가 나왔거나 상대방을 잡았다면 한 번 더!
		if current_roll_steps >= 4 or caught_someone:
			print("한 번 더 던지세요!")
			roll_button.visible = true
		else:
			next_turn()

func next_turn():
	Data.current_player = (Data.current_player + 1) % Data.player_count
	roll_button.visible = true

# calculate_targets, clear_indicators, roll_yut 함수는 이전과 동일하게 유지

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
			if last_spot == 100:
				next_routes.append(route)
				continue
			if Data.move_logic.has(last_spot):
				var options = Data.move_logic[last_spot]
				if (last_spot == 6 or last_spot == 11 or last_spot == 23) and i == 0:
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

func clear_indicators():
	for ind in indicators: ind.queue_free()
	indicators.clear()

func roll_yut():
	var roll = randf()
	if roll < 0.1: return {"name":"낙","steps":0}
	var sub = randf()
	if sub < 0.04: return {"name":"빽도","steps":-1}
	elif sub < 0.16: return {"name":"도","steps":1}
	elif sub < 0.50: return {"name":"개","steps":2}
	elif sub < 0.85: return {"name":"걸","steps":3}
	elif sub < 0.98: return {"name":"윷","steps":4}
	else: return {"name":"모","steps":5}
