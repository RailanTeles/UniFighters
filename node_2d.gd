extends Node2D

@onready var animacao: AnimatedSprite2D = $logoAni

func _ready():
	animacao.play("inicio")
	animacao.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _on_animation_finished():
	if animacao.animation == "inicio":
		animacao.play("idle")
