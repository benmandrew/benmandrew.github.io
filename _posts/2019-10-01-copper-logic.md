---
layout:     post
title:      "Copper Logic"
date:       2019-10-01
categories: articles
header:     headers/copper.jpg
tag:        "Interactive Project"
header_rendering: auto
banner: false
fullwidth: true
---

<script src="{{ site.s3_path }}/copper/UnityLoader.js"></script>
<script>
    var unityInstance = UnityLoader.instantiate("unityContainer", "{{ site.s3_path }}/copper/common.json");
</script>

<div class="webgl-content" style="padding: 20px 0px 30px 0px;">
<div id="unityContainer" style="width: 100%; height: 100%; border: 3px solid gray; margin: auto;"></div>
</div>

Visualiser of boolean logic circuits - The default circuit is an XOR gate

##### Controls

- Left click and drag gates to move them around.
- Right click on gates to delete, or create connections.
- Right click on the input gates to switch them on or off.
- Right click on connections to delete them.
- Right click elsewhere to spawn new gates
- Scroll the mouse wheel to zoom out.
- Click and drag the mouse wheel to pan the camera.

##### <a href="https://github.com/benmandrew/CopperLogic">Link to GitHub repository</a>

##### Example circuits

<div class="row">
  <div class="caption col-12 col-lg-4">
  <p>Full Adder</p>
  <img src="{{ site.s3_path }}/copper/full_adder.jpg" class="img-fluid">
  </div>

  <div class="caption col-12 col-lg-4">
  <p>XOR Gate</p>
  <img src="{{ site.s3_path }}/copper/xor.jpg" class="img-fluid">
  </div>

  <div class="caption col-12 col-lg-4">
  <p>2-Input Multiplexer</p>
  <img src="{{ site.s3_path }}/copper/multiplexer.jpg" class="img-fluid">
  </div>
</div>
