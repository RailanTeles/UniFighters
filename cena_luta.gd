extends Node2D

@onready var p1_start_position = $P1_StartPoint
@onready var p2_start_position = $P2_StartPoint
@onready var icone_p1: TextureRect = $HUD/P1/iconeP1
@onready var icone_p2: TextureRect = $HUD/P2/iconeP2
@onready var barra_vida_p1: ColorRect = $HUD/P1/infosP1/BarraVidaP1/VidaP1

# Salva o tamanho máximo da barra
var max_largura_barra_p1: float

var jamylle_textura = preload("res://assets/personagens/regulata/icones/RegulataIconeGrande.png")

var icone_personagens = {
	"res://regulata.tscn" : jamylle_textura
}

func _ready():
	var mapa = load(DadosdaPartida.caminho_mapa).instantiate()
	mapa.z_index = -10
	add_child(mapa)

	# 2. Instanciar os jogadores
	var p1 = load(DadosdaPartida.caminho_personagem_p1).instantiate()
	var p2 = load(DadosdaPartida.caminho_personagem_p2).instantiate()
	icone_p1.texture = icone_personagens[DadosdaPartida.caminho_personagem_p1]
	icone_p2.texture = icone_personagens[DadosdaPartida.caminho_personagem_p2]
	
	# ---- DEFINIR O ID DE CADA UM ----
	p1.player_id = 1
	p2.player_id = 2
	
	# 3. Salva o tamanho MÁXIMO da barra (o tamanho dela no editor)
	# (Baseado na sua imagem, o tamanho máximo é 370.0)
	max_largura_barra_p1 = barra_vida_p1.size.x
	
	# 4. CONECTAR O SINAL!
	# "Quando o 'p1' gritar 'vida_mudou', chame a minha função '_on_p1_vida_mudou'"
	p1.vida_mudou.connect(_on_p1_vida_mudou)
	# (Você fará o mesmo para o p2 com 'p2.vida_mudou.connect...')
	# ---------------------------------
	
	# 3. Adicionar os jogadores à cena
	add_child(p1)
	add_child(p2)
	
	# 4. Posicionar os jogadores nos pontos de start
	# (Fazemos isso DEPOIS de adicionar à cena para que 'global_position' funcione)
	p1.global_position = p1_start_position.global_position
	p2.global_position = p2_start_position.global_position
	
	# 5. A "Apresentação"
	p1.set_oponente(p2)
	p2.set_oponente(p1)

func _on_p1_vida_mudou(vida_atual_nova, vida_max_nova):
	
	var porcentagem = float(vida_atual_nova) / float(vida_max_nova)
	
	barra_vida_p1.size.x = max_largura_barra_p1 * porcentagem
