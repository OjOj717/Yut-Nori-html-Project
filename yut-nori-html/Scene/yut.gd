extends Node2D

@onready var front = $front
@onready var back = $back

func show_side(is_front: bool):
	front.visible = is_front
	back.visible = !is_front
