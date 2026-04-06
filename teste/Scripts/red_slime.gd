extends CharacterBody2D

const SPEED = 60
const GRAVIDADE = 900

var direction = 1

@onready var floor_check: RayCast2D = $FloorCheck
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# =========================
# ❤️ VIDA
# =========================
@export var vida: int = 80

# =========================
# 💥 DANO E STATUS
# =========================
@export var forca_knockback: float = 250.0 # Aumentei um pouco para ser mais visível
var tomando_dano: bool = false
var invencivel: bool = false

# =========================
# 🔄 PHYSICS
# =========================
func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	# Movimento lógico
	if not tomando_dano:
		# Muda direção se bater na parede ou se não houver chão
		if is_on_wall() or not floor_check.is_colliding():
			inverter_direcao()

		velocity.x = direction * SPEED
		
		# Garante que a animação de andar esteja tocando se não estiver ferido
		if is_on_floor() and animated_sprite.animation != "Hit":
			animated_sprite.play("default") # Ou "walk", dependendo do nome na sua Sprite
	else:
		# Desacelera o knockback gradualmente
		velocity.x = move_toward(velocity.x, 0, 400 * delta)

	move_and_slide()

	# Atualiza posição do raycast de chão para ficar à frente da slime
	floor_check.position.x = 10 * direction

# =========================
# ⬅️➡️ DIREÇÃO
# =========================
func inverter_direcao():
	direction *= -1
	animated_sprite.flip_h = (direction < 0)

# =========================
# ⚔️ RECEBER DANO (Chamado pelo Player)
# =========================
func tomar_dano(valor: int, origem: Vector2 = global_position):
	if invencivel or vida <= 0:
		return

	invencivel = true
	tomando_dano = true
	vida -= valor
	
	print("Slime atingida! Vida restante: ", vida)

	# Efeitos Visuais e Físicos
	aplicar_knockback(origem)
	animated_sprite.play("Hit")

	# Gerencia o tempo de recuperação
	iniciar_estado_dano()

# =========================
# ☄️ KNOCKBACK
# =========================
func aplicar_knockback(origem: Vector2):
	# Calcula a direção oposta ao impacto
	var direcao_impacto = (global_position - origem).normalized()
	
	# Se o impacto vier de cima, empurra para os lados baseado na posição
	velocity.x = direcao_impacto.x * forca_knockback
	velocity.y = -abs(forca_knockback * 0.6) # Pulinho para cima ao levar dano

# =========================
# ⏱️ CONTROLE DE RECUPERAÇÃO
# =========================
func iniciar_estado_dano():
	# Ajuste esse tempo para a duração da sua animação de "Hit"
	await get_tree().create_timer(0.4).timeout

	tomando_dano = false
	
	if vida <= 0:
		morrer()
	else:
		# Tempo extra de invencibilidade após o knockback (opcional)
		await get_tree().create_timer(0.2).timeout
		invencivel = false
		animated_sprite.play("default")

# =========================
# ☠️ MORTE
# =========================
func morrer():
	print("Slime derrotada!")
	# Aqui você pode instanciar partículas ou efeitos de morte antes de deletar
	animated_sprite.play("death")
	queue_free()
