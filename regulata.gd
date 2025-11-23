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
const KNOCKBACK_FORTE_X = 1200.0
const KNOCKBACK_FORTE_Y = -100.0 

var player_id = 1 
var oponente: Node2D 

# --- Estatísitcas ---
var vida_max = 1000.0
var vida_atual = 1000.0 
var aura_max = 500.0
var aura_atual = 0.0

signal vida_mudou(vida_atual_nova, vida_max_nova)
signal aura_mudou(aura_atual_nova, aura_max_nova)
signal morreu

# --- Variáveis de Estado para Ataque ---
var pode_agir = true
var contador_combo = 0
var dano_do_golpe = 0
var golpe_e_forte = false 
var esta_morto = false
var esta_em_hitstun = false

func _ready():
	emit_signal("vida_mudou", vida_atual, vida_max)

# -----------------------------------------------------------------
# _physics_process: (Continua igual)
# -----------------------------------------------------------------
# (Todo o seu código _physics_process está perfeito)
func _physics_process(delta):
	if esta_morto:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0
		move_and_slide()
		return 
	
	if not is_on_floor():
		velocity.y += gravity * delta

	var input_pular = "p" + str(player_id) + "_pular"
	if Input.is_action_just_pressed(input_pular) and is_on_floor() and pode_agir:
		velocity.y = JUMP_VELOCITY
		contador_combo = 0
		timer_combo.stop()

	var input_agachar = "p" + str(player_id) + "_baixo"
	var is_crouching = Input.is_action_pressed(input_agachar) and is_on_floor()
	var input_esquerda = "p" + str(player_id) + "_esquerda"
	var input_direita = "p" + str(player_id) + "_direita"
	var direcao_input = Input.get_axis(input_esquerda, input_direita)
	
	if not pode_agir:
		velocity.x = lerp(velocity.x, 0.0, 0.1) 
	elif direcao_input == 0 or is_crouching:
		velocity.x = 0
	elif direcao_input == direcao_olhando:
		velocity.x = direcao_input * velocidade
	else: 
		velocity.x = direcao_input * (velocidade * 0.7)
	
	move_and_slide()

# -----------------------------------------------------------------
# _process: (Continua igual)
# -----------------------------------------------------------------
# (Todo o seu código _process está perfeito)
func _process(delta):
	if oponente == null:
		return 

	if not esta_morto:
		if oponente.global_position.x > global_position.x:
			direcao_olhando = 1
			sprite.flip_h = false
		else:
			direcao_olhando = -1
			sprite.flip_h = true

	if esta_morto:
		animation_player.play("receber_dano")
		return

	if not pode_agir:
		return

	var input_agachar = "p" + str(player_id) + "_baixo"
	var is_crouching = Input.is_action_pressed(input_agachar)
	var input_socar_fraco = "p" + str(player_id) + "_socoFraco"
	var apertou_soco = Input.is_action_just_pressed(input_socar_fraco)
	
	if apertou_soco:
		pode_agir = false # Trava o personagem
		
		if contador_combo > 0 and timer_combo.time_left > 0:
			if contador_combo == 1:
				animation_player.play("golpe_fraco2")
				contador_combo = 2
			elif contador_combo == 2:
				animation_player.play("golpe_fraco3")
				contador_combo = 0 
		else:
			if not is_on_floor():
				animation_player.play("golpe_fraco_ar")
				contador_combo = 0 
			elif is_crouching:
				animation_player.play("golpe_fraco_agachado")
				contador_combo = 0 
			else:
				animation_player.play("golpe_fraco1")
				contador_combo = 1
		
		timer_combo.stop()

	elif is_on_floor():
		if is_crouching:
			sprite.play("agachar")
			contador_combo = 0 
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
				contador_combo = 0 
				timer_combo.stop()
	
	elif not is_on_floor():
		if velocity.y < 0:
			sprite.play("pular")
		else:
			sprite.play("queda")

# -----------------------------------------------------------------
# Função set_oponente (Continua igual)
# -----------------------------------------------------------------
func set_oponente(alvo: Node2D):
	oponente = alvo

# -----------------------------------------------------------------
# Função levar_dano (Corrigida)
# -----------------------------------------------------------------
func levar_dano(quantidade: int, e_forte: bool, direcao_knockback: int):
	# Se já estamos mortos OU JÁ ESTAMOS EM HITSTUN, não faça nada
	if esta_morto or esta_em_hitstun:
		return

	# Trava o personagem
	pode_agir = false
	esta_em_hitstun = true 
	
	# Reseta o nosso próprio combo
	contador_combo = 0
	timer_combo.stop()
	
	# Aplica o dano
	vida_atual -= quantidade
	vida_atual = max(0, vida_atual) # Garante que a vida não fique negativa
	emit_signal("vida_mudou", vida_atual, vida_max)
	
	# --- Lógica de Morte ---
	if vida_atual <= 0:
		esta_morto = true
		animation_player.play("receber_dano")
		emit_signal("morreu")
		return 

	# --- Lógica de Animação e Knockback (se NÃO estiver morto) ---
	if e_forte:
		animation_player.play("receber_dano") 
		velocity.x = KNOCKBACK_FORTE_X * direcao_knockback
		velocity.y = KNOCKBACK_FORTE_Y
	else:
		animation_player.play("receber_dano")
		velocity.x = KNOCKBACK_FRACO * direcao_knockback

func ganhar_aura(quantidade):
	aura_atual += quantidade
	aura_atual = min(aura_atual, aura_max)
	emit_signal("aura_mudou", aura_atual, aura_max)

# -----------------------------------------------------------------
# Funções de Sinal (Corrigidas)
# -----------------------------------------------------------------
func _on_timer_combo_timeout() -> void:
	contador_combo = 0

func _on_animation_player_animation_finished(anim_name: StringName):
	# Se o personagem está morto, ele NÃO PODE ser destravado
	if esta_morto:
		animation_player.play("receber_dano") 
		return

	# Destrava o personagem
	pode_agir = true
	
	# Se a animação que terminou foi a de levar dano,
	# reseta a trava de hitstun
	if anim_name == "receber_dano":
		esta_em_hitstun = false
	
	# (Sua lógica de combo continua igual)
	var ataques_combo = ["golpe_fraco1", "golpe_fraco2"]
	if anim_name in ataques_combo:
		timer_combo.start()
	
	var ataques_reset = ["golpe_fraco3", "golpe_fraco_ar", "golpe_fraco_agachado"]
	if anim_name in ataques_reset:
		contador_combo = 0

# -----------------------------------------------------------------
# _on_hurtbox_area_entered (Corrigido)
# -----------------------------------------------------------------
func _on_hurt_box_area_entered(area: Area2D) -> void:
	# A trava 'if not pode_agir' foi removida daqui.
	# 1. Verifica se a hitbox que entrou é a NOSSA PRÓPRIA.
	if area.get_owner() == self:
		return # Se for, ignore o golpe e saia da função.
		
	var oponente_script = area.get_owner()
	var dano_recebido = oponente_script.dano_do_golpe
	var e_forte = oponente_script.golpe_e_forte
	var direcao_knockback = sign(global_position.x - oponente_script.global_position.x)
	
	levar_dano(dano_recebido, e_forte, direcao_knockback)

# -----------------------------------------------------------------
# Ativa o Hitbox (Continua igual)
# -----------------------------------------------------------------
func _ativar_hitbox(dano: int, pos_x: float, pos_y: float, tam_x: float, tam_y: float, forte: bool = false):
	dano_do_golpe = dano
	golpe_e_forte = forte 
	hitbox_shape.position = Vector2(pos_x * direcao_olhando, pos_y)
	(hitbox_shape.shape as RectangleShape2D).size = Vector2(tam_x, tam_y)
	hitbox.monitorable = true 
	hitbox_shape.disabled = false

# -----------------------------------------------------------------
# Desativa o Hitbox (Continua igual)
# -----------------------------------------------------------------
func _desativar_hitbox():
	hitbox.monitorable = false
	hitbox_shape.disabled = true
	dano_do_golpe = 0 
	golpe_e_forte = false

# -----------------------------------------------------------------
# NOVA FUNÇÃO: Reseta o estado do personagem para um novo round
# -----------------------------------------------------------------
func resetar_estado():
	vida_atual = vida_max
	aura_atual = 0.0
	esta_morto = false
	pode_agir = true
	esta_em_hitstun = false
	contador_combo = 0
	velocity = Vector2.ZERO
	
	# Avisa a UI para resetar as barras
	emit_signal("vida_mudou", vida_atual, vida_max)
	emit_signal("aura_mudou", aura_atual, aura_max)
	
	# Garante que ele comece na animação correta
	sprite.play("idle")
