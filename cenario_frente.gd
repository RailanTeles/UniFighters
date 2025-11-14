extends AnimatedSprite2D
@onready var cenario_audio: AudioStreamPlayer = $cenario_audio

func resetar_audio():
	cenario_audio.stop()
	cenario_audio.play()
