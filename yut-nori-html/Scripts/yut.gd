extends Node2D

var is_front: bool = false  # 🔥 현재 면 상태 저장

@onready var front_sprite = $front
@onready var back_sprite = $back

func show_side(front: bool):
	is_front = front   # 🔥 상태 저장
	
	front_sprite.visible = front
	back_sprite.visible = not front
