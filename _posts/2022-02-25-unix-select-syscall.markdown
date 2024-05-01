---
layout:     post
title:      "Using the select System Call in Unix"
date:       2022-02-25
categories: articles
header:     headers/select.png
tag:        "Article"
header_rendering: auto
banner: false
---

Often in our programs we want to be able to respond to external events, with distinct responses for distinct events. We may want to wait for a timer to fire, wait to receive some data from the network, or wait for a keypress. One option is to use a 'busy-loop', checking each of our events in turn - handling them if they've occurred - then going right back to the start and doing it all over again. This is a massive waste of CPU power, as the processor is checking over and over again with tiny intervals in between, hogging CPU time from other processes that may actually be doing something useful.


{% highlight c %}{% raw %}while (true) {
  if (fileIsReady) {
  ...
  } else if (...) {
  ...
  }{% endraw %}{% endhighlight %}

Ideally we want to be able to 'pause' our program until we have something to do, resuming when we're able to do useful work. It's not immediately clear how one would do this purely within the language, but luckily C allows interaction with the operating system via **system calls**. Interacting with the OS allows us to be a good samaritan by giving up control of the CPU when we don't need it, allowing other processes to do stuff. In return the OS will be nice and give us back control when useful work arrives.

It's commonly said that in Unix, everything is a file. We can see with with I/O when we write to `stdout` and read from `stdin`. Both of these are simply file descriptors, represented by integers. We see a similar pattern with sockets, timers, and many other OS services.

The `select` system call gives us the ability to wait on a set of arbitrary file descriptors, giving control back to the OS while no work exists and being given it back when one or more are ready to be used. We then check which of the descriptors is ready in code, and handle the required case. We would then typically loop, handing back control to the OS until the descriptors are ready again.

The [man page](https://man7.org/linux/man-pages/man2/select.2.html) is a little dense, so we'll walk through it step-by-step:

{% highlight c %}{% raw %}int select(
  int nfds,
  fd_set *restrict readfds,
  fd_set *restrict writefds,
  fd_set *restrict exceptfds,
  struct timeval *restrict timeout);{% endraw %}{% endhighlight %}

We first look at the select system call at the top.

`nfds` is confusingly enough *not* the number of file descriptors that we're passing through, but the highest-numbered descriptor. Remember that descriptors are represented by the integer data type. You may want to actually compute the maximum and pass that through, but the simplest option is to simply pass the integer literal 1024, the maximum number that will be assigned to a process. This likely will cause the function to run for longer, so whatever you prefer.

`readfds`, `writefds`, and `exceptfds` are our sets of file descriptors that we're passing through, to wait for reading, writing, and `exceptional conditions` respectively. Exceptional conditions are often very specific and don't need to be worried about.

We can also pass timeout, to specify how long we should wait for our file descriptors until giving up. If we never want to bail we simply pass `NULL`.

The `fd_set` data structure is how we pass our file descriptors to `select`, and is interacted with via the four macros below:

{% highlight c %}{% raw %}void FD_CLR(int fd, fd_set *set);
int FD_ISSET(int fd, fd_set *set);
void FD_SET(int fd, fd_set *set);
void FD_ZERO(fd_set *set);{% endraw %}{% endhighlight %}

We first initialise our set to by empty with `FD_ZERO`. To add a file descriptor we call `FD_SET` with our desired `fd` and the set we want to add it to. We can similarly remove that `fd` from the set with `FD_CLR`. If we want to know whether a file descriptor is in the set then we’ll want to use `FD_ISSET`.

{% highlight c %}{% raw %}fd_set *fds;
FD_ZERO(fds);
int fd = 5;
FD_SET(fd);
FD_ISSET(fd, fds);
FD_CLR(fd, fds);
FD_ISSET(fd, fds);{% endraw %}{% endhighlight %}

Our `fd_set` can then be passed into `select` as one of the three set types and waited on.

### A Networking Listening Example

We explore a typical main loop using `select` to implement an event-driven program responding to messages received on the network.

{% highlight c %}{% raw %}fd_set s;
FD_ZERO(&amp;s);
int sockfd = init_sock();
FD_SET(sockfd, &amp;s);
while (true) {
  fd_set copy = s;
  int n_ready = 0;
  if ((n_ready = select(FD_SETSIZE, &amp;copy, NULL, NULL, NULL)) < 0) {
    exit(EXIT_FAILURE);
  } else if (n_ready == 0) {
    continue;
  }
...{% endraw %}{% endhighlight %}

The first thing we do in the loop is make a copy of our `fd_set`, `s`, which has had our socket file descriptor added to it. We make this copy because the `select` call modifies the the `fd_set` passed to it, and we would like to maintain our original version.

We then make our `select` call, passing our `fd_set` copy as the read set and using the provided `FD_SETSIZE` as our maximum descriptor number. This call blocks our process, returning when one of our provided file descriptors is ready to be read, and we verify that the number of ready descriptors is actually non-zero using `n_ready`.

{% highlight c %}{% raw %}...
if (FD_ISSET(sockfd, &amp;copy)) {
  recvfrom(sockfd, (void *)buffer, sizeof buffer, MSG_WAITALL, NULL, NULL);
  printf("%s\n", (char *)buffer);
}
...{% endraw %}{% endhighlight %}

We then check if our socket file descriptor is set using the `FD_ISSET` macro, and if so we receive the message and print it.

### A Practical Implementation

The best way to learn is by playing around with it yourself. I have written a small demonstration project [hosted on Github](https://github.com/benmandrew/select-demo) that involves a pair of programs: one sending periodic 'Hello' messages on the local loopback interface, and the other receiving them; the receiver uses a very similar structure as in the example above. Both programs involve the `select` system call for waiting on events. I would recommend having an explore.

Event-driven specific things are in the [`fd_event.c`](https://github.com/benmandrew/select-demo/blob/main/src/fd_event.c) file. This was done because the sender and listener share a lot of event-driven functionality, and it provides a somewhat general interface if you want to use it in your own projects.

I also make extensive use of this technique in my 3rd year undergraduate dissertation project, an implementation of a delay-tolerant link-state routing protocol (DTLSR) in C for running on Unix-based routers. The Github repo is linked [here](https://github.com/benmandrew/DTLSR). That project was the reason I originally explored this area, and the example repo above is derived from it.

### Conclusion

This approach is not lightweight, nor is it easy to use. This is not the ideal option for fully isolated event systems that don't interact with the outside world, such as an event-loop for a game engine. For one, Unix often limits the number of file descriptors a process can open to 1024. But even more, all of the kernel system calls we're doing introduce a large amount of overhead. However for many use-cases that involve external operating system events like receiving data on sockets, using system timers, detecting keypresses, etc. this is the only real 'lightweight' option.

##### Links:

- [Demonstration Github repo](https://github.com/benmandrew/select-demo)
- [`select` man page](https://man7.org/linux/man-pages/man2/select.2.html)
- [DTLSR Github repo](https://github.com/benmandrew/DTLSR)
