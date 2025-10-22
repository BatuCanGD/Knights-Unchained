extends Control

@onready var warningpanel: Panel = $CanvasLayer/Warningpanel

func _ready() -> void:
	warningpanel.visible = false

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_one.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_reset_progress_pressed() -> void:
	warningpanel.visible = true

func _on_button_pressed() -> void:
	Global.health = 100
	Global.stamina = 100
	Global.level = 1
	Global.experience = 0.0
	Global.exp_limit = 10.0
	
	
	Global.stamlevel = 1
	Global.swordlevel = 1
	Global.healthlevel = 1
	
	Global.skill_points = 0
	
	Global.healthskill = 0
	Global.staminaskill = 0
	Global.swordskill = 0
	Global.rebirth_amount = 0
	warningpanel.visible = false

func _on_button_2_pressed() -> void:
	warningpanel.visible = false
