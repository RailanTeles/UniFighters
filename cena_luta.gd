extends Node2D

@onready var p1_start_position = $P1_StartPoint
@onready var p2_start_position = $P2_StartPoint
@onready var icone_p1: TextureRect = $HUD/P1/iconeP1
@onready var icone_p2: TextureRect = $HUD/P2/iconeP2

# ---- Tempo -----
@onready var tempo_texto: Label = $HUD/TempoContainer/TempoTexto
@onready var timer_round: Timer = $TimerRound
var tempo_atual = 80

# ---- Animação -----
@onready var contagem_sprite: AnimatedSprite2D = $ContagemSprite
@onready var contagem_audio: AudioStreamPlayer = $contagemAudio

# ---- Menu de Pausa ----
@onready var pausa: Panel = $pausa
@onready var controles: TextureRect = $controles
@onready var retornar_botao: Button = $pausa/pausaOpcoes/VBoxContainer/retornarBotao
@onready var controles_botao: Button = $pausa/pausaOpcoes/VBoxContainer/controlesBotao
@onready var sair_botao: Button = $pausa/pausaOpcoes/VBoxContainer/sairBotao
var _esta_pausado = false
var _uid_controle = false

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
var estilo_vitoria = preload("res://assets/themes/estilo_vitoria.tres")

# Referências dos jogadores
var p1: CharacterBody2D
var p2: CharacterBody2D
var mapa: Node

var jamylle_textura = preload("res://assets/personagens/regulata/icones/RegulataIconeGrande.png")
var icone_personagens = {
	"res://regulata.tscn" : jamylle_textura
}

func _ready():
	tempo_texto.text = str(tempo_atual)
	
	# Instanciar mapa
	mapa = load(DadosdaPartida.caminho_mapa).instantiate()
	mapa.z_index = -10
	add_child(mapa)

	# Instanciar jogadores
	p1 = load(DadosdaPartida.caminho_personagem_p1).instantiate()
	p2 = load(DadosdaPartida.caminho_personagem_p2).instantiate()
	
	if icone_personagens.has(DadosdaPartida.caminho_personagem_p1):
		icone_p1.texture = icone_personagens[DadosdaPartida.caminho_personagem_p1]
	if icone_personagens.has(DadosdaPartida.caminho_personagem_p2):
		icone_p2.texture = icone_personagens[DadosdaPartida.caminho_personagem_p2]
	
	p1.player_id = 1
	p2.player_id = 2
	
	# Conexões
	p1.vida_mudou.connect(_on_p1_vida_mudou)
	p2.vida_mudou.connect(_on_p2_vida_mudou)
	p1.aura_mudou.connect(_on_p1_aura_mudou)
	p2.aura_mudou.connect(_on_p2_aura_mudou)
	p1.morreu.connect(_on_p1_morreu)
	p2.morreu.connect(_on_p2_morreu)
	
	add_child(p1)
	add_child(p2)
	
	p1.global_position = p1_start_position.global_position
	p2.global_position = p2_start_position.global_position
	
	p1.set_oponente(p2)
	p2.set_oponente(p1)
	
	_on_p1_vida_mudou(p1.vida_atual, p1.vida_max)
	_on_p2_vida_mudou(p2.vida_atual, p2.vida_max)
	_on_p1_aura_mudou(p1.aura_atual, p1.aura_max)
	_on_p2_aura_mudou(p2.aura_atual, p2.aura_max)
	
	_resetar_round()

func _input(event):
	if event is InputEventKey and not contagem_sprite.visible and round_em_andamento:
		if event.keycode == KEY_ESCAPE and event.is_pressed() and not event.is_echo():
			if not _esta_pausado and not _uid_controle:
				timer_round.paused = true
				_travar_personagens(true)
				_esta_pausado = true
				pausa.visible = true
				pausa.z_index = 100
				retornar_botao.grab_focus()
			elif _esta_pausado and _uid_controle:
				controles.visible = false
				_uid_controle = false
				retornar_botao.grab_focus()
			else:
				timer_round.paused = false
				pausa.visible = false
				_esta_pausado = false
				_travar_personagens(false)

# Função auxiliar para travar/destravar movimento e input dos jogadores
func _travar_personagens(travar: bool):
	var ativo = !travar
	p1.set_physics_process(ativo)
	p2.set_physics_process(ativo)
	p1.set_process(ativo)
	p2.set_process(ativo)

# --- Funções de Sinal (UI) ---
func _on_p1_vida_mudou(vida_atual_nova, vida_max_nova):
	barra_vida_p1.value = (float(vida_atual_nova) / float(vida_max_nova)) * 100
func _on_p1_aura_mudou(aura_atual_nova, aura_max_nova):
	barra_aura_p1.value = (float(aura_atual_nova) / float(aura_max_nova)) * 100
func _on_p2_vida_mudou(vida_atual_nova, vida_max_nova):
	barra_vida_p2.value = (float(vida_atual_nova) / float(vida_max_nova)) * 100
func _on_p2_aura_mudou(aura_atual_nova, aura_max_nova):
	barra_aura_p2.value = (float(aura_atual_nova) / float(aura_max_nova)) * 100

# --- Lógica de Round ---
func _on_p1_morreu():
	if not round_em_andamento: return
	
	round_em_andamento = false
	vitorias_p2 += 1
	_atualizar_ui_vitoria(2, vitorias_p2)
	
	await get_tree().create_timer(3.0).timeout
	_checar_fim_da_partida()

func _on_p2_morreu():
	if not round_em_andamento: return
	
	round_em_andamento = false
	vitorias_p1 += 1
	_atualizar_ui_vitoria(1, vitorias_p1)
	
	await get_tree().create_timer(3.0).timeout
	_checar_fim_da_partida()

func _atualizar_ui_vitoria(player_id: int, vitorias: int):
	if player_id == 1:
		if vitorias == 1: v1p1.set("theme_override_styles/panel", estilo_vitoria)
		elif vitorias == 2: v2p1.set("theme_override_styles/panel", estilo_vitoria)
	elif player_id == 2:
		if vitorias == 1: v1p2.set("theme_override_styles/panel", estilo_vitoria)
		elif vitorias == 2: v2p2.set("theme_override_styles/panel", estilo_vitoria)

func _checar_fim_da_partida():
	if vitorias_p1 == 2 or vitorias_p2 == 2:
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		_resetar_round()

func _resetar_round():
	p1.resetar_estado()
	p2.resetar_estado()
	mapa.resetar_audio()
	
	_travar_personagens(true)
	
	p1.global_position = p1_start_position.global_position
	p2.global_position = p2_start_position.global_position
	
	p1.sprite.flip_h = false
	p1.direcao_olhando = 1
	p2.sprite.flip_h = true
	p2.direcao_olhando = -1
	
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	
	tempo_atual = 80
	tempo_texto.text = str(tempo_atual)
	
	_iniciar_contagem()

func _on_timer_round_timeout() -> void:
	if _esta_pausado: return
	
	if round_em_andamento and tempo_atual > 0:
		tempo_atual -= 1
		tempo_texto.text = str(tempo_atual)
		if tempo_atual == 0:
			_on_tempo_acabou()

func _on_tempo_acabou():
	timer_round.stop()
	if p1.vida_atual > p2.vida_atual:
		_on_p2_morreu()
	elif p2.vida_atual > p1.vida_atual:
		_on_p1_morreu()
	else:
		_resetar_round()

func _iniciar_contagem():
	contagem_sprite.visible = true
	
	contagem_sprite.play("3")
	contagem_audio.play()
	await contagem_sprite.animation_finished
	
	contagem_sprite.play("2")
	await contagem_sprite.animation_finished
	
	contagem_sprite.play("1")
	await contagem_sprite.animation_finished
	
	contagem_sprite.play("go")
	
	_travar_personagens(false)
	timer_round.start()
	round_em_andamento = true
	
	await contagem_sprite.animation_finished
	contagem_sprite.visible = false

func _on_retornar_botao_pressed() -> void:
	pausa.visible = false
	_esta_pausado = false
	timer_round.paused = false
	_travar_personagens(false)

func _on_controles_botao_pressed() -> void:
	controles.visible = true
	controles.z_index = 120
	_uid_controle = true
	controles_botao.release_focus()

func _on_sair_botao_pressed() -> void:
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file("res://selecao.tscn")
