extends Spatial

export(int,25,75000) var num_cubes : int = 500
export(int,1,100) var side_length : int = 5
export(int,1,1000) var impulse : int = 250

onready var marble : PackedScene = preload("res://scenes/marble.tscn")
onready var fpsLabel : Label = $CanvasLayer/FPSLabel
onready var sleepLabel : Label = $CanvasLayer/SleepLabel
onready var mm : MultiMesh = $MultiMeshInstance.get_multimesh()
var instanced_marble
var cube_array = []

var timer : float = 0.0
var marble_launched : bool = false
export(float,0.01,1.0) var TIMER_LIMIT := 0.1	# fps gui refresh rate in seconds

onready var fps : int = int(Performance.get_monitor(Performance.TIME_FPS))
var fps_min : int = 9999
var fps_max : int = 0
var fps_sum : int = 0
var fps_average : float = 0.0
var frames : int = -20  # need to wait a bit before starting to track the fps

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instanced_marble = marble.instance()
	add_child(instanced_marble)
	$CanvasLayer/HSlider.value = num_cubes
	$CanvasLayer/NumLabel.text = "cubes: " + str(num_cubes) + " (" + str(num_cubes) + ")"
	# setup multimesh instances
	mm.set_instance_count(num_cubes)
	spawn_cubes()

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_SPACE):
			launchMarble()

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
				
			#fps_average = fps_sum / frames
			fpsLabel.text = "fps: " + str(fps) + " // " + "min: " + str(fps_min) + " // " + "max: " + str(fps_max) + " // " + "avg: " + str(fps_average)
	
func _physics_process(_delta) -> void:
	# update per-instance multimesh transforms on each physics frame
	for cube in cube_array:
		mm.set_instance_transform(cube.mmidx,PhysicsServer.body_get_state(cube.rid,PhysicsServer.BODY_STATE_TRANSFORM))

func spawn_cubes() -> void:
	PhysicsServer.set_active(false)
	cube_array.clear()
	
	for i in range(num_cubes):
		cube_array.append(InnerCube.new())
	
	var a = -side_length / 2.0
	var b = 0
	var c = a
	var d = 0
	var cnt = 0
	var box = PhysicsServer.shape_create(PhysicsServer.SHAPE_BOX)
	
	# set box shape extents to match mesh size of 1,1,1
	PhysicsServer.shape_set_data(box,Vector3(0.5,0.5,0.5))
	
	for cube in cube_array:
		# create collision shape in Physics Server
		cube.rid = PhysicsServer.body_create(PhysicsServer.BODY_MODE_RIGID, true)
		cube.mmidx = cnt
		var transform = Transform()

		PhysicsServer.body_add_shape(cube.rid,box)
		PhysicsServer.body_set_param(cube.rid,PhysicsServer.BODY_PARAM_MASS, 1.0)
		PhysicsServer.body_set_param(cube.rid,PhysicsServer.BODY_PARAM_GRAVITY_SCALE, 1.0)
		PhysicsServer.body_set_space(cube.rid,get_world().space)
		PhysicsServer.body_set_state(cube.rid,PhysicsServer.BODY_STATE_CAN_SLEEP,true)
		PhysicsServer.body_set_state(cube.rid,PhysicsServer.BODY_STATE_SLEEPING,true)
		
# warning-ignore:integer_division
		var level = cnt / (side_length * 4)
		
		#reset side a,b,c,d to zero on new level
		if (cnt % (side_length * 4) == 0):
			a = -side_length / 2.0
			b = 0
			c = a
			d = 0
		
		# y height should be (level - 0.5), but set to (level + 0.5) to let the bricks fall and collapse better
		if cnt%4 == 0:
			transform = transform.translated(Vector3(a+1,level + 0.5,0))
			a+=1
		elif cnt%4 == 1:
			transform = transform.translated(Vector3(-side_length / 2.0 + side_length + 1.0, level + 0.5, b + 1.0))
			b+=1
		elif cnt%4 == 2:
			transform = transform.translated(Vector3(c + 1.0, level + 0.5, side_length + 1.0))
			c+=1
		else:
			transform = transform.translated(Vector3(-side_length / 2.0, level + 0.5, d + 1.0))
			d+=1
		mm.set_instance_transform(cube.mmidx,transform)
		PhysicsServer.body_set_state(cube.rid,PhysicsServer.BODY_STATE_TRANSFORM,transform)
		cnt+=1
		
func resetFPS() -> void:
	fpsLabel.text = "fps: "
	fps_min = 9999
	fps_max = 0
	fps_sum = 0
	fps_average = 0.0
	frames = -20

func launchMarble() -> void:
	if not marble_launched:
		PhysicsServer.set_active(true)
		#instanced_marble.translate(Vector3(-side_length/2,0,0))
		instanced_marble.apply_central_impulse(Vector3(0,0,-impulse))
		marble_launched = true
		fps_sum = 0
		frames = 1

func deleteCubes() -> void:
	for cube in cube_array:
		PhysicsServer.free_rid(cube.rid)

func resetAll() -> void:
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
	spawn_cubes()

func _on_HSlider_value_changed(value) -> void:
	$CanvasLayer/NumLabel.text = "cubes: " + str(value) + " (" + str(num_cubes) + ")"

func _on_Timer_timeout() -> void:
	# Performance monitor does not work for Bullet Physics (we use a workaround) - https://github.com/godotengine/godot/issues/16540
	# sleepLabel.text = "sleeping: " + str(num_cubes - Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS) + 1)
	
	var sleep_count = 0
	for cube in cube_array:
		if PhysicsServer.body_get_direct_state(cube.rid).sleeping:
			sleep_count = sleep_count + 1
	sleepLabel.text = "sleeping: " + str(sleep_count)

func _on_CheckBox_toggled(button_pressed) -> void:
	if (button_pressed):
		$Timer.start()
		sleepLabel.text = "sleeping: "
	else:
		$Timer.stop()
		sleepLabel.text = "sleeping: (n/a)"

class InnerCube:
	var rid : RID
	var mmidx : int
	
