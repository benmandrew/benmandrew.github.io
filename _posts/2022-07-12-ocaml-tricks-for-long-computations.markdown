---
layout:     post
title:      "OCaml Tricks For Long Computations"
date:       2022-07-12
categories: articles
tag:        "Article"
header:     headers/ocaml_tricks.jpeg
header_rendering: auto
banner: true
---

When running long computations in OCaml---typically deep recursive calls---it is common to run into issues that cause crashes; you may have run into a `Stack_overflow` exception or just straight-up run out of memory. In a high-level language like OCaml it's not always obvious why these errors occur and how one should fix them.

I recently wrote an LZW compressor that compresses ASCII text files. During development I ran into the issues described above, and so using it as an example will be a good demonstration of how the fixes are implemented and why they're useful in the real world.

<div style="padding-top: 1em;"></div>

---

# Tail Recursion

Consider the pseudo-code below for compressing a string of characters one codeword at a time:

```ocaml
let rec compress_aux input dict pos =
  if pos >= String.length input then []
  else
    let codeword, match_len = Dictionary.longest_match dict input pos in
    codeword :: (compress_aux input dict (pos + match_len))

let compress input =
  let dict = Dictionary.create () in
  compress_aux input dict 0
```

On line 5 we have computed our new `codeword`, and we cons it onto a list containing the rest of the codewords which will be computed by the recursive call to `compress_aux`. This is an intuitive way to traverse the input string, converting to codewords as we go.

However, when we run this code on a sufficiently large file we will run into a runtime `Stack_overflow` exception. This happens because on every recursive call we are adding a new copy of the function's stack frame onto the stack, quickly eating up the entire stack space.

To fix this, we must convert the function to recurse via a *tail call*, where the recursive call is the very last thing the function does. By the time the recursive call is reached, the function has completed all of its work and so doesn't need to save any state for later computations; thus, we can *reuse* the stack space used by the function's stack frame for the next function call's frame, maintaining the stack space instead of growing it. This is reminiscent of a for loop in an imperative language like C, where the space taken by one loop iteration it reused for the next iteration.

If we look at line 5 again, at first glance it may look like the recursive call is the last thing done by the function, but in fact the last operation is the cons of the codeword onto the list of other codewords generated by the recursive call. Thus, we have to maintain the stack frame, waiting for the result of the recursive call before we do a little more computation and return. How do we fix this?

Here is a tail-recursive version of the code:

```ocaml
let rec compress_aux input dict pos v_aux =
  if pos >= String.length input then List.rev v_aux
  else
    let v, match_len = Dictionary.longest_match dict s pos in
    compress_aux input dict (pos + match_len) (v :: v_aux)

let compress input =
  let dict = Dictionary.Comp.initialise () in
  compress_aux input dict 0 []
```

The changes (on lines 2 and 5) may seem a little unclear at first, but consider the fact that in effect we have just moved the cons-ing of the new codeword to be *before* the recursive call, now making it a *tail call* like we wanted. The `v_aux` variable is a list containing the work we have done so far, that we want to carry along with us through the chain of recursive calls; we are essentially doing the same computation as before, but backwards! This is shown by the base case of `compress_aux`, where we return the entire codeword list reversed to get it into the correct order.

Astute readers may have noticed that while the number of stack frames needed by this program is constant in the size of the input string, the list of codewords that we're passing through is still growing linearly with the number of recursive calls; why then do we not still see a `Stack_overflow` exception?

This is because lists (and strings) are not stored on the stack in OCaml, but allocated on the heap, which is a much larger and more forgiving area of memory. All that is stored in the stack is a pointer to the head element of the data structure in the heap. Details of the memory representations of such 'blocks' can be found [here](https://v2.ocaml.org/manual/intfc.html#s:c-ocaml-datatype-repr).

<div style="padding-top: 1em;"></div>

---

# Streams and Lazy Evaluation

When running *very* long computations, even the heap may not have enough space to hold the data that we are carrying along. When running the compressor on large files, I was running out of RAM and the OS was then killing the process.

The issue was that I was performing three memory-intensive tasks one after the other, with each depending on the full output of the last. The entire `.txt` file was read, then it was all compressed at once, then the entire compressed output was written to a `.bin` file. Doing with large files of course leads to all of the system memory being eaten up.

<img src="{{ site.s3_path }}/ocaml_tricks/1.png" class="img-fluid" style="max-width: 600px;">

We fix this by splitting the computation up into sequential chunks, doing a little bit of work in each stage and then going back to the beginning to do the next bit. As each chunk is independent we can disregard the previous chunk's data, allowing it to be garbage-collected by the OCaml runtime.

<img src="{{ site.s3_path }}/ocaml_tricks/2.png" class="img-fluid" style="max-width: 600px;">

This is relatively simple to do in an imperative language, but how do we do this in a functional language like OCaml? We use a technique called 'lazy evaluation' to produce a 'stream'. Critical to lazy evaluation is the following data-type:

```ocaml
type comp_stream = Fin of int list | Cons of int list * (unit -> comp_stream)
```

The final chunk of data (`Fin`) is represented simply as a list of integers as we'd expect, but the interesting part is the `Cons` pattern.

`Cons` firstly contains the chunk of data that we've computed (`int list`) but secondly contains a function that contains another instance of `comp_stream`! This is very similar to a linked list you may already be familiar with, except here the `comp_stream` value within the function body has not yet been evaluated; when we want to evaluate it we simply call the function with `()`. This allows us to delay the computation of the next chunk of data until we are ready to deal with it!

```ocaml
let rec compress_aux input dict pos v_aux chunk_i =
  if pos >= String.length input then
    Fin ( List.rev v_aux )
  else if chunk_i >= max_chunk_size then
    Cons
      ( List.rev v_aux,
        fun () -> compress_aux s dict pos [] 0 )
  else
    let v, match_len = Dictionary.Comp.longest_match dict input pos in
    compress_aux input dict (pos + match_len) (v :: v_aux) (chunk_i + 1)

let compress input =
  let dict = Dictionary.initialise () in
  compress_aux input dict 0 [] 0
```

We see on line 4 a new case for when we have filled a chunk of data: we return a `Cons` with the current progress so far (`List.rev v_aux`) and an anonymous function whose body contains the rest of the computation---a recursive call to `compress_aux`.

And we must now change how the `compress` function is used by the output system, creating `write_stream`:

```ocaml
let rec write_stream filename = function
  | Fin codewords ->
      write filename codewords
  | Cons (codewords, thunk) ->
      write filename codewords;
      write_stream filename (thunk ())
```

We see in the `Cons` case that we first write the data to file, and then call the function `thunk` containing the rest of the compression task, recursing back to `write_stream` to write the outputted codewords. These functions are usually called 'thunks' in general use. Now when we run the program, it can run indefinitely without running out of memory!\*

<div style="padding-top: 1em;"></div>
---

### Links

- The LZW coder in question ([https://github.com/benmandrew/Olzw](https://github.com/benmandrew/Olzw)), if you'd like to see how it actually works in practice.

<div style="padding-top: 1em;"></div>

---

\*The streaming system above doesn't quite work: the actual system would require the initial reading of the text file to be streamed into the compression step. However, I thought that demonstrating lazy evaluation with the compression step was a bit more fun than just reading a text file.
