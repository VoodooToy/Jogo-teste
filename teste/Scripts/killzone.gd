extends Area2D

@export var dano: int = 10

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		if body.has_method("tomar_dano"):
			body.tomar_dano(dano, global_position)
