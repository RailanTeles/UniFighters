extends Control

@onready var menu: Panel = $menuOpcoes
@onready var texto: Label = $texto
@onready var animacao_menu: AnimationPlayer = $animacaoMenu

@onready var jogar_botao: Button = $menuOpcoes/VBoxContainer/jogarBotao
@onready var creditos_botao: Button = $menuOpcoes/VBoxContainer/creditosBotao
@onready var sair_botao: Button = $menuOpcoes/VBoxContainer/sairBotao

@onready var menu_musica: AudioStreamPlayer = $menuMusica
@onready var confirmar_musica: AudioStreamPlayer = $confirmarMusica

var _esta_transicionando = false

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
	jogar_botao.release_focus()
	if _esta_transicionando:
		return
	_esta_transicionando = true
	
	menu_musica.stop()
	confirmar_musica.play()
	var tween = create_tween()
	tween.tween_property(jogar_botao, "modulate:a", 0.0, 0.1)
	tween.tween_property(jogar_botao, "modulate:a", 1.0, 0.1)
	tween.tween_property(jogar_botao, "modulate:a", 0.0, 0.1)
	tween.tween_property(jogar_botao, "modulate:a", 1.0, 0.1)
	await tween.finished
	await confirmar_musica.finished
	get_tree().change_scene_to_file("res://selecao.tscn")

func _on_creditos_botao_pressed() -> void:
	if _esta_transicionando:
		return
	_esta_transicionando = true
	get_tree().change_scene_to_file("res://creditos.tscn")


func _on_sair_botao_pressed() -> void:
	if _esta_transicionando:
		return
	_esta_transicionando = true
	get_tree().quit()
