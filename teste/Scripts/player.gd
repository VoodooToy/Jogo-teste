extends CharacterBody2D

signal vida_alterada(valor)

# =========================
# ❤️ VIDA
# =========================
var vida_max = 100
var vida_atual = 100

@export var tempo_invencibilidade: float = 1.0
@export var forca_knockback: float = 200.0

var invencivel: bool = false
var em_animacao_dano: bool = false

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
# 🔄 PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	
	var direction := Input.get_axis("Move L", "Move R")
	var climb_input := 0
	
	if Input.is_action_pressed("Move Up"):
		climb_input -= 1
	elif Input.is_action_pressed("Move Down"):
		climb_input += 1

	var is_trying_to_climb = Input.is_action_pressed("Move Up") or Input.is_action_pressed("Move Down")

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
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			perform_wall_jump()
		elif can_double_jump:
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


# =========================
# 💥 DANO (VERSÃO FINAL)
# =========================
func tomar_dano(valor: int, origem: Vector2 = Vector2.ZERO):
	if invencivel:
		return

	invencivel = true
	em_animacao_dano = true

	vida_atual -= valor
	vida_atual = max(vida_atual, 0)

	print("Vida atual:", vida_atual)
	emit_signal("vida_alterada", vida_atual)

	aplicar_knockback(origem)

	# toca animação (não será interrompida)
	animated_sprite.play("Hit")

	iniciar_estado_dano()


# =========================
# ⏱️ CONTROLE DE ESTADO
# =========================
func iniciar_estado_dano():
	var tempo_animacao = 1.1 # 🔧 ajuste conforme sua animação

	await get_tree().create_timer(tempo_animacao).timeout
	em_animacao_dano = false

	await get_tree().create_timer(tempo_invencibilidade - tempo_animacao).timeout
	invencivel = false

	if vida_atual <= 0:
		morrer()


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
func morrer():
	print("Player morreu")
	get_tree().reload_current_scene()


## =========================
## 🧪 TESTE
## =========================
#func _process(_delta):
	#if Input.is_action_just_pressed("Interaction"):
		#tomar_dano(10, global_position - Vector2(10, 0))
