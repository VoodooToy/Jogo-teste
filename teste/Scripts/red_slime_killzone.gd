extends Area2D

@export var dano: int = 30
@export var intervalo_dano: float = 0.5

var pode_dar_dano = true

func _ready():
	monitoring = true

func _process(delta):
	if not pode_dar_dano:
		return

	var corpos = get_overlapping_bodies()

	for body in corpos:
		if body.name == "Player":
			if body.has_method("tomar_dano"):
				body.tomar_dano(dano, global_position)
				print("RED SLIME ATACOU:", dano)
				iniciar_cooldown()
				break


func iniciar_cooldown():
	pode_dar_dano = false
	await get_tree().create_timer(intervalo_dano).timeout
	pode_dar_dano = true
