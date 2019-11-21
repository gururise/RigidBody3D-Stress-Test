extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(int,20,75000) var num_cubes := 500
export(int,12,60) var size := 20
export(float) var x_dist := 2.0
export(float) var y_dist := 2.0
export(float) var z_dist := 2.0
#onready var cube : PackedScene = preload("res://scenes/cube.tscn")
onready var cube_mm : PackedScene = preload("res://scenes/cube_mm.tscn")
onready var marble : PackedScene = preload("res://scenes/marble.tscn")
onready var fpsLabel : Label = $CanvasLayer/FPSLabel
onready var sleepLabel : Label = $CanvasLayer/SleepLabel
onready var cubeContainer : Spatial = $CubeContainer
onready var mm : MultiMesh = $MultiMeshInstance.get_multimesh()
var instanced_marble

var timer : float = 0.0
var marble_launched : bool = false
var camera_anglev : int = -15
export(float,0.01,1.0) var TIMER_LIMIT := 0.1	# fps gui refresh rate in seconds
const mouse_sens : float  = 0.2

onready var fps : int = int(Performance.get_monitor(Performance.TIME_FPS))
onready var fps_min : int = 9999
onready var fps_max : int = 0
onready var fps_sum : int = 0
onready var fps_average : float = 0.0
onready var frames : int = -20  # need to wait a bit before starting to track the fps

# Called when the node enters the scene tree for the first time.
func _ready():
	instanced_marble = marble.instance()
	add_child(instanced_marble)
	$CanvasLayer/HSlider.value = num_cubes
	$CanvasLayer/NumLabel.text = "cubes: " + str(num_cubes) + " (" + str(num_cubes) + ")"
	# setup multimesh instances
	mm.set_instance_count(num_cubes)
	spawnCubes()

func _input(event):         
	if event is InputEventMouseMotion && Input.is_mouse_button_pressed(BUTTON_LEFT):
		$Camera.rotate_y(deg2rad(-event.relative.x*mouse_sens))
		var changev=-event.relative.y*mouse_sens
		if camera_anglev+changev>-50 and camera_anglev+changev<50:
			camera_anglev+=changev
			$Camera.rotate_x(deg2rad(changev))
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_SPACE):
			launchMarble()

func _process(delta):
	timer += delta
	if timer > TIMER_LIMIT:
		frames += 1
		timer = 0.0
		#OS.set_window_title(title + " | fps: " + str(Engine.get_frames_per_second()))
		fps = int(Performance.get_monitor(Performance.TIME_FPS))
		if frames > 0:
			if fps < fps_min:
				fps_min = fps
			if fps > fps_max:
				fps_max = fps
			fps_sum += fps
			fps_average = fps_sum / frames
			fpsLabel.text = "fps: " + str(fps) + " // " + "min: " + str(fps_min) + " // " + "max: " + str(fps_max) + " // " + "avg: " + str(fps_average)

func _physics_process(delta):
	# update per-instance multimesh transforms on each physics frame
	for i in range(num_cubes):
		mm.set_instance_transform(i,cubeContainer.get_child(i).transform)

func spawnCubes():
	for i in range(mm.instance_count):
		var instanced_cube = cube_mm.instance()
		var modval = i%size
# warning-ignore:integer_division
		if (modval < size/4):
			instanced_cube.translate(Vector3(modval*x_dist,i/size*y_dist,40))
# warning-ignore:integer_division
		elif (modval < size/2):
			instanced_cube.translate(Vector3(0,i/size*y_dist,40+z_dist+((modval-size/4)*z_dist)))
# warning-ignore:integer_division
		elif (modval < size/4*3):
			instanced_cube.translate(Vector3(size/2-x_dist,i/size*y_dist,40+z_dist+((modval-size/2)*z_dist)))
		else:
			instanced_cube.translate(Vector3((modval-size/4*3)*x_dist,i/size*y_dist,40+z_dist+size/4*z_dist))
		get_node("CubeContainer").add_child(instanced_cube)
		mm.set_instance_transform(i,instanced_cube.transform)

func resetFPS():
	fpsLabel.text = "fps: "
	fps_min = 9999
	fps_max = 0
	fps_sum = 0
	fps_average = 0.0
	frames = -20

func launchMarble():
	if not marble_launched:
		instanced_marble.add_central_force(Vector3(-2000,0,-19000))
		marble_launched = true

func deleteCubes():
	for c in cubeContainer.get_children():
		c.free()

func resetAll():
	resetFPS()
	# delete marble
	instanced_marble.free()
	
	# delete cubes
	deleteCubes()
	num_cubes = int($CanvasLayer/HSlider.value)
	_on_HSlider_value_changed(num_cubes)
	mm.set_instance_count(num_cubes)
	# reinstance marble
	instanced_marble = marble.instance()
	marble_launched = false
	add_child(instanced_marble)
	spawnCubes()


func _on_HSlider_value_changed(value):
	$CanvasLayer/NumLabel.text = "cubes: " + str(value) + " (" + str(num_cubes) + ")"

func _on_Timer_timeout():
	# Performance monitor does not work for Bullet Physics (we use a workaround) - https://github.com/godotengine/godot/issues/16540
	#sleepLabel.text = "sleeping: " + str(num_cubes - Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS) + 1)
	var sleep_count = 0
	for c in cubeContainer.get_children():
		if c.sleeping:
			sleep_count = sleep_count + 1
	sleepLabel.text = "sleeping: " + str(sleep_count)

func _on_CheckBox_toggled(button_pressed):
	if (button_pressed):
		$Timer.start()
		sleepLabel.text = "sleeping: "
	else:
		$Timer.stop()
		sleepLabel.text = "sleeping: (n/a)"