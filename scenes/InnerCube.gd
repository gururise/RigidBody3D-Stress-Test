#extends Node

class_name InnerCube

var rID : RID
var cID : int

func _init(rid : RID, cid : int) -> void:
	rID = rid
	cID = cid
