extends Area2D

var ja_ativou: bool = false

func _on_body_entered(body: Node2D) -> void:
	if ja_ativou:
		return

	if body.is_in_group("Player"):
		if body.has_method("morrer_com_delay"):
			ja_ativou = true

			# 💥 usa a posição da killzone como origem do dano
			body.morrer_com_delay(global_position)
