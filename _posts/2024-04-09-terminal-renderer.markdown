---
layout:     post
title:      "Rendering in the Terminal"
date:       2024-04-09
categories: articles
tag:        "Article"
header:     headers/terminal-renderer.png
header_rendering: auto
banner: true
---

Modern terminals can show far more than the green-and-black Matrix-style terminals of old. Many support a 24-bit colour space, allow interactivity, and can render characters from a vast array of scripts. With these capabilities, writing and using a purely terminal-based application can actually be enjoyable (rather than like pulling teeth).

The colour space support is particularly exciting, as it allows us to render arbitrary graphics, treating characters as pseudo-pixels. In fact, by carefully choosing which character we use in each spot, we can add more detail than a traditional pixel.

<a href="/articles/parallelising-a-software-ray-tracer">A previous project of mine</a> rendered 3D toruses with nice lighting and shadows, drawn into a traditional pixel-filled window. How can we draw to the terminal instead?

I use <a href="https://github.com/pqwy/notty">Notty</a>, an easy-to-use OCaml library that includes almost all of the infrastructure needed to draw characters to arbitrary points on the terminal. If you want to check out how it works, see the `Terminal` module in `lib/frontend.ml` in the <a href="https://github.com/benmandrew/Otorus">GitHub repository</a>.

Some example recordings are shown below, using the amazing <a href="https://asciinema.org">Asciinema</a> tool for recording terminal sessions.

<div style="margin-bottom:10px" id="demo1"></div>
<div style="margin-bottom:10px" id="demo2"></div>

<p align="center">
  <img src="{{ site.s3_path }}/terminal-renderer/big.png" align="center" width="100%" height="auto">
</p>

<p align="center">
  <img src="{{ site.s3_path }}/terminal-renderer/tiny.png" align="center" width="80%" height="auto">
</p>

## Quirks

- As terminal characters are approximately twice as tall as they are wide, the formula for projecting the rays out from the camera needs to be scaled in the $$y$$ direction appropriately, otherwise you will get quite a stretched image.

- Make sure that your terminal supports 24-bit colour! For whatever reason the MacOS Terminal doesn't support it, so I had to replace it with <a href="https://iterm2.com">iTerm2</a>.

<p align="center">
  <img src="{{ site.s3_path }}/terminal-renderer/fail.png" align="center" width="60%" height="auto">
</p>

## Links
- GitHub repository ([link](https://github.com/benmandrew/Otorus)).

<script src="/assets/asciinema-player.min.js"></script>
<script>
  AsciinemaPlayer.create('{{ site.s3_path }}/terminal-renderer/out6.cast', document.getElementById('demo1'));
  AsciinemaPlayer.create('{{ site.s3_path }}/terminal-renderer/out4.cast', document.getElementById('demo2'));
</script>
