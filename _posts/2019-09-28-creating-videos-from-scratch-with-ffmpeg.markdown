---
layout:     post
title:      "Creating Videos from Scratch with FFMPEG"
date:       2019-09-28
categories: articles
header:     headers/ffmpeg.jpg
tag:        "Article"
header_rendering: auto
banner: true
---

Rendering videos yourself sounds challenging, but using FFMPEG makes it incredibly easy.

FFMPEG is a command-line tool used to convert multimedia files between formats, for example changing a WMV file to an MP4 file, or merging two audio tracks into one. Here I’ll use it  to stack a sequence of images into a video, like a flipbook.

For the example I’ve implemented the jump flood algorithm for rendering Voronoi diagrams, but FFMPEG can be used for whatever purpose you need.

Download FFMPEG from the <a href="https://ffmpeg.org/download.html">download page</a>, and unzip it to a directory that you'll remember.

# Adding FFMPEG to PATH

In order to use FFMPEG from the command line without being in the same directory as ffmpeg.exe (a pain), you have to add the directory to the PATH <a href="https://en.wikipedia.org/wiki/Environment_variable">environment variable</a>.

On Windows 10 it's done like this (read left-to-right and top-to-bottom):

---

<div class="row">
<div class="col-md-6">
<img src="{{ site.s3_path }}/ffmpeg/1.jpeg" class="img-fluid" style="max-width: 70%">
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/ffmpeg/2.jpeg" class="img-fluid">
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/ffmpeg/3.jpeg" class="img-fluid">
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/ffmpeg/4.jpeg" class="img-fluid">
</div>
</div>

---

If you're on a different platform just look up how to set the PATH environment variable and you should be good.

# The Images

A video is just a sequence of images, so we first need to render each frame individually. For this I’m using the Pillow library for Python, but you can use whatever process you want, as long as you get an ordered sequence of image files at the end of it.

A digital image is a big grid of square pixels, each with an RGB value. To store the image I’m using a 3 dimensional NumPy array, the first two store each pixel location, and the third is a 3-tuple for the RGB values. This can also be called a ‘texture’. I’m also specifying the use of 8 bit integers, as the RGB values are bounded between 0 and 255 anyway, but it’s optional.

```python
self.outTexture = np.array([[[0, 0, 0]] * size] * size, np.uint8)
```

Rendering the image consists of literally just iterating over the array, and assigning colours to each pixel. Once complete, the texture is converted into a PIL image using ‘fromarray’, which happily enough is a-ok with taking a NumPy array. The image is then saved to the disk as a PNG file.

```python
for y in range(self.size):
  for x in range(self.size):
    outTexture[x, y] = self.stepJFA(np.array([x, y]), stepWidth)
```

```python
im = Image.fromarray(self.outTexture)
im.save(getFilename(index))
```

This can be done repeatedly to get a sequence of images. They must be named in order, for example I used the naming scheme “img#.png”, where # is the image’s place in the sequence. One pitfall is that numbers have to be left-padded with zeros up to the largest number of digits present, otherwise the ordering of the images gets screwed up during the video rendering process.

# The Video

Once the images are created and present in the working directory, you can run FFMPEG from the command line with the required arguments.

```python
ffmpeg -framerate 24 -i "img%03d.png" "out.mp4"
```

- `ffmpeg` is the program to be run.
- `-framerate` specifies the number of frames per second, the speed of the video. If you supply 48 images and set `-framerate` to 24, the video will last for two seconds.
- `-i` specifies the input files, and the string "`%03d`" inside the argument pattern matches against files numbered with 3 digit numbers, and orders them by this.
- The last argument `"out.mp4"` is the name of the output file that will be created.

In Python you can call command line EXEs from the program, using the `subprocess` library. The command is written and saved to a string variable, it is split into its constituent parts using the `shlex` library, and passed to `subprocess.check_call` to run it. I use Shlex to split the command instead of a simple `str.split(" ")` because command line commands have lots of annoying edge cases where this can break, so using `shlex` just lets it work.

```python
saveCommand  = "ffmpeg -framerate {} -i img%03d.png \"{}\"".format(frameRate, getOutFileName())
sp.check_call(shlex.split(saveCommand))
```

This will output the newly finished video in the working directory, and you’re done!

---

<div class="videoWrapper">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/-hZZf_u5ppc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

---

<a href="https://github.com/benmandrew/VoronoiJumpFlood">Here</a> is a link to the GitHub project if you want to have a look.
