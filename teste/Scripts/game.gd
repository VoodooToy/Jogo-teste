extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().process_frame
	
	var player = $Player
	var barra = get_node_or_null("CanvasLayer/Control/TextureProgressBar")
	
	print("Player:", player)
	print("Barra:", barra)

	if player and barra:
		player.vida_alterada.connect(barra._on_vida_alterada)
	else:
		print("ERRO: não encontrou player ou barra")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
