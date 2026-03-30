extends Node

var score = 0

@onready var game_score: Label = $"Game Score"

func add_point():
	score += 1
	game_score.text = str(score) + " coins."
