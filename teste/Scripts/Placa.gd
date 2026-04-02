extends Area2D

# Texto único para cada placa (edite no Inspetor)
@export_multiline var meu_texto: String = "Escreva aqui o que esta placa diz."

var jogador_perto: bool = false

func _ready():
	# Conecta os sinais de entrada e saída do jogador
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player": # Certifique-se de que seu Player se chama 'Player'
		jogador_perto = true

func _on_body_exited(body):
	if body.name == "Player":
		jogador_perto = false
		# Usa o nome correto do nó que você instanciou
		$InterfaceTexto.esconder_texto()

func _process(_delta):
	if jogador_perto and Input.is_action_just_pressed("Interaction"): # "ui_accept" costuma ser Espaço/Enter
		if $InterfaceTexto.visible:
			$InterfaceTexto.esconder_texto()
		else:
			$InterfaceTexto.mostrar_texto(meu_texto)
