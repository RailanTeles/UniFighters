extends Control

@onready var menu: Panel = $menuOpcoes
@onready var texto: Label = $texto
@onready var animacao_menu: AnimationPlayer = $animacaoMenu

@onready var jogar_botao: Button = $menuOpcoes/VBoxContainer/jogarBotao
@onready var creditos_botao: Button = $menuOpcoes/VBoxContainer/creditosBotao
@onready var sair_botao: Button = $menuOpcoes/VBoxContainer/sairBotao

func _ready():
	menu.visible = false
	menu.modulate.a = 0
	animacao_menu.animation_finished.connect(_on_animation_finished)

func _input(event):
	if not menu.visible and event.is_pressed() and not event.is_echo():
		menu.visible = true
		texto.visible = false
		animacao_menu.play("fade_in_menu")

func _on_animation_finished(anim_name):
	if anim_name == "fade_in_menu":
		jogar_botao.grab_focus()

func _on_jogar_botao_pressed() -> void:
	pass # Replace with function body.

func _on_creditos_botao_pressed() -> void:
	get_tree().change_scene_to_file("res://creditos.tscn")


func _on_sair_botao_pressed() -> void:
	get_tree().quit()
