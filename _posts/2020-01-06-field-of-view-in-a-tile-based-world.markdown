---
layout:     post
title:      "Field-of-view in a Tile-based World"
date:       2020-01-06
categories: articles
header:     headers/visibility.jpg
---

One of my favourite parts of roguelikes is exploring the dungeon, revealing the map over time. It's a great way to show the player's progress, as well as creating tension in the claustrophobic environment. Having this feature in my roguelike game <a href="https://github.com/benmandrew/Andleite">Ändleite</a> was a must.

---

<img src="{{ site.s3_path }}/visibility/1.gif" class="img-fluid" style="image-rendering: pixelated">

---

In this article I'll describe a quick and dirty solution to the problem of computing this.It's not an efficient solution but from profiling Ändleite it's such a small part of the time allocation that it doesn't matter. If you're really desperate for an efficient version, <a href="http://journal.stuffwithstuff.com/2015/09/07/what-the-hero-sees/">this article</a> is a good start, and <a href="http://www.roguebasin.com/index.php?title=Field_of_Vision">here is a compilation</a> of approaches to the same problem.

#### The Data

I represent the tile-map as a 2D array of tile objects, making traversal very easy.

{% highlight cpp %}{% raw %}Tile grid[TILE_NUM_X][TILE_NUM_Y];{% endraw %}{% endhighlight %}

At a minimum, each tile has one of three states, VISIBLE, SEEN, and HIDDEN.

- Visible tiles are currently visible, and are rendered normally.
- Seen tiles have been visible previously, and are rendered normally but slightly darker and muted. Items and NPCs on seen tiles are not rendered.
- Hidden tiles have not been seen before, and are rendered as solid black.

{% highlight cpp %}{% raw %}enum TileVisibility {
  visible, seen, hidden
};{% endraw %}{% endhighlight %}

#### Computing Visibility

We repeatedly use Bresenham's Line Algorithm to march a ray along the grid from the player to some far away point, continuing until we hit a wall. All the non-wall tiles passed over on the way are marked as visible. The wall you collide with should also be marked as visible or it won't be rendered. We pick a sample of points evenly distributed in a circle around the player, and raymarch from the player's position to each of these points in turn. The number of points you distribute on the circle is a tradeoff between wasting cycles checking tiles you've already tested, and missing tiles that should be visible. The distance of the points from the player is a simple matter of picking a number that seems large enough that it'll never be encountered.

{% highlight cpp %}{% raw %}Vec2 raycastOffsets[N_RAYCAST];
float step = 2 * M_PI / N_RAYCAST;
for (int i = 0; i < N_RAYCAST; i++) {
  raycastOffsets[i] = {
  RAYCAST_DIST * cos(i * step),
  RAYCAST_DIST * sin(i * step)};
}{% endraw %}{% endhighlight %}

An alternative to distributing the points on a circle is to run the algorithm for every point within the area, rather than hoping that they'll be caught by lines traced from the centre to the circumference. While this does guarantee correctness, it traces over the same tiles many times repeatedly, making it very wasteful. There is also the issue that the radius of the circle can become very important, as the number of points in the circle grows with the square of the radius, so if you're not careful it can very quickly become a performance bottleneck. With the circumference distribution the number of points on the edge can be independent of the radius, as the correctness degrades only with distance from the centre, thus the radius can be arbitrarily large. This make it much more customisable, and in my opinion the better choice.

#### Bresenham's Line Algorithm

Developed in 1962 for computers slower than a school calculator, this algorithm traces a line between two points on a tiled grid. Originally used for drawing straight lines on a drum plotter, it has become a staple of computer graphics everywhere, and here we're repurposing it for checking the visibility from one point to another. One of the best things about the algorithm is that it works entirely with integers (no floats!) and only uses addition, subtraction and bit shifting. This makes it extremely efficient, a benefit that still holds true today.

However when looking up implementations of the algorithm on the internet, the version that always comes up works only for the 1st octant on the plane. While this version is very simple and expressive, it's next to useless. I do recommend you try and learn the simplified version before the full version, as it expresses the same fundamental ideas in a much simpler way (<a href="https://csustan.csustan.edu/~tom/Lecture-Notes/Graphics/Bresenham-Line/Bresenham-Line.pdf">here is a good explanation</a>).

I found the full algorithm <a href="https://stackoverflow.com/questions/11678693/all-cases-covered-bresenhams-line-algorithm">here</a>. In my code sample I have modified it to be a little more readable, and to quit if a wall is encountered. It also changes the tiles it encounters to visible.

{% highlight cpp %}{% raw %}inline Vec2 getDelta0(const Vec2 dim) {
  Vec2 delta = {0, 0};
  if (dim.x < 0) delta.x = -1; else if (dim.x > 1) delta.x = 1;
  if (dim.y < 0) delta.y = -1; else if (dim.y > 1) delta.y = 1;
  return delta;
}

inline Vec2 getDelta1(const Vec2 dim, const bool swapAxes) {
  Vec2 delta = {0 ,0};
  if (dim.x < 0) delta.x = -1; else if (dim.x > 1) delta.x = 1;
  if (swapAxes) {
    if (dim.y < 0) delta.y = -1; else if (dim.y > 0) delta.y = 1;
    delta.x = 0;
  }
  return delta;
}

void RayCaster::raycast(const Vec2 start, const Vec2 end) {
  Vec2 pos = start;
  const Vec2 dim = end - start;
  int longest = abs(dim.x);
  int shortest = abs(dim.y);
  bool wallCollision = false;
  bool swapAxes;
  if (swapAxes = (longest <= shortest)) {
    longest = abs(dim.y);
    shortest = abs(dim.x);
  }
  const Vec2 delta0 = getDelta0(dim);
  const Vec2 delta1 = getDelta1(dim, swapAxes);

  int numerator = longest >> 1 ;
  int i = 0;
  while (!wallCollision && i <= longest) {
    map->setTileVisibility(pos, TileVisibility::visible);
    wallCollision = isWallCollision(pos);
    numerator += shortest ;
    if (numerator >= longest) {
      numerator -= longest ;
      pos += delta0;
    } else {
      pos += delta1;
    }
    i++;
  }
}{% endraw %}{% endhighlight %}

#### Seen Tiles

Currently the implementation works great, a hidden map is slowly revealed to the player as they explore it. However I also want to distinguish between what the player is currently seeing, and what they've seen in the past. This is where the 'seen' property in the 'TileVisibility' enum comes in. I use the simple, brute-force approach of setting every 'visible' tile in the map to 'seen' at the beginning of the frame, before the visibility algorithm shown above is run. While this does mean many tiles are unnecessarily set from 'visible' to 'seen' to 'visible' again, the alternative algorithm would be so complex that it'd negate any benefit in efficiency.

{% highlight cpp %}{% raw %}for (int x = 0; x < TILE_NUM_X; x++) {
  for (int y = 0; y < TILE_NUM_Y; y++) {
    Tile* tile = &grid[x][y];
    if (tile->visibility == TileVisibility::visible) {
      tile->visibility = TileVisibility::seen;
      tile->updated = true;
    }
  }
}{% endraw %}{% endhighlight %}

To visually represent the 'seen' tiles, I just use the same sprites as for if they were 'visible', but filtered to be darker.

Once this is done, the system is finished!

---

<img src="{{ site.s3_path }}/visibility/2.gif" class="img-fluid" style="image-rendering: pixelated">

---

<a href="https://github.com/benmandrew/Andleite">Here</a> is a link to the Github project if you want to take a look. The files to look for are 'raycaster', 'map', and 'region' (both the '.h' and '.cpp' variants).

