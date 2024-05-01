---
layout:     post
title:      "Custom Post-Processing Effects in Unity"
date:       2020-09-28
categories: articles
header:     headers/postprocessing.jpg
tag:        "Article"
header_rendering: auto
banner: true
---


Writing your own custom post-processing effects in Unity is possible and fast, but is not very well documented at all. Typically to do post-processing in Unity you would use the built-in post-processing stack that allows you to simply enable or disable a number of standard effects like anti-aliasing, bloom, and chromatic aberration, to name a few. The enabled effects are combined into a single pass, making them extremely fast, and the entire system is super easy to use.

<img src="{{ site.s3_path }}/postprocessing/processing.jpeg" class="img-fluid">

However the post-processing stack is quite limited in what it offers, especially if very specific effects are needed. To remedy this we can write our own custom post-processing effects using shaders, but this requires some knowledge and effort to get working in Unity, which is what this article is about!

### Key Terms

##### RenderTexture

A RenderTexture (RT) is a script representation of a texture on the GPU, that gives us a handle to reference the texture when we want to manipulate it, or access its metadata. We can set a scene camera to render to a RT instead of to the screen, allowing us to do post-processing effects, or to allow secondary cameras for specific purposes, such as dynamic shadows or in-game surveillance cameras.


##### Blitting

Blitting is the act of copying data from one RenderTexture to another, typically manipulating the data in some way with a shader. The shader is run once for each pixel in the destination RT, so if the two RTs are differently sized, the pixels in the input RT will be interpolated between, potentially using lower levels of the mipmap if the input RT is smaller (and mipmaps are enabled).


### Camera rendering to a RenderTexture

By default, the main camera will render directly to the screen, but we can instead set it to render to an intermediate RT for post-processing, which Unity allows you to do with this function:

{% highlight cs %}{% raw %}void OnRenderImage(RenderTexture src, RenderTexture dst);{% endraw %}{% endhighlight %}

The script with this function must be attached to the GameObject that has the camera on it. 'src' is the direct input from the camera, and 'dst' is the output to the screen The most basic working version of this function looks like:

{% highlight cs %}{% raw %}void OnRenderImage(RenderTexture src, RenderTexture dst) {
  Graphics.Blit(src, dst);
}{% endraw %}{% endhighlight %}

<img src="{{ site.s3_path }}/postprocessing/default.jpeg" class="img-fluid">

which directly blits the input to the output with no processing, essentially doing the exact same thing as if we didn't implement 'OnRenderImage' at all. However 'Graphics.Blit' has a third optional parameter where we can specify a shader/material to be used during the blitting process, and this is where we can add custom effects.


### Custom Screen-Space Shaders

We start by creating an 'Image Effect Shader' asset and a 'Material' asset from Unity's project tab.

<img src="{{ site.s3_path }}/postprocessing/project.png" class="img-fluid" style="max-width: 400px;">

Shaders must be attached to a material in order to be run during a blitting operation.

On opening the shader in a text editor, there is a lot of stuff to see, but there are only a couple of relevant sections. First, on the top line change 'Hidden' to 'Custom', so that the shader is actually visible in the editor. Why this isn't the default is beyond me.

{% highlight cs %}{% raw %}Shader "Custom/Main" {{% endraw %}{% endhighlight %}

In the editor, we can now assign the shader to the material.

<img src="{{ site.s3_path }}/postprocessing/set_mat.png" class="img-fluid" style="max-width: 400px;">

From here the only relevant section is the 'frag' function and variable definition near the bottom.

{% highlight cs %}{% raw %}sampler2D _MainTex;

fixed4 frag (v2f i) : SV_Target {
  fixed4 col = tex2D(_MainTex, i.uv);
  // just invert the colors
  col.rgb = 1 - col.rgb;
  return col;
}{% endraw %}{% endhighlight %}

The variable definition outside of the function defines variables that can be passed into the shader from scripts outside the program, in this case the main texture, but also allowing floats and other arbitrary data. The 'frag' function is the fragment shader, the program run for each pixel in the destination RT. The UV coordinates of the pixel are passed into the function, allowing us to do a texture read on the first line, reading in the colour at that point on the input texture. The next line simply inverts the colour, and then returns it, writing it to the output RT.

<img src="{{ site.s3_path }}/postprocessing/inverse.jpeg" class="img-fluid">

Using this we can do any arbitrary manipulation of colours, which you can do an awful lot with, but a more interesting technique to me is the manipulation of UV coordinates, for which I will introduce the technique of passing data to shaders.


### Passing Data to Shaders

For this example I will be creating a water ripple effect that will simulate the effect of water dripping over the lens of the camera. This will require us to use a noise texture to displace the UV coordinates, and a time-dependent float offset so that the water droplets appear to move downwards.

The noise texture can be downloaded <a href="https://mainbucketbenandrew.s3.amazonaws.com/images/postprocessing/noise.png">here</a>, or found in the Github project link at the bottom. Underneath the '_MainTex' variable definition, define two new variables.

{% highlight cpp %}{% raw %}sampler2D _MainTex;
sampler2D _NoiseTex;
float _NoiseOffset;{% endraw %}{% endhighlight %}

and replace the contents of the fragment function with these lines.

{% highlight cpp %}{% raw %}fixed2 noiseOffset = fixed2(0, _NoiseOffset);
// Scale the magnitude of the effect to taste
fixed2 mainOffset = tex2D(_NoiseTex, i.uv + noiseOffset).rg * 0.02;
fixed4 col = tex2D(_MainTex, i.uv + mainOffset);
return col;{% endraw %}{% endhighlight %}

In both 'tex2D' calls you can see the UV coordinate we are using is being offset, first by the time variable and second by the noise texture, and so it reads in the value from a different point on the corresponding texture. The effect of the first offset scrolls the noise texture downwards over time, by moving the sampled point upwards over time. The second offset displaces the point on the input texture by some random amount (according to the noise texture), creating a ripple effect.


In the script attached to the camera's GameObject, I add member variables for the material and noise texture, and Start and FixedUpdate member functions that pass the data to the shader. The noise texture is passed once as it doesn't change, but the noise texture offset changes with time so must be updated continuously.

{% highlight cs %}{% raw %}public class PostProcessing : MonoBehaviour {
  public Material mat;
  public Texture2D noiseTex;

  void Start() {
    mat.SetTexture("_NoiseTex", noiseTex);
  }

  void FixedUpdate() {
    // Scale speed of water droplets
    mat.SetFloat("_NoiseOffset", Time.time * 0.05f);
  }

  void OnRenderImage(RenderTexture src, RenderTexture dst) {
    Graphics.Blit(src, dst, mat);
  }
}{% endraw %}{% endhighlight %}

These public member variables are set in the editor.

<img src="{{ site.s3_path }}/postprocessing/camera.png" class="img-fluid" style="max-width: 400px;">

And with that, you can run the program in the editor and see it work! (Sorry about the laggy video, my recording software is bad)

---

<div class="videoWrapper">
<iframe width="560" height="349" src="https://www.youtube.com/embed/l4NTmwdDKXw" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

---

<a href="https://github.com/benmandrew/WaterRipple">Here</a> is the link to the project. As an extra challenge, see if you can implement Gaussian blur using multiple 'tex2D' calls on the same texture with different UV coordinates, and adding the results!

<img src="{{ site.s3_path }}/postprocessing/ripple.jpeg" class="img-fluid">

---

### Extra: Creating the Noise Texture

While not strictly related to the article, the creation of the noise texture was quite interesting and took a bit of finangling to do.

<img src="{{ site.s3_path }}/postprocessing/noise.png" class="img-fluid"  style="max-width: 350px; width: 80%; image-rendering: pixelated">

The difficulty lay in displacing the UV coordinates in both axes in a dependent way, as would be in real life. I took a greyscale Perlin noise texture from a google search and found the vertical and horizontal numerical derivatives, essentially doing edge detection in both directions. This was done with a <a href="https://en.wikipedia.org/wiki/Sobel_operator">Sobel filter</a>.

<img src="{{ site.s3_path }}/postprocessing/sobel.png" class="img-fluid"  style="max-width: 400px; width: 100%; image-rendering: pixelated">

These two derivative images, being one channel each, were combined into a single three channel (RGB) image, with the last channel filled with zeroes, as a third channel is required for textures (If you're clever you can put something else in this channel so it doesn't go to waste).

This then results in the image above, and in the shader we take the R and G components as the XY displacement vector. My version of this is not ideal, as the Sobel filter results in some negative values but I saved the image as a PNG, which clamps them non-negative. A better alternative would be to save the noise texture as a three channel floating point texture that allows negative values. A larger texture may also help!
