extends CharacterBody2D

signal vida_alterada(valor)

enum TipoInput { MOUSE, TECLADO }

var ultimo_input := TipoInput.MOUSE
var ultima_pos_mouse := Vector2.ZERO

# =========================
# ❤️ VIDA
# =========================
var vida_max = 100
var vida_atual = 100

@export var tempo_invencibilidade: float = 1.0
@export var forca_knockback: float = 200.0
@export var projectile_scene: PackedScene
@export var velocidade_mira: float = 400.0
@export var alcance_raio: float = 175.0
@export var fator_alcance: float = 0.5

var distancia_max_mira: float

@onready var mira = $AimMarker
@onready var ray_cast = $RayCastDano
@onready var jump_sound: AudioStreamPlayer2D = $Sounds/JumpSound
@onready var som_passo: AudioStreamPlayer2D = $Sounds/Step
@onready var hurt_sound: AudioStreamPlayer2D = $Sounds/HurtSound

var ultimo_frame_passo: int = -1
var mirando: bool = false
var direcao_mira: Vector2 = Vector2.RIGHT
var invencivel: bool = false
var em_animacao_dano: bool = false

# =========================
# ❤️ CURA
# =========================
func curar(valor: int):
	vida_atual += valor
	vida_atual = min(vida_atual, vida_max)

	print("Vida curada:", vida_atual)
	emit_signal("vida_alterada", vida_atual)


# =========================
# 🎮 MOVIMENTO
# =========================
const SPEED = 130.0
const JUMP_VELOCITY = -280.0

# Wall Jump
const WALL_JUMP_V_VELOCITY = -320.0 
const WALL_JUMP_H_PUSHBACK = 100.0  
const WALL_SLIDE_SPEED = 50.0       
var is_wall_jumping: bool = false   

# Pulo Duplo
var has_double_jump_powerup: bool = false 
var can_double_jump: bool = false        

# Escada
const CLIMB_SPEED = 100.0
var is_on_ladder: bool = false
var can_climb: bool = false
var is_on_ladder_top: bool = false
var current_ladder: Area2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


# =========================
# 🔄 LANÇAR O PROJÉTIL
# =========================
func lancar_projetil():
	var proj = projectile_scene.instantiate()

	# direção
	var direcao = -1 if animated_sprite.flip_h else 1

	# posição (na frente do player)
	proj.global_position = global_position + Vector2(20 * direcao, -10)

	# envia direção pro projétil
	proj.direcao = direcao

	get_tree().current_scene.add_child(proj)
	
	
# =========================
# 🔄 PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	
	var direction := 0.0

	if not mirando:
		direction = Input.get_axis("Move L", "Move R")
	var climb_input := 0
	
	if mirando:
	# trava movimento
		velocity = Vector2.ZERO
		
	
	if Input.is_action_pressed("Move Up"):
		climb_input -= 1
	elif Input.is_action_pressed("Move Down"):
		climb_input += 1

	var is_trying_to_climb = Input.is_action_pressed("Move Up") or Input.is_action_pressed("Move Down")
	
	if Input.is_action_just_pressed("Attack"):
		lancar_projetil()
		
	# SEGURAR PARA MIRAR
	if Input.is_action_pressed("Aim"):
		if not mirando:
			iniciar_mira()

		atualizar_mira(delta)

	# SOLTOU → DISPARA
	elif mirando:
		disparar_raio()
		
	
	# =========================
	# ESCADA
	# =========================
	if can_climb:
		if is_on_floor():
			if Input.is_action_pressed("Move Down"):
				is_on_ladder = true
		else:
			if climb_input != 0:
				is_on_ladder = true
	else:
		is_on_ladder = false

	is_on_ladder_top = can_climb and not is_on_ladder and not is_trying_to_climb and velocity.y >= 0

	if is_on_ladder:
		if current_ladder:
			global_position.x = lerp(global_position.x, current_ladder.global_position.x, 0.2)

		velocity.x = 0

		if climb_input != 0:
			velocity.y = climb_input * CLIMB_SPEED
		else:
			velocity.y = 0

		if Input.is_action_just_pressed("Jump"):
			is_on_ladder = false
			velocity.y = JUMP_VELOCITY

		animated_sprite.play("Jump")
		move_and_slide()
		return

	# =========================
	# GRAVIDADE
	# =========================
	if is_on_ladder_top:
		velocity.y = 0
	else:
		velocity += get_gravity() * delta

	# =========================
	# RESET
	# =========================
	if is_on_floor() or is_on_ladder_top:
		is_wall_jumping = false
		if has_double_jump_powerup:
			can_double_jump = true

	if is_on_wall():
		is_wall_jumping = false

	# =========================
	# PULO
	# =========================
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor() or is_on_ladder_top:
			jump_sound.play()
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			jump_sound.play()
			perform_wall_jump()
		elif can_double_jump:
			jump_sound.play()
			perform_double_jump()

	# =========================
	# WALL SLIDE
	# =========================
	if is_on_wall_only() and velocity.y > 0:
		var wall_normal = get_wall_normal()
		if (wall_normal.x < 0 and direction > 0) or (wall_normal.x > 0 and direction < 0):
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

	# =========================
	# MOVIMENTO
	# =========================
	if not is_wall_jumping:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# =========================
	# FLIP
	# =========================
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# =========================
	# ANIMAÇÕES (CORRIGIDO)
	# =========================
	if not em_animacao_dano:
		if is_on_floor() or is_on_ladder_top:
			if direction == 0:
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Run")
		else:
			animated_sprite.play("Jump")

	move_and_slide()
	
	# 🔊 som de passos
	tocar_som_passo()

# =========================
# 🔊 SOM DE PASSOS
# =========================
func tocar_som_passo():

	# só toca se estiver correndo no chão
	if animated_sprite.animation != "Run" or not is_on_floor():
		ultimo_frame_passo = -1
		return

	# ajuste conforme sua animação
	var frames_de_passo = [1, 3, 5, 7, 9, 11, 13, 15]

	if animated_sprite.frame in frames_de_passo:
		
		if ultimo_frame_passo != animated_sprite.frame:
			
			som_passo.pitch_scale = randf_range(0.9, 1.1)
			som_passo.play()

			ultimo_frame_passo = animated_sprite.frame

	else:
		# 🔥 libera para tocar novamente quando sair do frame de passo
		ultimo_frame_passo = -1

# =========================
# 💥 DANO (VERSÃO FINAL)
# =========================
func tomar_dano(valor: int, origem: Vector2 = Vector2.ZERO):
	if invencivel or morto:
		return

	vida_atual -= valor
	vida_atual = max(vida_atual, 0)

	print("Vida atual:", vida_atual)
	emit_signal("vida_alterada", vida_atual)

	# 💀 MORREU → fluxo especial
	if vida_atual <= 0:
		morrer_com_delay(origem)
		return

	# 🩸 DANO NORMAL
	invencivel = true
	em_animacao_dano = true

	aplicar_knockback(origem)
	hurt_sound.play()
	animated_sprite.play("Hit")

	iniciar_estado_dano()


# =========================
# ⏱️ CONTROLE DE ESTADO
# =========================
func iniciar_estado_dano():
	var tempo_animacao = 1.5 # 🔧 ajuste conforme sua animação

	await get_tree().create_timer(tempo_animacao).timeout
	em_animacao_dano = false

	await get_tree().create_timer(tempo_invencibilidade - tempo_animacao).timeout
	invencivel = false

# =========================
# 💥 KNOCKBACK
# =========================
func aplicar_knockback(origem: Vector2):
	var direcao = (global_position - origem).normalized()

	velocity.x = direcao.x * forca_knockback 
	velocity.y = -abs(forca_knockback * 0.5)


# =========================
# AUXILIARES
# =========================
func perform_wall_jump():
	var wall_normal = get_wall_normal()
	velocity.y = WALL_JUMP_V_VELOCITY
	velocity.x = wall_normal.x * WALL_JUMP_H_PUSHBACK
	is_wall_jumping = true
	
	await get_tree().create_timer(0.12).timeout
	if not is_on_floor():
		is_wall_jumping = false

func perform_double_jump():
	velocity.y = JUMP_VELOCITY
	can_double_jump = false


# =========================
# ESCADA DETECÇÃO
# =========================
func _on_area_2d_area_entered(area):
	if area.is_in_group("escada"):
		can_climb = true
		current_ladder = area

func _on_area_2d_area_exited(area):
	if area.is_in_group("escada"):
		can_climb = false
		is_on_ladder = false
		current_ladder = null


# =========================
# ☠️ MORTE
# =========================
var morto: bool = false

func morrer_com_delay(origem: Vector2):
	if morto:
		return

	morto = true

	print("Player morreu")
	animated_sprite.play("Half_Hit")	
	hurt_sound.play()

	# 💥 knockback inicial
	aplicar_knockback(origem)
	await get_tree().create_timer(0.3).timeout

	# 🚫 perde controle
	set_physics_process(false)
	

	# 🎬 animação de morte
	animated_sprite.play("Death")

	Engine.time_scale = 0.5
	await animated_sprite.animation_finished
	Engine.time_scale = 1.0

	# ⏳ pequeno delay final
	#await get_tree().create_timer(0.5).timeout

	get_tree().reload_current_scene()


## =========================
## 🧪 TESTE
## =========================
#func _process(_delta):
	#if Input.is_action_just_pressed("Interaction"):
		#tomar_dano(10, global_position - Vector2(10, 0))
		
# ===================
# MIRA E RAIO
# ===================
func iniciar_mira():
	mirando = true
	mira.visible = true
	Engine.time_scale = 0.3

	# nasce no player
	mira.global_position = global_position
	direcao_mira = Vector2.ZERO

	# 🔥 força começar pelo teclado
	ultimo_input = TipoInput.TECLADO

	# 🔥 evita "pulo" pro mouse
	ultima_pos_mouse = get_global_mouse_position()
	
func atualizar_mira(delta):

	var mouse_pos = get_global_mouse_position()
	var movimento_mouse = mouse_pos.distance_to(ultima_pos_mouse)

	var input_dir = Vector2(
		Input.get_axis("Move L", "Move R"),
		Input.get_axis("Move Up", "Move Down")
	)

	# 🎯 DETECTA QUAL INPUT FOI USADO

	# mouse se moveu
	if movimento_mouse > 2:
		ultimo_input = TipoInput.MOUSE

	# teclado pressionado
	elif input_dir != Vector2.ZERO:
		ultimo_input = TipoInput.TECLADO

	# salva posição do mouse
	ultima_pos_mouse = mouse_pos

	# =========================
	# 🎮 APLICA INPUT
	# =========================

	if ultimo_input == TipoInput.MOUSE:
		var vetor = mouse_pos - global_position
		var direcao = vetor.normalized()

		mira.global_position = global_position + direcao * min(vetor.length(), distancia_max_mira)

	else:
		if input_dir != Vector2.ZERO:
			direcao_mira = input_dir.normalized()
			mira.global_position += direcao_mira * velocidade_mira * delta

	# 🔒 limite final
	var offset = mira.global_position - global_position

	if offset.length() > distancia_max_mira:
		offset = offset.normalized() * distancia_max_mira
		mira.global_position = global_position + offset

func disparar_raio():
	mirando = false
	mira.visible = false

	Engine.time_scale = 1.0

	var direcao = (mira.global_position - global_position).normalized()

	tocar_animacao_raio(direcao)

# TESTE COM LINE2D
@onready var linha = $Line2D
@onready var raio_sprite = $RaySprite
@onready var som_raio = $"Sounds/Shock spell"

func tocar_animacao_raio(direcao):
	var origem = global_position
	var destino = mira.global_position
	var vetor = destino - origem
	
	ray_cast.target_position = ray_cast.to_local(destino)
	ray_cast.force_raycast_update()

	if ray_cast.is_colliding():
		var obj = ray_cast.get_collider()
		print("Raio colidiu com: ", obj.name) # Debug 1
		
				#CONFIGURAÇÃO DE DANO AQUI
		if obj.is_in_group("Inimigos"):
			print("É um inimigo! Tentando causar dano...") # Debug 2
			if obj.has_method("tomar_dano"):
				obj.tomar_dano(10, global_position) 
			else:
				print("ERRO: O inimigo não tem a função 'tomar_dano'")
		else:
			print("Colidiu com algo, mas não está no grupo 'Inimigos'")
	else:
		print("O raio não colidiu com nada.")

	# ... resto da animação visual (raio_sprite) ...
	# ----------------------------------

	# Visual do Raio (seu código original)
	raio_sprite.global_position = origem
	raio_sprite.rotation = vetor.angle()
	raio_sprite.visible = true
	raio_sprite.z_index = 100
	raio_sprite.scale = Vector2(0.5, 0.5)
	som_raio.play()
	raio_sprite.play("shoot")

	await raio_sprite.animation_finished
	raio_sprite.visible = false
	
func _ready():
	distancia_max_mira = alcance_raio * fator_alcance
	ultima_pos_mouse = get_global_mouse_position()
