---
layout:     post
title:      "Discrete Distortion"
date:       2024-08-16
categories: articles
tag:        "Article"
header:     headers/distortion.jpg
header_rendering: auto
separate_banner: true
banner_header: distortion/distortion-banner.jpg
fullwidth: true
---

<style>
p:not(.post-meta), h2 {
    max-width: 43.25rem;
    margin: auto;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
}
div {
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
}
div.row {
    justify-content: center;
}
img.pixelated {
    image-rendering: pixelated;
}
</style>

I've spent the past six weeks teaching English in Colombia, as a sort of holiday in the middle of a big life shift. To stop myself going crazy with little to do in the modest city of Ibagué, I managed to get a very cheap, very crap laptop to get programming on.

With the next few years of my life looking like they're going to be full of serious maths and proofs, I wanted a project that would combine my love of computers and visual art. I had the idea of generating interesting image effects in an *algorithmic* way.

Many commonly used image effects can be represented using linear or continuous approaches such as convolution, but I was interested in how a little bit of discrete behaviour could create completely new and interesting effects. In taking advantage of the messy, discrete nature of computers and data, I hoped to tie the images a little closer to the data formats they were encoded in and the hardware they were saved on, making some pretty pictures in the process.

In this article I'll demonstrate and explain some cool effects I came up with. You can try them out yourself using the publicly available [GitHub repo](https://github.com/benmandrew/distortion).

(All photos are my own.)

## Scaling and modulus

When messing around with scaling the brightness values of images, I ran into a strange phenomenon of colour discontinuities in the output images.

<div class="row">
<div class="col-md-6">
<img src="{{ site.s3_path }}/distortion/fin-mod-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-md-6">
<img src="{{ site.s3_path }}/distortion/fin-mod-2.jpg" width="100%" height="auto">
<p>With scaled pixel values</p>
</div>
</div>

To understand why this happens, imagine an image format where pixels can have a brightness from $$0$$ to $$1$$. If you multiply the value of every pixel by two, the range is now between $$0$$ and $$2$$. If you now take the $$\text{mod} \; 1$$ for every pixel, those that are in the range of $$1$$ to $$2$$ will be shifted down to be within the acceptable range, shifting $$1$$ to $$0$$ and $$2$$ to $$1$$. This causes *discontinuities* to appear at the line where the brightness was originally $$0.5$$.

This is exactly what I was seeing in my test images. First an image was read in, the red, green, and blue colour channels being converted from their single byte lengths (`unsigned char`) to `int`. Each channel was then scaled, resulting in some values being above the 255 `unsigned char` maximum. When an `int` is casted to `unsigned char`, the extra bits are "chopped off", effectively doing a $$\text{mod} \; 256$$ operation. As each colour channel is scaled individually, the discontinuities appear per-channel, leading to some interesting results.

<div class="row">
<div class="col-sm-4">
<img src="{{ site.s3_path }}/distortion/tim-mod-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-sm-4">
<img src="{{ site.s3_path }}/distortion/tim-mod-2.jpg" width="100%" height="auto">
<p>Black-and-white, scaled</p>
</div>
<div class="col-sm-4">
<img src="{{ site.s3_path }}/distortion/tim-mod-3.jpg" width="100%" height="auto">
<p>Original, scaled</p>
</div>
</div>

You may notice that the discontinuities in the scaled images often have strange, blocky appearances, rather than continuous, smooth lines or more uniform sensor noise. This is the usually imperceptible error in JPEG compression made visible.

## Streaking

I thought an interesting effect might be created if I took the brightest pixels of the image and "streaked" them across, with the length of the streak depending on the luminance of the pixel. A streak of length $$n$$ is made simply by copying the pixel's value in a line of $$n$$ pixels, either up, down, left, or right, overwriting the previous values.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-streak-1.jpg" class="pixelated" width="100%" height="auto">
<p>Small streaks</p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-streak-2.jpg" class="pixelated" width="100%" height="auto">
<p>Large streaks, skipping pixels</p>
</div>
</div>

The function computing the length of the streak can be customised. I typically used a polynomial weighting with various parameters for fine-grained control; without these it is easy to overpower the image, or produce no effect at all.

$$\text{streaklen} = c_1 \cdot \Big( \frac{\text{luminosity}}{256} \Big)^{c_2}$$

We can use the input image itself as the source for which pixels should be streaked and how much, or we could use a separate image for this, to change where streaking occurs. For example, we can streak more where there is more contrast in the image using edge-detection techniques, which are described below.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/megan-streak-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/megan-streak-2.jpg" width="100%" height="auto">
<p>Streaked according to edges</p>
</div>
</div>

## Edge detection

Discrete convolution kernels such as the Laplacian or Sobel operators can be used to detect edges in an image, producing larger values where there is higher local contrast, and smaller values where there is little. By themselves they can produce interesting images, but when used in conjunction with the discrete techniques already described, they massively expand what's possible.

Both kernels can produce negative values. Typically we might take the absolute value of each pixel to normalise it, but we can instead take the $$\text{mod} \; 256$$ so that the negative values *wrap around*, underflowing to the maximum.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-sobel-underflow.jpg" class="pixelated" width="100%" height="auto">
<p>Underflowed horizontal Sobel operator</p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-laplacian-underflow.jpg" class="pixelated" width="100%" height="auto">
<p>Underflowed Laplacian operator</p>
</div>
</div>

By applying edge detection after the scaling and modulus technique described above, we can see strong RGB contour lines appearing along the discontinuities.

<div class="row">
<div class="col-md-6">
<img src="{{ site.s3_path }}/distortion/fin-laplacian-mod.jpg" width="100%" height="auto">
<p></p>
</div>
<div class="col-md-6">
<img src="{{ site.s3_path }}/distortion/kane-laplacian-mod.jpg" width="100%" height="auto">
<p></p>
</div>
</div>

We could instead apply the scaling and modulus *after* the edge detection, exposing some of the discrete errors caused by JPEG compression.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/shoe-laplacian-mod-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/shoe-laplacian-mod-2.jpg" class="pixelated" width="100%" height="auto">
<p>Laplacian operator, scaled</p>
</div>
</div>

This can then be used as a source for streaking, causing streaks in interesting places in the original image.

## Colour models

The standard of using Red, Green, and Blue (RGB) channels to represent colours is just one option of many. Other more intuitive models exist, such as the Hue, Saturation, and Value (HSV) model. By converting into this colour model we can directly manipulate properties that are more interesting than just the amount of red, green, or blue.

If we add to the H (hue) channel, we can "rotate" the hue around the entire $$360°$$ colour wheel. To do this process we first convert from RGB to HSV, add some value to the H channel, then convert back to RGB.

<div class="row">
<div class="col-6 col-lg-3">
<img src="{{ site.s3_path }}/distortion/malachy-hue-rot-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-6 col-lg-3">
<img src="{{ site.s3_path }}/distortion/malachy-hue-rot-2.jpg" width="100%" height="auto">
<p>90° clockwise hue rotation</p>
</div>
<div class="col-6 col-lg-3">
<img src="{{ site.s3_path }}/distortion/malachy-hue-rot-3.jpg" width="100%" height="auto">
<p>180° clockwise hue rotation</p>
</div>
<div class="col-6 col-lg-3">
<img src="{{ site.s3_path }}/distortion/malachy-hue-rot-4.jpg" width="100%" height="auto">
<p>270° clockwise hue rotation</p>
</div>
</div>

Another possibility is that instead of converting back to RGB, we can simply treat the HSV values as if they were RGB and write them directly to the output image.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-hsv-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-hsv-2.jpg" width="100%" height="auto">
<p>HSV</p>
</div>
</div>

We can also use the "scaling and modulus" technique seen above, choosing which channels we want to modify.

<div class="row">
<div class="col-lg-4">
<img src="{{ site.s3_path }}/distortion/kane-hsvmod.jpg" width="100%" height="auto">
<p>All HSV channels scaled</p>
</div>
<div class="col-lg-4">
<img src="{{ site.s3_path }}/distortion/kane-huemod-5.jpg" width="100%" height="auto">
<p>Hue channel scaled 5x</p>
</div>
<div class="col-lg-4">
<img src="{{ site.s3_path }}/distortion/fin-huemod-16.jpg" width="100%" height="auto">
<p>Hue channel scaled 16x</p>
</div>
</div>

## Relative blocks

I had heard of the data compression technique of converting values from absolute to relative values, where for data with high local similarity, using relative values generally results in smaller numbers that can be represented with fewer bits of information. Inspired by this, I split the image into square blocks, taking a single center pixel as the only absolute value and subtracting its value from every pixel in the block, producing relative values.

For very small block sizes, because of local similarity this just leads to lots of uninteresting black. However, with larger blocks there are much more drastic changes of value, and so we see some interesting effects.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-block-1.jpg" width="100%" height="auto">
<p>Original</p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-block-2.jpg" width="100%" height="auto">
<p>Relative blocks</p>
</div>
</div>

One thing to be aware of is the existence of *negative values*. If these are casted back to `unsigned char` then we will again see a modulo-like effect, except in this case underflowing to the top of the range. This can produce nice effects, but if you don't want it then you can first compute each pixel's absolute value before writing the image.

## Combinations

The described techniques can be combined together in different ways to produce some cool results. Thanks for reading.

<div class="row">
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-block-mod-laplacian-streak.jpg" class="pixelated" width="100%" height="auto">
<p></p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/fin-block-mod-laplacian-streak.jpg" class="pixelated" width="100%" height="auto">
<p></p>
</div>
<div class="col-lg-12">
<img src="{{ site.s3_path }}/distortion/megan-block-mod-laplacian-streak.jpg" class="pixelated" width="100%" height="auto">
<p></p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-block-streak.jpg" class="pixelated" width="100%" height="auto">
<p></p>
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/poster.jpg" class="pixelated" width="100%" height="auto">
<p></p>
</div>
</div>

<!-- [^1]: USD$150 for a 2-core Celeron B815, 8GB of RAM and a 256GB SSD. -->
