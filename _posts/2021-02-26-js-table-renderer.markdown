---
layout:     post
title:      "Javascript 3D Renderer"
date:       2021-02-26
categories: articles
header:     headers/js_renderer.png
---

<script src="/assets/table.js"></script>

<div class="row mb-2">
<button class="col-5 m-auto" onclick="toggleRendering()">Start / Pause</button>
<button class="col-5 m-auto" onclick="stepRendering()">Step Once</button>
</div>

<div class="row">
<table class="col-12 table-renderer" id="table"></table>
</div>

---

# Table Renderer

Little-known fact: a HTML table is just a rectangular grid of cells. You can set the background colour of these cells using JavaScript. So why not write an entire 3D renderer using only these two things?

This started out as a joke, but after weeks of bashing my head against the wall with perspective-correct interpolation and homogeneous coordinate transforms, it  turns out it's actually not that funny. It was however a good way to learn about the inner workings of rasterisation rendering, especially the parts that the GPU typically hides from you. I'd like to go over some of the specific things that I find are usually never mentioned in tutorials or explanations.

If you'd like to see the code, you can either look at the repo on [GitHub](https://github.com/benmandrew/JSTableRenderer), or if you're on Chrome, press F12, go to the sources tab, and look in the **/static/js/** path for the actual JS code being run.

p.s. If you're about to read on, you may want to pause the renderer above: it likes to use 100% of the browser's JS thread :)

## Points vs. Directions in Homogeneous space

There's plenty of information online on how to transform vertices using the MVP matrix, but few go into detail on how you go about transforming direction vectors, such as normals.


If we were just using 3x3 matrices this wouldn't be an issue, but 4x4 matrices give us the ability to translate vertices in space, doing 'affine' transformations rather than just linear. This is great for point vectors, but a direction vector
should remain constant under translation.


We fix this by formulating point vectors and direction vectors slightly differently in homogeneous coordinate space. For both we take the *x*, *y*, and *z* components as usual, but we differ in the *w* components.
For point vectors we set *w=1*, and for direction vectors we set *w=0*.


To understand this change let's look at the general translation matrix application.

<img src="{{ site.s3_path }}/js_renderer/translation.png" class="img-fluid">

This super simple formulation means that point vectors (with *w=1*) get translated, and direction vectors (with *w=0*) are left unchanged.

## Perspective-Correct Interpolation

The properties of a particular model are usually given per-vertex. Examples include the vertex itself, UV coordinates, and normals. During rasterisation these properties are interpolated across the surface of the triangle being rendered. A quick Google search of potential techniques returns barycentric coordinates as a promising candidate, however copying a common implementation will likely
result in some very weird-looking textures...


<img src="{{ site.s3_path }}/js_renderer/side_incorrect.png" class="img-fluid">

This happens because the barycentric interpolation assumes that the triangle is in 2D, i.e. that all points on the triangle are at the same depth from the camera. However this is obviously not true, and it changes the code required by quite a bit. The maths is quite involved, so I recommend looking at this article [here](https://www.scratchapixel.com/lessons/3d-basic-rendering/rasterization-practical-implementation/perspective-correct-interpolation-vertex-attributes), and giving implementing it a go. It's practically the only source I've found that even mentions perspective-correct interpolation, let alone giving instructions.


<img src="{{ site.s3_path }}/js_renderer/side_correct.png" class="img-fluid">

## Clip, NDC, and Screen Space

Typically in a vertex shader you'll multiple your vertices by some model-view-projection (MVP) matrix and be done with it. Your transformed vertices will shoot off down the pipe, and out into the fragment shader comes nice rasterised pixels. However if you try to do this yourself in software you'll probably find your screen very blank.


The GPU actually fiddles with your vertices between the vertex and fragment shaders while you're not looking. The reason it does this is because of the way that we do projective transformations.


The issue here is the *w* component of the vector. We usually treat it as invariant that points in our space have a *w* component of 1, however if you do the computation of applying a projective matrix yourself, you'll see that it can change *w* to something else. The way we then renormalise our vector is by dividing all of the components by *w*, which makes *w=1*, but more importantly does a non-linear transformation on the *x*, *y*, and *z* components. This is the fundamental reason we can do perspective projection.


<img src="{{ site.s3_path }}/js_renderer/normalise.png" class="img-fluid" style="width: 25%">

This 'perspective division' is not done as part of the matrix multiplication, it is one of the hidden steps between the vertex and fragment shaders. One of the other hidden steps is necessitated by the fact that we're currently restricting ourself to a cube extending from *-1* to *1* in all axes. This is very nice for transformations and the like, but not very useful for rasterising fragments to put to the screen.


<img src="{{ site.s3_path }}/js_renderer/ndc.jpeg" class="img-fluid">        

Converting our space to be the right dimensions for the screen is suprisingly easy. We just want to map the x axis from *[-1, 1]* to *[0, screen_width]* and the y axis from *[-1, 1]* to *[0, screen_height]*.


<img src="{{ site.s3_path }}/js_renderer/screen.jpeg" class="img-fluid">

<img src="{{ site.s3_path }}/js_renderer/screen_transform.png" class="img-fluid">

We still need the depth (*z* component) in order to pass the z-test, so we can leave that component alone in the transformation.

Thus, we overall create a pipeline of transformations, each transitioning from one particular space to another.

<img src="{{ site.s3_path }}/js_renderer/pipeline.jpeg" class="img-fluid" style="max-width: 80%">

The MVP matrix takes us from the model's space to <u>Clip space</u>, with unnormalised homogeneous coordinates. Normalising these coordinates by perspective division takes us to <u>Normalised-Device-Coordinate (NDC) space</u>, and scaling to the dimensions of the screen takes us to <u>Screen space</u>, where rasterisation can finally occur.
