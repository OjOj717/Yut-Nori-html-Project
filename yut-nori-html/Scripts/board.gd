extends Node2D

var spot_positions = {} # 번호별 좌표를 저장할 사전

func _ready():
	for marker in get_children():
		if marker is Marker2D:
			var id = int(marker.name) # 이름을 숫자로 변환
			spot_positions[id] = marker.global_position
			
	print("윷판 좌표 로드 완료: ", spot_positions.size(), "개 지점")

var move_logic = {
	# --- 외곽 테두리 (1~20) ---
	1: [2], 2: [3], 3: [4], 4: [5],
	5: [6, 21],    # 우상단 모서리 (지름길 시작)
	6: [7], 7: [8], 8: [9], 9: [10],
	10: [11, 25],  # 좌상단 모서리 (지름길 시작)
	11: [12], 12: [13], 13: [14], 14: [15],
	15: [16],      # 좌하단 모서리 (꺾이는 길 없음)
	16: [17], 17: [18], 18: [19], 19: [20],
	20: [100],     # 100은 '골인'을 의미하는 임의의 번호

	# --- 우상단 -> 좌하단 대각선 (21~24) ---
	21: [22], 22: [23], 
	23: [24, 27],  # 정중앙 교차점
	24: [15],

	# --- 좌상단 -> 우하단 대각선 (25~28) ---
	25: [26], 26: [23], # 중앙으로 진입
	27: [28], 28: [20]
}

func get_next_position(current_id: int, is_turning: bool = false) -> int:
	if not move_logic.has(current_id):
		return -1
		
	var paths = move_logic[current_id]
	
	if is_turning and paths.size() > 1:
		return paths[1]
	
	return paths[0]
