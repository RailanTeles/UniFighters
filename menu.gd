extends Control

@onready var menu: Panel = $menuOpcoes
@onready var texto: Label = $texto
@onready var animacao_menu: AnimationPlayer = $animacaoMenu

func _ready():
	menu.visible = false
	menu.modulate.a = 0

func _input(event):
	if not menu.visible and event.is_pressed() and not event.is_echo():
		menu.visible = true
		texto.visible = false
		animacao_menu.play("fade_in_menu")


func _on_sair_botao_pressed() -> void:
	get_tree().quit()
