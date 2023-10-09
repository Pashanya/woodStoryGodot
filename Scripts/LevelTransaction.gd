extends Node2D

var ready_to_change_level = false

@export var level_to_change : String
@export var need_activation = false
@export var is_player_facing_right = false
@export var target_x = 0
@export var target_y = 0

var level_change = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("is_activation", change_level)

func change_level():
	if ready_to_change_level and !GlobalData.player_create_on_transition:
		if level_to_change == null:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(level_to_change)
		GlobalData.player_state["x"] = target_x
		GlobalData.player_state["y"] = target_y
		GlobalData.player_state["is_facing_right"] = is_player_facing_right
		level_change = true
		print("Штуки изменены")

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		print("Переходим на некст левел?")
		GlobalData.is_transaction_collided = true
		ready_to_change_level = true
		if !need_activation:
			change_level()

func _on_area_2d_body_exited(body):
	print("level_change", level_change)
	if body.name == "Player" and !level_change:
		print("Вышел из коллизии " , GlobalData.player_create_on_transition)
		GlobalData.is_transaction_collided = false
		print("Теперь не переходим на некст левел")
		ready_to_change_level = false
	
