extends CharacterBody2D

# --- Configurações de Movimento ---
const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# --- Configurações de Wall Jump (Estilo Mega Man X) ---
const WALL_JUMP_V_VELOCITY = -320.0 
const WALL_JUMP_H_PUSHBACK = 100.0  
const WALL_SLIDE_SPEED = 50.0       # Velocidade máxima ao deslizar na parede
var is_wall_jumping: bool = false   

# --- Configurações de Pulo Duplo ---
var has_double_jump_powerup: bool = false 
var can_double_jump: bool = false        

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. Aplica a Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Reseta estados ao tocar o chão ou parede
	if is_on_floor():
		is_wall_jumping = false
		if has_double_jump_powerup:
			can_double_jump = true
			
	if is_on_wall():
		is_wall_jumping = false

	# 3. Lógica de Pulo
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			perform_wall_jump()
		elif can_double_jump:
			perform_double_jump()

	# 4. Direção e Input
	var direction := Input.get_axis("Move L", "Move R")
	
	# 5. Lógica de Wall Slide (Deslizar na Parede)
	# Condições: No ar + Encostado na Parede + Caindo + Segurando na direção da parede
	if is_on_wall_only() and velocity.y > 0:
		var wall_normal = get_wall_normal()
		# Se a normal é (-1, 0), a parede está na direita (direção > 0)
		# Se a normal é (1, 0), a parede está na esquerda (direção < 0)
		if (wall_normal.x < 0 and direction > 0) or (wall_normal.x > 0 and direction < 0):
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
			# Opcional: Você pode tocar uma animação de "Wall Slide" aqui
			# animated_sprite.play("WallSlide")

	# 6. Flip do Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# 7. Animações
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("Idle")
		else:
			animated_sprite.play("Run")
	else:
		# Se estiver deslizando, talvez você queira manter o sprite de pulo ou um novo
		animated_sprite.play("Jump")
	
	# 8. Aplicação do Movimento Horizontal
	if is_wall_jumping:
		pass 
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

# --- Funções Auxiliares ---

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
