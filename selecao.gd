extends Control

# Armazena o nó que o cursor está apontando
var p1_foco_atual: Control
var p2_foco_atual: Control

# Armazena o personagem que foi confirmado
var p1_personagem_selecionado = null
var p2_personagem_selecionado = null

# Botôes
@onready var char_1: TextureButton = $selecao/GridContainer/Char1
@onready var char_2: TextureButton = $selecao/GridContainer/Char2
@onready var char_3: TextureButton = $selecao/GridContainer/Char3
@onready var char_4: TextureButton = $selecao/GridContainer/Char4
@onready var comecar_button: TextureButton = $botoes/comecarButton

# Cursores
@onready var p1_cursor: TextureRect = $P1_cursor
@onready var p2_cursor: TextureRect = $P2_cursor


func _ready():
	p1_foco_atual = char_1
	p2_foco_atual = char_2
	call_deferred("atualizar_posicao_cursores")

func _process(delta):
	var foco_mudou = false 
	var proximo_foco_path1 = null
	var proximo_foco_path2 = null

	# Controles P1
	if Input.is_action_just_pressed("p1_direita"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_RIGHT)
	elif Input.is_action_just_pressed("p1_esquerda"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_LEFT)
	elif Input.is_action_just_pressed("p1_cima"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_TOP)
	elif Input.is_action_just_pressed("p1_baixo"):
		proximo_foco_path1 = p1_foco_atual.get_focus_neighbor(SIDE_BOTTOM)

	# Verifica se um "vizinho" foi de fato configurado para aquela direção.
	if proximo_foco_path1 != null and not proximo_foco_path1.is_empty():
		var proximo_no1 = p1_foco_atual.get_node_or_null(proximo_foco_path1)
		if proximo_no1 is Control:
			p1_foco_atual = proximo_no1
			foco_mudou = true
	
	# Controles P2
	if Input.is_action_just_pressed("p2_direita"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_RIGHT)
	elif Input.is_action_just_pressed("p2_esquerda"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_LEFT)
	elif Input.is_action_just_pressed("p2_cima"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_TOP)
	elif Input.is_action_just_pressed("p2_baixo"):
		proximo_foco_path2 = p2_foco_atual.get_focus_neighbor(SIDE_BOTTOM)

	# Verifica se um "vizinho" foi de fato configurado para aquela direção.
	if proximo_foco_path2 != null and not proximo_foco_path2.is_empty():
		var proximo_no2 = p2_foco_atual.get_node_or_null(proximo_foco_path2)
		if proximo_no2 is Control:
			p2_foco_atual = proximo_no2
			foco_mudou = true
		
	# ----- ATUALIZAÇÃO VISUAL -----
	if foco_mudou:
		atualizar_posicao_cursores()

func atualizar_posicao_cursores():
	if p1_foco_atual:
		p1_cursor.size = p1_foco_atual.size
		p1_cursor.global_position = p1_foco_atual.global_position
	if p2_foco_atual:
		p2_cursor.size = p2_foco_atual.size
		p2_cursor.global_position = p2_foco_atual.global_position
