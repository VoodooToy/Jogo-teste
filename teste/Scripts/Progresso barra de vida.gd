extends TextureProgressBar

@export var velocidade_animacao: float = 5.0

var target_value: float

func _ready():
	target_value = value

func _process(delta):
	value = lerp(value, target_value, delta * velocidade_animacao)

	# 🔥 TRAVA VALORES MUITO PEQUENOS
	if abs(value - target_value) < 0.1:
		value = target_value

func atualizar_vida(nova_vida: float):
	target_value = clamp(nova_vida, min_value, max_value)

	# 🔥 ESCONDE quando zerar
	if target_value <= 0:
		target_value = 0
		value = 0
		hide()
	else:
		show()

func _on_vida_alterada(valor):
	print("HUD recebeu:", valor) # 👈 TESTE
	atualizar_vida(valor)
