using Godot;
using System;

public sealed class transCopy : Spatial
{
	private MultiMesh mm;
	private Label fpsLabel;

	private int fps = 0;
	private int fps_min = 9999;
	private int fps_max = 0;
	private int fps_sum = 0;
	private float fps_average = 0.0f;
	private int frames = -20;
	private float timer = 0.0f;
	[Export]
	private float TIMER_LIMIT = 0.1f;
	
    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        mm = (GetNode<MultiMeshInstance>("../MultiMeshInstance")).Multimesh;
		fpsLabel = GetNode<Label>("../CanvasLayer/FPSLabel");
    }

	public override void _Process(float delta) 
	{
		timer += delta;
		if (timer > TIMER_LIMIT)
		{
			frames++;
			timer = 0.0f;
			fps = (int)Performance.GetMonitor(Performance.Monitor.TimeFps);
			if (frames > 0) 
			{
				if (fps < fps_min) 
					fps_min = fps;
				if (fps > fps_max) 
					fps_max = fps;
				fps_sum += fps;
				fps_average = fps_sum / frames;
				fpsLabel.Text = "fps: " + fps.ToString() + " // " + "min: " + fps_min.ToString() + " // " + "max: " + 
					fps_max.ToString() + " // " + "avg: " + fps_average.ToString();
			}
		}
	}

	public void resetFPS() 
	{
		fpsLabel.Text = "fps: ";
		fps_min = 9999;
		fps_max = 0;
		fps_sum = 0;
		fps_average = 0;
		frames = -20;
	}

	public static void test() {

	}

	public override void _PhysicsProcess(float delta)
	{		
		for (int i=0;i<mm.InstanceCount;i++) 
		{
			// Here we update the per-instance multimesh transforms on every physics frame
			mm.SetInstanceTransform(i,((RigidBody)GetChild(i)).GetTransform());
		}
	}
	
}
