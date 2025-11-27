extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $SpriteAnimado
@onready var timer_combo: Timer = $TimerCombo
@onready var hitbox: Area2D = $HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/HitBoxShape
@onready var hurtbox: Area2D = $HurtBox
@onready var hurtbox_shape: CollisionShape2D = $HurtBox/HurtBoxShape
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Movimento e Física
var velocidade = 250.0
var direcao_olhando = 1
const JUMP_VELOCITY = -700.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var KNOCKBACK = 0.0
var KNOCKBACK_FORTE_Y = -200.0 

var player_id = 1 
var oponente: Node2D 

# Estatísticas
var vida_max = 1000.0
var vida_atual = 1000.0 
var aura_max = 100.0
var aura_atual = 0.0
var barra_aura = 0

var taxa_recarga_aura = 10.0
var bonus_aceleracao_aura = 15.0
var tempo_carregando = 0.0

signal vida_mudou(vida_atual_nova, vida_max_nova)
signal aura_mudou(aura_atual_nova, aura_max_nova, barras_totais)
signal morreu

# Estados de Controle
var pode_agir = true # Impede que o personagem faça duas coisas ao msm tempo (chutar e andar)
var contador_combo = 0
var dano_do_golpe = 0
var golpe_e_forte = false 
var esta_morto = false
var esta_em_hitstun = false # True quando toma o dano do golpe
var esta_carregando_aura = false

func _ready():
	emit_signal("vida_mudou", vida_atual, vida_max)
	emit_signal("aura_mudou", aura_atual, aura_max, barra_aura)

func _physics_process(delta):
	# 1. Morte
	if esta_morto:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0
		move_and_slide()
		return 
	
	# 2. Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 3. Carregando Aura
	if esta_carregando_aura and pode_agir:
		velocity.x = 0
		move_and_slide()
		return
		
	# 4. Pulo
	var input_pular = "p" + str(player_id) + "_pular"
	if Input.is_action_just_pressed(input_pular) and is_on_floor() and pode_agir:
		velocity.y = JUMP_VELOCITY
		contador_combo = 0
		timer_combo.stop()

	# 5. Movimento Horizontal
	var input_agachar = "p" + str(player_id) + "_baixo"
	var is_crouching = Input.is_action_pressed(input_agachar) and is_on_floor()
	var input_esquerda = "p" + str(player_id) + "_esquerda"
	var input_direita = "p" + str(player_id) + "_direita"
	var direcao_input = Input.get_axis(input_esquerda, input_direita)
	
	if not pode_agir:
		# Fricção durante knockback ou ataque
		velocity.x = lerp(velocity.x, 0.0, 0.1) 
	elif direcao_input == 0 or is_crouching:
		velocity.x = 0
	elif direcao_input == direcao_olhando:
		velocity.x = direcao_input * velocidade
	else: 
		velocity.x = direcao_input * (velocidade * 0.7)
	
	# 6. Lógica Anti-Stack
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo = colisao.get_collider()
		if corpo is CharacterBody2D:
			if global_position.y < corpo.global_position.y - 10:
				var dir = sign(global_position.x - corpo.global_position.x)
				if dir == 0: dir = 1
				velocity.x = dir * 800
	
	move_and_slide()

func _process(delta):
	if oponente == null: return 

	# --- Lógica de Virar ---
	if not esta_morto:
		if oponente.global_position.x > global_position.x:
			direcao_olhando = 1
			sprite.flip_h = false
		else:
			direcao_olhando = -1
			sprite.flip_h = true

	# --- Travas de Estado ---
	if esta_morto:
		animation_player.play("receber_dano")

	if not pode_agir: return

	# Inputs
	var input_agachar = "p" + str(player_id) + "_baixo"
	var is_crouching = Input.is_action_pressed(input_agachar)
	var input_socar = "p" + str(player_id) + "_socoFraco"
	var apertou_soco = Input.is_action_just_pressed(input_socar)
	var input_farmar = "p" + str(player_id) + "_aura"
	var segurando_aura = Input.is_action_pressed(input_farmar)
	
	if segurando_aura and is_on_floor() and barra_aura < 5:
		esta_carregando_aura = true
		if sprite.animation != "iniciando_aura" and sprite.animation != "farmando_aura":
			sprite.play("iniciando_aura")
		else:
			sprite.play("farmando_aura")
		tempo_carregando += delta
		var ganho_atual = taxa_recarga_aura + (tempo_carregando * bonus_aceleracao_aura)
		ganhar_aura(ganho_atual * delta)
		return
	else:
		tempo_carregando = 0.0
		esta_carregando_aura = false
	
	# Lógica de Ataque e Combo
	if apertou_soco:
		pode_agir = false
		
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

	# Animações de Movimento
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
		if velocity.y < 0: sprite.play("pular")
		else: sprite.play("queda")

func set_oponente(alvo: Node2D):
	oponente = alvo

func levar_dano(quantidade: int, e_forte: bool, knockback_oponente: float, direcao_knockback: int):
	if esta_morto or esta_em_hitstun: return
	
	esta_carregando_aura = false
	tempo_carregando = 0.0

	pode_agir = false
	esta_em_hitstun = true 
	
	contador_combo = 0
	timer_combo.stop()
	
	vida_atual -= quantidade
	vida_atual = max(0, vida_atual)
	emit_signal("vida_mudou", vida_atual, vida_max)
	
	if vida_atual <= 0:
		esta_morto = true
		animation_player.play("receber_dano")
		emit_signal("morreu")
		return 

	if e_forte:
		animation_player.play("derrubado")
		velocity.x = knockback_oponente * direcao_knockback
		velocity.y = KNOCKBACK_FORTE_Y
		await animation_player.animation_finished
		await piscar_no_animacao(sprite)
		animation_player.play("levantar")
	else:
		animation_player.play("receber_dano")
		velocity.x = knockback_oponente * direcao_knockback

func ganhar_aura(quantidade):
	if barra_aura >= 5:
		return
	aura_atual += quantidade
	aura_atual = min(aura_atual, aura_max)
	if aura_atual >= aura_max:
		barra_aura += 1
		if barra_aura < 5:
			aura_atual = 0.0
	emit_signal("aura_mudou", aura_atual, aura_max, barra_aura)

# --- Sinais e Callbacks ---
func _on_timer_combo_timeout() -> void:
	contador_combo = 0

func _on_animation_player_animation_finished(anim_name: StringName):
	if esta_morto: return
	
	if anim_name == "derrubado":
		return
	pode_agir = true
	
	var desativa_hitstun = ["receber_dano", "levantar"]
	if anim_name in desativa_hitstun:
		esta_em_hitstun = false
	
	var ataques_combo = ["golpe_fraco1", "golpe_fraco2"]
	if anim_name in ataques_combo:
		timer_combo.start()
	
	var ataques_reset = ["golpe_fraco3", "golpe_fraco_ar", "golpe_fraco_agachado"]
	if anim_name in ataques_reset:
		contador_combo = 0

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.get_owner() == self: return 
		
	var oponente_script = area.get_owner()
	var direcao_knockback = sign(global_position.x - oponente_script.global_position.x)
	
	levar_dano(oponente_script.dano_do_golpe, oponente_script.golpe_e_forte, oponente_script.KNOCKBACK ,direcao_knockback)

func _ativar_hitbox(dano: int, pos_x: float, pos_y: float, tam_x: float, tam_y: float, forte: bool = false, knockback: float = 0.0):
	dano_do_golpe = dano
	golpe_e_forte = forte
	KNOCKBACK = knockback
	hitbox_shape.position = Vector2(pos_x * direcao_olhando, pos_y)
	(hitbox_shape.shape as RectangleShape2D).size = Vector2(tam_x, tam_y)
	hitbox.monitorable = true 
	hitbox_shape.disabled = false

func _desativar_hitbox():
	hitbox.monitorable = false
	hitbox_shape.disabled = true
	dano_do_golpe = 0 
	golpe_e_forte = false

func resetar_estado():
	vida_atual = vida_max
	aura_atual = 0.0
	barra_aura = 0
	esta_morto = false
	pode_agir = true
	esta_em_hitstun = false
	contador_combo = 0
	velocity = Vector2.ZERO
	
	emit_signal("vida_mudou", vida_atual, vida_max)
	emit_signal("aura_mudou", aura_atual, aura_max, barra_aura)
	
	sprite.play("entrada")

func piscar_no_animacao(no) -> Signal:
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(no, "modulate:a", 0.0, 0.1)
	tween.tween_property(no, "modulate:a", 1.0, 0.1)
	
	return tween.finished
