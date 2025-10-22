extends Node
#Global script / Player progress
var health: float = 100.0
var stamina = 100.0
var player_weight: float = 80.0

var experience: float = 0.0
var exp_limit: float = 10.0

var level: int = 1
var level_limit: int = 100
var levelhundred := 26100.3

var rebirth_amount := 0

var skill_points: int = 0

var sword_damage := 10

var swordskill: int = 0
var healthskill: int = 0
var staminaskill: int = 0
var swordmax := 10
var healthmax := 10
var stammax := 10

var swordlevel := 1
var healthlevel := 1
var stamlevel := 1

func add_experience(amount: float) -> void:
	experience += amount
	while experience >= exp_limit and level < level_limit:
		level += 1
		experience -= exp_limit
		levelhundred -= exp_limit
		skill_points += 1
		exp_limit *= 1.05 - (rebirth_amount * 0.035)
		print("%.1f" % exp_limit)
	if level >= level_limit:
		level = level_limit
		experience = min(experience, exp_limit - 0.01)

func get_exp_needed()-> float:
	return exp_limit - experience
