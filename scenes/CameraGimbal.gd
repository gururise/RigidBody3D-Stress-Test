extends Spatial

export var rotation_speed : float = PI/2
var invert_y : bool = false
var invert_x : bool  = false
export var mouse_control : bool = false
var mouse_sensitivity : float = 0.005

export var max_zoom : float = 3.0
export var min_zoom : float = 0.5
export var zoom_speed : float = 0.09

var zoom : float = 1.5

func _unhandled_input(event):
	if event.is_action_pressed("cam_zoom_in"):
		zoom -= zoom_speed
	if event.is_action_pressed("cam_zoom_out"):
		zoom += zoom_speed
	zoom = clamp(zoom, min_zoom, max_zoom)
	if mouse_control and event is InputEventMouseMotion:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			var y_rotation = clamp(event.relative.y, -30, 30)
			$InnerGimbal.rotate_object_local(Vector3.RIGHT, dir * y_rotation * mouse_sensitivity)

func get_input_keyboard(delta) -> void:
	if Input.is_action_pressed("escape"):
		get_tree().change_scene("res://scenes/launch.tscn")
	# Rotate outer gimbal around y axis
	var y_rotation = 0
	if Input.is_action_pressed("cam_right"):
		y_rotation += 1
	if Input.is_action_pressed("cam_left"):
		y_rotation += -1
	rotate_object_local(Vector3.UP, y_rotation * rotation_speed * delta)
	# Rotate inner gimbal around local x axis
	var x_rotation = 0
	if Input.is_action_pressed("cam_up"):
		x_rotation += -1
		#translate(Vector3.FORWARD * zoom_speed);
	if Input.is_action_pressed("cam_down"):
		x_rotation += 1
		#translate(Vector3.BACK * zoom_speed);
	$InnerGimbal.rotate_object_local(Vector3.RIGHT, x_rotation * rotation_speed * delta)

func _process(_delta):    
	if !mouse_control:
		get_input_keyboard(_delta)
	$InnerGimbal.rotation.x = clamp($InnerGimbal.rotation.x, -1.4, 0.45)
	scale = lerp(scale, Vector3.ONE * zoom, zoom_speed)
