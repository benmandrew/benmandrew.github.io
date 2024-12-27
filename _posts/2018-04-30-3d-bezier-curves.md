---
layout:     post
title:      "3D Bézier Curves"
date:       2018-04-30
categories: articles
header:     headers/bezier3d.jpg
tag:        "Interactive Project"
header_rendering: auto
banner: false
fullwidth: true
---
<head>
<script src="{{ site.s3_path }}/bezier3d/UnityLoader.js"></script>
<script>
var unityInstance = UnityLoader.instantiate("unityContainer", "{{ site.s3_path }}/bezier3d/bezier.json");
</script>
</head>

<div class="webgl-content" style="padding: 20px 0px 30px 0px;">
<div id="unityContainer" style="width: 100%; height: 100%; border: 3px solid gray; margin: auto;"></div>
</div>

Press **space** to generate a new curve.

Plotting bezier curves in 3D. The algorithm is explained in [this post](/articles/bezier-curve-plotter).

##### [Link to GitHub repository](https://github.com/benmandrew/BezierCurve3D)
