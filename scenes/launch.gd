extends Control

func _on_TowerButtonNode_pressed():
	get_tree().change_scene("res://scenes/main.tscn")

func _on_TowerButtonPS_pressed():
	get_tree().change_scene("res://scenes/main_ps.tscn")


func _on_SpawnButtonGDNode_pressed():
	get_tree().change_scene("res://scenes/cube_node.tscn")

func _on_SpawnButtonGDPS_pressed():
	get_tree().change_scene("res://scenes/cube_ps_gdscript.tscn")

func _on_SpawnButtonCSPS_pressed():
	get_tree().change_scene("res://scenes/cube_ps_cs.tscn")
