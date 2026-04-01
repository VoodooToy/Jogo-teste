extends Area2D

# Isso permite que você escreva um texto diferente para cada placa no Inspetor
@export_multiline var meu_texto: String = "Olá! Eu sou uma placa."

var jogador_perto = false

# Quando o jogador entra na área
func _on_body_entered(body):
	if body.name == "Player": # Certifique-se que o nome do seu nó de jogador é "Player"
		jogador_perto = true

# Quando o jogador sai da área
func _on_body_exited(body):
	if body.name == "Player":
		jogador_perto = false
		# Opcional: Avisar a interface para sumir
		var interface = get_tree().current_scene.get_node("InterfaceTexto")
		if interface:
			interface.esconder_texto()

func _process(_delta):
	if jogador_perto and Input.is_action_just_pressed("Interaction"):
		# Aqui buscamos a interface que está na cena do mundo
		get_tree().current_scene.get_node("InterfaceTexto").mostrar_texto(meu_texto)
