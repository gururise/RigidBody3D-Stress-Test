# Godot Rigidbody3D Stress Test

![](demo.gif)

This is a Rigidbody3D stress test for ~~Godot 3.1~~+ (Updated for Godot 3.3+) designed to test the performance of the 3D Physics Engine in Godot.  It was inspired by a similar [stress test](https://www.youtube.com/watch?v=8zo5a_QvJtk) done in Unity.  In that test, Unity was able to simulate 1,500 rigid bodies and still maintain over 100 fps on a Dual Xeon E5-2v650 v2 (2.60 Ghz)

# Video
A video using this code can be found on [YouTube](https://www.youtube.com/watch?v=XTE4B6yULR4).

# Features

  - Use a PhysicsServer for handling physics simulations, reducing the overhead of having a bunch of nodes on the scene tree.
  - Use MultimeshInstance to optimize rendering of box meshes
  - Configurable number of Rigidbodies
  - GUI controls for reset and launch
  - Additional options available in exported Editor variables
  - Compatible with Godot 3.1.1 or newer
  - Physics update rate set to 50 fps to match default Unity fixed timestep of 0.02
  - VSYNC disabled to match the Unity test referenced above.
  - Report number of sleeping Rigidbodies (enable sleeping checkbox to view sleeping bodies).

### Performance

Since switching to MultiMeshes, performance has increased significantly. On my Core i7-3770 (3.4 Ghz), I am able to easily simulate well above 1500 cubes. Here are a couple of ideas for improving performance through adjustments to the Project Settings:

* Because multimesh requires code to update the per-instance mesh transforms on every physics frame, there is an opportunity for further optimization via a separate thread or switching to c#/c++ or both.
* ~~Use the Bullet Physics Engine (default).  The Godot Physics Engine is significantly slower.~~ Godot Physics in 3.3+ has seen major performance improvements.
* Drop Physics Framerate from the default 60 fps.
* Export as executable without Debug symbols.
* Disable shadows and/or directional lighting.
* You can play around with rendering quality/lighting and try GLES2.  I haven't noticed much difference.

### Todos

 - Separate thread to update per-instance mesh transforms on each physics frame. (Performance)
 - Convert code to update mesh transforms to C#. (Performance)
 - Bring more settings out to the GUI
 - ~~Record Min FPS and Avg FPS~~

License
----

MIT License (MIT)

Copyright (c) 2019 Gene Ruebsamen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
