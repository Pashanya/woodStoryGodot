extends Node

var plyer_health

var current_level 

var level_hause = "res://LevelHouse.tscn"


var player_state = {
	"x" = 0,
	"y" = 0,
	"is_facing_right" = true
}


var can_transition = true
var is_transaction_collided = false
var player_create_on_transition = false
