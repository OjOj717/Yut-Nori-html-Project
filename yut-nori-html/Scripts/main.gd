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
	# 1. spot_positions 초기화 확인
	spot_positions.clear() 
	
	# 2. Board 노드 아래의 모든 자식을 돌며 좌표 저장
	for marker in $Board.get_children():
		if marker is Marker2D:
			var id = int(marker.name) # 마커의 이름(1, 2, 3...)을 숫자로 변환
			spot_positions[id] = marker.global_position
			print("마커 로드: ", id, "번 위치 ", spot_positions[id]) # 디버깅용 출력

	# 3. 1번 마커가 정상적으로 로드되었는지 최종 확인
	if spot_positions.has(1):
		player.global_position = spot_positions[1]
	else:
		push_error("에러: 1번 마커를 찾을 수 없습니다! 마커 이름을 확인해주세요.")

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
