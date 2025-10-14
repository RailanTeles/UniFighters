extends AudioStreamPlayer

func _ready():
	connect("finished", Callable(self, "_on_finished"))
	
func _on_finished():
	play()
