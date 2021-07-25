using Godot;
using System;
using System.Collections.Generic;

public readonly struct InnerCube
{
    public InnerCube(RID rID, int cID) 
    {
        this.rID = rID;
        this.cID = cID;
    }
    public RID rID { get; }
    public int cID { get; }
}

public class test_cs : Spatial
{
    [Export] int spawnRate = 45;
    Label fpsLabel, sleepLabel, rateLabel;
    RichTextLabel numCountLabel;
    MultiMesh mm;
    private RID boxShape;
    private float timer = 0f;
    private const float TIMER_LIMIT = 0.1f;
    private const int MAX_MESHES = 2950;
    private int fps, fps_min = 9999, fps_max = 0, fps_sum = 0, fps_avg = 0, frames = -20;
    private Transform spawnTransform;
    private Random r = new Random();
    private uint start_msec, end_msec;
    List<InnerCube> cubeList = new List<InnerCube>();

    public override void _Ready()
    {
        // connect signals
        GetNode<Button>("CanvasLayer/ReferenceRect/ResetButton").Connect("pressed", this, nameof(_on_ResetButton_pressed));
        GetNode<HSlider>("CanvasLayer/ReferenceRect/HSlider").Connect("value_changed", this, nameof(_on_HSlider_value_changed));
        GetNode<CheckButton>("CanvasLayer/ReferenceRect/CheckButton").Connect("toggled", this, nameof(_on_CheckButton_toggled));
        GetNode<Timer>("CubeSpawnTimer").Connect("timeout", this, nameof(_on_CubeSpawnTimer_timeout));
        GetNode<Timer>("SleepUITimer").Connect("timeout", this, nameof(_on_SleepUITimer_timeout));
        GetNode<CheckBox>("CanvasLayer/ReferenceRect/CheckBox").Connect("toggled", this, nameof(_on_Checkbox_Toggled));

        // get object references
        rateLabel = GetNode<Label>("CanvasLayer/ReferenceRect/RateLabel");
        fpsLabel = GetNode<Label>("CanvasLayer/ReferenceRect/FPSLabel");
        numCountLabel = GetNode<RichTextLabel>("CanvasLayer/ReferenceRect/RichTextLabel");
        sleepLabel = GetNode<Label>("CanvasLayer/ReferenceRect/SleepLabel");
        mm = GetNode<MultiMeshInstance>("MultiMeshInstance").Multimesh;

        GetNode<RichTextLabel>("CanvasLayer/TimeLabel").BbcodeText = "";
        GetNode<HSlider>("CanvasLayer/ReferenceRect/HSlider").Value = spawnRate;
        rateLabel.Text = "rate (ms): " + spawnRate.ToString();
        numCountLabel.Text = " 0";

        mm.InstanceCount = MAX_MESHES; // max meshes;
        mm.VisibleInstanceCount = 0;

        // set box collision shape extens to match mesh size of 1,1,1
        boxShape = PhysicsServer.ShapeCreate(PhysicsServer.ShapeType.Box);        
        PhysicsServer.ShapeSetData(boxShape,new Vector3(0.5f,0.5f,0.5f));
        spawnTransform = Transform.Translated(new Vector3(0f, 35f, 0)); // spawn point
        //setupObjectPool();
    }

    private void setupObjectPool() 
    {
        // create object pool -- its slower than instantiating each cube obj in the spawn func
        for (int i = 0; i < mm.InstanceCount; i++)
        {
            cubeList.Add(new InnerCube(PhysicsServer.BodyCreate(PhysicsServer.BodyMode.Rigid, true), i)); // sleeping physics body            
        }
    }

    public override void _Process(float delta)
    {
        //base._Process(delta);
        timer += delta;
        if (timer > TIMER_LIMIT) 
        {
            frames++;
            timer = 0f;
            if (frames > 0) 
            {
                fps = (int)Performance.GetMonitor(Performance.Monitor.TimeFps);
                if (fps < fps_min)
                    fps_min = fps;
                if (fps > fps_max)
                    fps_max = fps;
                if (frames <= 10)
                    fps_sum += fps;
                else
                {
                    fps_avg = fps_sum / frames;
                    frames = 0;
                    fps_sum = fps;
                }
                fpsLabel.Text = "fps: " + fps.ToString() + " // min: " + fps_min.ToString() + " // max: " + fps_max.ToString() + " // avg: " + fps_avg.ToString();
            }
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        // update per-instance multimesh transforms on each physics frame
        foreach (InnerCube c in cubeList) {
            mm.SetInstanceTransform(c.cID, PhysicsServer.BodyGetDirectState(c.rID).Transform);
        }
    }

    private void spawnCubes() 
    {
        // create collision body in PhysicsServer
        InnerCube cube = new InnerCube(PhysicsServer.BodyCreate(PhysicsServer.BodyMode.Rigid, true),mm.VisibleInstanceCount++);
        // add collision shape to body + properties
        PhysicsServer.BodyAddShape(cube.rID,boxShape,Transform.Identity);
        // add to default world space
        PhysicsServer.BodySetSpace(cube.rID,this.GetWorld().Space);

        // set transform (spawn loc) of mesh
        mm.SetInstanceTransform(cube.cID, spawnTransform);
        PhysicsServer.BodySetState(cube.rID, PhysicsServer.BodyState.Transform, spawnTransform);
        PhysicsServer.BodyApplyCentralImpulse(cube.rID,new Vector3((float)r.NextDouble()*10-5,-45,(float)r.NextDouble()*10-5));

        cubeList.Add(cube);
    }

    private void resetFPS() 
    {
        fpsLabel.Text = "fps: ";
        fps_min = 9999; fps_max = 0; fps_sum = 0; fps_avg = 0; frames = -20;
    }

    private void deleteCubes() 
    {
        foreach (InnerCube c in cubeList) 
            PhysicsServer.FreeRid(c.rID);
        cubeList.Clear();
        //setupObjectPool();
    }

    private void _on_ResetButton_pressed()
    {
        resetFPS();
        deleteCubes();
        spawnRate = (int) GetNode<HSlider>("CanvasLayer/ReferenceRect/HSlider").Value;
        _on_HSlider_value_changed(spawnRate);
        mm.VisibleInstanceCount = 0;
    }

    private void _on_SleepUITimer_timeout() 
    {        
        int sleepCount = 0;
        foreach (InnerCube c in cubeList) 
        {
            if (PhysicsServer.BodyGetDirectState(c.rID).Sleeping) 
                sleepCount++;
        }
        sleepLabel.Text = "sleeping: " + sleepCount.ToString();
    }

    private void _on_Checkbox_Toggled(bool button_pressed) 
    {
        if (button_pressed) 
        {
            GetNode<Timer>("SleepUITimer").Start();
            sleepLabel.Text = "sleeping: ";
        }
        else
        {
            GetNode<Timer>("SleepUITimer").Stop();
            sleepLabel.Text = "sleeping: (n/a)";
        }
    }

    private void _on_HSlider_value_changed(int value) 
    {
        rateLabel.Text = "rate (ms): " + value.ToString();
        GetNode<Timer>("CubeSpawnTimer").WaitTime = value / 1000f;
    }

    private void _on_CubeSpawnTimer_timeout() 
    {
        if (mm.VisibleInstanceCount < MAX_MESHES) 
        {
            spawnCubes();
            numCountLabel.Text = " " + mm.VisibleInstanceCount.ToString();
        } else 
        {
            GetNode<Timer>("CubeSpawnTimer").Stop();
            end_msec = OS.GetTicksMsec();
            GD.Print("Elapsed Time: " + (end_msec-start_msec).ToString() + " ms");
            GetNode<RichTextLabel>("CanvasLayer/TimeLabel").BbcodeText = "[center]" + (end_msec - start_msec).ToString() + " ms[/center]";
        }
    }

    private void _on_CheckButton_toggled(bool button_pressed) 
    {
        if (button_pressed)
        {
            GetNode<Timer>("CubeSpawnTimer").Start();
            start_msec = OS.GetTicksMsec();
        }
        else
            GetNode<Timer>("CubeSpawnTimer").Stop();
    }
}
