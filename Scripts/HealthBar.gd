extends Node2D

@onready var health_bar = $HealthBar
@onready var health_bar_2 = $HealthBar2

var tween

func setup_health(health):
	health_bar.max_value = health
	health_bar.value = health
	health_bar_2.max_value = health
	health_bar_2.value = health
	
func update_health(health):
	tween = health_bar.create_tween()
	tween.tween_property(health_bar, "value", health, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(health_bar_2, "value", health, 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
