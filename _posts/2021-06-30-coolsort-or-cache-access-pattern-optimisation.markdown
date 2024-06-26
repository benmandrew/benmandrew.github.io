---
layout:     post
title:      "CoolSort, or Cache Access Pattern Optimisation"
date:       2021-06-30
categories: articles
header:     headers/coolsort.png
tag:        "Article"
header_rendering: pixelated
banner: true
---

When programming in a language like C, assembly, or even machine code, we treat memory simply as a huge, linear array, uniformly accessed at all locations. While this is an incredibly useful abstraction for most software, for performant programs it is a very naïve view of things. Critically it ignores the presence of **caches**.

<img src="{{ site.s3_path }}/coolsort/hierarchy.png" class="img-fluid" style="width: 50%; max-width: 1000px">

A fundamental trade-off of memory is that bigger memories are generally slower to access. So while gigabytes and gigabytes of RAM are wonderful for storing lots of useful data, actually accessing that data is cripplingly slow, taking hundreds of CPU cycles. This in combination with the fact that practically all programs are constantly manipulating data means that we are being massively bottlenecked by memory access latency.

# Caches

The solution\* is to have a second smaller (and thus faster) memory, situated between the CPU and RAM, which stores data that we are likely to use in the future so that overall access latency is decreased.

Caches exploit two phenomena, locality of **time** and locality of **space**:

- Time locality is the fact that if a program accesses one location, it is likely that in the near future it will access the same location; think incrementing a counter. We exploit this by keeping recently accessed data in the cache.
- Space locality is the fact that if a program accesses one location, it is likely that in the future it will access data that is close by; think iterating over an array. We exploit this by storing not just the accessed data in the cache, but a 64 byte\*\* block (or cacheline) including it and its neighbours.

If we can work within the confines of a single cacheline, we will only do L1 cache accesses, increasing the speed of our program dramatically.

Most modern CPUs actually have multiple layers of caches, but we can ignore these and just program for the highest level of cache. It's also interesting to note that
CPU registers are at the extreme end of the size-latency trade-off, being tiny but ridiculously fast to access.

# Merge Sort and Insertion Sort

I won't go into too much detail on the sorting algorithms (their Wikipedia pages are good resources), but we can compare their cache performance and running times.

Merge sort has an optimal running time of O(nlogn), but it can potentially have bad cache performance due to not being an **in-place** algorithm: we repeatedly move data between two large arrays, which can cause cachelines to be repeatedly moved in and out of the cache from memory.

Insertion sort has a terrible running time of O(n<sup>2</sup>), but it sorts in-place, so if we sort an array that resides within a cacheline, we will not have to evict or retrieve any new cachelines and will thus have awesome performance.

# Combining Them

We can combine these two algorithms into one, to get the best of both worlds while minimising their respective drawbacks. I will take excessive creative liberty and name this new algorithm **CoolSort!**\*\*\*

We start with an unsorted array of integers, and conceptually slice it into subarrays of the size of the system's cachelines (64 bytes on most CPUs). Be careful that the array itself is cacheline-aligned, otherwise in doing this we would be purposefully sorting across block boundaries, thrashing the cache.

<img src="{{ site.s3_path }}/coolsort/sorting1.png" class="img-fluid" style="max-width: 600px;">

We then run insertion sort on each subarray individually.

<img src="{{ site.s3_path }}/coolsort/sorting2.png" class="img-fluid" style="max-width: 600px;">

Each subarray is now *locally* sorted, having been done so extremely quickly due to working only within a single cacheline.

A happy coincidence is that mergesort's merging step has only the precondition that both input arrays are sorted. In standard mergesort this is the output of a previous merging step (or two single-item arrays), but it doesn't have to be.

Using this information we can simply run a standard recursive merge, except that we start by merging arrays of cacheline size instead of single-item arrays. We then end up with our sorted array.

<img src="{{ site.s3_path }}/coolsort/sorting3.png" class="img-fluid" style="max-width: 600px;">

##### Running Time

We preserve our O(nlogn) running time as well. We can deduce this by analysing each step individually, the insertion step then the merge step. While insertion sort is O(n<sup>2</sup>), each subarray is a constant size, so the sorting of each subarray is O(1). The number of subarrays is proportional to the size of the array, so the total running time is O(n) for this step. The merge step is exactly the same as in a standard mergesort, except we remove a constant number of layers from the bottom of the binary tree of merges. Thus this keeps its O(nlogn) running time.
As the two steps are performed in sequence, the overall running time is O(n+nlogn)=O(nlogn).


# The Code
The insertion sort function, with compile-time constants defining the number of integers in a cacheline.

```c
#define CACHELINE_SIZE 64
#define INTS_IN_CACHELINE (CACHELINE_SIZE / sizeof(int))

int* insertionsort(int* a, size_t n) {
  // Iterate over each subarray
  for (size_t run = 0; run < n; run += INTS_IN_CACHELINE) {
    // Sort subarray
    size_t i = run + 1;
    while (i < run + INTS_IN_CACHELINE) {
      size_t j = i;
      while (j > run && a[j-1] > a[j]) {
        size_t tmp = a[j-1];
        a[j-1] = a[j];
        a[j] = tmp;
        j--;
      }
      i++;
    }
  }
  return a;
}
```

The merge sort functions.

```c
void merge(int* a, size_t left, size_t right, size_t end, int* b) {
  size_t i = left, j = right;
  for (size_t k = left; k < end; k++) {
    if (i < right && (j >= end || a[i] <= a[j])) {
      b[k] = a[i];
      i++;
    } else {
      b[k] = a[j];
    j++;
    }
  }
}

int* mergesort(int* a, size_t n) {
  int* b = (int*)malloc(n * sizeof(int));
  // Switches us between the primary (a) and auxiliary (b) arrays
  char isPrimaryArr = 1;
  for (size_t width = INTS_IN_CACHELINE; width < n; width *= 2) {
    // Merge runs together of increasing size
    for (size_t i = 0; i < n; i += 2 * width) {
      // Alternate between the a and b arrays
      if (isPrimaryArr) {
        merge(a, i, minimum(i + width, n), minimum(i + 2 * width, n), b);
      } else {
        merge(b, i, minimum(i + width, n), minimum(i + 2 * width, n), a);
      }
    }
    isPrimaryArr = !isPrimaryArr;
  }
  if (!isPrimaryArr) copy(b, a, n);
  free(b);
  return a;
}
```

And the very simple composition of the two.

```c
int* coolsort(int* a, size_t n) {
  a = insertionsort(a, n);
  return mergesort(a, n);
}
```

# Testing Results

Here are the results of some crude testing, just to give a rough idea of actual performance. The program was compiled using GCC's -O3 optimisation level, and testing was performed on an Intel I5-5300U CPU ([spec sheet](https://ark.intel.com/content/www/us/en/ark/products/85213/intel-core-i55300u-processor-3m-cache-up-to-2-90-ghz.html)).

Arrays of increasing powers of 2 were sorted, with measurements taken using the Unix `time` tool.

The logX-Y and X-Y graphs include Insertion sort for comparison of asymptotic running times, but make it hard to compare Mergesort and Coolsort, which is what we're interested in.

<img src="{{ site.s3_path }}/coolsort/logx-y.png" class="img-fluid" style="max-width: 500px;">

The X-Y graph in particular highlights just how bad a running time of O(n<sup>2</sup>) really is.

<img src="{{ site.s3_path }}/coolsort/x-y.png" class="img-fluid" style="max-width: 500px;">

We plot the execution time of Coolsort as a percentage of Mergesort's execution time to better compare the two. We see the error on both measurements by the light blue bounds, showing the lack of precision of the timer.

<img src="{{ site.s3_path }}/coolsort/ratio.png" class="img-fluid" style="max-width: 500px;">

We can see that Coolsort is reliably between 80 and 95% of the running time of Mergesort, which is a comfortable improvement.

### Useful Links

- [Source code (GitHub)](https://github.com/benmandrew/CoolSort)
- [Useful article on general cache programming](http://igoro.com/archive/gallery-of-processor-cache-effects/)

---

- \*The actual solution is a fundamental change in computer architecture, see the Von Neumann bottleneck if you're interested.
- \*\*Most CPUs use a 64 byte cacheline, which is maintained all the way down the cache hierarchy: one of the reasons we can program for just the L1 cache.
- \*\*\*I hope it's obvious but I should probably say that I didn't come up with this idea. The name I *can* take credit for, unfortunately.
