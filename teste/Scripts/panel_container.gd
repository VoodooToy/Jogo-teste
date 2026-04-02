extends Control

@export var largura_maxima: float = 100.0
@export var margem_vertical: float = 20.0
@export var velocidade_leitura: float = 0.05 # Tempo em segundos por letra
var tween: Tween

func _ready():
	hide()

func mostrar_texto(conteudo: String):
	var label = $PanelContainer/MarginContainer/Label
	
	# 1. Preparação e Medição (Igual antes)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = 0
	label.text = conteudo
	label.visible_ratio = 0 # Começa com as letras escondidas
	
	reset_size()
	
	if conteudo.length() > 100:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 300
		reset_size()
		
	show()

	# 3. Efeito de Máquina de Escrever (Tween)
	# Calculamos o tempo total baseado no número de letras
	var tempo_total = conteudo.length() * velocidade_leitura
	tween = create_tween()
	# Animamos a propriedade 'visible_ratio' do 0 para o 1
	tween.tween_property(label, "visible_ratio", 1.0, tempo_total)
	

func esconder_texto():
	if tween:
		tween.kill()
	
	$PanelContainer/MarginContainer/Label.visible_ratio = 0
	
	hide()
