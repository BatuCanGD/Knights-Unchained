extends Node

signal UpdateExp (experience: float)

var experience: float = 0.0
var exp_limit: float = 50.0
var exp_topuplimit: float = 25.0

var level: int = 1
var level_limit: int = 99

var swordskill: int = 1
var healthskill: int = 1
var staminaskill: int = 1

func _ready() -> void:
	emit_signals()
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	emit_signals()

func add_experience(amount: float) -> void:
	experience += amount
	while experience >= exp_limit and level < level_limit:
		level += 1
		experience -= exp_limit
		exp_limit *= 1.2
		print(exp_limit)
func emit_signals():
	UpdateExp.emit(experience)
