extends Control

@export var largura_maxima: float = 100.0
@export var margem_vertical: float = 20.0
@export var velocidade_leitura: float = 0.05

var tween: Tween
var esta_escrevendo: bool = false
var texto_completo: String = ""

func _ready():
	hide()

func mostrar_texto(conteudo: String):
	var label = $PanelContainer/MarginContainer/Label
	
	texto_completo = conteudo
	esta_escrevendo = true

	# 1. Preparação
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = 0
	label.text = conteudo
	label.visible_ratio = 0
	
	reset_size()
	
	if conteudo.length() > 100:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 300
		reset_size()
		
	show()

	# 2. Tween (efeito de digitação)
	var tempo_total = conteudo.length() * velocidade_leitura
	
	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, tempo_total)

	# Quando terminar
	tween.finished.connect(_on_tween_finished)


func _on_tween_finished():
	esta_escrevendo = false


func mostrar_texto_completo():
	var label = $PanelContainer/MarginContainer/Label
	
	if tween:
		tween.kill()
	
	label.visible_ratio = 1.0
	esta_escrevendo = false


func esconder_texto():
	if tween:
		tween.kill()
	
	$PanelContainer/MarginContainer/Label.visible_ratio = 0
	
	esta_escrevendo = false
	hide()
