extends Spatial

export(int,5,250) var spawn_rate : int = 45
const MAX_MESHES : int = 2950

onready var fpsLabel : Label = $CanvasLayer/ReferenceRect/FPSLabel
onready var sleepLabel : Label = $CanvasLayer/ReferenceRect/SleepLabel
onready var mm : MultiMesh = $MultiMeshInstance.get_multimesh()
var cube_list = []

var timer : float = 0.0
var start : bool = false
export(float,0.01,1.0) var TIMER_LIMIT := 0.1	# fps gui refresh rate in seconds

onready var fps : int = int(Performance.get_monitor(Performance.TIME_FPS))
onready var box = PhysicsServer.shape_create(PhysicsServer.SHAPE_BOX)
var fps_min : int = 9999
var fps_max : int = 0
var fps_sum : int = 0
var fps_average : float = 0.0
var frames : int = -20  # need to wait a bit before starting to track the fps
var start_msec : int
var end_msec : int

var spawn_transform : Transform = Transform()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/TimeLabel.bbcode_text = ""
	$CanvasLayer/ReferenceRect/HSlider.value = spawn_rate
	$CanvasLayer/ReferenceRect/NumLabel.text = "rate (ms): " + str(spawn_rate)
	# setup multimesh instances
	mm.set_instance_count(MAX_MESHES)   # max total meshes
	mm.visible_instance_count = 0

	# set box shape extents to match mesh size of 1,1,1
	PhysicsServer.shape_set_data(box,Vector3(0.5,0.5,0.5))
	spawn_transform = transform.translated(Vector3(0,35,0))

func _process(delta) -> void:
	timer += delta
	if timer > TIMER_LIMIT:
		frames += 1
		timer = 0.0
		#OS.set_window_title(title + " | fps: " + str(Engine.get_frames_per_second()))
		if frames > 0:
			fps = int(Performance.get_monitor(Performance.TIME_FPS))
			if fps < fps_min:
				fps_min = fps
			if fps > fps_max:
				fps_max = fps
			# calc fps avg of last 1 second in 1 second intervals (we only do a division once every second)
			if frames <= 10:
				fps_sum += fps
			else:
				# warning-ignore:integer_division
				fps_average = fps_sum / frames
				frames = 0
				fps_sum = fps
				
			fpsLabel.text = "fps: " + str(fps) + " // " + "min: " + str(fps_min) + " // " + "max: " + str(fps_max) + " // " + "avg: " + str(fps_average)
	
func _physics_process(_delta) -> void:
	# update per-instance multimesh transforms on each physics frame
	for cube in cube_list:
		mm.set_instance_transform(cube.cID,PhysicsServer.body_get_direct_state(cube.rID).transform)

func spawn_cubes() -> void:
	# create collision body in Physics Server
	var cube : InnerCube = InnerCube.new(PhysicsServer.body_create(PhysicsServer.BODY_MODE_RIGID, true), mm.visible_instance_count)

	PhysicsServer.body_add_shape(cube.rID,box)
	PhysicsServer.body_set_space(cube.rID,get_world().space)

	mm.set_instance_transform(cube.cID,spawn_transform)
	PhysicsServer.body_set_state(cube.rID,PhysicsServer.BODY_STATE_TRANSFORM,spawn_transform)
	PhysicsServer.body_apply_central_impulse(cube.rID,Vector3(rand_range(-5,5),-45,rand_range(-5,5)))
	
	mm.visible_instance_count += 1
	cube_list.append(cube)

func resetFPS() -> void:
	fpsLabel.text = "fps: "
	fps_min = 9999
	fps_max = 0
	fps_sum = 0
	fps_average = 0.0
	frames = -20

func deleteCubes() -> void:
	for cube in cube_list:
		PhysicsServer.free_rid(cube.rID)
	cube_list.clear()

func resetAll() -> void:
	resetFPS()
	deleteCubes()
	spawn_rate = int($CanvasLayer/ReferenceRect/HSlider.value)
	_on_HSlider_value_changed(spawn_rate)
	mm.visible_instance_count = 0

func _on_SleepUITimer_timeout() -> void:
	# Performance monitor does not work for Bullet Physics (we use a workaround) - https://github.com/godotengine/godot/issues/16540
	# sleepLabel.text = "sleeping: " + str(num_cubes - Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS) + 1)
	var sleep_count = 0
	for cube in cube_list:
		if PhysicsServer.body_get_direct_state(cube.rid).sleeping:
			sleep_count = sleep_count + 1
	sleepLabel.text = "sleeping: " + str(sleep_count)

func _on_CheckBox_toggled(button_pressed) -> void:
	if (button_pressed):
		$SleepUITimer.start()
		sleepLabel.text = "sleeping: "
	else:
		$SleepUITimer.stop()
		sleepLabel.text = "sleeping: (n/a)"

func _on_HSlider_value_changed(value):
	$CanvasLayer/ReferenceRect/NumLabel.text = "rate (ms): " + str(value)
	$CubeSpawnTimer.wait_time = value/1000

func _on_CubeSpawnTimer_timeout():
	if mm.visible_instance_count < MAX_MESHES:
		spawn_cubes()
		$CanvasLayer/ReferenceRect/RichTextLabel.text = " " + str(mm.visible_instance_count)
	else:
		$CubeSpawnTimer.stop()
		end_msec = OS.get_ticks_msec()
		print("Elapsed Time: " + str(end_msec - start_msec) + " ms")
		$CanvasLayer/TimeLabel.bbcode_text = "[center]" + str(end_msec-start_msec) + " ms[/center]"
	
func _on_ResetButton_pressed():
	resetAll()

func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		$CubeSpawnTimer.start()
		start_msec = OS.get_ticks_msec()
	else:
		$CubeSpawnTimer.stop()
