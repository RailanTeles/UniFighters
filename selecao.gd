extends Control

#
var _esta_carregando = false

# Texto
@onready var texto: Label = $texto
var texto_normal = "Escolha os personagens e clique em “Começar”
					Ou pressione “Esc” para retornar"
var texto_erro = "Todos os jogadores precisam ter escolhido um personagem"

# Armazena o nó que o cursor está apontando
var p1_foco_atual: Control
var p2_foco_atual: Control

# Botôes
@onready var char_1: TextureButton = $selecao/GridContainer/Char1
@onready var char_2: TextureButton = $selecao/GridContainer/Char2
@onready var char_3: TextureButton = $selecao/GridContainer/Char3
@onready var char_4: TextureButton = $selecao/GridContainer/Char4

@onready var comecar_button: TextureButton = $botoes/comecarButton
@onready var erro_som: AudioStreamPlayer = $botoes/comecarButton/erroSom
@onready var confirmar_som: AudioStreamPlayer = $botoes/comecarButton/confirmarSom
@onready var erro_timer: Timer = $botoes/comecarButton/erroTimer
@onready var animacao: AnimatedSprite2D = $botoes/comecarButton/animacao


# Cursores
@onready var p1_cursor: TextureRect = $P1_cursor
@onready var p2_cursor: TextureRect = $P2_cursor

# Banners
@onready var banner_p1_display: TextureRect = $selecao/BannerP1_Display
@onready var banner_p2_display: TextureRect = $selecao/BannerP2_Display

# Armazena o personagem que foi confirmado
var p1_personagem_selecionado = null
var p2_personagem_selecionado = null

# Pre render das imagens
var banner_padrao_p1 = preload("res://assets/selecaoPersonagem/padraoP1.png")
var banner_padrao_p2 = preload("res://assets/selecaoPersonagem/padraoP2.png")
var banner_regulata_p1 = preload("res://assets/personagens/regulata/icones/RegulataP1.png")
var banner_regulata_p2 = preload("res://assets/personagens/regulata/icones/RegulataP2.png")
var banner_cabomante_p1 = preload("res://assets/personagens/cabomante/icone/CabomanteP1.png")
var banner_cabomante_p2 = preload("res://assets/personagens/cabomante/icone/CabomanteP2.png")
var banner_imperatech_p1 = preload("res://assets/personagens/imperatech/icone/ImperatechP1.png")
var banner_imperatech_p2 = preload("res://assets/personagens/imperatech/icone/ImperatechP2.png")
var banner_sprintora_p1 = preload("res://assets/personagens/sprintora/icones/SprintoraP1.png")
var banner_sprintora_p2 = preload("res://assets/personagens/sprintora/icones/SprintoraP2.png")

var dados_banners_p1 = {
	"Regulata" : banner_regulata_p1,
	"Cabomante" : banner_cabomante_p1,
	"Imperatech" : banner_imperatech_p1,
	"Sprintora" : banner_sprintora_p1
}

var dados_banners_p2 = {
	"Regulata" : banner_regulata_p2,
	"Cabomante" : banner_cabomante_p2,
	"Imperatech" : banner_imperatech_p2,
	"Sprintora" : banner_sprintora_p2
}

var dados_caracteristicas = {}

func _ready():
	dados_caracteristicas = {
		char_1 : "Regulata",
		char_2 : "Cabomante",
		char_3 : "Imperatech",
		char_4 : "Sprintora"
	}
	banner_p1_display.texture = banner_padrao_p1
	banner_p2_display.texture = banner_padrao_p2
	p1_foco_atual = char_1
	p2_foco_atual = char_2
	call_deferred("atualizar_posicao_cursores")

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.is_pressed():
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file("res://menu.tscn")

func _process(delta):
	if _esta_carregando:
		return
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
	if proximo_foco_path1 != null and not proximo_foco_path1.is_empty():
		var proximo_no1 = p1_foco_atual.get_node_or_null(proximo_foco_path1)
		if proximo_no1 is Control:
			p1_foco_atual = proximo_no1
			foco_mudou = true
	
	# Botão de selecionar o personagem ou começar
	if Input.is_action_just_pressed("p1_pular"):
		if p1_foco_atual == comecar_button:
			_on_comecar_button_pressed()
		else:
			p1_personagem_selecionado = dados_caracteristicas[p1_foco_atual]
			atualizar_banner_p1(p1_personagem_selecionado)
	
	# Controles P2 ------------------------
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
	
		# Botão de selecionar o personagem
	if Input.is_action_just_pressed("p2_pular"):
		if p2_foco_atual == comecar_button:
			_on_comecar_button_pressed()
		else:
			p2_personagem_selecionado = dados_caracteristicas[p2_foco_atual]
			atualizar_banner_p2(p2_personagem_selecionado)

	# ----- ATUALIZAÇÃO VISUAL -----
	if foco_mudou:
		atualizar_posicao_cursores()

func _on_comecar_button_pressed() -> void:
	if comecar_button.disabled:
		return
	if p1_personagem_selecionado != null and p2_personagem_selecionado != null:
		_esta_carregando = true
		p1_cursor.visible = false
		p2_cursor.visible = false
		comecar_button.disabled = true
		confirmar_som.play()
		for i in 3:
			animacao.play("pressionado")
			await animacao.animation_finished
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		texto.text = texto_erro
		texto.self_modulate = Color(1,0,0)
		erro_som.play();
		erro_timer.start()

func atualizar_posicao_cursores():
	if p1_foco_atual:
		p1_cursor.size = p1_foco_atual.size
		p1_cursor.global_position = p1_foco_atual.global_position
	if p2_foco_atual:
		p2_cursor.size = p2_foco_atual.size
		p2_cursor.global_position = p2_foco_atual.global_position

func atualizar_banner_p1(nome_personagem):
	if dados_banners_p1.has(nome_personagem):
		banner_p1_display.texture = dados_banners_p1[nome_personagem]

func atualizar_banner_p2(nome_personagem):
	if dados_banners_p2.has(nome_personagem):
		banner_p2_display.texture = dados_banners_p2[nome_personagem]

func _on_erro_timer_timeout() -> void:
	texto.text = texto_normal
	texto.self_modulate = Color(1,1,1)
