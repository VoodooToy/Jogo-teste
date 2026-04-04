extends Area2D

@export_multiline var meu_texto: String = "Escreva aqui o que esta placa diz."

var jogador_perto: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		jogador_perto = true

func _on_body_exited(body):
	if body.name == "Player":
		jogador_perto = false
		$InterfaceTexto.esconder_texto()

func _process(_delta):
	if jogador_perto and Input.is_action_just_pressed("Interaction"):
		
		if $InterfaceTexto.visible:
			
			if $InterfaceTexto.esta_escrevendo:
				# 👉 termina instantaneamente
				$InterfaceTexto.mostrar_texto_completo()
			else:
				# 👉 fecha
				$InterfaceTexto.esconder_texto()
		
		else:
			# 👉 abre
			$InterfaceTexto.mostrar_texto(meu_texto)
