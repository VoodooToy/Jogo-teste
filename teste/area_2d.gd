extends Area2D

@onready var som_powerup: AudioStreamPlayer2D = $PowerupSound

func _on_body_entered(body: Node2D) -> void:
	# Verifica se quem entrou na área é o jogador
	# Estamos checando se o corpo tem a variável que criamos no script anterior
	if "has_double_jump_powerup" in body:
		# 🔊 toca som desacoplado do projétil
		som_powerup.reparent(get_tree().current_scene)
		som_powerup.play()
		som_powerup.finished.connect(som_powerup.queue_free)
		body.has_double_jump_powerup = true
		print("Pulo duplo coletado!") # Aparecerá no console se funcionar
		queue_free() # Isso faz o item sumir do mapa
