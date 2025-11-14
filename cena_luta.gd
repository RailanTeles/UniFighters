extends Node2D

@onready var p1_start_position = $P1_StartPoint
@onready var p2_start_position = $P2_StartPoint
@onready var icone_p1: TextureRect = $HUD/P1/iconeP1
@onready var icone_p2: TextureRect = $HUD/P2/iconeP2
@onready var tempo_texto: Label = $HUD/TempoContainer/TempoTexto

# --- Referências de Barras ---
@onready var barra_vida_p1: TextureProgressBar = $HUD/P1/infosP1/barra_vida_p1
@onready var barra_vida_p2: TextureProgressBar = $HUD/P2/infosP2/barra_vida_p2
@onready var barra_aura_p1: TextureProgressBar = $HUD/P1/infosP1/AuraP1/barra_aura_p1
@onready var barra_aura_p2: TextureProgressBar = $HUD/P2/infosP2/AuraP2/barra_aura_p2

# --- Referências dos Indicadores de Vitória ---
@onready var v1p1: PanelContainer = $HUD/P1/infosP1/VitoriasP1/V1P1
@onready var v2p1: PanelContainer = $HUD/P1/infosP1/VitoriasP1/V2P1
@onready var v1p2: PanelContainer = $HUD/P2/infosP2/VitoriasP2/V1P2
@onready var v2p2: PanelContainer = $HUD/P2/infosP2/VitoriasP2/V2P2

# --- Variáveis de Lógica do Round ---
var vitorias_p1 = 0
var vitorias_p2 = 0
var round_em_andamento = true
var estilo_vitoria = preload("res://assets/themes/estilo_vitoria.tres") # O arquivo que você criou

# Referências dos jogadores (para podermos resetá-los)
var p1: CharacterBody2D
var p2: CharacterBody2D
var mapa: Node

# (Seu dicionário de ícones)
var jamylle_textura = preload("res://assets/personagens/regulata/icones/RegulataIconeGrande.png")
var icone_personagens = {
	"res://regulata.tscn" : jamylle_textura
	# (Adicione os outros personagens)
}

func _ready():
	# 1. Instanciar o mapa
	mapa = load(DadosdaPartida.caminho_mapa).instantiate()
	mapa.z_index = -10
	add_child(mapa)

	# 2. Instanciar os jogadores (agora salvos nas variáveis da classe)
	p1 = load(DadosdaPartida.caminho_personagem_p1).instantiate()
	p2 = load(DadosdaPartida.caminho_personagem_p2).instantiate()
	
	# 3. Lógica dos Ícones
	if icone_personagens.has(DadosdaPartida.caminho_personagem_p1):
		icone_p1.texture = icone_personagens[DadosdaPartida.caminho_personagem_p1]
	if icone_personagens.has(DadosdaPartida.caminho_personagem_p2):
		icone_p2.texture = icone_personagens[DadosdaPartida.caminho_personagem_p2]
	
	# 4. Definir IDs
	p1.player_id = 1
	p2.player_id = 2
	
	# 5. CONECTAR TODOS OS SINAIS!
	p1.vida_mudou.connect(_on_p1_vida_mudou)
	p2.vida_mudou.connect(_on_p2_vida_mudou)
	p1.aura_mudou.connect(_on_p1_aura_mudou)
	p2.aura_mudou.connect(_on_p2_aura_mudou)
	
	# Conecta os NOVOS sinais de "morte"
	p1.morreu.connect(_on_p1_morreu)
	p2.morreu.connect(_on_p2_morreu)
	
	# 6. Adicionar os jogadores à cena
	add_child(p1)
	add_child(p2)
	
	# 7. Posicionar os jogadores
	p1.global_position = p1_start_position.global_position
	p2.global_position = p2_start_position.global_position
	
	# 8. A "Apresentação"
	p1.set_oponente(p2)
	p2.set_oponente(p1)
	
	# 9. Puxa os valores iniciais
	_on_p1_vida_mudou(p1.vida_atual, p1.vida_max)
	_on_p2_vida_mudou(p2.vida_atual, p2.vida_max)
	_on_p1_aura_mudou(p1.aura_atual, p1.aura_max)
	_on_p2_aura_mudou(p2.aura_atual, p2.aura_max)

# --- Funções de Sinal (Barras de Vida e Aura) ---
# (As 4 funções _on_pX_vida_mudou e _on_pX_aura_mudou continuam iguais)
func _on_p1_vida_mudou(vida_atual_nova, vida_max_nova):
	barra_vida_p1.value = (float(vida_atual_nova) / float(vida_max_nova)) * 100
func _on_p1_aura_mudou(aura_atual_nova, aura_max_nova):
	barra_aura_p1.value = (float(aura_atual_nova) / float(aura_max_nova)) * 100
func _on_p2_vida_mudou(vida_atual_nova, vida_max_nova):
	barra_vida_p2.value = (float(vida_atual_nova) / float(vida_max_nova)) * 100
func _on_p2_aura_mudou(aura_atual_nova, aura_max_nova):
	barra_aura_p2.value = (float(aura_atual_nova) / float(aura_max_nova)) * 100

# --- NOVAS FUNÇÕES: Lógica de Round ---

# Chamada quando o P1 morre (P2 ganha o round)
func _on_p1_morreu():
	# Se o round já acabou, não faz nada (evita bugs)
	if not round_em_andamento:
		return
	
	round_em_andamento = false
	vitorias_p2 += 1 # P2 ganha
	_atualizar_ui_vitoria(2, vitorias_p2) # Atualiza a UI do P2
	
	# Espera 3 segundos e então checa o fim da partida
	await get_tree().create_timer(3.0).timeout
	_checar_fim_da_partida()

# Chamada quando o P2 morre (P1 ganha o round)
func _on_p2_morreu():
	if not round_em_andamento:
		return
	
	round_em_andamento = false
	vitorias_p1 += 1 # P1 ganha
	_atualizar_ui_vitoria(1, vitorias_p1) # Atualiza a UI do P1
	
	await get_tree().create_timer(3.0).timeout
	_checar_fim_da_partida()

# Atualiza os painéis de vitória
func _atualizar_ui_vitoria(player_id: int, vitorias: int):
	if player_id == 1:
		if vitorias == 1:
			v1p1.set("theme_override_styles/panel", estilo_vitoria)
		elif vitorias == 2:
			v2p1.set("theme_override_styles/panel", estilo_vitoria)
	elif player_id == 2:
		if vitorias == 1:
			v1p2.set("theme_override_styles/panel", estilo_vitoria)
		elif vitorias == 2:
			v2p2.set("theme_override_styles/panel", estilo_vitoria)

# Checa se o jogo acabou ou se um novo round deve começar
func _checar_fim_da_partida():
	if vitorias_p1 == 2 or vitorias_p2 == 2:
		# Jogo acabou, volta pro menu
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		# Jogo continua, reseta o round
		_resetar_round()

# Coloca os jogadores de volta no lugar e reseta o estado deles
func _resetar_round():
	p1.resetar_estado()
	p2.resetar_estado()
	mapa.resetar_audio()
	
	p1.global_position = p1_start_position.global_position
	p2.global_position = p2_start_position.global_position
	
	# Opcional: Reseta a velocidade caso eles estivessem em knockback
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	
	# Permite que o próximo round comece
	round_em_andamento = true
