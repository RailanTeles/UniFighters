extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $SpriteAnimado
@onready var timer_combo: Timer = $TimerCombo
@onready var hitbox: Area2D = $HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/HitBoxShape
@onready var hurtbox: Area2D = $HurtBox
@onready var hurtbox_shape: CollisionShape2D = $HurtBox/HurtBoxShape
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Variáveis de Movimento, Pulo, Jogador, Oponente
var velocidade = 250.0
var direcao_olhando = 1
const JUMP_VELOCITY = -600.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Novas Constantes de Knockback ---
const KNOCKBACK_FRACO = 80.0
const KNOCKBACK_FORTE_X = 120.0
const KNOCKBACK_FORTE_Y = -100.0 # Joga o oponente um pouco para cima

var player_id = 1 
var oponente: Node2D 

# --- Estatísitcas ---
var vida_max = 1000.0
var vida_atual = 1000.0 
var aura_max = 1000.0
var aura_atual = 0.0

signal vida_mudou(vida_atual_nova, vida_max_nova)

# --- Variáveis de Estado para Ataque ---
var pode_agir = true      # 'false' durante a animação (trava de movimento)
var contador_combo = 0
var dano_do_golpe = 0
var golpe_e_forte = false 

func _ready():
	# Emite o sinal no início para a UI (barra de vida) começar cheia
	emit_signal("vida_mudou", vida_atual, vida_max)

# -----------------------------------------------------------------
# _physics_process: Cuida de toda a física
# -----------------------------------------------------------------
func _physics_process(delta):
	# --- 1. GRAVIDADE ---
	# Aplica gravidade se não estiver no chão
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- 2. PULO ---
	var input_pular = "p" + str(player_id) + "_pular"
	# Só pode pular se puder agir (não estar atacando ou levando dano)
	if Input.is_action_just_pressed(input_pular) and is_on_floor() and pode_agir:
		velocity.y = JUMP_VELOCITY
		contador_combo = 0 # Pular quebra o combo
		timer_combo.stop() # Pular quebra o combo

	# --- 3. MOVIMENTO HORIZONTAL ---
	var input_agachar = "p" + str(player_id) + "_baixo"
	var is_crouching = Input.is_action_pressed(input_agachar) and is_on_floor()
	var input_esquerda = "p" + str(player_id) + "_esquerda"
	var input_direita = "p" + str(player_id) + "_direita"
	var direcao_input = Input.get_axis(input_esquerda, input_direita)
	
	# Não pode andar se estiver agachado ou não puder agir
	if direcao_input == 0 or is_crouching or not pode_agir:
		# Se não puder agir (ex: levando knockback), deixa a física (velocidade) rolar
		if pode_agir:
			velocity.x = 0
	elif direcao_input == direcao_olhando:
		velocity.x = direcao_input * velocidade
	else: 
		velocity.x = direcao_input * (velocidade * 0.7) # Andar para trás é mais lento
	
	# Aplica o movimento final
	move_and_slide()

# -----------------------------------------------------------------
# _process: Cuida das animações e lógica de virar
# -----------------------------------------------------------------
func _process(delta):
	# Se o oponente não foi definido, não faz nada
	if oponente == null:
		return 

	# --- LÓGICA DE VIRAR (FLIP) ---
	# Sempre vira para encarar o oponente
	if oponente.global_position.x > global_position.x:
		direcao_olhando = 1
		sprite.flip_h = false
	else:
		direcao_olhando = -1
		sprite.flip_h = true

	# --- LÓGICA DE ANIMAÇÃO ---

	# Se não pudermos agir (ex: no meio de um golpe), não fazemos nada
	if not pode_agir:
		return

	# Pega os inputs do jogador
	var input_agachar = "p" + str(player_id) + "_baixo"
	var is_crouching = Input.is_action_pressed(input_agachar)
	var input_socar_fraco = "p" + str(player_id) + "_socoFraco"
	var apertou_soco = Input.is_action_just_pressed(input_socar_fraco)
	
	# --- LÓGICA DE ATAQUE (Prioridade Máxima) ---
	if apertou_soco:
		pode_agir = false # Trava o personagem
		
		# Verifica se estamos em uma janela de combo
		if contador_combo > 0 and timer_combo.time_left > 0:
			# Se sim, continua o combo
			if contador_combo == 1:
				animation_player.play("golpe_fraco2")
				contador_combo = 2
			elif contador_combo == 2:
				animation_player.play("golpe_fraco3")
				contador_combo = 0 # Fim do combo
		else:
			# Se não, começa um combo novo
			
			# Checa se está no ar ou agachado
			if not is_on_floor():
				animation_player.play("golpe_fraco_ar")
				contador_combo = 0 # Ataques no ar não dão combo
			elif is_crouching:
				animation_player.play("golpe_fraco_agachado")
				contador_combo = 0 # Ataques agachados não dão combo
			else:
				# Começa o combo no chão
				animation_player.play("golpe_fraco1")
				contador_combo = 1
		
		# Para qualquer timer de combo que estivesse rodando
		timer_combo.stop()

	# --- LÓGICA DE MOVIMENTO (Se não estiver atacando) ---
	elif is_on_floor():
		if is_crouching:
			sprite.play("agachar")
			contador_combo = 0 # Agachar quebra o combo
			timer_combo.stop()
		else:
			var direcao_input = Input.get_axis("p" + str(player_id) + "_esquerda", "p" + str(player_id) + "_direita")
			if direcao_input == 0:
				sprite.play("idle")
			else:
				if direcao_input == direcao_olhando:
					sprite.play("andar_frente")
				else: 
					sprite.play("andar_tras")
				contador_combo = 0 # Andar quebra o combo
				timer_combo.stop()
	
	# --- LÓGICA DE ANIMAÇÃO NO AR (Se não estiver atacando) ---
	elif not is_on_floor():
		if velocity.y < 0:
			sprite.play("pular")
		else:
			sprite.play("queda")

# -----------------------------------------------------------------
# Função set_oponente (Chamada pela cena_luta)
# -----------------------------------------------------------------
func set_oponente(alvo: Node2D):
	# Define quem é o nosso alvo
	oponente = alvo

# -----------------------------------------------------------------
# Função levar_dano (Atualizada)
# -----------------------------------------------------------------
func levar_dano(quantidade: int, e_forte: bool, direcao_knockback: int):
	# Se já estamos levando dano, não faça nada
	if not pode_agir:
		return

	# Trava o personagem
	pode_agir = false
	
	# Reseta o nosso próprio combo (se estávamos no meio de um)
	contador_combo = 0
	timer_combo.stop()
	
	# Aplica o dano
	vida_atual -= quantidade
	vida_atual = max(0, vida_atual)
	emit_signal("vida_mudou", vida_atual, vida_max) # Avisa a UI
	
	# --- Lógica de Animação e Knockback ---
	if e_forte:
		# Toca a animação de "caído" (você precisa criar ela no AnimationPlayer)
		animation_player.play("caido")
		# Aplica o knockback forte (para trás e para cima)
		velocity.x = KNOCKBACK_FORTE_X * direcao_knockback
		velocity.y = KNOCKBACK_FORTE_Y
	else:
		# Toca a animação de "receber_dano"
		animation_player.play("receber_dano")
		# Aplica o knockback fraco (só para trás)
		velocity.x = KNOCKBACK_FRACO * direcao_knockback


# -----------------------------------------------------------------
# Funções de Sinal (Conectadas pelo Editor)
# -----------------------------------------------------------------
func _on_timer_combo_timeout() -> void:
	# Chamada quando os 2s da janela de combo terminam
	contador_combo = 0

func _on_animation_player_animation_finished(anim_name: StringName):
	# Chamada quando uma animação do AnimationPlayer termina
	
	# Destrava o personagem
	pode_agir = true
	
	# Lista de animações que ABREM uma janela de combo
	var ataques_combo = ["golpe_fraco1", "golpe_fraco2"]
	if anim_name in ataques_combo:
		# Inicia o timer da "janela" para o próximo golpe
		timer_combo.start()
	
	# Lista de animações que RESETAM o combo
	var ataques_reset = ["golpe_fraco3", "golpe_fraco_ar", "golpe_fraco_agachado"]
	if anim_name in ataques_reset:
		contador_combo = 0

# -----------------------------------------------------------------
# _on_hurtbox_area_entered
# -----------------------------------------------------------------
func _on_hurt_box_area_entered(area: Area2D) -> void:
	# Esta função é chamada quando o Hitbox do oponente (area) entra no nosso Hurtbox
	
	# 1. Pega o script do oponente (que é o "dono" do hitbox)
	var oponente_script = area.get_owner()
	
	# 2. Pega os dados do golpe dele
	var dano_recebido = oponente_script.dano_do_golpe
	var e_forte = oponente_script.golpe_e_forte
	
	# 3. Calcula a direção do knockback (para onde vamos ser empurrados)
	# (sign() retorna 1 se for positivo, -1 se for negativo)
	var direcao_knockback = sign(global_position.x - oponente_script.global_position.x)
	
	# 4. Chama nossa função levar_dano com todas as informações
	levar_dano(dano_recebido, e_forte, direcao_knockback)

# -----------------------------------------------------------------
# Ativa o Hitbox (Chamada pela Faixa de Função da Animação)
# -----------------------------------------------------------------
func _ativar_hitbox(dano: int, pos_x: float, pos_y: float, tam_x: float, tam_y: float, forte: bool = false):
	# Armazena as propriedades do golpe atual
	dano_do_golpe = dano
	golpe_e_forte = forte # Armazena se é um golpe forte
	
	# Ajusta a posição da hitbox baseado na direção que estamos olhando
	hitbox_shape.position = Vector2(pos_x * direcao_olhando, pos_y)
	
	# Ajusta o tamanho do shape
	(hitbox_shape.shape as RectangleShape2D).size = Vector2(tam_x, tam_y)
	
	# Ativa a detecção
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	print("Hitbox ATIVADO - Dano: ", dano_do_golpe, " | Forte: ", golpe_e_forte)

# -----------------------------------------------------------------
# Desativa o Hitbox (Chamada pela Faixa de Função da Animação)
# -----------------------------------------------------------------
func _desativar_hitbox():
	# Desativa a detecção
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	
	# Zera as propriedades do golpe
	dano_do_golpe = 0 
	golpe_e_forte = false
	print("Hitbox DESATIVADO")
