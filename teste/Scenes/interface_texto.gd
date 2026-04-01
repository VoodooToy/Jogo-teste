extends Control

func _ready():
	hide() # Começa escondida

func mostrar_texto(conteudo):
	$Panel/Label.text = conteudo
	show() # Mostra a caixa quando chamada

func esconder_texto():
	hide()
