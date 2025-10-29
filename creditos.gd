extends Control

func _input(event):
	if event.is_pressed() and not event.is_echo():
		get_tree().change_scene_to_file("res://menu.tscn")
