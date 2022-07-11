---
layout:     post
title:      "Ray-tracing with Bounding Volume Hierarchies"
date:       2020-02-06
categories: articles
header:     headers/bvh.jpg
tag:        "Article"
header_rendering: auto
---

When naively raytracing (with triangle primitives), for n rays and m triangles there are mn intersection tests, as every ray must check for intersection with every triangle in the scene (ignoring triangle culling).

---

<div class="row align-items-center">
<div class="col-md-6">
{% highlight cpp %}{% raw %}for (Ray ray : rays) {
  for (Triangle triangle : triangles) {
    if (ray.intersectsWith(triangle)) {
      drawPixel();
    }
  }
}{% endraw %}{% endhighlight %}
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/bvh/1.jpg" class="img-fluid" style="width: 60%">
</div>
</div>

---

<div class="row">
<div class="col-md-6">
This cost can be reduced with a spatial partitioning data structure, which groups primitives that are close together. This is useful because you can surround each group with some 'bounding volume' (BV), e.g. a sphere, and test intersections of the rays with the volume. If it doesn't intersect, then you are guaranteed that the ray does not intersect with any of the primitives in the group, as the volume surrounds the group. Thus you can completely ignore that group, saving on lots of useless computation.
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/bvh/2.jpg" class="img-fluid">
</div>
</div>

---

<div class="row">
<div class="col-md-6">
If the BV is intersected with, then we need to check intersections with all the primitives in the group, as intersection with the BV only says that there 'may' be an intersection with a primitive in the group. It is very common for rays intersecting with the BV to completely miss all the primitives in the group.

We can do this process multiple times, further partitioning groups of primitives into smaller and smaller groups, and creating a tree of bounding volumes. This is called a bounding volume hierarchy (BVH).
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/bvh/7.gif" class="img-fluid">
</div>
</div>

---

<div class="row">
<div class="col-md-6">
For the BVH to have good performance, we ideally want every BV on a given level to be completely separate from each other, i.e. not intersecting one another. They should also conform as tightly as possible to the shape of the group, to minimise wasted intersection checks, and the tree should be as balanced as possible so that as many primitives as possible can be ignored during intersection testing. This maintains as closely as possible the O(nlogm) running time we're looking for with this data structure.
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/bvh/3.jpg" class="img-fluid">
</div>
</div>

---

<div class="row">
<div class="col-md-6">
The choice of the bounding volume is a tradeoff between conforming tightly to the shape of the group, and the speed of intersection tests with rays. We can use anything from spheres, which are incredibly cheap to test intersection with but risk unnecessarily huge volumes, and convex hulls, which fit the group perfectly but can be arbitrarily expensive to test intersections against. Personally I found spheres to be the fastest option, but I would recommend testing out axis-aligned bounding boxes if you have the time. <a href="https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection">Here</a> is a good tutorial on ray-sphere intersection algorithms.
</div>

<div class="col-md-6">
<img src="{{ site.s3_path }}/bvh/4.jpg" class="img-fluid" style="width: 50%">
</div>
</div>

---

I will be making a binary tree as these are by far the most common, but there's nothing stopping you from making a tree of higher degree.

---

<div class="row">
<figure class="col-6">
<img src="{{ site.s3_path }}/bvh/5.jpg" class="img-fluid" style="width: 80%">
</figure>
<figure class="col-6">
<img src="{{ site.s3_path }}/bvh/6.jpg" class="img-fluid" style="width: 80%">
</figure>
</div>

---

A non-ideal case of a sphere hierarchy, and a *really* non-ideal case.

##### Constructing the BVH

I'll be starting with a 3D model imported from a '.obj' file, a triangle mesh represented as an array of triangles. In my implementation I only use vertex information, no normals or UVs, as they're unrelated to the BVH, and implementing them is it's own task.

As we're making a binary BVH, at every level we split the group of triangles into two groups. This splitting should be done so that each group is as spatially distinct as possible from the other. My quick and dirty solution is to calculate the variance in position of all the triangles in each dimension, relative to the centre of the BV of the group. In the process I also calculate the means position of the triangles. Then I find the dimension with the greatest variance as split along that axis, using the previously found mean position to get the mean along the splitting axis, defining the axis aligned plane that splits the triangles into two groups.

{% highlight cpp %}{% raw %}// Get the axis with the greatest variance
Axes::Axes getAxis(Vec3 variance) {
  // Variance is stored in a 3-vector ordered by axis
  if (variance.x > variance.y && variance.x > variance.z) return Axes::x;
  else if (variance.y > variance.z) return Axes::y;
  else return Axes::z;
}

// Calculate the variance of the positions of the triangle centers
// in each axis, and return the axis with the greatest variance
Axes::Axes BVHNode::calcAxisWithGreatestVariance() {
  Vec3 mean, sumOfSqrs;
  for (int i = 0; i < triangles.size(); i++) {
    // Using Welford's method for computing variance
    Vec3 center = triangles[i].getCenter();
    Vec3 oldMean = mean;
    mean = mean + (center - mean) / (float)(i + 1);
    sumOfSqrs = sumOfSqrs + (center - mean) * (center - oldMean);
  }
  return getAxis(sumOfSqrs);
}{% endraw %}{% endhighlight %}

[Welford's method for computing variance](https://jonisalonen.com/2013/deriving-welfords-method-for-computing-variance/).

This approach is far from ideal, and has many cases with pretty awful BV choices for the subgroups. But it works, and improvement on it is left as an exercise for the reader :).

Once we have our two subgroups, we calculate the mean position of each subgroup, and find the minimum radius of each sphere that completely covers each subgroup, by iterating over each vertex in the subgroup and calculating the distance to the mean position. Once done, we have two new BVs for our subgroups, and we can recurse downwards again!

{% highlight cpp %}{% raw %}// Partition the triangles into two groups
void BVHNode::partition(Model* model) {
  std::vector&lt;Triangle&gt; leftPartitionTriangles;
  std::vector&lt;Triangle&gt; rightPartitionTriangles;
  Axes::Axes greatestVarianceAxis = calcAxisWithGreatestVariance();
  // Partition along the axis with the greatest variance in triangle position
  switch (greatestVarianceAxis) {
    case Axes::x:
      partitionX(leftPartitionTriangles, rightPartitionTriangles);
      break;
    case Axes::y:
      partitionY(leftPartitionTriangles, rightPartitionTriangles);
      break;
    case Axes::z:
      partitionZ(leftPartitionTriangles, rightPartitionTriangles);
      break;
  }
  // Initialise the children of the node using the two separated groups
  child0 = std::make_unique&lt;BVHNode&gt;(leftPartitionTriangles, model);
  child1 = std::make_unique&lt;BVHNode&gt;(rightPartitionTriangles, model);
}{% endraw %}{% endhighlight %}

A major choice during the BVH construction is when to stop recursing down. We might naively keep going until we get a subgroup with a single element that can't be split any further, but this only adds a rather unnecessary check when we should just be intersection testing against the triangle. With such small groups of triangles the benefits of a BVH can be quickly outweighed by it's overhead.

This is a similar way of thinking to the way that the most efficient sorting algorithms are implemented, with quicksort at a high level for it's asymptotic O(nlogn) running time, then when the sizes of the arrays to be sorted are reduced to a low enough number switching to insertion sort. Even though insertion sort has an O(n^2) running time, it can be quicker than quicksort on these small array slices due to quicksort's overhead.

The approach I used was to just pick a minimum number of triangles that each group could have, and if a subgroup had that or below (due to splitting a group of size just above the minimum) then it wouldn't recursively split and would instead store the triangles in it's group.

{% highlight cpp %}{% raw %}// If the number of triangles is above the maximum, partition,
// else identify itself as a leaf node in the tree
void BVHNode::build(Model* model) {
  isLeaf = true;
  if (triangles.size() > maxTriangleNumPerLeaf) {
    partition(model);
    // Free memory
    std::vector&lt;Triangle&gt;().swap(triangles);
    triangles.clear();
    isLeaf = false;
  }
}{% endraw %}{% endhighlight %}

##### Rendering with the BVH

As stated before, we test for intersection with the BV, and if that is true then we recursively test for intersection with it's children.

{% highlight cpp %}{% raw %}bool BVHNode::rayIntersection(const Ray& ray, float& t, int& triangleIndex) {
  if (!raySphereIntersection(ray)) {
    return false;
  }
  else if (isLeaf) {
    // Test for intersection with the triangles of the leaf node
    return rayTrianglesIntersection(ray, t, triangleIndex);
  }
  else {
    // Recursively test for intersection with child nodes
    return recurseRayIntersection(ray, t, triangleIndex);
  }
}{% endraw %}{% endhighlight %}

The in-depth implementation of the BVH, along with a lot of extras, can be found [here](https://mainbucketbenandrew.s3.amazonaws.com/lux/ProjectLux.pdf), along with a code repo [here](https://github.com/benmandrew/ProjectLux).

Thanks for reading, and I hope it's been helpful! :)
