extends CharacterBody2D

@export var velocidade_horizontal: float = 200.0
@export var velocidade_vertical: float = -100.0
@export var gravidade: float = 900.0
@export var tempo_de_vida: float = 3.0
@export var velocidade_rotacao: float = 20.0
@export var dano: int = 10

var direcao: int = 1
var ja_acertou: bool = false
var explodindo: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D
@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var som_explosao: AudioStreamPlayer2D = $ExplosionSound

# =========================
# 🚀 INÍCIO
# =========================
func _ready():
	# impulso inicial
	velocity.x = velocidade_horizontal * direcao
	velocity.y = velocidade_vertical

	await get_tree().create_timer(tempo_de_vida).timeout
	if not explodindo:
		queue_free()


func _physics_process(delta):
	if explodindo:
		return

	# gravidade
	velocity.y += gravidade * delta

	# rotação
	rotation += velocidade_rotacao * delta

	move_and_slide()

		# 💥 bateu no chão
	if is_on_floor():
		explodir()

# =========================
# 💥 DETECÇÃO (AREA)
# =========================
func _on_area_2d_area_entered(area):
	if ja_acertou or explodindo:
		return

	var alvo = area.get_parent()

	if alvo and alvo.is_in_group("Inimigos"):
		aplicar_dano(alvo)

# =========================
# 💥 DETECÇÃO (BODY)
# =========================
func _on_area_2d_body_entered(body):
	if ja_acertou or explodindo:
		return

	if body and body.is_in_group("Inimigos"):
		aplicar_dano(body)

# =========================
# 🎯 APLICA DANO
# =========================
func aplicar_dano(alvo):
	ja_acertou = true

	if alvo.has_method("tomar_dano"):
		alvo.tomar_dano(dano, global_position)

	explodir()

# =========================
# 💥 EXPLOSÃO
# =========================
func explodir():
	if explodindo:
		return

	explodindo = true

	# para movimento
	velocity = Vector2.ZERO

	# desativa colisões
	colisao.disabled = true
	hitbox.monitoring = false

	# opcional: parar rotação
	rotation = 0
	sprite.scale = Vector2(0.5, 0.5)

	# 🔊 toca som desacoplado do projétil
	som_explosao.reparent(get_tree().current_scene)
	som_explosao.play()
	som_explosao.finished.connect(som_explosao.queue_free)

	# toca animação
	sprite.play("Explode")
	


	await sprite.animation_finished

	queue_free()
