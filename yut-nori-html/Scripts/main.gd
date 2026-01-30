extends Node2D

@onready var player = $Player
@onready var board = $Board

var current_spot = 1 # 현재 위치 (1번 마커에서 시작)
var spot_positions = {}

var move_logic = {
	1: [2], 2: [3], 3: [4], 4: [5], 5: [6, 21],
	6: [7], 7: [8], 8: [9], 9: [10], 10: [11, 25],
	11: [12], 12: [13], 13: [14], 14: [15], 15: [16],
	16: [17], 17: [18], 18: [19], 19: [20], 20: [100],
	21: [22], 22: [23], 23: [24, 27], 24: [15],
	25: [26], 26: [23], 27: [28], 28: [20]
}

func _ready():
	spot_positions.clear()
	
	# 이름 상관없이 Board의 자식들을 순서대로 1, 2, 3... 번으로 등록
	var index = 1
	for marker in $Board.get_children():
		if marker is Marker2D:
			spot_positions[index] = marker.global_position
			index += 1
	
	print("등록된 마커 개수: ", spot_positions.size())
	print("등록된 마커 번호들: ", spot_positions.keys())
	
	# 시작 위치 설정
	if spot_positions.has(1):
		$Player.global_position = spot_positions[1]

# 버튼을 눌렀을 때 실행될 함수
func _on_button_pressed():
	# 1~5 사이 랜덤 숫자 (도~모)
	var steps = randi_range(1, 5)
	print("나온 숫자: ", steps)
	
	move_player(steps)

func move_player(steps):
	for i in range(steps):
		if move_logic.has(current_spot):
			# 여기서는 단순화를 위해 항상 첫 번째 길([0])로만 갑니다.
			current_spot = move_logic[current_spot][0]
			
			if current_spot == 100:
				print("골인!")
				current_spot = 1 # 다시 시작점으로
				break
				
			# 부드럽게 이동하는 효과 (Tween)
			var tween = create_tween()
			tween.tween_property(player, "global_position", spot_positions[current_spot], 0.2)
			await tween.finished # 이동이 끝날 때까지 대기
