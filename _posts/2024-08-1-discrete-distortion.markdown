---
layout:     post
title:      "Discrete Distortion"
date:       2024-08-11
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
    padding-bottom: 10px;
}
</style>

I've spent the past six weeks teaching English in Colombia, as a sort of holiday in the middle of a big life shift. To stop myself going crazy with little to do in the modest city of Ibagué, I managed to get a very cheap, very crap laptop to get programming on.

With the next few years of my life looking like they're going to be full of serious maths and proofs, I wanted a project that would combine my love of computers and visual art. I had the idea of generating interesting image effects in an *algorithmic* way.

Many commonly used image effects can be represented using linear or continuous approaches such as convolution, but I was interested in how a little bit of discrete behaviour could create completely new and interesting effects. In taking advantage of the messy, discrete nature of computers and data, I hoped to tie the images a little closer to the data formats they were encoded in and the hardware they were saved on, making some pretty pictures in the process.

In this article I'll demonstrate and explain some cool effects I came up with. You can try them out yourself using the publicly available [GitHub repo](https://github.com/benmandrew/distortion).

## Scaling and modulus

When messing around with scaling the brightness values of images, I ran into a strange phenomenon of colour discontinuities in the output images.

Imagine an image format where pixels can have a brightness from 0 to 1. If you multiply the value of every pixel by two, the range is now between 0 and 2. If you now take the modulo 1 for every pixel, those that are in the range of 1 to 2 will be shifted down to be within the acceptable range, shifting 1 to 0 and 2 to 1. This causes a discontinuity, with discontinuities appearing at the line where the brightness was originally 0.5.

This is exactly what I was seeing in my test images. First an image was read in, the red, green, and blue colour channels being converted from their single byte lengths (`unsigned char`) to `int`. Each channel was then scaled, critically resulting in some values being above the 255 `unsigned char` maximum. When an `int` is casted to `unsigned char`, the extra bits are "chopped off", effectively doing a modulo 256 operation.

As each colour channel is scaled individually, the discontinuities appear per-channel, leading to some interesting results.

It should also be possible to convert to other colour models, do the scaling and modulo, and then convert back to get interesting discontinuities dependent on other colour properties. For example you could use the hue, saturation, and value (HSV) colour model.

## Streaking

I thought an interesting effect might be created if I took the brightest pixels of the image and "streaked" them across, with the length of the streak depending on the luminance of the pixel. A streak of length $$n$$ is made simply by copying the pixel's value in a line of $$n$$ pixels, either up, down, left, or right, overwriting the previous values.

The function computing the length of the streak can be customised. I typically used an exponential weighting with various parameters for fine-grained control; without these it is easy to overpower the image, or produce little effect at all.

We can use the input image itself as the source for which pixels should be streaked and how much, or we could use a separate image for this, to change where streaking occurs. An example of this is detailed below.

## Edge detection

Kernels such as the Laplacian or Sobel operators can be used to detect edges in an image, producing larger values where there is higher local contrast, and smaller values where there is little. By themselves they can produce interesting images, but when used in conjunction with the discrete techniques already described, they massively expand what's possible.

By applying edge detection after the scaling and modulus technique described above, we can see strong contour lines appearing along the discontinuities.

This can then be used as a source for streaking, causing streaks in interesting places in the original image.

## Relative blocks

I had heard of the data compression technique of converting values from absolute to relative values, where for data with high local similarity, using relative values generally results in smaller numbers that can be represented with fewer bits of information. Inspired by this, I split the image into square blocks, taking a single center pixel as the only absolute value and subtracting its value from every pixel in the block, producing relative values.

For very small block sizes, because of local similarity this just leads to lots of uninteresting black. However, with larger blocks there are much more drastic changes of value, and so we see some interesting effects.

One thing to be aware of is the existence of *negative values*. If these are casted back to `unsigned char` then we will again see a modulo-like effect, except in this case underflowing to the top of the range. This can produce nice effects, but if you don't want it then you can first compute each pixel's absolute value before writing the image.

<!-- <div class="row">

<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane.jpg" class="img-fluid w-100" style="padding-bottom: 10px">
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-laplacian.jpg" class="img-fluid w-100" style="padding-bottom: 10px">
</div>

<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-block-streak-1.jpg" class="img-fluid w-100" style="padding-bottom: 10px">
</div>
<div class="col-lg-6">
<img src="{{ site.s3_path }}/distortion/kane-dct-8-bug.jpg" class="img-fluid w-100" style="padding-bottom: 10px">
</div>

</div> -->

<!-- [^1]: USD$150 for a 2-core Celeron B815, 8GB of RAM and a 256GB SSD. -->
