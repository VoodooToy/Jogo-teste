extends Area2D


func _on_body_entered(body: Node2D) -> void:
	# Verifica se quem entrou na área é o jogador
	# Estamos checando se o corpo tem a variável que criamos no script anterior
	if "has_double_jump_powerup" in body:
		body.has_double_jump_powerup = true
		print("Pulo duplo coletado!") # Aparecerá no console se funcionar
		queue_free() # Isso faz o item sumir do mapa
