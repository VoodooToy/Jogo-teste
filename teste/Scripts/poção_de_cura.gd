extends Area2D

@export var cura: int = 10
@onready var som_cura = $"Som de cura"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("curar"):
		
		# 🔥 Só cura se NÃO estiver cheio
		if body.vida_atual < body.vida_max:
			som_cura.play()
			body.curar(cura)
			visible = false
			set_deferred("monitoring", false)
			await som_cura.finished
			queue_free()
			
