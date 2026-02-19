extends Node2D

signal roll_finished(result)

@onready var yut_container = $yut
@onready var result_label = $ResultLabel
@onready var board = $YutBoard

const BOARD_SIZE := 507.0
const BOARD_HALF := BOARD_SIZE / 2.0

var current_result = {}
var initial_positions := []

func _ready():
	visible = false
	result_label.visible = false
	yut_container.z_index = 100
	
	# 🔥 처음 위치 저장
	for i in range(4):
		initial_positions.append(
			yut_container.get_child(i).position
		)
	
func reset_yuts():
	for i in range(4):
		var yut = yut_container.get_child(i)
		
		yut.position = initial_positions[i]
		yut.rotation_degrees = 45
		yut.scale = Vector2(1,1)
		yut.modulate = Color(1,1,1,1)
		
		# 기본 앞면/뒷면 상태 (원하는 기본값)
		yut.show_side(false)

func roll():
	reset_yuts()   # 🔥 추가
	
	visible = true
	result_label.visible = false

	
	current_result = roll_yut()
	
	await animate_yuts(current_result)
	await show_result(current_result)
	
	await get_tree().create_timer(0.7).timeout
	await hide_yuts()
	
	emit_signal("roll_finished", current_result)

# -------------------------

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

func get_yut_faces(name:String):
	match name:
		"도": return [false,true,true,true]
		"개": return [false,false,true,true]
		"걸": return [false,false,false,true]
		"윷": return [false,false,false,false]
		"모": return [true,true,true,true]
		"빽도": return [true,true,true,false]
		_: return [true,true,true,true]

# -------------------------

func animate_yuts(result):
	if result["name"] == "낙":
		await animate_nak()
		return
		
	var faces = get_yut_faces(result["name"])
	
	for i in range(4):
		var yut = yut_container.get_child(i)
		
		yut.scale = Vector2(1,1)
		yut.rotation_degrees = 0
		yut.show_side(randi() % 2 == 0) # 시작은 랜덤
		
		var original_pos = yut.position
		var random_x = randf_range(-40, 40)
		var jump_height = randf_range(180, 230)
		var rotation_amount = randf_range(-1080, 1080)
		
		# 🎬 점프 + 회전
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			yut, "position",
			original_pos + Vector2(random_x, -jump_height),
			0.35
		)
		
		tween.parallel().tween_property(
			yut, "rotation_degrees",
			rotation_amount,
			0.35
		)
		
		await tween.finished
		
		# 🎬 착지
		var fall = create_tween()
		fall.set_trans(Tween.TRANS_BOUNCE)
		fall.set_ease(Tween.EASE_OUT)
		
		fall.tween_property(
			yut, "position",
			original_pos + Vector2(random_x, 0),
			0.4
		)
		
		await fall.finished
		
		var final_face = faces[i]

		# 착지 후 살짝 텀 (자연스러움 증가)
		await get_tree().create_timer(0.05).timeout

		# 🎯 현재 면과 다를 때만 flip
		if yut.is_front != final_face:
			var flip = create_tween()
			flip.set_trans(Tween.TRANS_SINE)
			flip.set_ease(Tween.EASE_IN_OUT)
			
			flip.tween_property(yut, "scale:x", 0.0, 0.08)
			flip.tween_callback(
				Callable(yut, "show_side").bind(final_face)
			)
			flip.tween_property(yut, "scale:x", 1.0, 0.08)
			
			await flip.finished

		# 🔥 착지 스쿼시
		var squash = create_tween()
		squash.tween_property(yut,"scale", Vector2(1.15,0.85),0.08)
		squash.tween_property(yut,"scale", Vector2(1,1),0.12)

		await squash.finished

# -------------------------

func show_result(result):
	result_label.visible = true
	result_label.text = result["name"]
	result_label.scale = Vector2(1,1)
	
	var tween = create_tween()
	tween.tween_property(result_label,"scale",
		Vector2(1.2,1.2),0.1)
	tween.tween_property(result_label,"scale",
		Vector2(1,1),0.1)
	
	await tween.finished

# -------------------------

func hide_yuts():
	var tween = create_tween()
	tween.tween_property(yut_container,"modulate:a",0.0,0.2)
	await tween.finished
	
	visible = false
	yut_container.modulate.a = 1.0
	result_label.visible = false
	
#----------------------------

func get_board_rect() -> Rect2:
	return Rect2(
		Vector2(-BOARD_HALF, -BOARD_HALF),
		Vector2(BOARD_SIZE, BOARD_SIZE)
	)
	
# ---------------------------

func get_board_center() -> Vector2:
	return board.global_position
	
# -----------------------------

func get_screen_rect() -> Rect2:
	return get_viewport().get_visible_rect()

# ---------------------------

func animate_nak():
	var board_center = board.global_position
	var screen_rect = get_viewport().get_visible_rect()
	
	# 🎲 밖으로 나갈 윷 하나 랜덤 선택
	var escape_index = randi() % 4
	
	for i in range(4):
		var yut = yut_container.get_child(i)
		
		yut.scale = Vector2(1,1)
		yut.rotation_degrees = randf_range(-360,360)
		
		var target_global = yut.global_position
		
		# 🎯 선택된 윷만 탈출
		if i == escape_index:
			
			var side = randi() % 4
			
			match side:
				0: # 위
					target_global = Vector2(
						randf_range(board_center.x - BOARD_HALF, board_center.x + BOARD_HALF),
						board_center.y - BOARD_HALF - 120
					)
				1: # 아래
					target_global = Vector2(
						randf_range(board_center.x - BOARD_HALF, board_center.x + BOARD_HALF),
						board_center.y + BOARD_HALF + 120
					)
				2: # 왼쪽
					target_global = Vector2(
						board_center.x - BOARD_HALF - 120,
						randf_range(board_center.y - BOARD_HALF, board_center.y + BOARD_HALF)
					)
				3: # 오른쪽
					target_global = Vector2(
						board_center.x + BOARD_HALF + 120,
						randf_range(board_center.y - BOARD_HALF, board_center.y + BOARD_HALF)
					)
		else:
			target_global += Vector2(
				randf_range(-60,60),
				randf_range(-40,40)
			)
		
		# 🖥 화면 밖으로 안 나가게 clamp
		target_global.x = clamp(
			target_global.x,
			screen_rect.position.x + 20,
			screen_rect.position.x + screen_rect.size.x - 20
		)
		
		target_global.y = clamp(
			target_global.y,
			screen_rect.position.y + 20,
			screen_rect.position.y + screen_rect.size.y - 20
		)
		
		# 🎬 이동 + 회전
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			yut, "global_position", target_global, 0.5
		)
		
		tween.parallel().tween_property(
			yut, "rotation_degrees",
			yut.rotation_degrees + randf_range(-180,180),
			0.5
		)
		
		await tween.finished
		
		# 🎲 랜덤 결과 면
		var final_face = randi() % 2 == 0
		
		# 🎯 현재 면과 다를 때만 flip
		if yut.is_front != final_face:
			
			var flip = create_tween()
			flip.set_trans(Tween.TRANS_SINE)
			flip.set_ease(Tween.EASE_IN_OUT)
			
			flip.tween_property(yut, "scale:x", 0.0, 0.08)
			flip.tween_callback(
				Callable(yut, "show_side").bind(final_face)
			)
			flip.tween_property(yut, "scale:x", 1.0, 0.08)
			
			await flip.finished
		
		# 🔥 살짝 착지 스쿼시
		var squash = create_tween()
		squash.tween_property(yut,"scale", Vector2(1.15,0.85),0.08)
		squash.tween_property(yut,"scale", Vector2(1,1),0.12)
		
		await squash.finished
		
		await get_tree().create_timer(0.05).timeout
