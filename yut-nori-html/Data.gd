extends Node

var spot_positions = {}
var player_count = 2 
var current_player = 0 

# 플레이어별 말 4개의 위치 데이터
var piece_positions = []
var finished_counts = []

func setup_game(count):
	player_count = count
	current_player = 0
	piece_positions.clear()
	finished_counts.clear()
	for i in range(count):
		piece_positions.append([0, 0, 0, 0])
		finished_counts.append(0)

var move_logic = {
	0:[2], 1:[100], 2:[3], 3:[4], 4:[5], 5:[6],
	6:[7, 21], 7:[8], 8:[9], 9:[10], 10:[11],
	11:[12, 26], 12:[13], 13:[14], 14:[15], 15:[16],
	16:[17], 17:[18], 18:[19], 19:[20], 20:[1],
	21:[22], 22:[23], 23:[24, 28], 24:[25], 25:[16],
	26:[27], 27:[23], 28:[29], 29:[20]
}

var back_logic = {
	2:0, 3:2, 4:3, 5:4, 6:5, 7:6, 8:7, 9:8, 10:9, 11:10,
	12:11, 13:12, 14:13, 15:14, 16:15, 17:16, 18:17, 19:18, 20:19,
	1:20, 21:6, 22:21, 23:22, 24:23, 25:24, 26:11, 27:26, 28:23, 29:28
}
