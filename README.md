# Godot Rigidbody3D Stress Test

![](demo.gif)

This is a Rigidbody3D stress test for Godot 3.1+ designed to test the performance of the 3D Physics Engine in Godot.  It was inspired by a similar [stress test](https://www.youtube.com/watch?v=8zo5a_QvJtk) done in Unity.

# Features

  - Configurable number of Rigidbodies
  - GUI controls for reset and launch
  - Additional options available in exported Editor variables
  - Compatible with Godot 3.1.1 or newer

### Performance

On my Core i7 3770, going much above 1,000 rigid bodies using the default settings results in significant frame drops. Here are a couple of ideas for improving performance through adjustments to the Project Settings:

* Use the Bullet Physics Engine (default).  The Godot Physics Engine is significantly slower.
* Drop Physics Framerate from the default 60 FPS.
* Export as executable without Debug symbols.
* You can play around with rendering quality/lighting and try GLES2.  I haven't noticed much difference.

### Todos

 - Bring more settings out to the GUI
 - Record Min FPS and Avg FPS

License
----

MIT
