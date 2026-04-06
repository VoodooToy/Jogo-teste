extends CharacterBody2D

const SPEED = 60
const GRAVIDADE = 900

var direction = 1

@onready var ray_cast_r: RayCast2D = $RayCastR
@onready var ray_cast_l: RayCast2D = $RayCastL
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# =========================
# VIDA
# =========================
@export var vida: int = 20

# =========================
# DANO / ESTADO
# =========================
@export var forca_knockback: float = 200.0

var tomando_dano: bool = false
var invencivel: bool = false


func _physics_process(delta):

	# gravidade
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	# =========================
	# MOVIMENTO NORMAL
	# =========================
	if not tomando_dano:
		if ray_cast_r.is_colliding():
			direction = -1
			animated_sprite.flip_h = true

		if ray_cast_l.is_colliding():
			direction = 1
			animated_sprite.flip_h = false

		velocity.x = direction * SPEED

	else:
		# desacelera knockback
		velocity.x = move_toward(velocity.x, 0, 200 * delta)

	move_and_slide()


# =========================
# DANO
# =========================
func tomar_dano(valor: int, origem: Vector2 = global_position):
	if invencivel:
		return

	invencivel = true
	tomando_dano = true

	vida -= valor
	print("Slime vida:", vida)

	aplicar_knockback(origem)

	animated_sprite.play("Hit")

	iniciar_estado_dano()


# =========================
# KNOCKBACK
# =========================
func aplicar_knockback(origem: Vector2):
	var direcao = (global_position - origem).normalized()

	velocity.x = direcao.x * forca_knockback
	velocity.y = -abs(forca_knockback * 0.5)


# =========================
# CONTROLE
# =========================
func iniciar_estado_dano():
	var tempo_animacao = 0.4

	await get_tree().create_timer(tempo_animacao).timeout

	tomando_dano = false
	invencivel = false

	if vida <= 0:
		morrer()


# =========================
# MORTE
# =========================
func morrer():
	queue_free()
