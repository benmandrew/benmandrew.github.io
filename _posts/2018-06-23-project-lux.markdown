---
layout:     post
title:      "Spatially-Accelerated Ray-Tracing of Triangle Meshes"
date:       2018-06-23
categories: articles
header:     headers/lux.png
tag:        "A-level Coursework"
header_rendering: pixelated
---

This is my A-level computer science coursework. The project was to write a 3D ray-tracer that renders triangle meshes, using a bounding volume hierarchy to accelerate the ray-triangle intersections to be logarithmic in the number of triangles rather than linear. With large meshes this reduces the rendering time from minutes to a few seconds.

The renderer is written in C++, with a simple UI for modifying camera and mesh properties (number-of, orientation, etc,) written in Python using the tkinter library.

Please don't judge the project's name too harshly, 17-year-old me thought it was cool.

##### Links:

- The [coursework itself](https://benmandrew.s3.amazonaws.com/lux/lux.pdf) (PDF).
- The [GitHub repository](https://github.com/benmandrew/ProjectLux); be warned, it is a mess.
