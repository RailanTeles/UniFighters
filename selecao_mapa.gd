extends Control

# Nós
var p1_foco_atual: Control
var p2_foco_atual: Control

# Sons
@onready var confirmar_som: AudioStreamPlayer = $confirmarSom

# Mapas
@onready var mapa_1: TextureRect = $containerMapas/gridMapas/mapa1
@onready var mapa_2: TextureRect = $containerMapas/gridMapas/mapa2
@onready var mapa_3: TextureRect = $containerMapas/gridMapas2/mapa3

# Cursores
@onready var p1_cursor: TextureRect = $P1_cursor
@onready var p2_cursor: TextureRect = $P2_cursor
@onready var cursor_aleatorio: TextureRect = $CursorAleatorio

# Mapa Selecionado
var mapa_selecionado_p1 = null
var mapa_selecionado_p2 = null

var p1_selecionou = false
var p2_selecionou = false
var esta_mudando_cena = false

func _ready():
	cursor_aleatorio.visible = false
	p1_foco_atual = mapa_1
	p2_foco_atual = mapa_2
	call_deferred("atualizar_posicao_cursores")

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.is_pressed():
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file("res://selecao.tscn")

func _process(delta):
	var foco_mudou = false 
	var proximo_foco_path1 = null
	var proximo_foco_path2 = null
	
	# --------------------- Controles P1 ---------------------
	if Input.is_action_just_pressed("p1_direita"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_RIGHT)
	elif Input.is_action_just_pressed("p1_esquerda"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_LEFT)
	elif Input.is_action_just_pressed("p1_cima"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_TOP)
	elif Input.is_action_just_pressed("p1_baixo"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_BOTTOM)
		
	# Verifica se um "vizinho" foi de fato configurado para aquela direção.
	if proximo_foco_path1 != null and not proximo_foco_path1.is_empty() and not p1_selecionou:
		var proximo_no1 = p1_foco_atual.get_node_or_null(proximo_foco_path1)
		if proximo_no1 is Control:
			p1_foco_atual = proximo_no1
			foco_mudou = true
	
	# Selecionar Mapa
	if Input.is_action_just_pressed("p1_pular") and not p1_selecionou:
		p1_selecionou = true
		_on_p1_selecionar()
	
	# --------------------- Controles P2 ---------------------
	if Input.is_action_just_pressed("p2_direita"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_RIGHT)
	elif Input.is_action_just_pressed("p2_esquerda"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_LEFT)
	elif Input.is_action_just_pressed("p2_cima"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_TOP)
	elif Input.is_action_just_pressed("p2_baixo"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_BOTTOM)
		
	# Verifica se um "vizinho" foi de fato configurado para aquela direção.
	if proximo_foco_path2 != null and not proximo_foco_path2.is_empty() and not p2_selecionou:
		var proximo_no2 = p2_foco_atual.get_node_or_null(proximo_foco_path2)
		if proximo_no2 is Control:
			p2_foco_atual = proximo_no2
			foco_mudou = true
	
	# Selecionar Mapa
	if Input.is_action_just_pressed("p2_pular") and not p2_selecionou:
		p2_selecionou = true
		_on_p2_selecionar()
	
	# Verificar se o foco mudou
	if foco_mudou:
		atualizar_posicao_cursores()

func atualizar_posicao_cursores():
	if p1_foco_atual and not p1_selecionou:
		p1_cursor.size = p1_foco_atual.size
		p1_cursor.global_position = p1_foco_atual.global_position
	if p2_foco_atual and not p2_selecionou:
		p2_cursor.size = p2_foco_atual.size
		p2_cursor.global_position = p2_foco_atual.global_position

func piscar_no_animacao(no) -> Signal: # <-- Mude aqui
	var tween = create_tween()
	tween.tween_property(no, "modulate:a", 0.0, 0.1)
	tween.tween_property(no, "modulate:a", 1.0, 0.1)
	tween.tween_property(no, "modulate:a", 0.0, 0.1)
	tween.tween_property(no, "modulate:a", 1.0, 0.1)
	
	return tween.finished

func _on_p1_selecionar() -> void:
	mapa_selecionado_p1 = p1_foco_atual
	confirmar_som.play()
	piscar_no_animacao(p1_foco_atual) 
	await piscar_no_animacao(p1_cursor)
	await confirmar_som.finished
	seSelecinou()

func _on_p2_selecionar() -> void:
	mapa_selecionado_p2 = p2_foco_atual
	confirmar_som.play()
	piscar_no_animacao(p2_foco_atual)
	await piscar_no_animacao(p2_cursor)
	await confirmar_som.finished
	seSelecinou()

func seSelecinou():
	if esta_mudando_cena:
		return
	if mapa_selecionado_p1 != null and mapa_selecionado_p2 != null:
		if mapa_selecionado_p1 == mapa_selecionado_p2:
			# Aqui provalvemente uma varável global vai receber o mapa
			esta_mudando_cena = true
			get_tree().change_scene_to_file("res://menu.tscn")
		else:
			print("diferentes") # Se forem diferentes, sorteia
