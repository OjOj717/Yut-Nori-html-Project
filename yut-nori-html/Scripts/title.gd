extends Node2D

func _ready():
	var container = $CanvasLayer/StartMenu/HBoxContainer
	for btn in container.get_children():
		if btn is Button:
			btn.pressed.connect(_on_player_button_pressed.bind(int(btn.name)))

func _on_player_button_pressed(count: int):
	# 1. 데이터 저장
	Data.setup_game(count)
	# 2. 게임 씬으로 이동
	get_tree().change_scene_to_file("res://Scene/main.tscn")
